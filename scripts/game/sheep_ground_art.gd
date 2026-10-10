extends RefCounted

# Complete, identity-specific grazing cels. Anchors use the original1254px canvases.
const CELLS := {
	"sheep_a": {
		"texture": "res://assets/holiday/characters/ground_feed/sheep-clingy-graze-v1.png",
		"metadata": {"ground_anchor": [650, 1060], "mouth_anchor": [1040, 1062],
			"alpha_bbox": [95, 247, 1139, 824], "native_facing": 1.0},
	},
	"sheep_b": {
		"texture": "res://assets/holiday/characters/ground_feed/sheep-dull-graze-v1.png",
		"metadata": {"ground_anchor": [740, 1110], "mouth_anchor": [193, 1060],
			"alpha_bbox": [70, 310, 1158, 807], "native_facing": -1.0},
	},
}

static func mouth_offset(actor: FeltActor, food: Vector2) -> Vector2:
	var metadata: Dictionary = CELLS[actor.actor_id].metadata
	var ground: Array = metadata.ground_anchor
	var mouth: Array = metadata.mouth_anchor
	var side := signf(food.x - actor.position.x)
	if side == 0.0: side = actor.facing
	var source := Vector2((float(mouth[0]) - float(ground[0])) * float(metadata.native_facing) * side,
		float(mouth[1]) - float(ground[1]))
	return source * actor._base_scale * float(actor.get_meta("visual_scale", 1.0)) * YardGround.depth_at(food.y)
