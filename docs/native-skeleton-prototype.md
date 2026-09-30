# Native Skeleton2D motion prototype

After rejecting the PNG/cutout deformation experiment, the user explicitly
requested a new, simple, purely 2D skeletal character. This is that separate
prototype. It does not reuse any cutout/atlas art or the rejected leg-warp system.

## Run

```sh
YOUJIA_PLAYER_GAIT=skeleton godot --path .
```

Normal launch still uses the accepted v1 player. `YOUJIA_PLAYER_GAIT=v2` is the
separate rejected cutout experiment, not this character. The llama and other
animals remain v1. No published build or deployment was changed.

## Character and movement

- Reusable scene: `scenes/native_walker.tscn`
- Builder/controller: `scripts/entities/native_walker.gd`
- A real Skeleton2D/Bone2D hierarchy is created by the scene script: pelvis,
  spine/head, two hip→knee→ankle chains, and two shoulder→elbow chains.
- Visible artwork is simple code-defined Polygon2D/Line2D geometry with rigid
  limb segments. No bitmap editing, generated atlas, or vertex warping is used.
- Fixed-length leg bones follow an authored stance/swing trajectory; relaxed
  arms counter-swing. The body rises to an upright mid-stance and shifts weight
  at step transfer. The short stop blend returns to a relaxed two-foot stance.
- Existing input, acceleration, collision, depth scaling and direction logic
  remain intact. Turning mirrors the clean character at the existing direction
  transition; it is not a newly drawn multi-angle turn sequence.

This is deliberately a simple motion model for user review, not final art.
Animation is code-authored; it is not yet an AnimationPlayer keyframe library
or a production artist-facing static rig scene. Artistic polish and additional
views should wait until the motion direction is accepted.

## Verification

`npm run verify:locomotion` passes 389 general checks and 264 focused checks on
Godot 4.6.3. Native checks verify the actual Skeleton2D/Bone2D structure,
constant-length/scale thigh and shin segments, support continuity, bounded body
height with an upright mid-stance, settled idle feet, and reduced motion.
Selection tests cover unset/v1/v2/skeleton modes and prevent double rendering.

A same-input native OpenGL recording covers rightward walking, stop, reversal,
and idle in the actual yard. The first video delivered for feedback preceded
only a 1.2px upright-height adjustment. A second recording uses the final source
and includes its SHA-256 manifest. Neither contact statistics nor automated tests
are a substitute for the user's aesthetic judgment.

## User review outcome

The user rejected this prototype's appearance as too ugly. It is a technical
motion proof only and is NOT approved character art. It remains opt-in; normal
launch continues to use v1, and no further integration should be inferred from
the requested native-skeleton direction. The next visual step is a polished,
complete character concept that fits the painterly/storybook yard, approved as
a static design before any additional rigging or game-default changes.
