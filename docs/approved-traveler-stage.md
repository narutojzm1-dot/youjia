# Approved painterly traveler: assembly gate

The user approved the new complete painted traveler and Alpine garden concept
on 2026-09-30: “好看啊，还原度很高，这个画风，这个背景，我都很喜欢”.
The earlier geometric Skeleton2D prototype was rejected for appearance; the
layered v2 experiment was rejected for deformation. Neither is the visual target.

## Target

- Chestnut tousled hair, expressive face, cream cable-knit sweater, brown pack
  and camera, continuous loose olive trousers, brown hiking boots
- Follow the approved concept's actual proportions; do not enlarge the head or
  substitute a geometric body
- Separate painted art on real Bone2D nodes, with coherent hidden overlaps
- No visible repeated cuffs at the knees, no stretching to enforce contact math
- Keep the accepted v1 renderer as the default while validating this candidate

## Gates, in order

1. Source-faithful layered art
2. Actual Godot static reconstruction at detail and game size. Verify head/body
   identity, complete silhouette, cloth continuity, occlusion, and joint seams
3. Only after the static reconstruction succeeds: a short walk, stop, and turn
4. Test rigid limb lengths, selector isolation, reduced motion and gameplay
   regressions; record actual rendered evidence of the final candidate

A passing numerical test is not an aesthetic acceptance. The approved concept
is a direction reference, not permission to publish or change all animals.

## Candidate implementation and review

Select locally with `YOUJIA_PLAYER_GAIT=painted godot --path .`.
`PaintedWalker` uses one unwarped upper-body layer and six rigid leg/boot layers
on a real Skeleton2D/Bone2D hierarchy. All artwork uses uniform scaling.
Hands hold the backpack straps, so the complete upper body stays rigid rather
than inventing an arm swing that would break that contact. This is not yet a
fully articulated upper-body rig or a directional character sheet.

A source-UV polygon excludes boot fragments that share the upper-body sheet.
Thigh endings alpha-blend into overlapping shin fabric; no pixels are rewritten.
The two generated sheets are preserved verbatim and tracked explicitly.

The static rest assembly passed review before motion: recognizable face,
clothing, pack, separate relaxed legs, no stray pale fragments, no hard knee
cut. Motion review of actual frames 15/25/35/85 found no detached joints or
background holes at the knees. Footwear remains visibly rigid, facing changes
still mirror a 3/4 pose, and small ground slip is deliberately preferable to
stretching the approved silhouette. This is a candidate for user review, not a
claim of final animation quality or approved replacement of v1.

`tools/capture_traveler_rest.gd` renders detail and yard views.
`tools/capture_planted_gait.gd` captures 180 real rendered frames, with source
hashes and the same right/stop/left/settle sequence used for v1 comparisons.
