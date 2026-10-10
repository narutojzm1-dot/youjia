extends Node
## Resident routing shares the real gate and body collisions. Never teleport
## during play or consume ground food while waiting for the narrow doorway.
const Ground := preload("res://scripts/game/yard_gate_ground.gd")
const Daylight := preload("res://scripts/game/world_daylight.gd")
const IDS := ["sheep_a", "cow", "sheep_b"]
const GUESTS := ["horse", "llama"]
const ALL_IDS := IDS + GUESTS
const HOME_REST := {"horse": Vector2(615,466), "llama": Vector2(710,500)}
const BEDS := {"sheep_a": Vector2(977,478), "cow": Vector2(1041,476), "sheep_b": Vector2(1103,484),
	"horse": Vector2(1041,444), "llama": Vector2(970,443)}
var world: Node2D
var outdoors: Dictionary = {}
var active := ""
var paths: Dictionary = {}
var repath := 0.0
var returning := false

func _init(host: Node2D) -> void:
	world = host
	for id: String in ALL_IDS:
		var actor = world.actor_named(id)
		outdoors[id] = actor.wander_rect
		if wants_pen(actor) or (IDS.has(id) and not world.gate.opened):
			actor.position = BEDS[id]
			actor._velocity = Vector2.ZERO
			actor._gait.weight = 0.0
			actor.z_index = roundi(actor.position.y)
	prepare(0.0)

func is_night() -> bool:
	return Daylight.phase(world.tod_fraction()) == "night"

func inside(actor: FeltActor) -> bool:
	return YardGround.contains(Ground.inside(), actor.position)

func needs_shelter() -> bool:
	return is_night() or world.weather == "rain"

func wants_pen(actor: FeltActor) -> bool:
	return needs_shelter() if IDS.has(actor.actor_id) else world.weather == "rain"

func player_owned(actor: FeltActor) -> bool:
	return actor.posed or (actor.actor_id == "llama" and (world._leading or world._pending_interaction == "llama")) \
		or (actor.actor_id == "horse" and world._goose_mount_phase >= 0)

func destination(actor: FeltActor) -> Vector2:
	if wants_pen(actor): return BEDS[actor.actor_id]
	return HOME_REST[actor.actor_id] if GUESTS.has(actor.actor_id) else outdoors[actor.actor_id].get_center()

func release(actor: FeltActor) -> void:
	actor.remove_meta("shelter_controlled")
	actor.remove_meta("shelter_rest")
	actor.remove_meta("shelter_return_home")
	actor.wander_rect = outdoors[actor.actor_id]

func prepare(delta: float) -> void:
	var night := needs_shelter()
	returning = false
	for id: String in ALL_IDS:
		var actor = world.actor_named(id)
		actor.walk_ground = Ground.for_body(world.gate.opened, actor.position)
		actor.avoid_pond = true
		if wants_pen(actor) and not at_bed(actor) and not player_owned(actor): returning = true
		if GUESTS.has(id) and inside(actor) and not wants_pen(actor) and not player_owned(actor): returning = true
		if GUESTS.has(id) and inside(actor) and not wants_pen(actor): actor.set_meta("shelter_return_home", true)
	# A closed gate is opened durably before the evening walk begins.
	if returning and not world.gate.opened and world.gate.pending.is_empty():
		world.gate.toggle()
	var queue: Array = ["sheep_b", "cow", "sheep_a", "horse", "llama"] if night else ALL_IDS.duplicate()
	if not active.is_empty() and (not needs_trip(world.actor_named(active), night) or player_owned(world.actor_named(active))):
		active = ""
		paths.clear()
	for id: String in queue:
		var actor = world.actor_named(id)
		if player_owned(actor):
			release(actor)
			continue
		var trip := needs_trip(actor, night)
		if trip and active.is_empty() and (world.gate.opened or (not inside(actor) and not wants_pen(actor))):
			active = id
			repath = 0.0
		if trip or inside(actor) or (GUESTS.has(id) and is_night()):
			actor.set_meta("shelter_controlled", true)
			world.ground_food.targets.erase(id)
			world.ground_food.waiting.erase(id)
		else:
			release(actor)
	repath -= delta

func at_bed(actor: FeltActor) -> bool:
	return actor.position.distance_to(BEDS[actor.actor_id]) < 4.0

func needs_trip(actor: FeltActor, _night: bool) -> bool:
	if wants_pen(actor): return not at_bed(actor)
	if GUESTS.has(actor.actor_id) and is_night():
		return actor.position.distance_to(destination(actor)) >= 4.0
	if GUESTS.has(actor.actor_id) and actor.has_meta("shelter_return_home"):
		return actor.position.distance_to(destination(actor)) >= 4.0
	return world.gate.opened and inside(actor)

func step(actor: FeltActor, delta: float) -> bool:
	if not ALL_IDS.has(actor.actor_id) or not actor.has_meta("shelter_controlled"): return false
	if player_owned(actor): return false
	var id: String = actor.actor_id
	if id != active or (not world.gate.opened and (inside(actor) or wants_pen(actor))):
		rest(actor, delta)
		return true
	var goal := destination(actor)
	# Clear the concave inner rail before turning toward the eastern beds.
	if wants_pen(actor) and actor.position.x < 959.5:
		goal = Vector2(960,444)
	# First approach the inside of the doorway. A direct smoothed route from
	# the eastern beds can skim the concave rail corner between grid samples.
	if not wants_pen(actor) and inside(actor) and actor.position.x > 936.0:
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
	if (IDS.has(actor.actor_id) and inside(actor)) or (wants_pen(actor) and at_bed(actor)) or (GUESTS.has(actor.actor_id) and is_night() and actor.position.distance_to(destination(actor)) < 4.0): actor.set_meta("shelter_rest", true)
	else: actor.remove_meta("shelter_rest")
	actor.tick(delta, world.WORLD_SIZE)
