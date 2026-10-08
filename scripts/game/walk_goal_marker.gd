extends RefCounted

## REQ-20261008-074: the tap-to-walk destination ring.
## It used to be a perfect upright circle of radius 10 drawn without
## anti-aliasing, the same size near the house and far by the pond. Every
## shadow and ground cue in the yard is a flattened ellipse that scales with
## YardGround.depth_at, so the ring read like a sticker on the screen rather
## than a mark on the grass, and it popped in fully on the tap frame.
##
## Now: same warm cream colour and 0.85 alpha, flattened to lie on the ground,
## scaled by depth, a uniform 2px anti-aliased line, and a 0.15s fade in.
## Reduced motion shows it at full alpha at once. Walk logic, goal position,
## when it shows and when it clears are unchanged; YardWorld.tick owns the age.

const RADIUS := 10.0
const FLATTEN := 0.45
const WIDTH := 2.0
const ALPHA := 0.85
const FADE_IN := 0.15
const COLOR := Color(1.0, 0.92, 0.65)
const SEGMENTS := 32


static func pose(age: float, reduced_motion: bool, depth: float) -> Dictionary:
	var alpha := ALPHA
	if not reduced_motion:
		alpha = ALPHA * clampf(maxf(0.0, age) / FADE_IN, 0.0, 1.0)
	var r := RADIUS * clampf(depth, 0.5, 1.5)
	return {"alpha": alpha, "radius": Vector2(r, r * FLATTEN)}


static func points(center: Vector2, radius: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i: int in SEGMENTS + 1:
		var angle := TAU * float(i) / float(SEGMENTS)
		result.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return result
