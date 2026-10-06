class_name VillagePathLayout
extends RefCounted
## Existing 05 lakeside village, original 1672x941. No redrawn geography.
static var _geometry: PaintedPath
static func geometry() -> PaintedPath:
	if _geometry == null:
		_geometry = PaintedPath.new({
			"ART": "res://assets/holiday/exploration/lakeside_village.png",
			"SIZE": Vector2(1672, 941), "JUNCTION": Vector2(560, 873),
			"ARMS": {"lane": [Vector2(560, 873), Vector2(470, 835), Vector2(386, 790), Vector2(313, 741), Vector2(257, 691), Vector2(252, 662), Vector2(302, 625), Vector2(350, 598), Vector2(362, 559)]},
			"HOME_ARM": "", "START": {"arm": "lane", "d": 0.0},
			"WALK_SPEED": 85.0, "NEAR": 55.0, "HOME_HOLD": 0.45, "MIN_ALIGN": 0.3,
			"HOME_TAP_REACH": 0.0, "HOME_TAP_BELOW": 0.0,
			"DEPTH_NEAR_Y": 873.0, "DEPTH_FAR_Y": 559.0, "DEPTH_NEAR": 1.35, "DEPTH_FAR": 0.75,
			"WALKER_BOX": Rect2(-24, -108, 48, 108), "FULL_VIEW_MIN": 600.0,
			"PHONE_VIEW_HEIGHT": 640.0, "PHONE_VIEW_WIDTH": 420.0,
			"STOPS": [
				{"id": "village_entry", "arm": "lane", "d": 35.0},
				{"id": "village_stray", "arm": "lane", "d": 325.0},
				{"id": "village_lake", "arm": "lane", "d": 440.0},
			],
		})
	return _geometry
