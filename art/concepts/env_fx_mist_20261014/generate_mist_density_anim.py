#!/usr/bin/env python3
"""Reproducible generator for lake/valley mist isolation candidate (#749).

Two hand-painted mist layers (derived from approved mist_candidate.png) +
multi-scale continuous alpha/micro-deform modulation + soft spatial envelope.
Foreground path / cottage / bridge / paper rim stay pixel-stable across frames.

Aligned with godot_preview/mist_density.gdshader defaults.
# 2026-10-14 加强运动：整数谐波聚散 + 可见漂移/抬升。phase 与 phase+2π 相同。
# 手绘层本身横向几乎均匀，平移必须带动调制波；覆盖度只乘一次，避免运动被平方吃掉。
"""
from __future__ import annotations

import argparse
import os
import shutil

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

# Defaults mirrored by mist_density.gdshader / mist_density_preview.tscn
BASE_SIZE = (1672, 941)
# 雾带重心放到谷地，而不是压在近景小路和屋顶上
FAR_ORIGIN = (70, 220)
NEAR_ORIGIN = (160, 300)
FAR_SCALE = 1.0  # layers already pre-scaled into mist_far/near pngs
NEAR_SCALE = 1.0
# 调制分母（层像素）。波长 = 2π * 分母；一圈平移一个大团波长。
FAR_MOD_XX = 230.0
FAR_MOD_YY = 160.0
FAR_MOD_FINE = 92.0
NEAR_MOD_XX = 145.0
NEAR_MOD_YY = 110.0
NEAR_MOD_FINE = 60.0
# 水平漂移（像素，sin(phase)）。带动层空间里的浓淡波，不是空移一块均匀色带。
FAR_DRIFT_PX = 150.0
NEAR_DRIFT_PX = -120.0
# 垂直抬升（像素）。(1-cos(phase))/2：起点贴谷底，中点抬到最高，一圈回到起点。
FAR_LIFT_PX = 48.0
NEAR_LIFT_PX = 62.0
# 微形变幅度（像素）。空间周期须与 shader 常量一致。
FAR_DEFORM = 22.0
NEAR_DEFORM = 30.0
DEFORM_X_PERIOD = 160.0
DEFORM_Y_PERIOD = 300.0
# 近层相位错开，避免两层同步呼吸
NEAR_PHASE = 2.1
# 远层相对强度
FAR_STRENGTH = 0.90
# 单层覆盖上限，峰值是乳白色雾团，不是铺满的死白
CA_CAP = 170.0
BLUR_RADIUS = 26
# 谷地/湖面软带；前景小路、木屋屋顶、桥、纸边挖空
ENVELOPE_TOP = 430
ENVELOPE_BOTTOM = 740
ENVELOPE_LEFT = 80
ENVELOPE_RIGHT = 1500
# Hard protect ellipses / polygons (black = protect) before blur
PATH_ELLIPSE = (400, 780, 1150, 970)  # 近景小路，留在雾带下方
COTTAGE_BOX = (1120, 340, 1640, 800)  # 木屋含屋顶
BRIDGE_BOX = (100, 500, 500, 760)
PAPER_RIM = 28  # fade outer paper edge


def mist_modulation(phase: float, xx: np.ndarray, yy: np.ndarray, mod_xx: float, mod_yy: float, mod_fine: float) -> np.ndarray:
    """整数谐波聚散。只用 1× 与 2×，phase=0 与 phase=2π 相同，循环缝无跳变。

    大团每圈平移一个波长（中点相对起点错开半个波长）；细团两圈、反向。
    """
    bank = np.sin(phase + xx / mod_xx + yy / (mod_yy * 1.7))
    wisp = np.sin(phase * 2.0 - xx / mod_fine + yy / mod_yy)
    # 薄隙仍留一点雾，峰值拉到明显的一团
    mod = 0.12 + 0.58 * bank + 0.30 * wisp
    return np.clip(mod, 0.02, 1.0)


