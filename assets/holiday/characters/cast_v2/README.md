# Approved cast v2: production sources

Ten transparent PNG sources, all 1254 × 1254, generated with the built-in image tool from the approved seven-design sheet. No shipped original asset was overwritten. Source prompts are under `art/concepts/animal_cast_v2/prompt_*.txt`.

## Files and facing

- `llama_smirk.png`: canonical full body, right-facing
- `llama_idle.png`: neutral expression candidate, right-facing
- `llama_happy.png`: happy expression candidate, right-facing
- `llama_annoyed.png`: annoyed expression candidate, right-facing
- `cow.png`: weary cream/caramel cow, left-facing
- `horse.png`: weary chestnut/bay horse, left-facing
- `sheep_clingy.png`: affectionate sheep, right-facing
- `sheep_dull.png`: sleepy grass-chewing sheep, left-facing
- `goose.png`: angry honking white goose, right-facing
- `duck.png`: yellow duckling, right-facing, reused by three actors

`manifest.json` gives native-facing sign, complete canvas dimensions, alpha bounds `[x,y,width,height]`, ground anchor, and alpha audit. Bounds use alpha > 16. Ground anchors use the lower foot region with alpha > 128. The art keeps its original generated alpha; no raster cleanup was applied.

## Transparency and visual audit

All ten files have real alpha transparency. Approximately 51–64% of each canvas is fully transparent, while animal interiors have median alpha 252–253. All have zero alpha > 16 pixels touching canvas edges. No ivory paper rectangle, labels, ground clumps, or baked cast shadows remain. Mouth-held grass remains intentionally on the sleepy sheep.

The first cow extraction touched the right edge near the tail. The delivered `cow.png` uses a corrected, smaller frame with the full tail inside the canvas; the original extraction is retained only as a concept reference.

All animals' visible hooves/feet, ears and tails are present. The horse keeps single equine hooves and no tack. The goose's broad flared wing is intentional and retains the approved angry posture. These are high-resolution painterly recreations of the approved design rather than literal lossless crops; some brush-detail variation is unavoidable.

## Important llama expression constraint

The tool preserved the standing pose and scale visually, but did NOT return pixel-identical body pixels for face-only edits. Relative to `llama_smirk.png`, body silhouette intersection-over-union is 98.42% for idle, 98.53% for happy, and 98.50% for annoyed. Raw foot baselines differ by 1–2 source pixels. Do not describe these source PNGs as pixel-identical body swaps.

To strictly lock the body, use `llama_smirk.png` as the canonical body for every state and apply only a facial-region override from the appropriate candidate. Suggested face region in full-canvas pixel coordinates is `[810,225,220,155]`; the face interior contains the changing eyes, brows and mouth. Verify the seam in runtime at the intended display scale. All expression states should retain canonical ground anchor `[556.5,1227]` and mouth anchor `[962,341]`.

This source-art delivery does not itself implement a shader, layer system, animal behavior, animation, or asset switching.
