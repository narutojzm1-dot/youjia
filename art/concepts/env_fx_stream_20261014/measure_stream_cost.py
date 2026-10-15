#!/usr/bin/env python3
"""#749 溪流候选：资源成本与显式遮罩裁切测量（仍只是候选，不改生产）。

Agent-ID: GROK-BUILD
从本目录已提交的蒙版/贴图测量：水面覆盖率、建议裁切矩形、整幅 vs 裁切显存估算、
PNG 字节数，以及低动效静帧相对原画的保护区差。只读，不写任何文件。
用法（仓库根）：python3 art/concepts/env_fx_stream_20261014/measure_stream_cost.py
"""
import os
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
PAD = 16
FULL_TEX = ["flow_map.png", "coord_sn.png", "water_detail.png", "secondary_map.png", "secondary_weight.png"]


def load(name):
    return np.array(Image.open(os.path.join(HERE, name)))


def bbox(a):
    ys, xs = np.nonzero(a)
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def main():
    water = load("mask_water.png") > 0
    flow_a = load("flow_map.png")[..., 3] > 0
    sec = load("secondary_weight.png").max(axis=2) > 0
    protect = load("mask_protect.png") > 0
    h, w = water.shape
    active = water | flow_a | sec
    print(f"canvas {w}x{h}")
    print(f"water px {int(water.sum())} ({water.mean()*100:.2f}%) bbox {bbox(water)}")
    print(f"secondary px {int(sec.sum())} bbox {bbox(sec)}")
    print(f"protect px {int(protect.sum())} ({protect.mean()*100:.2f}%)")
    print(f"protect & active overlap px {int((protect & active).sum())}")
    x0, y0, x1, y1 = bbox(active)
    x0, y0 = max(0, x0 - PAD), max(0, y0 - PAD)
    x1, y1 = min(w, x1 + PAD), min(h, y1 + PAD)
    cw, ch = x1 - x0, y1 - y0
    print(f"crop rect (pad {PAD}) x{x0}-{x1} y{y0}-{y1} = {cw}x{ch} ({cw*ch/(w*h)*100:.1f}% of canvas)")
    full_mib = w * h * 4 / 2**20
    crop_mib = cw * ch * 4 / 2**20
    print(f"RGBA8 VRAM per full texture {full_mib:.2f} MiB x{len(FULL_TEX)} = {full_mib*len(FULL_TEX):.2f} MiB")
    print(f"RGBA8 VRAM per cropped texture {crop_mib:.3f} MiB x{len(FULL_TEX)} = {crop_mib*len(FULL_TEX):.3f} MiB")
    rt = Image.open(os.path.join(HERE, "ripple_tile.png")).size
    print(f"ripple_tile {rt[0]}x{rt[1]} RGBA8 {rt[0]*rt[1]*4/2**10:.1f} KiB")
    png = {f: os.path.getsize(os.path.join(HERE, f)) for f in FULL_TEX + ["ripple_tile.png"]}
    print(f"png bytes total {sum(png.values())} {png}")
    print(f"fragments: full-canvas quad {w*h}, cropped quad {cw*ch} ({cw*ch/(w*h)*100:.1f}%)")
    base_p = os.path.join(REPO, "assets", "holiday", "exploration", "near_path_02.webp")
    stat_p = os.path.join(HERE, "sample_frames", "stream_static_low_motion.png")
    if os.path.isfile(base_p) and os.path.isfile(stat_p):
        base = np.array(Image.open(base_p).convert("RGB")).astype(int)
        stat = np.array(Image.open(stat_p).convert("RGB")).astype(int)
        if base.shape == stat.shape:
            d = np.abs(base - stat).max(axis=2)
            outside = np.ones_like(water)
            outside[y0:y1, x0:x1] = False
            print(f"low-motion static vs base: protect max diff {int(d[protect].max())}, "
                  f"outside-crop max diff {int(d[outside].max())}, "
                  f"water mean diff {d[water].mean():.2f}, changed px {int((d>0).sum())}")
        else:
            print(f"low-motion static shape {stat.shape} != base {base.shape}; skipped")


if __name__ == "__main__":
    main()
