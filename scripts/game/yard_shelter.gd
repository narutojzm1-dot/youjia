extends Node
## Resident routing shares the real gate and body collisions. Never teleport
## during play or consume ground food while waiting for the narrow doorway.
const Ground := preload("res://scripts/game/yard_gate_ground.gd")
const Daylight := preload("res://scripts/game/world_daylight.gd")
const IDS := ["sheep_a", "cow", "sheep_b"]
const BEDS := {"sheep_a": Vector2(952,461), "cow": Vector2(1010,474), "sheep_b": Vector2(1090,484)}
var world: Node2D
var outdoors: Dictionary = {}
var active := ""
var paths: Dictionary = {}
var repath := 0.0
var returning := false

func _init(host: Node2D) -> void:
	world = host
	for id: String in IDS:
		var actor = world.actor_named(id)
		outdoors[id] = actor.wander_rect
		if not world.gate.opened or is_night():
			actor.position = BEDS[id]
			actor._velocity = Vector2.ZERO
			actor._gait.weight = 0.0
			actor.z_index = roundi(actor.position.y)
	prepare(0.0)

func is_night() -> bool:
	return Daylight.phase(world.tod_fraction()) == "night"

func inside(actor: FeltActor) -> bool:
	return YardGround.contains(Ground.inside(), actor.position)

func prepare(delta: float) -> void:
	var night := is_night()
	returning = false
	for id: String in IDS:
		var actor = world.actor_named(id)
		actor.walk_ground = Ground.for_body(world.gate.opened, actor.position)
		actor.avoid_pond = true
		if night and not at_bed(actor): returning = true
	# A closed gate is opened durably before the evening walk begins.
	if returning and not world.gate.opened and world.gate.pending.is_empty():
		world.gate.toggle()
	var queue: Array = ["sheep_b", "cow", "sheep_a"] if night else IDS.duplicate()
	if not active.is_empty() and not needs_trip(world.actor_named(active), night):
		active = ""
		paths.clear()
	for id: String in queue:
		var actor = world.actor_named(id)
		var trip := needs_trip(actor, night)
		if trip and active.is_empty() and world.gate.opened:
			active = id
			repath = 0.0
		if trip or inside(actor):
			actor.set_meta("shelter_controlled", true)
			world.ground_food.targets.erase(id)
			world.ground_food.waiting.erase(id)
		else:
			actor.remove_meta("shelter_controlled")
			actor.remove_meta("shelter_rest")
			actor.wander_rect = outdoors[id]
	repath -= delta

func at_bed(actor: FeltActor) -> bool:
	return actor.position.distance_to(BEDS[actor.actor_id]) < 4.0

func needs_trip(actor: FeltActor, night: bool) -> bool:
	if night: return not at_bed(actor)
	return world.gate.opened and inside(actor)

func step(actor: FeltActor, delta: float) -> bool:
	if not IDS.has(actor.actor_id) or not actor.has_meta("shelter_controlled"): return false
	if actor.posed: return false
	var id: String = actor.actor_id
	if id != active or not world.gate.opened:
		rest(actor, delta)
		return true
	var goal: Vector2 = BEDS[id] if is_night() else outdoors[id].get_center()
	# First approach the inside of the doorway. A direct smoothed route from
	# the eastern beds can skim the concave rail corner between grid samples.
	if not is_night() and inside(actor) and actor.position.x > 936.0:
		goal = Vector2(924,466)
	var obstacles: Array = world.physical_obstacles(id)
	if repath <= 0.0:
		paths[id] = YardBodies.route(actor.position, goal, actor.body_radius * YardGround.depth_at(actor.position.y), obstacles, actor.walk_ground)
		repath = 0.6
	var path: Array = paths.get(id, [])
	# The inner fence corner is narrow. Dropping a waypoint several pixels early
	# cuts across its rail at small frame steps and leaves the next resident stuck.
	while not path.is_empty() and actor.position.distance_to(path[0]) < 0.05: path.pop_front()
	if path.is_empty():
		rest(actor, delta)
		return true
	actor.remove_meta("shelter_rest")
	actor.state = "path"
	actor._ack_cel = ""
	actor._ack_left = 0.0
	actor._refresh_painted_posture()
	var depth := YardGround.depth_at(actor.position.y)
	var before: Vector2 = actor.position
	var motion: Vector2 = (path[0] - before).limit_length(actor.speed * depth * delta)
	actor.position = YardBodies.move_inside(before, motion, actor.body_radius * depth, obstacles, actor.walk_ground, true)
	actor.advance_path(delta, actor.position - before, depth, bool(TuningStore.get_value("ui.reduced_motion", false)))
	return true

func rest(actor: FeltActor, delta: float) -> void:
	actor._velocity = Vector2.ZERO
	actor._gait.weight = 0.0
	actor.state = "rest"
	actor._idle_time = maxf(actor._idle_time, 2.0)
	if inside(actor): actor.set_meta("shelter_rest", true)
	else: actor.remove_meta("shelter_rest")
	actor.tick(delta, world.WORLD_SIZE)
