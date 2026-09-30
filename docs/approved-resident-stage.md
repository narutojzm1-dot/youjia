# Approved resident character

The user changed the outfit direction on 2026-09-30: this is a permanent resident,
not an outdoor traveler. The revised complete static concept was approved with
“这次可以”. Preserve its face, painted style and proportions.

Target: oatmeal linen shirt with rolled sleeves, relaxed olive trousers, cream
canvas slip-ons, freely resting arms, no backpack, camera, leather hiking boots,
or exposed thick socks. The earlier traveler remains historical work, not the
current art target.

The successful pants textures and rigid leg skeleton may be reused, with longer
trouser legs filling the previous sock space. Canvas shoes must not be inflated
to make up height. New complete arms attach at the shoulders for restrained
natural swing, without deforming the approved face or shirt.

Validation order remains: actual static assembly review, then walk/stop/turn,
then tests and source-matched rendered evidence. Keep v1 as the default until a
replacement candidate has been demonstrated and accepted. No publication is
part of this local work.

## Implemented candidate

Use `YOUJIA_PLAYER_GAIT=resident godot --path .` to opt in. Default remains v1.
The traveler remains selectable as `painted` only for historical comparison.

`ResidentWalker` subclasses the tested `PaintedWalker` leg rig and replaces the
visible upper body and shoes. Two independent shoulder/elbow Bone2D chains carry rigid painted arm regions.
The elbow split is hidden beneath the existing rolled sleeve, with no new
bitmap editing. Shoulders move less than before (about 3–4 degrees), while small
forearm flex follows with a slower response. Far-arm swing is quieter and stays
behind the torso. Start/stop are exponentially eased rather than making the
entire shoulder-to-hand image follow one cosine. Head and shirt remain a
coherent rigid layer. Input, speed, collision and following behavior
are unchanged.

All art transforms are uniform. The source trouser scale rises from .043 to
.049 to fill the previous hiking-boot/sock space, while the new shoes stay low
and thin. Each leg's bone lengths remain constant throughout the animation.
The longer trouser fabric is a little more gathered than the newest concept,
but does not expose the former socks or an artificial knee cuff.

The actual static Godot assembly passed review before adding motion: continuous
shoulders, hands at upper-thigh height, no extra gear, coherent trouser/shoe
contact. The same six-second right/stop/left/settle capture is used for motion
review, with source hashes recorded in the manifest. This is a local visual
candidate awaiting user judgment; no publication or default replacement is
implied by numerical checks.


## Arm-only refinement

After the user liked the resident overall but found the arms unnatural, only
arm rendering and motion changed. The earlier whole-arm pendulum is retained
in the previous local commit for the controlled comparison. Existing torso,
leg animation, art files, movement, and background are unchanged. The original
six-second frames and refined frames use the same input and camera.

Numerical coverage includes fixed shoulder-to-elbow length, rigid forearm scale,
bounded independent elbow articulation, gentle shoulder range, complete idle
settling and teleport reset. These checks supplement actual rendered start,
stop, turn and walking frames; visual naturalness still requires user review.
