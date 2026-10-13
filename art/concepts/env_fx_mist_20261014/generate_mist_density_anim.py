#!/usr/bin/env python3
"""Reproducible generator for lake/valley mist isolation candidate (#749).

Two hand-painted mist layers (derived from approved mist_candidate.png) +
multi-scale continuous alpha/micro-deform modulation + soft spatial envelope.
Foreground path / cottage / bridge / paper rim stay pixel-stable across frames.

Aligned with godot_preview/mist_density.gdshader defaults.
"""
from __future__ import annotations

import argparse
import os
import shutil

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

# Defaults mirrored by mist_density.gdshader
BASE_SIZE = (1672, 941)
FAR_ORIGIN = (80, 340)
NEAR_ORIGIN = (220, 420)
FAR_SCALE = 1.0  # layers already pre-scaled into mist_far/near pngs
NEAR_SCALE = 1.0
# Multi-scale modulation denominators (pixel space on each layer)
FAR_MOD_XX = 95.0
FAR_MOD_YY = 70.0
FAR_MOD_FINE = 38.0
NEAR_MOD_XX = 70.0
NEAR_MOD_YY = 55.0
NEAR_MOD_FINE = 28.0
# Optional slow horizontal drift (pixels over full 2π); small so motion is gather/disperse first
FAR_DRIFT_PX = 6.0
NEAR_DRIFT_PX = -4.0
# Micro UV deform amplitude in pixels
FAR_DEFORM = 1.4
NEAR_DEFORM = 1.8
BLUR_RADIUS = 22
# Soft envelope: allow mist in mid valley/lake band; protect foreground path & cottage
ENVELOPE_TOP = 280
ENVELOPE_BOTTOM = 720
ENVELOPE_LEFT = 40
ENVELOPE_RIGHT = 1500
# Hard protect ellipses / polygons (black = protect) before blur
PATH_ELLIPSE = (420, 620, 980, 920)  # foreground path lower center
COTTAGE_BOX = (1180, 480, 1580, 780)
BRIDGE_BOX = (180, 560, 420, 720)
PAPER_RIM = 28  # fade outer paper edge


def mist_modulation(phase: float, xx: np.ndarray, yy: np.ndarray, mod_xx: float, mod_yy: float, mod_fine: float) -> np.ndarray:
    """Integer-harmonic gather/disperse; phase=0 and 2π identical."""
    coarse = np.sin(phase + xx / mod_xx + yy / mod_yy) * np.cos(phase * 0.5 + yy / (mod_yy * 1.3))
    fine = np.sin(phase * 2.0 + xx / mod_fine - yy / (mod_fine * 1.1))
    # Bias toward soft mist; never full wipe
    mod = 0.42 + 0.38 * coarse + 0.12 * fine
    return np.clip(mod, 0.18, 0.95)


def build_envelope(size: tuple[int, int]) -> Image.Image:
    """White = allow mist, black = protect. Soft valley/lake band + foreground cutouts."""
    w, h = size
    env = Image.new("L", size, 0)
    draw = ImageDraw.Draw(env)
    # Vertical falloff: strongest mid band
    for y in range(h):
        if y < ENVELOPE_TOP:
            a = int(255 * max(0.0, 1.0 - (ENVELOPE_TOP - y) / 120.0) * 0.35)
        elif y > ENVELOPE_BOTTOM:
            a = int(255 * max(0.0, 1.0 - (y - ENVELOPE_BOTTOM) / 140.0) * 0.25)
        else:
            # Peak near lake mid
            t = (y - ENVELOPE_TOP) / max(1.0, ENVELOPE_BOTTOM - ENVELOPE_TOP)
            a = int(255 * (0.55 + 0.45 * np.sin(np.pi * t)))
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
    deform: float,
    mod_xx: float,
    mod_yy: float,
    mod_fine: float,
    strength: float,
) -> tuple[np.ndarray, np.ndarray]:
    """Return RGB u8 and A u8 arrays for the layer contribution at base pixel coords."""
    h, w = layer_rgba.shape[:2]
    ox, oy = origin
    # Optional translation (optional component per #749)
    drift = drift_px * np.sin(phase)
    # Local coords into layer
    lx = base_px_x - ox - drift
    ly = base_px_y - oy
    # Micro deform
    lx = lx + deform * np.sin(phase + base_px_y / 55.0)
    ly = ly + deform * 0.6 * np.cos(phase + base_px_x / 70.0)
    xi = np.floor(lx).astype(np.int32)
    yi = np.floor(ly).astype(np.int32)
    inside = (xi >= 0) & (xi < w) & (yi >= 0) & (yi < h)
    rgb = np.zeros(base_px_x.shape + (3,), dtype=np.int32)
    a = np.zeros(base_px_x.shape, dtype=np.int32)
    if not inside.any():
        return rgb, a
    xs = xi[inside]
    ys = yi[inside]
    pix = layer_rgba[ys, xs]
    mod = mist_modulation(phase, xs.astype(np.float64), ys.astype(np.float64), mod_xx, mod_yy, mod_fine)
    ca = np.clip(np.floor(pix[:, 3].astype(np.float64) * mod * strength), 0, 255).astype(np.int32)
    # paste-style: RGB and A each multiplied by ca
    pr = _muldiv255(pix[:, 0], ca)
    pg = _muldiv255(pix[:, 1], ca)
    pb = _muldiv255(pix[:, 2], ca)
    pa = _muldiv255(ca, ca)
    rgb[inside, 0] = pr
    rgb[inside, 1] = pg
    rgb[inside, 2] = pb
    a[inside] = pa
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
        far, xx, yy, FAR_ORIGIN, phase, FAR_DRIFT_PX, FAR_DEFORM,
        FAR_MOD_XX, FAR_MOD_YY, FAR_MOD_FINE, strength * 0.85,
    )
    near_rgb, near_a = sample_layer(
        near, xx, yy, NEAR_ORIGIN, phase + 1.7, NEAR_DRIFT_PX, NEAR_DEFORM,
        NEAR_MOD_XX, NEAR_MOD_YY, NEAR_MOD_FINE, strength,
    )
    # Over far then near (near sits closer)
    out = base_rgb.astype(np.float64)
    for rgb, a in ((far_rgb, far_a), (near_rgb, near_a)):
        ma = _muldiv255(a, mask_u8.astype(np.int32)).astype(np.float64) / 255.0
        mr = _muldiv255(rgb[:, :, 0], mask_u8.astype(np.int32)).astype(np.float64)
        mg = _muldiv255(rgb[:, :, 1], mask_u8.astype(np.int32)).astype(np.float64)
        mb = _muldiv255(rgb[:, :, 2], mask_u8.astype(np.int32)).astype(np.float64)
        masked = np.stack([mr, mg, mb], axis=-1)
        out = masked * ma[..., None] + out * (1.0 - ma[..., None])
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

    # Stability check: protect zones should be near-identical
    f0 = np.array(Image.open(os.path.join(out_dir, "mist_frame_00.png")))
    f10 = np.array(Image.open(os.path.join(out_dir, "mist_frame_10.png")))
    protect = (mask_u8 < 8)
    if protect.any():
        diff = np.max(np.abs(f0[protect].astype(np.int16) - f10[protect].astype(np.int16)))
        print(f"Protect-zone max channel diff frame00 vs 10: {diff}")
    skyish = mask_u8 > 40
    if skyish.any():
        diff2 = np.max(np.abs(f0[skyish].astype(np.int16) - f10[skyish].astype(np.int16)))
        print(f"Envelope-active max channel diff frame00 vs 10: {diff2}")

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
