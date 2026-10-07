extends RefCounted

# Complete generated cel, not a deformation of the idle cow. Pixel anchors
# refer to the 1254-square source; native art faces left.
const TEXTURE := "res://assets/holiday/characters/ground_feed/cow-graze-v2.png"
const METADATA := {
	"ground_anchor": [750, 990], "mouth_anchor": [223, 965],
	"alpha_bbox": [73, 314, 1104, 682], "native_facing": -1.0,
}

static func mouth_offset(actor: FeltActor, food: Vector2) -> Vector2:
	var side := signf(food.x - actor.position.x)
	if side == 0.0: side = actor.facing
	var source := Vector2(527.0 * side, -25.0)
	return source * actor._base_scale * float(actor.get_meta("visual_scale", 1.0)) * YardGround.depth_at(food.y)
