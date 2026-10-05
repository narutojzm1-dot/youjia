extends SceneTree
# REQ-20261003-021: rest poses and the path snail use the new paintings.

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var tuning := root.get_node("TuningStore")
	tuning.reset_defaults()
	var world = load("res://scripts/game/yard_world.gd").new()
	root.add_child(world)
	world.setup()
	for actor_id: String in world._actors:
		world.debug_place_actor(actor_id, Vector2(1100, 400))
	_expect_rest(world, "duck_a", "preen", "duck_preen.png")
	_expect_rest(world, "horse", "idle", "horse.png")
	_expect_rest(world, "cow", "chew", "cow_chew.png")
	_expect_rest(world, "sheep_a", "shake", "sheep_shake.png")
	var dull = world._actors["sheep_b"]
	dull.state = "rest"
	dull._velocity = Vector2.ZERO
	dull._gait.weight = 0.0
	dull.posed = false
	dull.set_expression("idle")
	_check(dull._posture_id == "shake" and is_equal_approx(dull._sprite.scale.x, 1.0), "the left-facing sheep keeps the shake painting upright")
	var duck = world._actors["duck_a"]
	duck.state = "wander"
	duck._velocity = Vector2(20, 0)
	duck.set_expression("idle")
	_check(duck._posture_id == "idle", "a moving duck keeps the standing painting")
	var horse = world._actors["horse"]
	horse.state = "rest"
	horse._velocity = Vector2.ZERO
	horse._gait.weight = 0.0
	horse.posed = false
	horse.set_expression("idle")
	horse.set_pose(horse.position, horse._base_scale, horse.facing)
	_check(horse._posture_id == "idle" and str(horse._sprite.texture.resource_path).ends_with("horse.png"), "a posed horse retains its standing painting")
	_check_horse_size(world, tuning)
	world.debug_place_player(world._scene_feedback.PATH_POINT)
	world._has_walk_goal = false
	world._pending_interaction = ""
	for _i: int in 60:
		world.tick(1.0 / 60.0, Vector2.ZERO)
	_check(world._scene_feedback._path_duration <= 0.0, "the path painting waits through the first second")
	for _i: int in 120:
		world.tick(1.0 / 60.0, Vector2.ZERO)
	_check(world._scene_feedback._path_duration > 0.0, "standing on the south path shows the snail and clover")
	var album = world.collected.duplicate()
	world.tick(0.05, Vector2(1, 0))
	_check(world._scene_feedback._path_duration <= 0.0, "walking hides the path painting")
	_check(world.collected == album, "the path painting does not write the album")
	world.free()
	if failures.is_empty():
		print("INTERACTION POSE PASS ", checks)
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _expect_rest(world, actor_id: String, pose: String, file_name: String) -> void:
	var actor = world._actors[actor_id]
	actor.state = "rest"
	actor._velocity = Vector2.ZERO
	actor._gait.weight = 0.0
	actor.posed = false
	actor.set_expression("idle")
	var shown := str(actor._textures.get(pose, ""))
	_check(actor._posture_id == pose and shown.ends_with(file_name), actor_id + " rests on " + file_name)


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)


func _check_horse_size(world, tuning) -> void:
	var horse = world._actors["horse"]
	horse.posed = false
	var expected_size := Vector2.ZERO
	for reduced: bool in [false, true]:
		tuning.set_value("ui.reduced_motion", reduced)
		for face: float in [-1.0, 1.0]:
			for posture: String in ["graze", "rest", "graze"]:
				horse.position = Vector2(640,470)
				horse.state = posture
				horse._idle_time = 100.0
				horse._velocity = Vector2.ZERO
				horse._gait.weight = 0.0
				horse._gait.face = face
				horse.facing = face
				horse._breath = 0.0
				horse.tick(0.0, Vector2(1280,720))
				var actual: Vector2 = horse._art_bounds.size * horse.scale.abs()
				if expected_size == Vector2.ZERO:
					expected_size = actual
				_check(actual.is_equal_approx(expected_size), "horse rest transition preserves visible size, reduced=%s face=%s posture=%s" % [reduced,face,posture])
				_check(horse.position.is_equal_approx(Vector2(640,470)), "horse rest transition preserves feet position")
	tuning.reset_defaults()
