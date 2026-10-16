#!/usr/bin/env python3
"""#749 溪流候选：按 CODEX-LEAD 给的溪床矩形裁切控制图（仍只是候选，不改生产）。

Agent-ID: GROK-BUILD
矩形 Rect2i(191, 543, 183, 302)，与 measure_stream_cost.py 的外扩 16 px 结果一致。
只从 godot_preview/textures/ 下已提交的整幅控制图裁切，写到 godot_preview/textures/crop/。
底图不裁切：宿主继续采样原 near_path_02，偏移由 crop_origin uniform 对齐。
写之前先校验：所有水面 / 次级层像素都在矩形里，矩形外控制值全为 0（或 water_detail 的中性灰）。
用法（仓库根）：python3 art/concepts/env_fx_stream_20261014/make_crop_textures.py [--check]
"""
import os
import sys
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "godot_preview", "textures")
DST = os.path.join(SRC, "crop")
RECT = (191, 543, 183, 302)  # x, y, w, h（Rect2i）
TEX = ["flow_map.png", "coord_sn.png", "water_detail.png", "secondary_map.png", "secondary_weight.png"]
MAX_TRAVEL_PX = 12  # stream_flow.gdshader advect_travel_px


def load(name):
    return np.array(Image.open(os.path.join(SRC, name)))


def main():
    check_only = "--check" in sys.argv
    x, y, w, h = RECT
    flow = load("flow_map.png")
    sec_w = load("secondary_weight.png")
    active = (flow[..., 3] > 0) | (sec_w.max(axis=2) > 0)
    ys, xs = np.nonzero(active)
    bx0, by0, bx1, by1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
    margin = min(bx0 - x, by0 - y, x + w - bx1, y + h - by1)
    inside = np.zeros_like(active)
    inside[y:y + h, x:x + w] = True
    outside_active = int((active & ~inside).sum())
    print(f"rect x{x} y{y} {w}x{h}; active bbox x{bx0}-{bx1} y{by0}-{by1}; min margin {margin}px")
    print(f"active px outside rect: {outside_active}")
    ok = outside_active == 0 and margin > MAX_TRAVEL_PX + 1
    if not ok:
        print("FAIL: rect does not contain active area with advect margin")
        return 1
    os.makedirs(DST, exist_ok=True)
    for name in TEX:
        full = load(name)
        crop = full[y:y + h, x:x + w]
        out = os.path.join(DST, name)
        if check_only:
            have = np.array(Image.open(out))
            same = have.shape == crop.shape and np.array_equal(have, crop)
            print(f"{name}: crop file matches source sub-rect: {same}")
            ok = ok and same
        else:
            Image.fromarray(crop).save(out, optimize=True)
            print(f"{name}: wrote {crop.shape[1]}x{crop.shape[0]} {Image.fromarray(crop).mode} {os.path.getsize(out)} B")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
