#!/usr/bin/env python3
"""Derive compact transparent fence cels from original watercolor paintings.

Both grass poses retain the same square canvas and rooted pivot. No synthetic
warping, rotation, outlines, painted backplates or tinted alpha masks are added.
"""
from pathlib import Path
from PIL import Image

HERE = Path(__file__).resolve().parent
OUTPUT = HERE.parents[3] / "assets/holiday/fx"
OUTPUT.mkdir(parents=True, exist_ok=True)


def render(source: str, output: str, size: int) -> None:
    original = Image.open(HERE / source).convert("RGBA")
    assert original.size == (1920, 1920), source
    alpha = original.getchannel("A").point(lambda value: 0 if value < 30 else value)
    original.putalpha(alpha)
    frame = original.resize((size, size), Image.Resampling.LANCZOS)
    frame.save(OUTPUT / output, optimize=True)
    assert frame.getchannel("A").getbbox() is not None, output
    print(output, frame.size, frame.getchannel("A").getbbox())


if __name__ == "__main__":
    render("grass_still_master.png", "fence_grass_still.png", 320)
    render("grass_bent_master.png", "fence_grass_bent.png", 320)
    render("feather_master.png", "shed_feather.png", 256)
