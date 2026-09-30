# Approved traveler layered assets, v1

Date: 2026-09-30. Status: candidate for static in-engine assembly and visual comparison; not yet accepted as a finished animation.

## Source and method

Canonical source is the user-approved large traveler at left of `generated_images/exec-0fa63cfd-75ab-4a0a-9f02-5d5885ff27b6.png` (1536×1024). Source SHA-256: `bea249e6f755e3ef76b73ccab9011c3d083a92699c5163354ccbc22fbee3d0dc`.

Created with the built-in `image_gen.imagegen` image-edit tool, with `transparent_background=true`. No bitmap editing, masking, recoloring or compositing scripts were used. Python/Pillow/NumPy/SciPy were used only to read dimensions, alpha values and connected-component bounds. Files were copied without modification. Original game assets and earlier atlases were not overwritten.

This is a faithful generative reconstruction, not lossless pixel extraction. Hidden cloth is newly painted. The approved youthful human-like painted traveler replaces the earlier felt-toy direction for this candidate.

## Files

- `assets/holiday/characters/approved_traveler_upper_v1.png`: 1536×1024 RGBA; SHA-256 `b738ae0bd57ad588fc9bbcc9b5dabef54e5eec9d2bb5c9a2b0f39e9a8996d64f`. Generated source: `exec-ddb7b5ad-d0fb-410f-91e8-131772ed2bda.png`.
- `assets/holiday/characters/approved_traveler_pants_v1.png`: 1254×1254 RGBA; SHA-256 `cb0c47b9aad3ba59490fca24463f60d069208ef2fa2b10b4a097d90a8ce01f8f`. Generated source: `exec-60c01f5d-b485-4b99-90bd-05265932aa74.png`, targeted edit of `exec-7a1564d6-19b8-44c5-a261-64029a306b80.png`.

The first all-in-one candidate (`exec-20d196c2-f14d-4bd5-b05c-e43237658ddb.png`) was rejected: duplicate attached sleeves and malformed trouser segmentation. It is not a project asset.

## Generation specification

Upper asset: extract/reconstruct exactly the large approved traveler's intact head, neck, sweater, both arms and hands holding backpack straps, entire backpack/blanket and camera as one rigid upper-body sprite, stopping cleanly at the complete sweater hem. Keep approved face, curls, pose, human proportions, warm watercolor/gouache materials. Remove all pants and background. Include two separate original-angle hiking boots with socks at coherent anatomical scale. No text, labels, backdrop or floor shadow; actual alpha.

Pants asset: exactly four detached single-leg components (rear thigh, front thigh, rear shin, front shin) with original smooth painted woven olive cloth, matching texture scale and loose silhouette. Thighs stop below the knee with unhemmed plain cloth overlap; shins start above the knee and extend to actual gathered ankles. No socks, no visible knee hems, cuffs, rings, seams, circular pads, knitted fabric or round endcaps. Complete hidden anatomy for crossing. The targeted final edit removed the erroneous additional rear leg in the upper-right piece while keeping all other pieces and positions unchanged.

## Pixel-measured regions and estimated anchors

Regions are (x,y,width,height), including 3 pixels of padding around alpha>16 component bounds. Anchors are atlas-global (x,y), estimated visually, and require static assembly verification. Subtract region origin for sprite-local coordinates.

| File | Part | Region | Proximal pivot | Distal pivot |
|---|---|---|---|---|
| upper | complete upper body | (444,4,590,795) | rear hip (748,710), front hip (868,715) | n/a |
| upper | rear boot+sock | (300,751,170,234) | ankle (409,790) | sole (387,968) |
| upper | front boot+sock | (937,775,314,212) | ankle (1012,814) | sole (1092,970) |
| pants | rear thigh | (248,68,321,537) | hip (425,128) | knee (418,560) |
| pants | front thigh | (757,75,241,528) | hip (883,140) | knee (878,558) |
| pants | rear shin | (267,659,291,516) | knee (422,699) | ankle (402,1140) |
| pants | front shin | (721,655,294,524) | knee (855,697) | ankle (867,1140) |

## Assembly guidance

Candidate uniform scales to the concept's roughly 920-pixel full-body height: upper body 0.64; all four pants pieces 0.43; both boots 0.56. These differ between sheets because the generator did not retain literal source pixel scale. Do not stretch width independently from height. Assemble at canonical resolution, inspect against the approved concept, then scale the complete rig to its intended game height (engineer proposed 94 pixels).

Upper body remains rigid in this prototype, preserving hand/strap contact. Place thigh hips behind sweater hem; overlap knee material by approximately 18–20 canonical pixels. No knee cuff exists in the generated texture. Leave true ankle folds on the shins, and align boot sock anchors beneath them. Rear/front components may require mild pivot and rest-rotation adjustment, but any substantial shape/proportion discrepancy should be reported instead of concealed with nonuniform scaling.

## Inspection and caveats

Alpha>16 connected-component analysis found exactly three significant upper-sheet components and four significant pants-sheet components. 76.77% and 67.53% of respective pixels have alpha=0. Some image viewers display underlying RGB color even in fully transparent areas, making a false brown backdrop visible; use alpha-aware engine rendering to judge it. Very low-alpha fringe pixels also exist and should be assessed in the final render.

The upper-body face and clothing remain recognizable, but are regenerated rather than identical source pixels. The front upper leg was repaired into one complete piece. The rear thigh is wider near the seat than the front one, and static knee continuity still requires engine QA. No finished walking quality is claimed here.

## Static in-engine review, 2026-09-30 11:19 UTC

Reviewed actual Godot `rest-detail.png` after engineer's rest-pose update: rear leg outward angle about 11.5 degrees, rigid upper-body UV region excludes neighboring boot pixels, and the thigh's final 75 atlas pixels fade into the overlapping shin in the runtime shader. No source PNG was modified. No nonuniform width/length stretching was used.

The revised static silhouette is coherent with the approved relaxed stance. White neighboring-component fragments are gone. Knee transitions read as fabric fold changes rather than horizontal cuts or cuff rings. Static review passes for proceeding to prototype motion testing. This is not final animation acceptance: bent-knee gaps, semitransparent overlap, crossed-leg depth and planted shoe contact still require motion QA.

## Motion-frame spot check, 2026-09-30 11:22 UTC

Reviewed actual Godot normal-game-resolution frames 0015, 0025, 0035 and 0085 from the first 180-frame walking capture. No visible open knee gaps, detached leg segments or background leaking through the knee overlap were identified in these sampled phases. Bent-knee, crossed-leg and mirrored-facing poses remained coherent. The rigid cutout foot style remains visible and is appropriate to assess as a first prototype. These four frames establish pose/coverage checks only; they do not establish temporal smoothness or final animation quality. No further bitmap generation was needed for this pass.
