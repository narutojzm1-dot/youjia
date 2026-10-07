extends Node2D
## Whole painted cels share the turtle's photo subject. Hidden live actors are
## omitted by PhotoMoment, so a replay cannot invent a second chicken/goose.
var actor_id := "turtle"
var cel: Sprite2D
const RIDE := "res://assets/holiday/characters/pond/turtle-hen-ride.png"
const MISS := "res://assets/holiday/characters/pond/goose-turtle-peck-miss.png"

func _init() -> void:
	cel = Sprite2D.new()
	cel.centered = false
	cel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(cel)
	visible = false

func present(kind: String, point: Vector2, tint: Color) -> void:
	visible = kind in ["ride", "peck_attempt"]
	if not visible: return
	var ride := kind == "ride"
	cel.texture = load(RIDE if ride else MISS)
	cel.position = -Vector2(750, 1040) if ride else -Vector2(1400, 820)
	scale = Vector2.ONE * (90.0 / 1220.0 if ride else 90.0 / 650.0) * YardGround.depth_at(point.y)
	position = point
	z_index = roundi(point.y)
	modulate = tint
