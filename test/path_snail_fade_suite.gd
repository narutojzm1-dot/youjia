extends SceneTree
# REQ-20261008-072: the path snail and clover ease in and fade out at the end
# of the hold instead of popping on and off; walking off still clears them at
# once, and low motion keeps the instant show / hide.

const STEP := 1.0 / 60.0

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var tuning := root.get_node("TuningStore")
	for reduced: bool in [false, true]:
		tuning.reset_defaults()
		tuning.set_value("ui.reduced_motion", reduced)
		var world = load("res://scripts/game/yard_world.gd").new()
		root.add_child(world)
		world.setup()
		_run_world(world, reduced)
		world.free()
	tuning.reset_defaults()
	# A script error inside _run_world aborts it silently; never call that a pass.
	_check(checks >= 40, "suite ran all its checks (%d)" % checks)
	if failures.is_empty():
		print("PATH SNAIL FADE PASS ", checks)
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _stand(world) -> void:
	world.debug_place_player(world._scene_feedback.PATH_POINT)
	world._has_walk_goal = false
	world._pending_interaction = ""


func _tick_still(world, seconds: float) -> void:
	var frames := roundi(seconds / STEP)
	for _i: int in frames:
		world.tick(STEP, Vector2.ZERO)


## Stand until the pair has just appeared; returns false if it never did.
func _wait_for_show(world) -> bool:
	for _i: int in 600:
		world.tick(STEP, Vector2.ZERO)
		if world._scene_feedback._path_duration > 0.0:
			return true
	return false


func _run_world(world, reduced: bool) -> void:
	var tag := " (reduced=%s)" % reduced
	var fb = world._scene_feedback
	var snail: Sprite2D = fb.get_node("PathSnail")
	var clover: Sprite2D = fb.get_node("PathClover")
	_check(fb.has_method("path_alpha"), "YardSceneFeedback exposes path_alpha()" + tag)
	if not fb.has_method("path_alpha"):
		return
	_check(fb.path_alpha() == 0.0 and not snail.is_visible_in_tree(), "pair hidden before anything happens" + tag)
	_stand(world)
	_check(_wait_for_show(world), "standing still on the south path still shows the pair" + tag)
	_check(snail.visible and clover.visible and fb.visible, "both paintings visible once the encounter starts" + tag)
	_check(is_equal_approx(snail.modulate.a, clover.modulate.a), "snail and clover share one opacity" + tag)
	if reduced:
		_check(snail.modulate.a == 1.0, "low motion shows the pair at full strength on the first frame" + tag)
	else:
		_check(snail.modulate.a < 0.2, "first frame is nearly transparent, not a pop (a=%.3f)" % snail.modulate.a + tag)
		var last := snail.modulate.a
		var rising := true
		for _i: int in 17:
			world.tick(STEP, Vector2.ZERO)
			if snail.modulate.a + 0.0001 < last:
				rising = false
			last = snail.modulate.a
		_check(rising, "opacity rises monotonically during the fade-in" + tag)
		_check(last > 0.9 and last <= 1.0, "pair reaches full strength within 0.3s (a=%.3f)" % last + tag)
	# Hold: full strength in the middle of the 3.2s hold.
	_tick_still(world, 1.2)
	_check(snail.modulate.a == 1.0 and clover.modulate.a == 1.0, "pair is fully opaque mid-hold" + tag)
	_check(is_equal_approx(fb._path_duration, fb.PATH_HOLD_SECONDS), "hold length unchanged at 3.2s" + tag)
	# Natural end: fades out in the last 0.35s, then is gone.
	var remaining: float = fb._path_duration - fb._path_elapsed
	_tick_still(world, remaining - 0.2)
	if reduced:
		_check(snail.modulate.a == 1.0, "low motion keeps full strength right up to the end" + tag)
	else:
		_check(snail.modulate.a > 0.05 and snail.modulate.a < 0.95, "pair is mid fade-out near the end of the hold (a=%.3f)" % snail.modulate.a + tag)
	_tick_still(world, 0.4)
	_check(fb._path_duration <= 0.0 and not snail.visible and not clover.visible, "pair is gone once the hold ends" + tag)
	_check(fb.path_alpha() == 0.0, "no leftover alpha after the hold" + tag)
	_check(is_equal_approx(fb._path_wait, fb.PATH_GAP_SECONDS) or fb._path_wait > fb.PATH_GAP_SECONDS - 0.5, "14s gap still starts after a full hold" + tag)
	# Walking off mid-hold still ends and hides the pair at once (unchanged).
	fb._path_wait = 0.0
	_stand(world)
	_check(_wait_for_show(world), "pair shows again after the gap" + tag)
	_tick_still(world, 0.8)
	var album = world.collected.duplicate()
	world.tick(0.05, Vector2(1, 0))
	_check(fb._path_duration <= 0.0 and not snail.is_visible_in_tree() and not clover.is_visible_in_tree(), "walking clears the pair at once" + tag)
	_check(world.collected == album, "the path pair still does not write the album" + tag)
	# A pair that comes back starts from transparent again.
	_stand(world)
	fb._path_wait = 0.0
	_check(_wait_for_show(world), "pair shows a third time" + tag)
	_check(snail.modulate.a == (1.0 if reduced else 0.0) or (not reduced and snail.modulate.a < 0.2), "a returning pair restarts its fade-in" + tag)
	# cancel() mid-hold clears everything at once.
	_tick_still(world, 0.5)
	fb.cancel()
	_check(not snail.visible and not clover.visible and fb.path_alpha() == 0.0, "cancel clears the pair at once" + tag)
	# Positions are unchanged.
	_check(snail.position.is_equal_approx(fb.PATH_POINT + Vector2(-16, -8)), "snail position unchanged" + tag)
	_check(clover.position.is_equal_approx(fb.PATH_POINT + Vector2(22, -4)), "clover position unchanged" + tag)
	_check(is_equal_approx(snail.scale.x, 0.72) and is_equal_approx(clover.scale.x, 0.34), "painting scales unchanged" + tag)


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
