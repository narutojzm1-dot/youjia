class_name YardSceneHotspots
extends RefCounted

# All positions use the existing 1280x720 YardWorld coordinates. The painted
# balcony is not walkable: hit, safe approach and art anchors stay independent.
const WINDOWBOX := "windowbox"
static var CATALOG: Array[Dictionary] = [
	{
		"id": WINDOWBOX,
		"hit_polygon": PackedVector2Array([
			Vector2(239, 244), Vector2(335, 244), Vector2(357, 255),
			Vector2(368, 280), Vector2(354, 307), Vector2(226, 307),
			Vector2(213, 281), Vector2(219, 252),
		]),
		"approach_points": [Vector2(253, 494), Vector2(282, 487)],
		"visual_anchor": Vector2(284, 225),
		"reach": 64.0,
		"label_key": "action.observe_windowbox",
		"target_key": "target.windowbox",
	}
]


static func available(world: Node2D) -> bool:
	var player = world.get_player()
	# No environmental observation should steal leading, a cast, or an item
	# being carried to an animal. Explicitly reserve their existing routes.
	return player != null and not world.is_leading() and not player.carrying_grass \
		and world._fish_carry_type.is_empty() and world._fish_state == world.FISH_IDLE


static func get_hotspot(target: String) -> Dictionary:
	for hotspot: Dictionary in CATALOG:
		if hotspot.id == target:
			return hotspot
	return {}


static func resolve(world: Node2D, target: String) -> Dictionary:
	var hotspot := get_hotspot(target)
	if hotspot.is_empty() or not available(world):
		return {}
	var point := Vector2.INF
	for candidate: Vector2 in hotspot.approach_points:
		if YardGround.allows(candidate, YardGround.lawn(), true):
			point = candidate
			break
	if not point.is_finite():
		return {}
	return {
		"target": target, "point": point, "label": hotspot.label_key,
		"reach": hotspot.reach,
	}


static func at_point(world: Node2D, point: Vector2) -> Dictionary:
	for hotspot: Dictionary in CATALOG:
		if Geometry2D.is_point_in_polygon(point, hotspot.hit_polygon):
			return resolve(world, hotspot.id)
	return {}


static func near_player(world: Node2D) -> Dictionary:
	if not available(world):
		return {}
	var player = world.get_player()
	var best: Dictionary = {}
	var distance := INF
	for hotspot: Dictionary in CATALOG:
		var candidate := resolve(world, hotspot.id)
		if candidate.is_empty():
			continue
		var gap: float = player.position.distance_to(candidate.point)
		if gap < candidate.reach and gap < distance:
			distance = gap
			best = candidate
	return best


static func reach(target: String) -> float:
	return float(get_hotspot(target).get("reach", 0.0))
