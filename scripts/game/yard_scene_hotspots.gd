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
		# Door leaf, with separate approach points on each side.
		"id": FENCE_GATE,
		"hit_polygon": PackedVector2Array([Vector2(888,435), Vector2(940,440),
			Vector2(941,509), Vector2(885,503)]),
		"approach_points": [Vector2(914,516), Vector2(914,466)],
		"visual_anchor": Vector2(912,488),
		"ambient_anchor": Vector2(1008,393),
		"reach": 20.0,
		"label_key": "action.open_gate",
		"target_key": "target.fence_gate",
	},
	{
		# The painted stone path leaves the frame bottom-left; that edge is the
		# way out to the near path (exploration). Feet stop on the lawn's bottom edge
		# near the path, outside the plant bed (75px) and grass (78px) reach so their key actions stay.
		"id": PATH_OUT,
		"hit_polygon": PackedVector2Array([
			Vector2(40, 560), Vector2(170, 585), Vector2(300, 655),
			Vector2(320, 720), Vector2(20, 720),
		]),
		"approach_points": [Vector2(262, 630), Vector2(256, 626)],
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
		and not world._millet_held and world._fish_carry_type.is_empty() and world._fish_state == world.FISH_IDLE


static func get_hotspot(target: String) -> Dictionary:
	for hotspot: Dictionary in CATALOG:
		if hotspot.id == target:
			return hotspot
	return {}


static func resolve(world: Node2D, target: String) -> Dictionary:
	var hotspot := get_hotspot(target)
	# Durable carried food can travel with the player. Keep ordinary ambient
	# observations suppressed while carrying; explicit doors do not consume food.
	var carrying_exit: bool = (target == PATH_OUT or (target == FENCE_GATE and not world.is_leading())) and world.inventory_enabled \
		and world.get_player() != null and world._fish_state == world.FISH_IDLE
	if hotspot.is_empty() or (not available(world) and not carrying_exit):
		return {}
	var point := Vector2.INF
	var best_distance := INF
	for candidate: Vector2 in hotspot.approach_points:
		if YardGround.allows(candidate, world.player_ground(), true):
			var distance: float = world.get_player().position.distance_squared_to(candidate)
			if distance < best_distance:
				point = candidate
				best_distance = distance
			if target != FENCE_GATE: break
	if not point.is_finite():
		return {}
	return {
		"target": target, "point": point, "label": ("action.close_gate" if world.gate.opened else "action.open_gate") if target == FENCE_GATE else hotspot.label_key,
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
