extends SceneTree

# Outcome regressions from the real, unmodified initial yard. No actor is
# teleported, frozen, or given a synthetic wander target. Pointer-controller
# routes and held movement vectors are the same commands used by the game;
# explicit_target_suite.gd separately exercises raw viewport/HUD dispatch.
# Run: godot --headless --path . --script res://test/physical_yard_suite.gd
const FRAME_RATES := [30, 60, 120]
const LAND_IDS := ["cow", "horse", "sheep_a", "sheep_b", "goose", "llama"]
const APPROACH_IDS := ["cow", "sheep_a", "horse", "goose"]
const SIDES := [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
const SIDE_NAMES := ["west", "east", "north", "south"]
const CLEARANCE_TOLERANCE := 0.995

var _checks := 0
var _failures := PackedStringArray()
var _world_script: Script


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var tuning := root.get_node("TuningStore")
	tuning.call("end_run")
	tuning.call("reset_defaults")
	_world_script = load("res://scripts/game/yard_world.gd")
	_check(_world_script != null and _world_script.can_instantiate(), "yard script compiles")
	if _world_script != null and _world_script.can_instantiate():
		for fps: int in FRAME_RATES:
			_test_keyboard_approaches(fps)
			_test_resident_routes(fps)
			_test_leading_routes(fps)
	root.get_node("AudioDirector").call("release_streams")
	if _failures.is_empty():
		print("[physical-yard-tests] PASS: %d checks" % _checks)
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[physical-yard-tests] " + failure)
		print("[physical-yard-tests] FAIL: %d failures across %d checks" % [_failures.size(), _checks])
		quit(1)


func _world(fps: int, fixture: int):
	seed(1102026 + fps * 100 + fixture)
	var world = _world_script.new()
	root.add_child(world)
	world.setup()
	if world.get_player() == null or world._actors.size() != 9:
		_check(false, "fixture %d at %dHz must instantiate the complete real yard" % [fixture, fps])
		world.free()
		return null
	world.tick(1.0 / float(fps), Vector2.ZERO)
	_check(world.get_player().position.distance_to(Vector2(260, 540)) < 0.001,
		"fixture %d at %dHz begins at the real player spawn" % [fixture, fps])
	for actor_id: String in LAND_IDS:
		var actor = world.actor_named(actor_id)
		var radius: Variant = actor.get("body_radius") if actor != null else null
		var has_body: bool = radius is Vector2 and radius.x > 0.0 and radius.y > 0.0
		_check(has_body,
			"%s has a physical foot-space at %dHz" % [actor_id, fps])
		if not has_body:
			world.free()
			return null
	var player_radius: Variant = world.get_player().get("body_radius")
	var has_player_body: bool = player_radius is Vector2 and player_radius.x > 0.0 and player_radius.y > 0.0
	_check(has_player_body,
		"player has a physical foot-space at %dHz" % fps)
	if not has_player_body:
		world.free()
		return null
	return world


func _test_keyboard_approaches(fps: int) -> void:
	for actor_index: int in APPROACH_IDS.size():
		var actor_id: String = APPROACH_IDS[actor_index]
		var world = _world(fps, actor_index)
		if world == null:
			return
		var actor = world.actor_named(actor_id)
		var approached_sides := 0
		for side_index: int in SIDES.size():
			var side: Vector2 = SIDES[side_index]
			var label := "%s from %s at %dHz" % [actor_id, SIDE_NAMES[side_index], fps]
			var staging := _approach_point(world, actor, side)
			# The pond edge and roof-side lawn genuinely have no standing room
			# from every angle. Require at least two usable approaches per animal.
			if staging == Vector2.INF:
				continue
			var metric := _new_metric(world)
			if not _walk_to(world, staging, fps, metric, label + " staging", 14.0):
				_assert_metric(metric, label)
				continue
			# A resident may have taken a short walk while we crossed the yard.
			# Restage once using its new position, still through normal walking.
			if (world.get_player().position - actor.position).normalized().dot(side) < 0.25:
				staging = _approach_point(world, actor, side)
				if staging == Vector2.INF or not _walk_to(world, staging, fps, metric, label + " restaging", 14.0):
					_assert_metric(metric, label)
					continue
			var actual_side: Vector2 = (world.get_player().position - actor.position).normalized()
			_check(actual_side.dot(side) >= 0.25, label + " really starts on the requested side")
			var nearest := INF
			var before: Vector2 = world.get_player().position
			for frame: int in fps * 6:
				var toward: Vector2 = actor.position - world.get_player().position
				world.tick(1.0 / float(fps), toward.normalized())
				_observe(world, metric)
				nearest = minf(nearest, _separation(world.get_player(), actor))
			_check(nearest <= 1.12, label + " actually reaches the animal footprint (nearest %.3f)" % nearest)
			_check(world.get_player().position.distance_to(before) > 2.0,
				label + " tests real keyboard travel rather than a frozen player")
			_assert_metric(metric, label)
			approached_sides += 1
		_check(approached_sides >= 2, "%s gets multiple real approach sides at %dHz (%d)" % [actor_id, fps, approached_sides])
		world.free()


func _approach_point(world, actor, side: Vector2) -> Vector2:
	var combined: Vector2 = _radius(world.get_player()) + _radius(actor)
	for margin: float in [28.0, 18.0, 9.0]:
		var point: Vector2 = actor.position + side * (combined + Vector2.ONE * margin)
		if YardGround.allows(point, YardGround.lawn(), true) and _clear_for_player(world, point):
			return point
	return Vector2.INF


func _test_resident_routes(fps: int) -> void:
	var world = _world(fps, 20)
	if world == null:
		return
	var metric := _new_metric(world)
	# The first west-to-east path crosses the cow and horse homes. Later legs
	# reverse direction, cross both sheep homes, and turn along the pond rim.
	var goals: Array[Vector2] = [
		Vector2(865, 478), Vector2(252, 472), Vector2(860, 530),
		Vector2(392, 552), Vector2(758, 442), Vector2(228, 564),
	]
	for index: int in goals.size():
		_walk_to(world, goals[index], fps, metric, "resident crossing %d at %dHz" % [index + 1, fps])
	_check(float(metric.travel) > 2200.0, "resident routes cover real yard distance at %dHz (%.1fpx)" % [fps, metric.travel])
	_assert_metric(metric, "multiple natural resident routes at %dHz" % fps)
	world.free()


func _test_leading_routes(fps: int) -> void:
	var world = _world(fps, 30)
	if world == null:
		return
	var metric := _new_metric(world)
	var llama = world.actor_named("llama")
	world.request_pointer_action(llama.position + Vector2(0, -48))
	for frame: int in fps * 35:
		world.tick(1.0 / float(fps), Vector2.ZERO)
		_observe(world, metric)
		if world._leading:
			break
	_check(world._leading and world.get_player().leading and llama.state == "lead",
		"natural pointer approach starts leading at %dHz" % fps)
	if world._leading:
		var goals: Array[Vector2] = [
			Vector2(820, 454), # east pasture, past horse and goose
			Vector2(267, 561), # cottage, around cow and both sheep
			Vector2(545, 526), # west pond rim
			Vector2(856, 529), # east pond rim
			Vector2(447, 442), # back through the pasture in the other direction
		]
		for index: int in goals.size():
			var label := "leading leg %d at %dHz" % [index + 1, fps]
			_walk_to(world, goals[index], fps, metric, label)
			for frame: int in fps * 8:
				world.tick(1.0 / float(fps), Vector2.ZERO)
				_observe(world, metric)
			_check(world._leading and llama.state == "lead", label + " preserves leading")
			_check(llama.position.distance_to(world.get_player().position) < 96.0,
				label + " brings the llama along instead of abandoning it (gap %.1fpx)" % llama.position.distance_to(world.get_player().position))
		var settled: Vector2 = llama.position
		for frame: int in fps * 3:
			world.tick(1.0 / float(fps), Vector2.ZERO)
			_observe(world, metric)
		_check(llama.position.distance_to(settled) < 0.5,
			"lead settles without oscillating after physical routes at %dHz" % fps)
		# The follower can take shorter inside turns than the player's route.
		# Per-leg proximity above proves every destination was actually visited.
		_check(float(metric.llama_travel) > 1000.0,
			"llama follows the full cottage/pasture/pond route at %dHz (%.1fpx)" % [fps, metric.llama_travel])
	_assert_metric(metric, "leading around residents at %dHz" % fps)
	world.free()


func _walk_to(world, goal: Vector2, fps: int, metric: Dictionary, label: String, initial_tolerance: float = 14.0) -> bool:
	var player = world.get_player()
	# Staging uses the same 14px arrival tolerance as every route; the
	# requested approach side and subsequent real body contact are checked.
	if player.position.distance_to(goal) <= initial_tolerance:
		return true
	var accepted: bool = world.try_walk_to(goal)
	_check(accepted, label + " accepts valid reachable lawn destination %s" % goal)
	if not accepted:
		_print_route_state(world, label)
		return false
	_check(world._walk_goal.distance_to(goal) < 0.01, label + " keeps the exact requested ground destination")
	# Calibrated character speed is leisurely. This bound permits the longest
	# diagonal route while still detecting an indefinitely stalled controller.
	for frame: int in fps * 45:
		world.tick(1.0 / float(fps), Vector2.ZERO)
		_observe(world, metric)
		if not world._has_walk_goal:
			break
	var reached: bool = player.position.distance_to(goal) <= 14.0 and not world._has_walk_goal
	_check(reached, label + " reaches its goal without a deadlock (player %s, goal %s, gap %.1fpx)" % [player.position, goal, player.position.distance_to(goal)])
	if not reached:
		_print_route_state(world, label)
	return reached


func _print_route_state(world, label: String) -> void:
	var player = world.get_player()
	var bodies: Array[String] = []
	for actor_id: String in LAND_IDS:
		var actor = world.actor_named(actor_id)
		bodies.append("%s=%s gap=%.4f state=%s" % [actor_id, actor.position, _separation(player, actor), actor.state])
	print("[physical-yard-route-state] %s player=%s velocity=%s goal_active=%s path=%s pending=%s bodies=%s" % [
		label, player.position, player._velocity, world._has_walk_goal, world._walk_path,
		world._pending_interaction, "; ".join(bodies),
	])


func _new_metric(world) -> Dictionary:
	return {
		"frames": 0, "travel": 0.0, "llama_travel": 0.0,
		"previous": world.get_player().position,
		"llama_previous": world.actor_named("llama").position,
		"minimum_gap": INF, "overlap_frames": 0, "first_overlap": "",
		"depth_errors": 0, "first_depth_error": "", "outside_frames": 0,
	}


func _observe(world, metric: Dictionary) -> void:
	var player = world.get_player()
	var llama = world.actor_named("llama")
	metric.frames += 1
	metric.travel += player.position.distance_to(metric.previous)
	metric.llama_travel += llama.position.distance_to(metric.llama_previous)
	metric.previous = player.position
	metric.llama_previous = llama.position
	if not YardGround.allows(player.position, YardGround.lawn(), true) or not llama._stands_on(llama.position):
		metric.outside_frames += 1
	var actors: Array = [player]
	for actor_id: String in LAND_IDS:
		actors.append(world.actor_named(actor_id))
	for first: int in actors.size():
		for second: int in range(first + 1, actors.size()):
			var a = actors[first]
			var b = actors[second]
			# All real actors share one foot-Y depth scale, including when a
			# taller sprite extends visually across a nearer actor's head.
			var depth_delta: float = a.position.y - b.position.y
			if absf(depth_delta) >= 1.0 and signf(float(a.z_index - b.z_index)) != signf(depth_delta):
				metric.depth_errors += 1
				if str(metric.first_depth_error).is_empty():
					metric.first_depth_error = "%s y=%.2f z=%d / %s y=%.2f z=%d" % [_label(a), a.position.y, a.z_index, _label(b), b.position.y, b.z_index]
			if a != player and a != llama and b != llama:
				continue
			var gap := _separation(a, b)
			metric.minimum_gap = minf(metric.minimum_gap, gap)
			if gap < CLEARANCE_TOLERANCE:
				metric.overlap_frames += 1
				if str(metric.first_overlap).is_empty():
					metric.first_overlap = "%s %s / %s %s normalized gap=%.4f" % [_label(a), a.position, _label(b), b.position, gap]


func _radius(actor) -> Vector2:
	return actor.body_radius * YardGround.depth_at(actor.position.y)


func _separation(a, b) -> float:
	var combined: Vector2 = _radius(a) + _radius(b)
	return ((a.position - b.position) / combined).length()


func _clear_for_player(world, point: Vector2) -> bool:
	var radius: Vector2 = world.get_player().body_radius * YardGround.depth_at(point.y)
	for actor_id: String in LAND_IDS:
		var actor = world.actor_named(actor_id)
		if ((point - actor.position) / (radius + _radius(actor))).length() < 1.15:
			return false
	return true


func _label(actor) -> String:
	return "player" if actor.has_method("snapshot_state") else str(actor.actor_id)


func _assert_metric(metric: Dictionary, label: String) -> void:
	print("[physical-yard-tests] %s frames=%d travel=%.1f llama=%.1f min_gap=%.4f overlap=%d depth=%d" % [label, metric.frames, metric.travel, metric.llama_travel, metric.minimum_gap, metric.overlap_frames, metric.depth_errors])
	_check(metric.overlap_frames == 0, label + " never penetrates a player/animal or llama/resident footprint (%s)" % metric.first_overlap)
	_check(metric.depth_errors == 0, label + " consistently draws the lower feet in front (%s)" % metric.first_depth_error)
	_check(metric.outside_frames == 0, label + " keeps player and llama on their allowed ground")


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
		print("[physical-yard-failure] " + message)
