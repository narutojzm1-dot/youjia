#!/usr/bin/env python3
"""#749 溪流候选：原速 30fps 录屏帧的循环与静止区核对（仍只是候选，不改生产）。

Agent-ID: GROK-BUILD
输入是 Godot Movie Maker 对 stream_flow_preview.tscn 录出的 PNG 序列（真实着色器、固定 30fps、
phase 按 8 秒一圈的真实 delta 推进，不是 Python 生成帧，也不是加速/抽帧）。只读帧目录，不改仓库文件。

录制（仓库根，无显示器时加 xvfb-run）：
  xvfb-run -a -s "-screen 0 1800x1000x24" godot --path art/concepts/env_fx_stream_20261014/godot_preview \
    --resolution 1672x941 --write-movie /tmp/mv749/f.png --fixed-fps 30 --quit-after 1200 -- --hide-ui
核对：
  python3 art/concepts/env_fx_stream_20261014/verify_realtime_movie.py /tmp/mv749
"""
import argparse
import glob
import json
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
TEX = os.path.join(HERE, "godot_preview", "textures")
FPS = 30
PERIOD_FRAMES = 8 * FPS  # 一圈 8 秒


def load(p):
    return np.asarray(Image.open(p).convert("RGB"), dtype=np.int16)


def mask(name):
    m = np.asarray(Image.open(os.path.join(TEX, name)))
    return (m[..., 0] if m.ndim == 3 else m) > 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("frames_dir")
    ap.add_argument("--expect-frames", type=int, default=40 * FPS)
    ap.add_argument("--loop-tolerance", type=int, default=0, help="第 2 圈起相隔一整圈两帧允许的最大通道差")
    ap.add_argument("--startup-tolerance", type=int, default=3, help="第 1 圈 vs 第 2 圈允许的最大通道差（录制启动段）")
    ap.add_argument("--spike-ratio", type=float, default=1.5, help="圈界相邻帧差 / 全片相邻帧差中位数 的上限")
    a = ap.parse_args()

    files = sorted(glob.glob(os.path.join(a.frames_dir, "*.png")))
    n = len(files)
    water = mask("mask_water.png")
    prot = mask("mask_protect.png")
    still = ~water  # 水遮罩以外整片都应不动
    first = load(files[0])
    loop_max = 0  # 第 2 圈起：第 k 帧 vs 第 k+240 帧
    first_cycle = {"max": 0, "frames": []}  # 第 1 圈 vs 第 2 圈（启动段单独报告，不并入稳态循环）
    still_max = 0
    prot_max = 0
    steps = []
    prev = first
    ring = {}
    for k, f in enumerate(files):
        cur = load(f)
        d0 = np.abs(cur - first).max(axis=2)
        still_max = max(still_max, int(d0[still].max()))
        prot_max = max(prot_max, int(d0[prot].max()))
        if k:
            steps.append(float(np.abs(cur - prev)[water].mean()))
        if k >= PERIOD_FRAMES:
            dl = int(np.abs(cur - ring.pop(k - PERIOD_FRAMES)).max())
            if k < 2 * PERIOD_FRAMES:
                first_cycle["max"] = max(first_cycle["max"], dl)
                if dl:
                    first_cycle["frames"].append(k - PERIOD_FRAMES)
            else:
                loop_max = max(loop_max, dl)
        ring[k] = cur
        prev = cur
    steps = np.array(steps)
    med = float(np.median(steps))
    # steps[i] 是第 i 帧到第 i+1 帧；圈界是第 240k-1 → 240k 帧
    bounds = [b - 1 for b in range(PERIOD_FRAMES, n, PERIOD_FRAMES)]
    bound_steps = [float(steps[b]) for b in bounds]
    half = int((np.abs(load(files[min(PERIOD_FRAMES // 2, n - 1)]) - first).max(axis=2)[water] > 0).sum())
    res = {
        "frames": n,
        "fps": FPS,
        "seconds": n / FPS,
        "period_frames": PERIOD_FRAMES,
        "loop_max_diff": loop_max,
        "first_vs_second_cycle_max_diff": first_cycle["max"],
        "first_cycle_frames_differing": first_cycle["frames"],
        "still_outside_water_max_diff": still_max,
        "protect_max_diff": prot_max,
        "half_cycle_changed_water_px": half,
        "step_mean_median": round(med, 4),
        "step_mean_max": round(float(steps.max()), 4),
        "step_mean_min": round(float(steps.min()), 4),
        "boundary_steps": [round(s, 4) for s in bound_steps],
    }
    ok = (n == a.expect_frames and loop_max <= a.loop_tolerance and first_cycle["max"] <= a.startup_tolerance and still_max == 0 and prot_max == 0
          and half > 0 and steps.min() > 0 and all(s <= med * a.spike_ratio for s in bound_steps))
    res["ok"] = bool(ok)
    print("REALTIME_MOVIE " + json.dumps(res, ensure_ascii=False))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
