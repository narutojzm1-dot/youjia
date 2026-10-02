#!/usr/bin/env python3
"""Convert authored transparent watercolors into stable, compact Godot cels.

The two ripple paintings share one canvas and center; the dragonfly cels use
one body pivot and scale, so no wing is ever drawn or warped programmatically.
"""
from pathlib import Path
from PIL import Image

HERE = Path(__file__).resolve().parent
OUTPUT = HERE.parents[3] / "assets/holiday/fx"
OUTPUT.mkdir(parents=True, exist_ok=True)


def cleaned(name: str) -> Image.Image:
    image = Image.open(HERE / name).convert("RGBA")
    alpha = image.getchannel("A").point(lambda value: 0 if value < 25 else value)
    image.putalpha(alpha)
    return image


def ripple(source: str, target: str) -> None:
    image = cleaned(source)
    bounds = image.getchannel("A").point(lambda value: 255 if value > 40 else 0).getbbox()
    assert bounds is not None, source
    pad = 25
    crop = image.crop((max(0, bounds[0] - pad), max(0, bounds[1] - pad),
                       min(image.width, bounds[2] + pad), min(image.height, bounds[3] + pad)))
    crop.thumbnail((352, 150), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (384, 208))
    canvas.alpha_composite(crop, ((canvas.width - crop.width) // 2,
                                  (canvas.height - crop.height) // 2))
    canvas.save(OUTPUT / target, optimize=True)


def dragonfly(source: str, target: str, x_adjust: int) -> None:
    image = cleaned(source)
    assert image.size == (1920, 1920), source
    # Both master paintings share the same coordinate scale; align the torso,
    # not the very different full-wing bounding boxes.
    small = image.resize((307, 307), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (320, 320))
    canvas.alpha_composite(small, (6 + x_adjust, 6))
    canvas.save(OUTPUT / target, optimize=True)


if __name__ == "__main__":
    ripple("ripple_start_master.png", "shore_ripple_start.png")
    ripple("ripple_wide_master.png", "shore_ripple_wide.png")
    dragonfly("dragonfly_flight_master.png", "shore_dragonfly_flight.png", 0)
    dragonfly("dragonfly_rest_master.png", "shore_dragonfly_rest.png", -18)
    for path in sorted(OUTPUT.glob("shore_*.png")):
        image = Image.open(path)
        print(path.relative_to(OUTPUT.parents[2]), image.size, image.getchannel("A").getbbox())
