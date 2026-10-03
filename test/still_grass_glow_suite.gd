extends SceneTree
# REQ-20261003-020: the grass pile stays a steady brightness when motion is reduced.

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
		world.debug_place_actor(actor_id, Vector2(1100, 520))
	world.debug_place_player(world._grass_point())
	world._has_walk_goal = false
	world._pending_interaction = ""
	tuning.set_value("ui.reduced_motion", true, false)
	var near_a := _sample(world, 0.1)
	var near_b := _sample(world, PI / (2.0 * 3.4))
	_check(near_a.is_equal_approx(near_b), "reduced motion keeps the nearby grass pile from pulsing")
	_check(near_a.r > 1.02 and near_a.r < 1.12, "nearby grass stays slightly bright so it can still be found")
	world.debug_place_player(Vector2(20, 20))
	var far_a := _sample(world, 0.2)
	var far_b := _sample(world, PI / (2.0 * 0.9))
	_check(far_a.is_equal_approx(far_b) and far_a.is_equal_approx(Color.WHITE), "reduced motion holds distant grass at a plain white")
	tuning.set_value("ui.reduced_motion", false, false)
	world.debug_place_player(world._grass_point())
	var live_low := _sample(world, 0.0)
	var live_high := _sample(world, PI / (2.0 * 3.4))
	_check(live_high.r > live_low.r + 0.1, "ordinary grass brightness still breathes")
	world.free()
	if failures.is_empty():
		print("STILL GRASS GLOW PASS ", checks)
		quit(0)
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _sample(world, day_seconds: float) -> Color:
	world._day_seconds = day_seconds
	world.tick(0.0, Vector2.ZERO)
	return world._grass_patch.modulate


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