def build_envelope(size: tuple[int, int]) -> Image.Image:
    """White = allow mist, black = protect. Soft valley/lake band + foreground cutouts."""
    w, h = size
    env = Image.new("L", size, 0)
    draw = ImageDraw.Draw(env)
    # Vertical falloff: strongest mid band
    for y in range(h):
        if y < ENVELOPE_TOP:
            a = int(255 * max(0.0, 1.0 - (ENVELOPE_TOP - y) / 160.0) * 0.45)
        elif y > ENVELOPE_BOTTOM:
            a = int(255 * max(0.0, 1.0 - (y - ENVELOPE_BOTTOM) / 160.0) * 0.35)
        else:
            # 谷地中段留出足够浓度，雾团的浓淡才看得见
            t = (y - ENVELOPE_TOP) / max(1.0, ENVELOPE_BOTTOM - ENVELOPE_TOP)
            a = int(255 * (0.72 + 0.28 * np.sin(np.pi * t)))
        draw.line([(0, y), (w, y)], fill=a)
    # Horizontal soft sides
    side = Image.new("L", size, 0)
    sdraw = ImageDraw.Draw(side)
    for x in range(w):
        if x < ENVELOPE_LEFT:
            a = int(255 * max(0.0, x / max(1.0, ENVELOPE_LEFT)))
        elif x > ENVELOPE_RIGHT:
            a = int(255 * max(0.0, 1.0 - (x - ENVELOPE_RIGHT) / max(1.0, w - ENVELOPE_RIGHT)))
        else:
            a = 255
        sdraw.line([(x, 0), (x, h)], fill=a)
    env = Image.fromarray(
        (np.array(env, dtype=np.float32) * np.array(side, dtype=np.float32) / 255.0).astype(np.uint8),
        "L",
    )
    # Protect foreground path / cottage / bridge / paper rim
    draw = ImageDraw.Draw(env)
    draw.ellipse(list(PATH_ELLIPSE), fill=0)
    draw.rectangle(list(COTTAGE_BOX), fill=0)
    draw.rectangle(list(BRIDGE_BOX), fill=0)
    draw.rectangle([0, 0, w, PAPER_RIM], fill=0)
    draw.rectangle([0, h - PAPER_RIM, w, h], fill=0)
    draw.rectangle([0, 0, PAPER_RIM, h], fill=0)
    draw.rectangle([w - PAPER_RIM, 0, w, h], fill=0)
    env = env.filter(ImageFilter.GaussianBlur(radius=BLUR_RADIUS))
    return env


def build_protect_masks(size: tuple[int, int]) -> tuple[Image.Image, Image.Image, Image.Image]:
    """Semantic allow-masks (white allow) for optional hard gate in shader."""
    def allow() -> Image.Image:
        return Image.new("L", size, 255)

    path = allow()
    ImageDraw.Draw(path).ellipse(list(PATH_ELLIPSE), fill=0)
    cottage = allow()
    ImageDraw.Draw(cottage).rectangle(list(COTTAGE_BOX), fill=0)
    bridge = allow()
    ImageDraw.Draw(bridge).rectangle(list(BRIDGE_BOX), fill=0)
    return path, cottage, bridge


