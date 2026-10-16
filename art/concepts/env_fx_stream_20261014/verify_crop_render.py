#!/usr/bin/env python3
"""#749 溪流候选：整幅版 vs 裁切版渲染逐像素对照（仍只是候选，不改生产）。

Agent-ID: GROK-BUILD
用 Godot 4.7 分别导出 stream_flow_preview.tscn（整幅四边形）与 stream_flow_crop_demo.tscn
（整幅原画 + 183×302 溪床子层）的同 phase 帧，再与原画比较。只写到 --out 目录，不改仓库文件。
用法（仓库根）：
  GODOT=/path/to/godot python3 art/concepts/env_fx_stream_20261014/verify_crop_render.py --out /tmp/crop749
没有显示器时在命令前加 xvfb-run -a -s "-screen 0 1800x1000x24"。
"""
import argparse
import math
import os
import subprocess
import sys
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.join(HERE, "godot_preview")
TEX = os.path.join(PROJ, "textures")
X, Y, W, H = 191, 543, 183, 302
PHASES = [0.0, math.pi / 2, math.pi, 3 * math.pi / 2, math.tau]


def dump(godot, scene, out, *extra):
    cmd = [godot, "--rendering-driver", "opengl3", "--path", PROJ, "--resolution", "1672x941",
           scene, "--", "--dump-frame", out, *extra]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=120)
    return np.array(Image.open(out).convert("RGB")).astype(int)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--tolerance", type=int, default=1, help="整幅 vs 裁切允许的最大通道差（GPU 采样舍入）")
    a = ap.parse_args()
    godot = os.environ.get("GODOT", "godot")
    os.makedirs(a.out, exist_ok=True)
    base = np.array(Image.open(os.path.join(TEX, "near_path_base.png")).convert("RGB")).astype(int)
    prot = np.array(Image.open(os.path.join(TEX, "mask_protect.png")))
    prot = (prot[..., 0] if prot.ndim == 3 else prot) > 0
    inside = np.zeros(base.shape[:2], bool)
    inside[Y:Y + H, X:X + W] = True
    ok = True
    crops = {}
    for ph in PHASES:
        tag = f"{ph:.4f}"
        full = dump(godot, "res://stream_flow_preview.tscn", os.path.join(a.out, f"full_{tag}.png"), "--phase", repr(ph))
        crop = dump(godot, "res://stream_flow_crop_demo.tscn", os.path.join(a.out, f"crop_{tag}.png"), "--phase", repr(ph))
        crops[ph] = crop
        d = np.abs(full - crop).max(axis=2)
        db = np.abs(crop - base).max(axis=2)
        good = d.max() <= a.tolerance and db[~inside].max() == 0 and db[prot].max() == 0
        ok = ok and good
        print(f"phase {tag}: crop-vs-full max {d.max()} ({int((d > 0).sum())} px); changed vs base {int((db > 0).sum())} px; "
              f"outside rect max {db[~inside].max()}; protect max {db[prot].max()} {'OK' if good else 'FAIL'}")
    loop = np.abs(crops[PHASES[0]] - crops[PHASES[-1]]).max()
    half = int((np.abs(crops[PHASES[0]] - crops[PHASES[2]]).max(axis=2) > 0).sum())
    print(f"loop phase 0 vs TAU max diff {loop}; half-cycle changed px {half}")
    ok = ok and loop == 0 and half > 0
    for name, extra in [("strength0", ["--strength", "0"]), ("reduced", ["--reduced"])]:
        img = dump(godot, "res://stream_flow_crop_demo.tscn", os.path.join(a.out, f"crop_{name}.png"), "--phase", "1.5707963", *extra)
        m = np.abs(img - base).max()
        print(f"{name}: max diff vs base {m} {'OK' if m == 0 else 'FAIL'}")
        ok = ok and m == 0
    print("RESULT", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
