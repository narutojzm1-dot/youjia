# Player limb atlas provenance

- Created: 2026-09-30
- Method: imagegen image editing/generation from the existing character reference
- Reference: `assets/holiday/characters/player.png`
- New output: `assets/holiday/characters/player_rig_atlas_v1.png`
- Format: 1254 × 1254 RGBA PNG, transparent background
- SHA-256: `0936cf5f1f6555ab8191bf6a37baace53a6a595337b9e34dbb45e34818475f21`

Only rear/front thigh and shin regions are used by the default player rig. The original player PNG supplies the head, upper body and brown shoes.

The generated head/body/shoes are intentionally unused: the head differs from the source, and generated shoes have a light cuff. Per-part scales differ. Pants still have a coarser textile pattern than the original; this remains an art-direction review point.

The source images were inspected before generation and were not overwritten.
Parts are selected at runtime with texture regions or mesh UVs; no destructive
raster cutting, recoloring, or alpha cleanup was applied to the returned atlas.
Tiny very-low-alpha edge wisps were inspected in real game-background renders.
Measured regions and anatomical pivots are recorded in
`scripts/entities/layered_hero.gd`.
These measurements are rig calibration data, not a guarantee of visual quality.
