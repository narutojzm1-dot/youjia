#!/usr/bin/env python3
"""Reproducible generator for cloud internal density candidate animation.
Uses fixed yard_sunny.png background + soft sky mask + cloud_candidate.png.
Internal alpha modulation only; non-sky regions remain pixel-identical across frames.
Paths resolved relative to this script for clean repo reproduction.

# 云层变换与 godot_preview/cloud_density.gdshader 对齐。
# 改缩放、原点或调制分母时，必须同时改着色器里的同名默认值。
"""
from PIL import Image, ImageFilter, ImageDraw
import numpy as np
import os
import argparse
import shutil

## 与 cloud_density.gdshader 的默认 uniform 相同
CLOUD_SCALE = 1.8
CLOUD_ORIGIN = (180, 30)
MOD_XX = 70.0
MOD_YY_SIN = 50.0
MOD_YY_COS = 90.0
SKY_ROWS = 420
SKY_DENOM = 380.0
BLUR_RADIUS = 18
ROOF_ELLIPSE = (350, 220, 520, 360)
SNOW_POLYGON = ((980, 140), (1120, 140), (1120, 280), (980, 280))
CANOPY_ELLIPSE = (200, 180, 450, 320)


def cloud_modulation(phase, xx, yy):
    ## xx、yy 是缩放后云图的像素坐标，不是整幅画面的 0–1 UV
    mod = 0.4 + 0.5 * np.sin(phase + xx / MOD_XX + yy / MOD_YY_SIN) * np.cos(phase + yy / MOD_YY_COS)
    return np.clip(mod, 0.15, 1.0)


def build_masks(size):
    ## 白色 = 允许云，黑色 = 保护。语义遮罩是模糊前的硬边；合成遮罩才用于叠图。
    def allow_canvas():
        return Image.new("L", size, 255)

    roof = allow_canvas()
    ImageDraw.Draw(roof).ellipse(list(ROOF_ELLIPSE), fill=0)
    snow = allow_canvas()
    ImageDraw.Draw(snow).polygon(list(SNOW_POLYGON), fill=0)
    canopy = allow_canvas()
    ImageDraw.Draw(canopy).ellipse(list(CANOPY_ELLIPSE), fill=0)

    ## 天空渐变后再挖屋顶、雪峰、树冠，最后高斯模糊。顺序与历史帧一致。
    combined = Image.new("L", size, 0)
    draw = ImageDraw.Draw(combined)
    for y in range(SKY_ROWS):
        alpha = int(255 * max(0, 1 - y / SKY_DENOM))
        draw.line([(0, y), (size[0], y)], fill=alpha)
    draw.ellipse(list(ROOF_ELLIPSE), fill=0)
    draw.polygon(list(SNOW_POLYGON), fill=0)
    draw.ellipse(list(CANOPY_ELLIPSE), fill=0)
    combined = combined.filter(ImageFilter.GaussianBlur(radius=BLUR_RADIUS))
    return roof, snow, canopy, combined


def scale_cloud(cloud):
    ## LANCZOS 1.8 倍。着色器采样的是这张缩放结果，而不是运行时再线性放大原图。
    return cloud.resize((int(cloud.width * CLOUD_SCALE), int(cloud.height * CLOUD_SCALE)), Image.LANCZOS)


def _muldiv255(a, b):
    ## 与 PIL 合成的 8 位乘除一致：((a*b+128)>>8 + (a*b+128))>>8
    t = a.astype(np.int32) * b.astype(np.int32) + 128
    return ((t >> 8) + t) >> 8


def shader_composite(base_rgba, cloud_scaled, mask_l, phase, strength=1.0):
    ## 复刻 cloud_density.gdshader：缩放云贴到 CLOUD_ORIGIN，再按 PIL composite + alpha_composite 叠到院落。
    base = np.array(base_rgba.convert("RGBA"))
    cloud = np.array(cloud_scaled.convert("RGBA"))
    mask = np.array(mask_l.convert("L"))
    h, w = cloud.shape[:2]
    cx, cy = CLOUD_ORIGIN
    out = base[:, :, :3].copy()
    yy, xx = np.mgrid[0:h, 0:w]
    mod = cloud_modulation(phase, xx, yy)
    ca = np.clip(np.floor(cloud[:, :, 3].astype(np.float64) * mod * strength), 0, 255).astype(np.int32)
    ## paste(cloud, pos, cloud) 会用自身 alpha 当蒙版，RGB 与 alpha 各乘一次 ca。
    pasted_rgb = np.stack([
        _muldiv255(cloud[:, :, 0], ca),
        _muldiv255(cloud[:, :, 1], ca),
        _muldiv255(cloud[:, :, 2], ca),
    ], axis=-1)
    pasted_a = _muldiv255(ca, ca)
    sub_mask = mask[cy:cy + h, cx:cx + w].astype(np.int32)
    masked_rgb = np.stack([
        _muldiv255(pasted_rgb[:, :, 0], sub_mask),
        _muldiv255(pasted_rgb[:, :, 1], sub_mask),
        _muldiv255(pasted_rgb[:, :, 2], sub_mask),
    ], axis=-1).astype(np.float64)
    masked_a = _muldiv255(pasted_a, sub_mask).astype(np.float64) / 255.0
    bg = base[cy:cy + h, cx:cx + w, :3].astype(np.float64)
    rgb = masked_rgb * masked_a[..., None] + bg * (1.0 - masked_a[..., None])
    out[cy:cy + h, cx:cx + w] = np.clip(np.round(rgb), 0, 255).astype(np.uint8)
    return out


