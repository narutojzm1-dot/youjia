# Resident sequence animation gate

The user requested trying sequence frames after continued dissatisfaction with
procedural leg motion. Further bone-trajectory experiments were stopped and
not committed. Existing approved resident art and the previous selectable rig
remain intact.

The first resource gate is an eight-pose, one-direction full-body walk cycle:
contact, load, passing, push-off, then the opposite leg's corresponding phases.
Near/far legs must actually exchange roles. Identical poses shifted around a
canvas, mirrored idles, and duplicated half-cycles do not satisfy this gate.

`tools/capture_resident_sequence.gd` previews a four-column/two-row sheet as
actual AnimatedSprite2D/SpriteFrames playback at 8 fps, alongside 2 fps pose
inspection. Cells share one uniform scale, body axis and ground line. There is
no per-frame shrinking, root repositioning, interpolation or texture warp to
conceal bad frame registration. Non-integer equal cell widths are technically
supported; cross-cell limbs or inconsistent source alignment are not.

Only after a coherent standalone loop passes visual inspection should this
resource be integrated into game locomotion. Keep the previous game renderer
available and do not label engine/test success as natural animation quality.

## Authored bake prototype

Two generated full sprite sheets failed the visual gate (repeated half-cycles,
incorrect leg exchange, high marching knees, and source alignment/cell spill).
They were not integrated. The approved alternative is a bounded manual-pose bake.

`tools/capture_authored_poses.gd` renders the first four pose silhouettes.
`tools/bake_resident_walk.gd` contains eight explicit hip/knee/ankle angle keys,
with one rigid in-between per interval. It renders sixteen whole-character
transparent frames and previews them through AnimatedSprite2D at 12 fps and
3 fps. No automatic IK walk is sampled. The source is still the existing layered
painted artwork, not sixteen independently illustrated drawings.

The reproducible candidate is in
`assets/holiday/characters/resident_walk_authored_v1/`, including a source/frame
SHA-256 manifest. The isolated resource and scene live in `scenes/experimental/`.
Canvas: 384×448, foot/root anchor (192,420), optional game-scale .25. All frames
use identical canvas/anchor/scale. Runtime playback needs no skeleton.

The independent loop was sent for user review. It is **not integrated into the
game**; v1/resident defaults and movement remain unchanged. Near/far shoe viewing
angles still differ, small sole alignment drift remains, and game root motion
has not been calibrated. Wait for visual feedback before further changes.

Checks: `godot --headless --path . --script test/authored_sequence_suite.gd`
verifies complete distinct frames, dimensions, anchor, timing and looping. The
standard `npm run verify:locomotion` remains the regression check. Neither test
establishes naturalness; that is a visual acceptance decision.


## Accepted integration (2026-09-30)

The user accepted this version with “先用这个版本吧，继续完成其他角色定稿”.
The exact sixteen approved walk frames are now the default hero renderer.
`YOUJIA_PLAYER_GAIT=sequence` selects it explicitly; `v1`, `v2`, `skeleton`,
`painted` and `resident` preserve earlier versions for local comparison.

`SequenceResident` displays complete frames through AnimatedSprite2D. Its phase
comes from actual post-collision travel, so blocked movement does not run in
place. A matching static idle is baked from the already approved relaxed pose,
using the same 384×448 canvas and (192,420) anchor. Reduced motion holds that idle
while movement and interaction remain available. Turning uses the existing
facing hysteresis and mirrors the right-facing art.

Minimal root calibration uses 52 world pixels per full cycle. At the accepted
12 frames/sec, sixteen frames take 1.333 seconds, giving 39px/s at unit depth.
The sequence mode applies 39/96 to the existing base movement tuning value;
thus its default96 reference gives39 actualpx/s, and leading/depth multipliers
still apply. This is intentionally slower than the old96px/s character. Visual
scale is included when converting distance to frame progress. No accepted pose
or walk PNG was redrawn or re-timed independently.

Regression coverage includes default/legacy selection isolation, 30/60/120Hz
travel stability, keyboard and existing click-goal travel, start/stop/turn,
teleport reset, visible grass carrying, feeding, photo collection, leading,
and reduced motion. Actual rendered yard evidence covers walking, stopping,
mirroring and returning to idle. Small residual foot drift and the two shoes'
different viewing angles remain the accepted art limitations.
