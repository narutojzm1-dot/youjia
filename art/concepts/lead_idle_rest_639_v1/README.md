# #639 idle rest preparation — CODEX-LEAD

2026-10-10. Original eight-pose artwork generated using built-in image_gen, referencing accepted resident_walk_authored_v1/idle.png. Standing, crouching, sitting, leaning, elbow recline, awake lying, closed-eye lying, rise crouch. Source exec-e2862069-126d-49fe-b73b-d4dabf71bb0f.png. Existing Grok #665 candidate is retained.

PREPARATION ONLY, no runtime reference and not a completed feature. Atlas output 1448x1086 has unequal cel bounds despite prompt requesting uniform cells. Must author explicit nonoverlapping regions, contact pivots and relative scales, verify alpha and real game transitions before production acceptance. Colored fringe shown by viewer includes low-alpha pixels; do not infer opaque halo without actual compositing. Preserve native alpha, no raster postprocessing performed.

Plan: only controlled outdoor idle with empty hands, no leading/fishing/interactions/cutscene; 45s sit, 90s later nap. Pause/UI no accumulation; input restores control without consuming command; no forced day advance or new save fields. Need clearance for horizontal pose, actor/shadow/photo compatibility, reduced motion, complete GPU and Web experience tests. Shared integration starts after PR691 delivery on an isolated branch.

Second original image-generation revision: poses-v2.png (exec-6b16b123-ca92-4c3c-96e1-8d851b8f1094.png). Requested strict uniform 4x2 cells and same lying silhouette with eyes-only change. This is the preferred candidate to validate in game; no runtime integration or completion claim yet. Original poses.png remains as provenance and rejected layout reference.

Revision2 measured1774x887. Four columns fit isolated figures; upper row extends to y546, so do not assume equal row heights. Lying opaque bodies now395/397px wide with same163px height; visible red edge pixels have max alpha5/255. Needs explicit region/pivot calibration and real compositing before acceptance.
