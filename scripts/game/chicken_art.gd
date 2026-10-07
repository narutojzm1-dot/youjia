class_name ChickenArt
extends RefCounted
static func configure(stage: String) -> Dictionary:
	var grown := stage == "hen"
	return {"id": "chicken", "species": "chicken", "name_key": "target.hen" if grown else "target.chick",
		"textures": {"idle": "res://assets/holiday/characters/chicken/%s.png" % ("hen" if grown else "chick"),
			"peck": "res://assets/holiday/characters/chicken/%s-peck.png" % ("hen" if grown else "chick")},
		"posture_metadata": {"peck": {"ground_anchor": [660, 1160] if grown else [640, 1090], "alpha_bbox": [99, 156, 1081, 1012] if grown else [186, 253, 949, 846], "native_facing": 1.0}},
		"scale": 56.0 / 1160.0 if grown else 25.0 / 989.0,
		"ground_anchor": Vector2(660, 1200) if grown else Vector2(640, 1100),
		"art_bounds": Rect2(163, 61, 887, 1160) if grown else Rect2(244, 137, 785, 989),
		"body_radius": Vector2(16, 7) if grown else Vector2(9, 5), "native_facing": 1.0,
		# Dry left bank beside the pond, separate from the cow's grazing patch.
		"speed": 24.0, "daily_routine": true, "position": Vector2(542, 522), "wander": Rect2(510, 507, 65, 30)}