def _muldiv255(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    t = a.astype(np.int32) * b.astype(np.int32) + 128
    return ((t >> 8) + t) >> 8


def sample_layer(
    layer_rgba: np.ndarray,
    base_px_x: np.ndarray,
    base_px_y: np.ndarray,
    origin: tuple[int, int],
    phase: float,
    drift_px: float,
    lift_px: float,
    deform: float,
    mod_xx: float,
    mod_yy: float,
    mod_fine: float,
    strength: float,
) -> tuple[np.ndarray, np.ndarray]:
    """直线 RGB 与覆盖度 ca。覆盖度稍后只与包络相乘一次。"""
    h, w = layer_rgba.shape[:2]
    ox, oy = origin
    # 水平漂移带动调制采样点；垂直抬升让雾带边缘一圈内升起再落下
    drift = drift_px * np.sin(phase)
    lift = lift_px * (1.0 - np.cos(phase)) * 0.5
    lx = base_px_x - ox - drift + deform * 0.55 * np.sin(phase * 2.0 + base_px_y / DEFORM_X_PERIOD)
    ly = base_px_y - oy - lift + deform * np.cos(phase + base_px_x / DEFORM_Y_PERIOD)
    xi = np.floor(lx).astype(np.int32)
    yi = np.floor(ly).astype(np.int32)
    inside = (xi >= 0) & (xi < w) & (yi >= 0) & (yi < h)
    rgb = np.zeros(base_px_x.shape + (3,), dtype=np.float64)
    a = np.zeros(base_px_x.shape, dtype=np.int32)
    if not inside.any():
        return rgb, a
    xs = xi[inside]
    ys = yi[inside]
    pix = layer_rgba[ys, xs]
    mod = mist_modulation(phase, xs.astype(np.float64), ys.astype(np.float64), mod_xx, mod_yy, mod_fine)
    ca = np.clip(np.floor(pix[:, 3].astype(np.float64) * mod * strength), 0, CA_CAP).astype(np.int32)
    rgb[inside] = pix[:, :3]
    a[inside] = ca
    return rgb, a


def composite_frame(
    base_rgb: np.ndarray,
    far: np.ndarray,
    near: np.ndarray,
    mask_u8: np.ndarray,
    phase: float,
    strength: float = 1.0,
) -> np.ndarray:
    h, w = base_rgb.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float64)
    far_rgb, far_a = sample_layer(
        far, xx, yy, FAR_ORIGIN, phase, FAR_DRIFT_PX, FAR_LIFT_PX, FAR_DEFORM,
        FAR_MOD_XX, FAR_MOD_YY, FAR_MOD_FINE, strength * FAR_STRENGTH,
    )
    near_rgb, near_a = sample_layer(
        near, xx, yy, NEAR_ORIGIN, phase + NEAR_PHASE, NEAR_DRIFT_PX, NEAR_LIFT_PX, NEAR_DEFORM,
        NEAR_MOD_XX, NEAR_MOD_YY, NEAR_MOD_FINE, strength,
    )
    # 先远后近。覆盖度 = ca 与包络各乘一次，雾色按这个比例盖到原画上。
    out = base_rgb.astype(np.float64)
    mask_i = mask_u8.astype(np.int32)
    for rgb, a in ((far_rgb, far_a), (near_rgb, near_a)):
        cov = _muldiv255(a, mask_i).astype(np.float64) / 255.0
        out = rgb * cov[..., None] + out * (1.0 - cov[..., None])
    return np.clip(np.round(out), 0, 255).astype(np.uint8)


def _paths(base_path, far_path, near_path):
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.abspath(os.path.join(script_dir, "..", "..", ".."))
    if base_path is None:
        base_path = os.path.join(repo_root, "assets", "holiday", "exploration", "near_path_02.webp")
    if far_path is None:
        far_path = os.path.join(script_dir, "mist_far_layer.png")
    if near_path is None:
        near_path = os.path.join(script_dir, "mist_near_layer.png")
    return script_dir, repo_root, base_path, far_path, near_path


def export_preview(script_dir: str, base: Image.Image, far: Image.Image, near: Image.Image, env: Image.Image,
                   path_m: Image.Image, cottage_m: Image.Image, bridge_m: Image.Image) -> None:
    tex = os.path.join(script_dir, "godot_preview", "textures")
    os.makedirs(tex, exist_ok=True)
    base.convert("RGBA").save(os.path.join(tex, "near_path_base.png"), optimize=True)
    far.save(os.path.join(tex, "mist_far.png"), optimize=True)
    near.save(os.path.join(tex, "mist_near.png"), optimize=True)
    env.save(os.path.join(tex, "mask_envelope.png"), optimize=True)
    path_m.save(os.path.join(tex, "mask_path.png"), optimize=True)
    cottage_m.save(os.path.join(tex, "mask_cottage.png"), optimize=True)
    bridge_m.save(os.path.join(tex, "mask_bridge.png"), optimize=True)
    print(f"Exported preview textures to {tex}")


