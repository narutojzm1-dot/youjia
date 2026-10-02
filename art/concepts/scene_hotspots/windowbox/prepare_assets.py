#!/usr/bin/env python3
"""Derive lightweight alpha cels from the approved high-resolution paintings.

The butterfly cels use one canvas and an approximate shared torso pivot instead of
per-frame tight crops, so changing wing posture does not teleport the insect.
"""
from pathlib import Path
from PIL import Image

HERE = Path(__file__).resolve().parent
OUTPUT = HERE.parents[3] / "assets/holiday/fx"
OUTPUT.mkdir(parents=True, exist_ok=True)


def cleaned(name: str) -> Image.Image:
    image = Image.open(HERE / name).convert("RGBA")
    alpha = image.getchannel("A").point(lambda v: 0 if v < 26 else v)
    image.putalpha(alpha)
    return image


def render_butterfly(source: str, dest: str, torso: tuple[int, int]) -> None:
    image = cleaned(source)
    # A constant scale preserves the identity of the same insect in both cels.
    size = (round(image.width * 0.12), round(image.height * 0.12))
    small = image.resize(size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (256, 256))
    torso_on_canvas = (round(torso[0] * 0.12), round(torso[1] * 0.12))
    canvas.alpha_composite(small, (128 - torso_on_canvas[0], 151 - torso_on_canvas[1]))
    canvas.save(OUTPUT / dest, optimize=True)


def render_petals() -> None:
    image = cleaned("petals_master.png")
    # The loose original flower petals remain one complete brushwork composition.
    visible = image.getchannel("A").point(lambda v: 255 if v > 45 else 0).getbbox()
    assert visible is not None
    padding = 22
    bounds = (max(0, visible[0] - padding), max(0, visible[1] - padding),
              min(image.width, visible[2] + padding), min(image.height, visible[3] + padding))
    crop = image.crop(bounds)
    crop.thumbnail((304, 118), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (320, 136))
    canvas.alpha_composite(crop, ((canvas.width - crop.width)//2,
                                   (canvas.height - crop.height)//2))
    canvas.save(OUTPUT / "windowbox_petals.png", optimize=True)


if __name__ == "__main__":
    render_petals()
    render_butterfly("butterfly_open_master.png", "windowbox_butterfly_open.png", (820, 855))
    render_butterfly("butterfly_rest_master.png", "windowbox_butterfly_rest.png", (775, 1040))
    for path in sorted(OUTPUT.glob("windowbox_*.png")):
        im = Image.open(path)
        print(path.relative_to(OUTPUT.parents[2]), im.size, im.getchannel("A").getbbox())
