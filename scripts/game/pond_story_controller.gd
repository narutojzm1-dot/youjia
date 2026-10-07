extends Node
const Sequence := preload("res://scripts/game/pond_story_sequence.gd")
const Stage := preload("res://scripts/game/pond_story_stage.gd")
const MEET := Vector2(480, 545)
const HEN_POINT := Vector2(460, 530)
const GOOSE_POINT := Vector2(343, 537)
const HOME := Vector2(470, 650)
var world: Node2D
var sequence = Sequence.new()
var stage: Node2D
var borrowed: Array = []
var routes: Dictionary = {}

func _init(owner_world: Node2D) -> void:
	world = owner_world
	stage = Stage.new()
	world.add_child(stage)

func busy() -> bool: return sequence.active()

func cancel() -> void:
	sequence.cancel()
	stage.visible = false
	for actor in borrowed:
		if not is_instance_valid(actor): continue
		actor.visible = true
		actor.remove_meta("pond_story")
		if actor.actor_id == "turtle":
			var reached: Vector2 = actor.position
			var face: float = actor.facing
			actor.release_encounter_pose()
			actor.set_pose(reached, actor._base_scale, face)
		else:
			# Preserve the reached safe position, never teleport back to where an
			# interrupted animal was standing before it approached the bank.
			actor._encounter_saved_position = actor.position
			actor.release_encounter_pose()
	borrowed.clear()
	routes.clear()

func tick(delta: float, move: Vector2) -> void:
	var turtle = world.actor_named("turtle")
	var hen = world.actor_named("chicken")
	var goose = world.actor_named("goose")
	var interrupted: bool = not world.input_enabled or world._has_walk_goal or world._leading \
		or not move.is_zero_approx() or world.inventory_busy or world._goose_mount_phase >= 0
	interrupted = interrupted or world.get_player().carrying_grass or world._millet_held \
		or not world._fish_carry_type.is_empty() or world._fish_state != world.FISH_IDLE
	var owns_participants := borrowed.size() == 3
	for actor in borrowed:
		if not is_instance_valid(actor) or actor not in [turtle, hen, goose] or not actor.has_meta("pond_story"):
			owns_participants = false
	var available: bool = not interrupted and hen != null and goose != null \
		and not hen.posed and not goose.posed and hen.state != "food" and goose.state != "food" \
		and world.get_player().position.distance_to(MEET) < 240.0
	if available and world.ground_food != null:
		available = not world.ground_food.targets.has("chicken") and not world.ground_food.targets.has("goose")
	var context := {"turtle_present": turtle != null,
		"chicken_stage": hen.get_meta("resident_stage", "") if hen != null else "",
		"goose_present": goose != null, "available": available,
		"owns_participants": owns_participants, "interrupted": interrupted}
	if busy() and not interrupted and owns_participants:
		if sequence.phase == "approach_hen":
			_move(turtle, MEET, delta, false)
			_move(hen, HEN_POINT, delta, true)
			context.hen_arrived = turtle.position.distance_to(MEET) < 2.0 and hen.position.distance_to(HEN_POINT) < 2.0
		elif sequence.phase == "approach_goose":
			_move(goose, GOOSE_POINT, delta, true)
			context.goose_arrived = goose.position.distance_to(GOOSE_POINT) < 2.0
		elif sequence.phase == "retreat":
			_move(turtle, HOME, delta, false)
			context.turtle_home = turtle.position.distance_to(HOME) < 2.0
	var was_active := busy()
	var result: Dictionary = sequence.tick(delta, context)
	if result.release:
		cancel()
		return
	if not was_active and busy():
		for actor in [turtle, hen, goose]:
			actor.set_meta("pond_story", true)
			actor.set_encounter_pose(actor.position, actor._base_scale, actor.facing)
			borrowed.append(actor)
	if not busy(): return
	for actor in borrowed:
		actor.visible = true
	var phase: String = sequence.phase
	if phase != "refuse": goose.show_goose_encounter_cel("idle")
	if phase == "ride":
		var progress: float = sequence.elapsed / float(Sequence.DURATIONS.ride)
		var travel := 0.0 if bool(TuningStore.get_value("ui.reduced_motion", false)) else 22.0 * sin(progress * PI)
		turtle.position = MEET + Vector2(travel, 0)
		turtle.pose_point = turtle.position
		turtle.visible = false
		hen.visible = false
	elif phase == "peck_attempt":
		turtle.visible = false
		goose.visible = false
	elif phase == "refuse":
		goose.facing = 1.0
		goose.show_goose_encounter_cel("riding_up")
		goose.advance_path(delta, Vector2.ZERO, YardGround.depth_at(goose.position.y), true)
		turtle.facing = 1.0
		turtle.advance_path(delta, Vector2.ZERO, YardGround.depth_at(turtle.position.y), true)
	stage.present(phase, turtle.position, world._backdrop.modulate)
	if phase == "ride" and sequence.elapsed >= 1.5:
		_record("pond_hen_ride")
	elif phase == "peck_attempt" and sequence.elapsed >= 0.4:
		_record("pond_goose_refused")

func _record(event_id: String) -> void:
	if event_id in world.collected and PhotoMoment.has_event_subject(world.photo_moments.get(event_id, {}), event_id): return
	var moment := PhotoMoment.capture(world, ExpressionCatalog.find_rule(event_id))
	if not PhotoMoment.has_event_subject(moment, event_id): return
	world.photo_moments[event_id] = moment
	if event_id not in world.collected: world.collected.append(event_id)
	world.last_photo = event_id
	world.album_updated.emit(world.collected, event_id)

func _move(actor, goal: Vector2, delta: float, lawn: bool) -> void:
	var point := goal
	if lawn:
		var route: Array = routes.get(actor.actor_id, [])
		while not route.is_empty() and actor.position.distance_to(route[0]) < 2.0:
			route.pop_front()
		if route.is_empty():
			route = YardBodies.route(actor.position, goal,
				# Plan for the largest footprint along the perspective lawn, so
				# growing a few pixels nearer the camera cannot stall a tangent.
				actor.body_radius * YardGround.depth_at(YardGround.NEAR_Y),
				world.physical_obstacles(actor.actor_id), YardGround.lawn())
			routes[actor.actor_id] = route
		if route.is_empty(): return
		point = route[0]
	var previous: Vector2 = actor.position
	var next: Vector2 = previous.move_toward(point, float(actor.get_meta("base_speed", 12.0)) * delta)
	if lawn and not YardBodies.clear_segment(previous, next, actor.body_radius * YardGround.depth_at(next.y), world.physical_obstacles(actor.actor_id)):
		routes.erase(actor.actor_id)
		return
	actor.position = next
	actor.pose_point = next
	actor.advance_path(delta, next - previous, YardGround.depth_at(next.y), bool(TuningStore.get_value("ui.reduced_motion", false)))