def _paths(base_path, cloud_path):
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.abspath(os.path.join(script_dir, "..", "..", ".."))
    if base_path is None:
        base_path = os.path.join(repo_root, "assets", "holiday", "environment", "yard_sunny.png")
    if cloud_path is None:
        cloud_path = os.path.join(script_dir, "cloud_candidate.png")
    return script_dir, base_path, cloud_path


def generate(out_dir=None, n_frames=40, base_path=None, cloud_path=None):
    script_dir, base_path, cloud_path = _paths(base_path, cloud_path)
    if out_dir is None:
        out_dir = os.path.join(script_dir, "anim_frames")
    os.makedirs(out_dir, exist_ok=True)

    base = Image.open(base_path).convert("RGBA")
    cloud = Image.open(cloud_path).convert("RGBA")
    _roof, _snow, _canopy, mask = build_masks(base.size)
    cloud_scaled = scale_cloud(cloud)
    cx, cy = CLOUD_ORIGIN

    for i in range(n_frames):
        # Use integer harmonic so phase=0 and 2π produce identical modulation
        phase = i / n_frames * 2 * np.pi
        arr = np.array(cloud_scaled)
        h, w = arr.shape[:2]
        yy, xx = np.mgrid[0:h, 0:w]
        mod = cloud_modulation(phase, xx, yy)
        arr[:, :, 3] = np.clip(arr[:, :, 3].astype(float) * mod, 0, 255).astype(np.uint8)
        varied = Image.fromarray(arr, "RGBA")
        frame = base.copy()
        temp = Image.new("RGBA", base.size, (0, 0, 0, 0))
        temp.paste(varied, (cx, cy), varied)
        masked = Image.composite(temp, Image.new("RGBA", base.size, (0, 0, 0, 0)), mask)
        frame = Image.alpha_composite(frame, masked)
        frame.convert("RGB").save(os.path.join(out_dir, f"cloud_frame_{i:02d}.png"), optimize=True)

    # Static reference (fixed modulation equivalent to average or low motion)
    static = base.copy()
    fixed = Image.new("RGBA", base.size, (0, 0, 0, 0))
    fixed.paste(cloud_scaled, (cx, cy), cloud_scaled)
    fixed_m = Image.composite(fixed, Image.new("RGBA", base.size, (0, 0, 0, 0)), mask)
    Image.alpha_composite(static, fixed_m).convert("RGB").save(os.path.join(out_dir, "cloud_static_low_motion.png"), optimize=True)
    print(f"Generated {n_frames} frames + static in {out_dir}")
    print(f"Base: {base_path}")
    print(f"Cloud: {cloud_path}")


def _save_mask_rgba(mask_l, path):
    ## 存成 RGBA，避免灰度导入把通道含义弄混。R=G=B=遮罩，A=255。
    arr = np.array(mask_l.convert("L"))
    rgba = np.zeros((arr.shape[0], arr.shape[1], 4), np.uint8)
    rgba[:, :, 0] = arr
    rgba[:, :, 1] = arr
    rgba[:, :, 2] = arr
    rgba[:, :, 3] = 255
    Image.fromarray(rgba, "RGBA").save(path)


def export_preview_textures(dest=None, base_path=None, cloud_path=None):
    ## 写出 Godot 预览已经绑好的底图、缩放云和语义遮罩。不覆盖 assets/holiday。
    script_dir, base_path, cloud_path = _paths(base_path, cloud_path)
    if dest is None:
        dest = os.path.join(script_dir, "godot_preview", "textures")
    os.makedirs(dest, exist_ok=True)
    base = Image.open(base_path).convert("RGBA")
    cloud = Image.open(cloud_path).convert("RGBA")
    roof, snow, canopy, combined = build_masks(base.size)
    cloud_scaled = scale_cloud(cloud)
    shutil.copy2(base_path, os.path.join(dest, "yard_sunny.png"))
    cloud_scaled.save(os.path.join(dest, "cloud_scaled.png"))
    _save_mask_rgba(roof, os.path.join(dest, "mask_roof.png"))
    _save_mask_rgba(snow, os.path.join(dest, "mask_snow_peaks.png"))
    _save_mask_rgba(canopy, os.path.join(dest, "mask_canopy.png"))
    _save_mask_rgba(combined, os.path.join(dest, "mask_combined.png"))
    print(f"Exported preview textures to {dest}")
    print(f"Cloud scaled size: {cloud_scaled.size} origin: {CLOUD_ORIGIN} scale: {CLOUD_SCALE}")
    _check_against_anim_frames(base, cloud_scaled, combined, script_dir)


def _check_against_anim_frames(base, cloud_scaled, combined, script_dir):
    ## 着色器公式必须对得上当前 anim_frames，否则预览不能当 PNG 证据。
    for index in (0, 10):
        frame_path = os.path.join(script_dir, "anim_frames", f"cloud_frame_{index:02d}.png")
        if not os.path.isfile(frame_path):
            print(f"Skip check, missing {frame_path}")
            continue
        phase = index / 40.0 * 2 * np.pi
        expected = np.array(Image.open(frame_path).convert("RGB"))
        got = shader_composite(base, cloud_scaled, combined, phase)
        diff = np.abs(got.astype(np.int16) - expected.astype(np.int16))
        print(f"shader formula vs cloud_frame_{index:02d}.png max {int(diff.max())} mean {float(diff.mean()):.6f}")
        if int(diff.max()) != 0:
            raise SystemExit(f"preview formula diverges from {frame_path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default=None)
    parser.add_argument("--frames", type=int, default=40)
    parser.add_argument("--base", default=None)
    parser.add_argument("--cloud", default=None)
    parser.add_argument("--export-preview", action="store_true")
    args = parser.parse_args()
    if args.export_preview:
        export_preview_textures(args.out, args.base, args.cloud)
    else:
        generate(args.out, args.frames, args.base, args.cloud)
