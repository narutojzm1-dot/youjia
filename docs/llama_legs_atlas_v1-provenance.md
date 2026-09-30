# Experimental llama leg atlas provenance

- Created: 2026-09-30
- Method: imagegen image editing/generation from the existing character reference
- Reference: `assets/holiday/characters/llama.png`
- New output: `assets/holiday/characters/llama_legs_atlas_v1.png`
- Format: 1254 × 1254 RGBA PNG, transparent background
- SHA-256: `8f66ec6b331be15fe9943d97b155a5cdb69617b43e3ab60bb0ad47b135f73ad5`

Four complete legs for the neutral-pose experimental rig. This rig is OFF in the default yard; config.experimental_planted_gait=true or enable_experimental_planted_gait() explicitly enables it.

The generated leg fur is thinner, lighter and denser-grained than the original body. The resulting composite did not meet visual acceptance, so default llama movement and every expression retain iteration 1. Keep this asset for further experiments, not as evidence of approved production art.

The source images were inspected before generation and were not overwritten.
Parts are selected at runtime with texture regions or mesh UVs; no destructive
raster cutting, recoloring, or alpha cleanup was applied to the returned atlas.
Tiny very-low-alpha edge wisps were inspected in real game-background renders.
Measured regions and anatomical pivots are recorded in
`scripts/entities/layered_llama.gd`.
These measurements are rig calibration data, not a guarantee of visual quality.
