# Planted gait experiment, iteration 2 (rejected; opt-in only)

This is a bounded follow-up to the user's review of the first locomotion video.
The user rejected the player candidate as more deformed and less natural than
v1. Both player and llama now DEFAULT TO V1. Both v2 rigs remain explicitly
opt-in experiments only. Other animals
retain the first movement pass; no engine, map, gameplay loop, or online release
was replaced.

## Architecture

- `PlantedGait` keeps individual sole contacts in world space during stance.
  Recovery feet move toward a predicted landing point with a lift arc, then
  become supporting contacts. Interrupted recovery finishes its touchdown.
- Each limb has its own contact phase. A reach-limited early recovery handles
  steering changes, and the final supporting foot is never released into an
  unsupported walking frame.
- Hip/knee/ankle targets drive two-segment articulation. A small weight-bearing
  body drop and rigid upper-body sway replace whole-image squash. The face and
  upper-body texture are never distorted by a leg shader.
- `LayeredHero` uses complete generated thigh/shin parts, the ORIGINAL player's
  upper body and ORIGINAL brown shoe regions. Bone alignment is evaluated
  through the actual Sprite2D transforms, including per-part width corrections.
- EXPERIMENTAL ONLY: `LayeredLlama` uses four complete generated leg paintings with independent
  textured meshes. The original neutral torso/head is drawn above fluffy hip
  overlap caps. The body mask follows its wool/belly contour.
- Reduced-motion mode restores the original undeformed cutout. Teleports and
  legacy posed-state changes reinitialize contacts rather than stretching limbs
  toward their previous world positions.

## Defaults and explicit experimental selection

Normal launch and `YOUJIA_PLAYER_GAIT=v1` use the accepted first-pass player
renderer and original artwork. Only `YOUJIA_PLAYER_GAIT=v2 godot --path .`
explicitly selects the rejected experimental player. Code can switch through
`Vacationer.set_planted_gait_enabled(false/true)`. No save migration is involved.
The llama remains v1 unless separately opted into its experimental rig.

## Important boundaries

This is an art-direction candidate, not a claim of finished production animation.
It is still a single-view character with a mirrored turn, without new front/back
views or physically modeled contact/occlusion between different animals. New
limb texture, seam blending, and proportions should be judged in the same-input
rendered comparison, not inferred from passing numerical tests.

The llama's happy/annoyed/smirk PNGs have different body widths and leg poses.
They deliberately retain the first-pass renderer; neutral-pose joints must not
be applied blindly to those images. Future work should author/map equivalent
expression bodies to the same rig before claiming complete llama coverage.

All original artwork remains untouched. Generated sources are separately named
atlases. Atlas provenance and measured attachment coordinates accompany them.

## Validation

`npm run verify:locomotion` imports and runs the general game suite plus the
movement suite in isolated save/settings directories. The wrapper now rejects
Godot script/shader/engine errors even if Godot later exits with code zero.

The contact tests exercise 30/60/120Hz, visible sole vertices/sprite pivots,
visible hip/knee/ankle alignment, stance drift, support continuity, interrupted
steps, stable stops, original upper-body geometry, reduced motion, teleport,
pose transitions, and expression fallback. Ground-distance and frame-rate
regressions from iteration 1 are retained.

For a six-second near comparison (right, stop, left, settle):

```sh
YOUJIA_CAPTURE_DIR=/workspace/shared/youjia-gait-frames godot --path . \
  --fixed-fps 30 --script res://tools/capture_planted_gait.gd
```

Run through a real display/rendering backend, not headless. Each recording writes
`manifest.json` with engine information and SHA-256 hashes of relevant source
and asset files. `tools/capture_locomotion.gd` provides the wider yard scenario.
No push, PR, deployment, or publication is included in this work.

## Recorded outcome

The user rejected the **player art-direction candidate** after viewing the
same-input comparison: v1 looked more natural despite sliding, whereas v2
deformed too much. The accepted v1 player is restored as the default. The llama prototype was rejected
for now because its new limb fur does not match the original body; it remains
explicitly opt-in. The candidate player's trouser segmentation/textile is still
more conspicuous than the original. No more deformation tuning or new asset
generation is authorized by this experiment; any next direction should first
validate coherent authored walk frames or a properly authored rig separately.

Final local verification: 389 general checks and 232 movement/rig checks passed
on Godot 4.6.3. Tested planted-contact drift was 0px at 30/60/120Hz; actual visible
sole/joint alignment remained within 0.001px. Neither tested walker had an
unsupported walking frame. Numeric contact correctness is not an aesthetic pass.

Real native-renderer evidence includes a six-second v1/candidate player comparison
and a five-second default-yard clip. Recording manifests identify the sampled
source. Final code additionally includes short-relocation contact reset and the
reversible player-v1 selector; these do not alter the recorded default walking
sequence. A Web export/browser acceptance pass was not performed.

After restoring defaults, 389 general checks and 244 focused checks pass,
including explicit unset/v1/v2 environment selection and default llama checks.
The subsequent requested direction is a separate clean native Skeleton2D
character; it must not silently re-enable this rejected cutout experiment.
