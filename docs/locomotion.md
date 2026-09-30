# Grounded movement pass

This change addresses the existing yard characters' unnatural locomotion while
keeping the Godot project, artwork, painted ground boundaries and expression game.

## What changed

- Character and animal gait advances from **actual ground displacement**, after
  boundary clipping. Slower travel has slower steps; a blocked actor cannot bounce
  in place. Ground-distance normalization preserves cadence across perspective.
- Removed the old fixed ~8 bounces/second and whole-body walking squash. A restrained
  shader alternates lower-leg swing/lift below the hip, leaving faces and expressions
  unchanged. The body has only a small weight shift.
- Players accelerate smoothly and brake more firmly; the old per-frame 0.2px cutoff
  is gone. Mouse destination approach decelerates before stopping.
- Animals ease into/out of movement, rest between destinations, and have different
  stride lengths. Ducks in the pond glide without land-foot stepping.
- Turn direction uses velocity thresholds and a brief pivot. Each cutout declares
  its original facing: cow, goose and sheep_b face left in their source images.
- Leading follows the player's ground position with separate start/stop distances.
  It no longer creates a new target on the opposite side every time the llama turns.
- Random social nudges use delta-time probabilities rather than frame counts.
- Restored foot shadows that the opaque backdrop had hidden, and flattened them
  into subtle ground ellipses.
- Reduced-motion mode disables decorative foot/body movement and turning squeeze.

## Reproduce checks

With Godot on PATH, run `npm run verify:locomotion` (or set GODOT_BIN). This imports
resources and runs both the existing game suite and focused movement regressions.
It creates isolated temporary save/settings directories; it does not touch a
player's saved album. The original Manus runtime wrapper remains unchanged.

Focused tests cover 30/60/120Hz travel, stopping, blocked player/animal gait,
stationary leader stability, valid animal ground positions, and reduced motion.
Actual renderer evidence can be recorded with:

```sh
YOUJIA_CAPTURE_DIR=/tmp/youjia-frames godot --path . --fixed-fps 30 \
  --script res://tools/capture_locomotion.gd
ffmpeg -framerate 30 -i /tmp/youjia-frames/%04d.png \
  -c:v libx264 -pix_fmt yuv420p /tmp/youjia-movement.mp4
```

The capture must run with a real display/rendering backend, not `--headless`.

## Quality boundary

These are procedural deformations of the existing single-view painted cutouts,
not newly drawn multi-direction walk cycles or an articulated skeleton. They
cannot supply correct front/back views, accurate four-foot contact for every
pose, or eliminate all foot sliding. Actor-to-actor physical avoidance is also
outside this pass. The next art-quality step is authored directional walk/turn/
idle clips (or segmented body/leg rigs) for the same felt characters.

Verification was performed with installed Godot 4.6.3; the README's advertised
4.7 version was not available for this local check. Web release export and
publication are separate from the movement/source tests.

## Deterministic before/after findings

Using the identical test harness on commit `65318cf` and this branch, the player
starts at (300, 500) and receives rightward input for three seconds, well clear of
world boundaries. At 30/60/120 Hz respectively, original displacement is
261.57/31.99/16.00 px; this pass produces 262.33/261.62/261.25 px.
The original code zeroed velocity whenever one frame traveled less than 0.2px,
which misclassified high-frame-rate acceleration as collision. The fix tests
for actual blocked displacement instead of using that per-frame threshold.

The same original 78-check movement harness fails 25 checks on the baseline and
passes all 78 on the changed implementation. Additional rendering/orientation
checks may be added to the current suite; the 78-check result is the matched
baseline comparison. The unchanged general game suite passes 389 checks.

Final focused suite: **148 checks passed**; general game suite: **389 passed**.
Added coverage includes moving-leader catch-up, lead-speed tuning, mouse-goal
settling, rapid turn cancellation, texture facing, pond-swimming behavior, and
backdrop/shadow ordering. Native before/after recordings use the actual Godot
OpenGL 4.5 renderer (Mesa llvmpipe) in the cloud desktop, 150 frames at 30fps.
The desktop has no audio device and uses the dummy audio driver; audio is silent
by design in this project. Web browser/export acceptance was not run.
