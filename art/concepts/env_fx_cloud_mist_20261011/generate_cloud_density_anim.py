#!/usr/bin/env python3
"""Reproducible generator for cloud internal density candidate animation.
Uses fixed yard_sunny.png background + soft sky mask + cloud_candidate.png.
Internal alpha modulation only; non-sky regions remain pixel-identical across frames.
Paths resolved relative to this script for clean repo reproduction.
"""
from PIL import Image, ImageFilter, ImageDraw
import numpy as np
import os
import argparse

def generate(out_dir=None, n_frames=40, base_path=None, cloud_path=None):
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.abspath(os.path.join(script_dir, "..", "..", ".."))
    if base_path is None:
        base_path = os.path.join(repo_root, "assets", "holiday", "environment", "yard_sunny.png")
    if cloud_path is None:
        cloud_path = os.path.join(script_dir, "cloud_candidate.png")
    if out_dir is None:
        out_dir = os.path.join(script_dir, "anim_frames")
    os.makedirs(out_dir, exist_ok=True)

    base = Image.open(base_path).convert("RGBA")
    cloud = Image.open(cloud_path).convert("RGBA")
    mask = Image.new("L", base.size, 0)
    draw = ImageDraw.Draw(mask)
    for y in range(500):
        alpha = int(255 * max(0, 1 - y / 480.0))
        draw.line([(0, y), (base.width, y)], fill=alpha)
    mask = mask.filter(ImageFilter.GaussianBlur(radius=25))
    cloud_scaled = cloud.resize((int(cloud.width * 1.8), int(cloud.height * 1.8)), Image.LANCZOS)
    cx, cy = 180, 30

    for i in range(n_frames):
        # Use integer harmonic so phase=0 and 2π produce identical modulation
        phase = i / n_frames * 2 * np.pi
        arr = np.array(cloud_scaled)
        h, w = arr.shape[:2]
        yy, xx = np.mgrid[0:h, 0:w]
        mod = 0.4 + 0.5 * np.sin(phase + xx / 70.0 + yy / 50.0) * np.cos(phase + yy / 90.0)
        mod = np.clip(mod, 0.15, 1.0)
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

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default=None)
    parser.add_argument("--frames", type=int, default=40)
    parser.add_argument("--base", default=None)
    parser.add_argument("--cloud", default=None)
    args = parser.parse_args()
    generate(args.out, args.frames, args.base, args.cloud)
