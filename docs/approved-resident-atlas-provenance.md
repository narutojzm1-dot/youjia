# Approved resident upper-body atlas v1

Generated 2026-09-30. Candidate for parent-reviewed static assembly before motion.

## Approved reference

User-approved resident concept: `generated_images/exec-3fb5843a-9300-466f-822e-16a7e7b7559c.png`, 1536×1024 RGB. SHA-256: `93a8f1fafc53171e8640fab3ea5a04800d46b2eb0cbf19ca193e203b30185ef5`.

This reference supersedes the outdoor traveler's outfit: oatmeal loose linen shirt with rolled sleeves, naturally hanging arms, olive loose trousers and cream canvas slip-ons. No backpack, camera, straps, hiking boots, sweater or visible socks. Preserve the approved face, hair, painted material and human proportions.

## Deliverable and generation

`assets/holiday/characters/approved_resident_upper_v1.png`: 1536×1024 RGBA. SHA-256: `4fd91b466c653ceeadb9f19a18ed3b71e14b51d2653cb1c25a775c02f1909294`.

Created using built-in `image_gen.imagegen` with canonical reference and `transparent_background=true`; output `generated_images/exec-813dac16-0b5e-4947-ba15-7d18f9b8a572.png`, copied unmodified to project. Original assets, traveler atlases and pants files were not overwritten. No scripted raster editing was performed; Pillow/NumPy/SciPy only read alpha and component bounds.

Generation specification: exactly five detached components, comprising approved head+neck+complete linen torso with all sleeves/arms removed; two complete shoulder-to-relaxed-hand arms with original rolled linen sleeves; rear front-facing and front right-facing cream slip-on shoes. Reconstruct hidden shirt sides and shoulder overlap so arms can swing without gaps. Preserve face, curls, collar, button placket, asymmetric hem, slender human proportions and watercolor/gouache paint. No pants on core, no duplicate sleeves, no straps, no knitted materials, no socks, text, scenery or floor shadows. Natural transparent antialiased silhouettes. The image is generatively reconstructed, not a lossless extraction.

## Measured regions

Regions (x,y,width,height) have 3px padding around significant alpha>16 connected components. Atlas-global anchors are visually estimated; subtract region origin for local Sprite2D coordinates.

| Part | Region | Anchors |
|---|---|---|
| head+torso core | (556,1,412,844) | rear shoulder (605,403), front shoulder (893,399), rear hip (707,771), front hip (852,771) |
| rear whole arm | (245,178,191,665) | shoulder (385,226), wrist (325,721) |
| front whole arm | (1088,174,207,673) | shoulder (1140,226), wrist (1244,723) |
| rear canvas shoe | (426,846,166,161) | ankle (524,874), sole (513,992) |
| front canvas shoe | (874,871,314,135) | ankle (958,898), sole (1030,989) |

## Assembly and inspection

The existing `approved_traveler_pants_v1.png` olive painted fabric is compatible and can be reused. Resident trousers should reach shoe openings instead of ending at the previous long socks. Preserve overall approved height and relaxed silhouette through uniform component scales and proper joint placements, not axis stretching.

Initial canonical roughly920px-tall assembly suggestions: core uniform0.60, arms0.53–0.55, shoes0.48, existing pants around0.45 (tune uniformly to cover previous sock space). Per-category scales are necessary because image generation did not maintain literal source pixel scale. Source limbs are natural hanging arms with wrists/hands around upper thighs. Shoulders should remain relaxed; keep motion subtle until static approval.

Inspection: exactly five significant alpha>16 components; 72.63% of pixels are fully transparent. No duplicate sleeves on core, no attached arms, no extra props, no visible socks. Some viewers ignore alpha in preview and show brown RGB under transparent pixels; judge actual alpha-aware rendering. The image's tiny low-alpha fringe should also be assessed in engine. Face remains recognizable but is regenerated; static parent review is required before animation.

## Static review, 2026-09-30 11:37 UTC

Reviewed actual Godot rest-detail render with core0.060, arms0.052, pants0.049 and shoes0.048/0.050 at game scale. Shoulder joins are continuous, no duplicate sleeves or detached limbs; fingertips land around upper thighs consistent with the approved image. Linen collar, relaxed shoulders and thin cream slip-ons preserve the resident direction. Reused trouser ankles have slightly more bunched folds than the latest concept, a disclosed minor fidelity difference. The asset reviewer found no blocking static defect. Parent's static approval is still required before proceeding to motion; this review does not authorize bypassing that gate.
