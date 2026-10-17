#!/usr/bin/env python3
"""#749 溪流候选：连续暂停 / 低动效切换的原速录屏核对（仍只是候选，不改生产）。

Agent-ID: GROK-BUILD
输入：Godot Movie Maker 对 stream_flow_preview.tscn 以固定 30fps 录出的 PNG 序列，以及同次运行的
stdout 日志（含每帧 TOGGLE_SEQ JSON）。驱动按帧号注入真实按键事件（P 暂停/继续、L 低动效），
走与玩家相同的 _unhandled_input 路径。本脚本只读帧目录与日志，不改仓库文件。

录制（仓库根，无显示器时加 xvfb-run）：
  xvfb-run -a -s "-screen 0 1800x1000x24" godot --path art/concepts/env_fx_stream_20261014/godot_preview \
    --resolution 1672x941 --write-movie /tmp/mvtog/f.png --fixed-fps 30 --quit-after 360 \
    -- --hide-ui --toggle-sequence > /tmp/mvtog_log.txt 2>&1
核对：
  python3 art/concepts/env_fx_stream_20261014/verify_toggle_sequence.py /tmp/mvtog /tmp/mvtog_log.txt

检查项：
  1. 状态切换只发生在排定帧（与 TOGGLE_SCHEDULE 一致），同帧双键/隔帧快切都生效。
  2. 每帧 phase 步长：正常 2π/240、低动效 2π/960、暂停 0（容差 1e-6；首帧 Godot 给的 delta 另记）。
  3. 继续时 phase 从暂停值接着走一步，无跳变。
  4. 像素：暂停中相邻帧整画面差 0；运动段水域有变化；低动效段平均帧差小于正常段；
     水遮罩外与保护区全程差 0。
不能当作实体设备 30fps 性能、宿主接线或正式美术验收。
"""
import argparse
import glob
import json
import math
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
TEX = os.path.join(HERE, "godot_preview", "textures")
TAU = 2 * math.pi
FPS = 30
NORMAL_STEP = TAU / 8.0 / FPS
LOW_STEP = NORMAL_STEP * 0.25
# 与 stream_flow_driver.gd 的 TOGGLE_SCHEDULE 一致：帧号 → 按键
SCHEDULE = {60: "P", 120: "P", 150: "L", 180: "P", 210: "P", 240: "L",
            270: "P", 271: "P", 280: "L", 281: "L", 300: "LP", 330: "PL"}


def load(p):
    return np.asarray(Image.open(p).convert("RGB"), dtype=np.int16)


def mask(name):
    m = np.asarray(Image.open(os.path.join(TEX, name)))
    return (m[..., 0] if m.ndim == 3 else m) > 0


def expected_states(n):
    paused = low = False
    out = []
    for f in range(n):
        for k in SCHEDULE.get(f, ""):
            if k == "P":
                paused = not paused
            else:
                low = not low
        out.append((paused, low))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("frames_dir")
    ap.add_argument("log")
    ap.add_argument("--expect-frames", type=int, default=360)
    a = ap.parse_args()

    log = []
    with open(a.log, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            if line.startswith("TOGGLE_SEQ "):
                log.append(json.loads(line[len("TOGGLE_SEQ "):]))
    files = sorted(glob.glob(os.path.join(a.frames_dir, "f*.png")))
    n = min(len(files), len(log))
    exp = expected_states(len(log))

    state_mismatch = [r["frame"] for r, e in zip(log, exp) if (r["paused"], r["low"]) != e]
    step_bad = []
    resume_jumps = []
    prev_phase = 0.0
    for i, r in enumerate(log):
        step = (r["phase"] - prev_phase) % TAU
        if r["paused"]:
            want = 0.0
        else:
            base = TAU / 8.0 * r["delta"]
            want = base * (0.25 if r["low"] else 1.0)
        if i > 0 and abs(step - want) > 1e-6:
            step_bad.append({"frame": r["frame"], "step": step, "want": want})
        if i > 0 and log[i - 1]["paused"] and not r["paused"] and abs(step - want) > 1e-6:
            resume_jumps.append(r["frame"])
        prev_phase = r["phase"]
    first_delta = log[0]["delta"] if log else None

    water = mask("mask_water.png")
    prot = mask("mask_protect.png")
    still = ~water
    paused_pairs_max = 0
    still_max = 0
    prot_max = 0
    seg = {"normal": [], "low": []}
    moving_zero = []
    prev = load(files[0])
    for i in range(1, n):
        cur = load(files[i])
        d = np.abs(cur - prev).max(axis=2)
        still_max = max(still_max, int(d[still].max()))
        prot_max = max(prot_max, int(d[prot].max()))
        p, lo = log[i]["paused"], log[i]["low"]
        if p:
            paused_pairs_max = max(paused_pairs_max, int(d.max()))
        else:
            m = float(d[water].mean())
            seg["low" if lo else "normal"].append(m)
            if int(d[water].max()) == 0:
                moving_zero.append(i)
        prev = cur
    normal_mean = float(np.mean(seg["normal"])) if seg["normal"] else None
    low_mean = float(np.mean(seg["low"])) if seg["low"] else None
    paused_frames = sum(1 for r in log[1:n] if r["paused"])

    res = {
        "frames": n, "log_frames": len(log), "png_frames": len(files), "fps": FPS,
        "first_frame_delta": first_delta,
        "state_mismatch_frames": state_mismatch,
        "step_mismatch": step_bad[:10], "step_mismatch_count": len(step_bad),
        "resume_jump_frames": resume_jumps,
        "paused_frame_pairs": paused_frames, "paused_pairs_max_diff": paused_pairs_max,
        "moving_frames_without_water_change": moving_zero,
        "normal_water_step_mean": round(normal_mean, 4) if normal_mean is not None else None,
        "low_water_step_mean": round(low_mean, 4) if low_mean is not None else None,
        "low_over_normal": round(low_mean / normal_mean, 4) if normal_mean and low_mean is not None else None,
        "still_outside_water_max_diff": still_max, "protect_max_diff": prot_max,
    }
    ok = (n == a.expect_frames and len(log) == a.expect_frames and not state_mismatch and not step_bad
          and not resume_jumps and paused_frames > 0 and paused_pairs_max == 0 and not moving_zero
          and normal_mean is not None and low_mean is not None and low_mean < normal_mean
          and still_max == 0 and prot_max == 0)
    res["ok"] = ok
    print("TOGGLE_MOVIE " + json.dumps(res, ensure_ascii=False))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
