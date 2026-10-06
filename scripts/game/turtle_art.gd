class_name TurtleArt
extends RefCounted
const TEXTURE := "res://assets/holiday/characters/pond/turtle.png"
const ANCHOR := Vector2(710, 910)
const BOUNDS := Rect2(57, 279, 1307, 638)
const SCALE := 90.0 / 1307.0
static func configure() -> Dictionary:
	return {"id": "turtle", "species": "turtle", "name_key": "target.turtle",
		"textures": {"idle": TEXTURE}, "scale": SCALE, "ground_anchor": ANCHOR,
		"art_bounds": BOUNDS, "body_radius": Vector2(30, 9), "native_facing": 1.0,
		"speed": 5.0, "position": Vector2(470, 650), "wander": Rect2(457, 640, 25, 10)}
