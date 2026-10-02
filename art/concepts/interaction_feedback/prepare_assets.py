#!/usr/bin/env python3
"""Create transparent 512px runtime response cels from approved painted masters."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
SOURCE = Path(__file__).resolve().parent
TARGET = ROOT / "assets/holiday/fx"
for stem, output in (("pet_heart", "pet_heart_watercolor"), ("water_splash", "water_splash_watercolor")):
    original = Image.open(SOURCE / f"{stem}_master.png").convert("RGBA")
    alpha = original.getchannel("A")
    opaque = alpha.point(lambda value: 255 if value > 16 else 0).getbbox()
    if opaque is None:
        raise ValueError(f"{stem}: no visible alpha content")
    x0, y0, x1, y1 = opaque
    side = round(max(x1 - x0, y1 - y0) * 1.24)
    center_x, center_y = (x0 + x1) // 2, (y0 + y1) // 2
    box = (center_x - side // 2, center_y - side // 2,
           center_x + side - side // 2, center_y + side - side // 2)
    crop = original.crop(box).resize((512, 512), Image.Resampling.LANCZOS)
    pixels = crop.load()
    for y in range(512):
        for x in range(512):
            r, g, b, a = pixels[x, y]
            if a <= 8:
                pixels[x, y] = (r, g, b, 0)
    TARGET.mkdir(parents=True, exist_ok=True)
    path = TARGET / f"{output}.png"
    crop.save(path, optimize=True)
    print(f"{stem}: original_bbox={opaque} -> {path}, runtime_alpha={crop.getchannel('A').point(lambda v: 255 if v>16 else 0).getbbox()}")