def generate(out_dir=None, n_frames=40, base_path=None, far_path=None, near_path=None, export_preview_tex=False):
    script_dir, _repo, base_path, far_path, near_path = _paths(base_path, far_path, near_path)
    if out_dir is None:
        out_dir = os.path.join(script_dir, "anim_frames")
    os.makedirs(out_dir, exist_ok=True)

    base_img = Image.open(base_path).convert("RGBA")
    if base_img.size != BASE_SIZE:
        print(f"WARN: base size {base_img.size} != {BASE_SIZE}")
    far_img = Image.open(far_path).convert("RGBA")
    near_img = Image.open(near_path).convert("RGBA")
    env = build_envelope(base_img.size)
    path_m, cottage_m, bridge_m = build_protect_masks(base_img.size)
    mask_u8 = np.array(env.convert("L"))
    base_rgb = np.array(base_img.convert("RGB"))
    far = np.array(far_img)
    near = np.array(near_img)

    for i in range(n_frames):
        phase = i / n_frames * 2 * np.pi
        frame = composite_frame(base_rgb, far, near, mask_u8, phase)
        Image.fromarray(frame, "RGB").save(os.path.join(out_dir, f"mist_frame_{i:02d}.png"), optimize=True)

    # Low-motion static: phase 0 with reduced strength
    static = composite_frame(base_rgb, far, near, mask_u8, 0.0, strength=0.35)
    Image.fromarray(static, "RGB").save(os.path.join(out_dir, "mist_static_low_motion.png"), optimize=True)

    # Sample frames
    sample_dir = os.path.join(script_dir, "sample_frames")
    os.makedirs(sample_dir, exist_ok=True)
    for idx in (0, 10, 20, 30):
        src = os.path.join(out_dir, f"mist_frame_{idx:02d}.png")
        if os.path.isfile(src):
            shutil.copy2(src, os.path.join(sample_dir, f"mist_frame_{idx:02d}.png"))
    shutil.copy2(os.path.join(out_dir, "mist_static_low_motion.png"), os.path.join(sample_dir, "mist_static_low_motion.png"))

    # 保护区应几乎不动；谷地浓淡在首帧与中帧必须肉眼可辨。循环缝应接近相邻帧，而不是跳变。
    f0 = np.array(Image.open(os.path.join(out_dir, "mist_frame_00.png")))
    f1 = np.array(Image.open(os.path.join(out_dir, "mist_frame_01.png")))
    f10 = np.array(Image.open(os.path.join(out_dir, "mist_frame_10.png")))
    f20 = np.array(Image.open(os.path.join(out_dir, "mist_frame_20.png")))
    f39 = np.array(Image.open(os.path.join(out_dir, "mist_frame_39.png")))
    protect = mask_u8 < 8
    valley = mask_u8 > 100

    def _motion(a, b, label):
        d = np.abs(a.astype(np.int16) - b.astype(np.int16))
        ch = d.max(axis=2)
        valley_mean = float(d[valley].mean()) if valley.any() else -1.0
        protect_max = int(d[protect].max()) if protect.any() else -1
        print(
            f"{label} mean {d.mean():.2f} valley {valley_mean:.2f} "
            f"frac>8 {(ch > 8).mean():.3f} frac>20 {(ch > 20).mean():.3f} "
            f"max {int(d.max())} protect_max {protect_max}"
        )

    _motion(f0, f1, "frame00 vs 01")
    _motion(f0, f10, "frame00 vs 10")
    _motion(f0, f20, "frame00 vs 20")
    _motion(f0, f39, "frame00 vs 39 seam")

    env.save(os.path.join(script_dir, "mask_envelope.png"), optimize=True)
    if export_preview_tex:
        export_preview(script_dir, base_img, far_img, near_img, env, path_m, cottage_m, bridge_m)

    print(f"Generated {n_frames} frames + static in {out_dir}")
    print(f"Base: {base_path}")
    print(f"Far: {far_path}")
    print(f"Near: {near_path}")


def main():
    ap = argparse.ArgumentParser(description="Generate #749 mist isolation candidate frames")
    ap.add_argument("--frames", type=int, default=40)
    ap.add_argument("--out", default=None)
    ap.add_argument("--base", default=None)
    ap.add_argument("--far", default=None)
    ap.add_argument("--near", default=None)
    ap.add_argument("--export-preview", action="store_true")
    args = ap.parse_args()
    generate(
        out_dir=args.out,
        n_frames=args.frames,
        base_path=args.base,
        far_path=args.far,
        near_path=args.near,
        export_preview_tex=args.export_preview,
    )


if __name__ == "__main__":
    main()
