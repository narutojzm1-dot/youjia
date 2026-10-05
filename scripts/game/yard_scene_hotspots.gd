class_name YardSceneHotspots
extends RefCounted

# All positions use the existing 1280x720 YardWorld coordinates. The painted
# balcony is not walkable: hit, safe approach and art anchors stay independent.
const WINDOWBOX := "windowbox"
const SHORE_STONES := "shore_stones"
const FENCE_GATE := "fence_gate"
const PATH_OUT := "path_out"
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
	},
	{
		# Only the painted stones on the west bank are clickable. The nearby
		# water remains fishing; the feet stop on grass above the shore.
		"id": SHORE_STONES,
		"hit_polygon": PackedVector2Array([
			Vector2(477, 545), Vector2(494, 538), Vector2(522, 542),
			Vector2(537, 550), Vector2(543, 580), Vector2(537, 610),
			Vector2(529, 634), Vector2(511, 638), Vector2(486, 627),
			Vector2(469, 606), Vector2(464, 575),
		]),
		"approach_points": [Vector2(515, 527), Vector2(499, 521)],
		"visual_anchor": Vector2(568, 580),
		"reach": 54.0,
		"label_key": "action.touch_shore",
		"target_key": "target.shore_stones",
	},
	{
		# The gate is only a painted background detail. The player remains
		# well inside the yard while observing it; opening it needs separate art.
		"id": FENCE_GATE,
		"hit_polygon": PackedVector2Array([
			Vector2(907, 412), Vector2(959, 412), Vector2(967, 440),
			Vector2(970, 487), Vector2(961, 506), Vector2(910, 506),
			Vector2(905, 480), Vector2(903, 444),
		]),
		"approach_points": [Vector2(830, 510), Vector2(820, 505)],
		"visual_anchor": Vector2(929, 507),
		"ambient_anchor": Vector2(1008, 393),
		"reach": 64.0,
		"label_key": "action.observe_fence",
		"target_key": "target.fence_gate",
	},
	{
		# The painted stone path leaves the frame bottom-left; that edge is the
		# way out to the near path (exploration). Feet stop on the lawn's path end.
		"id": PATH_OUT,
		"hit_polygon": PackedVector2Array([
			Vector2(40, 560), Vector2(170, 585), Vector2(300, 655),
			Vector2(320, 720), Vector2(20, 720),
		]),
		"approach_points": [Vector2(232, 606), Vector2(250, 600)],
		"visual_anchor": Vector2(150, 660),
		"reach": 48.0,
		"label_key": "action.go_out",
		"target_key": "target.path_out",
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
