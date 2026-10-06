class_name BeibeiArt
extends RefCounted
## Two separately painted whole-body cels share a resident identity.
static func configure(stage: String) -> Dictionary:
	var grown := stage == "grown"
	var bounds := Rect2(116, 32, 1149, 1089) if grown else Rect2(186, 46, 1036, 1061)
	return {
		"id": "beibei", "species": "dog", "name_key": "target.beibei",
		"textures": {"idle": "res://assets/holiday/characters/beibei/%s.png" % ("grown" if grown else "puppy")},
		"scale": (72.0 if grown else 43.0) / bounds.size.y,
		"ground_anchor": Vector2(700, 1090), "art_bounds": bounds,
		"body_radius": Vector2(26, 10) if grown else Vector2(16, 8),
		"native_facing": 1.0, "speed": 22.0, "daily_routine": true,
		"position": Vector2(300, 530), "wander": Rect2(255, 495, 145, 80),
	}
