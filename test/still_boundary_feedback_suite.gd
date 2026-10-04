extends SceneTree

## REQ-20261003-024: real unreachable-tap cue. Tick owns remaining time.
## Draw must call BoundaryFeedback.pose. No autoload and no wall clock.

var checks := 0
var failures: Array[String] = []
const _BAD := Vector2(865, 478)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_sources()
	if not failures.is_empty():
		_finish()
		return
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.set_process(false)
	main._start_holiday()
	var world = main._world
	_check_motion_frames(world, false)
	_check_motion_frames(world, true)
	_check_expiry_refresh_cancel(world)
	await _check_album_and_pause(main, world)
	_check_reduced_toggle(world)
	world = _check_rebuild(main)
	_check(world._rejected_seconds == 0.0, "rebuilt yard does not keep the previous cue")
	_reject(world)
	_check(is_equal_approx(world._rejected_seconds, 1.2), "rebuilt yard can show a new unreachable cue")
	_finish()


func _check_sources() -> void:
	_check(not FileAccess.file_exists("res://autoload/still_boundary_hook.gd"), "still boundary hook script is gone")
	_check(not FileAccess.file_exists("res://autoload/still_boundary_hook.gd.uid"), "still boundary hook uid is gone")
	var project := _read("res://project.godot")
	_check(not project.contains("StillBoundaryHook"), "project.godot does not register StillBoundaryHook")
	var yard := _read("res://scripts/game/yard_world.gd")
	_check(not yard.contains("Time.get_ticks_msec"), "yard world does not read the wall clock")
	var draw := _draw_body(yard)
	_check(draw.contains("BoundaryFeedback.pose"), "boundary arc draw calls BoundaryFeedback.pose")
	_check(not draw.contains("_rejected_seconds / 0.35"), "draw does not fade from remaining itself")
	_check(draw.contains("12.0"), "draw keeps the existing arc radius")
	# The hook can be absent and this still fails when draw never calls pose.
	_check(not FileAccess.file_exists("res://autoload/still_boundary_hook.gd") and draw.contains("BoundaryFeedback.pose"), "missing hook is not enough without pose in draw")


func _check_motion_frames(world, reduced: bool) -> void:
	TuningStore.set_value("ui.reduced_motion", reduced, false)
	_reject(world)
	world.queue_redraw()
	var early := float(world._rejected_seconds)
	var early_pose: Dictionary = BoundaryFeedback.pose(early, reduced)
	_check(is_equal_approx(early, 1.2), "trigger starts a 1.2s cue (%s)" % _mode(reduced))
	_check(is_equal_approx(float(early_pose.alpha), 0.80), "early frame stays readable (%s)" % _mode(reduced))
	_check(is_equal_approx(float(early_pose.radius), 12.0), "pose radius stays 12 (%s)" % _mode(reduced))
	world.tick(1.0, Vector2.ZERO)
	var late := float(world._rejected_seconds)
	var late_pose: Dictionary = BoundaryFeedback.pose(late, reduced)
	_check(is_equal_approx(late, 0.2), "one simulation second leaves 0.2 (%s)" % _mode(reduced))
	if reduced:
		_check(is_equal_approx(float(late_pose.alpha), 0.80), "reduced motion late frame does not fade")
	else:
		_check(is_equal_approx(float(late_pose.alpha), minf(1.0, late / 0.35) * 0.80), "ordinary late frame still fades")
		_check(float(late_pose.alpha) < 0.80, "ordinary late alpha is below the held still value")


func _check_expiry_refresh_cancel(world) -> void:
	TuningStore.set_value("ui.reduced_motion", false, false)
	_reject(world)
	var steps := 0
	while world._rejected_seconds > 0.0 and steps < 90:
		world.tick(1.0 / 60.0, Vector2.ZERO)
		steps += 1
	_check(world._rejected_seconds == 0.0 and steps >= 50 and steps <= 90, "cue expires from tick deltas, not a wall clock")
	_check(is_equal_approx(float(BoundaryFeedback.pose(world._rejected_seconds, false).alpha), 0.0), "expired cue has no alpha")
	_reject(world)
	world.tick(0.5, Vector2.ZERO)
	var faded := float(world._rejected_seconds)
	_reject(world)
	_check(faded < 1.2 and is_equal_approx(world._rejected_seconds, 1.2), "repeat invalid click refreshes the cue")
	world.simulation_active = false
	world.tick(5.0, Vector2.ZERO)
	_check(is_equal_approx(world._rejected_seconds, 1.2), "inactive simulation does not spend the cue")
	world.simulation_active = true
	world.tick(1.0 / 60.0, Vector2.RIGHT)
	_check(world._rejected_seconds == 0.0, "movement still cancels the cue immediately")


func _check_album_and_pause(main, world) -> void:
	_reject(world)
	var held := float(world._rejected_seconds)
	var wall := Time.get_ticks_msec()
	main._show_album()
	main.set_process(true)
	for _i in 4:
		await process_frame
	main.set_process(false)
	_check(Time.get_ticks_msec() > wall, "album wait actually advances the wall clock")
	_check(is_equal_approx(world._rejected_seconds, held), "album does not spend the cue on the wall clock")
	main._hide_album()
	world.tick(0.2, Vector2.ZERO)
	_check(is_equal_approx(world._rejected_seconds, held - 0.2), "leaving the album resumes tick-owned time")
	_reject(world)
	held = float(world._rejected_seconds)
	wall = Time.get_ticks_msec()
	main._toggle_pause()
	for _i in 4:
		await process_frame
	_check(Time.get_ticks_msec() > wall, "pause wait actually advances the wall clock")
	_check(is_equal_approx(world._rejected_seconds, held), "pause does not spend the cue on the wall clock")
	main._toggle_pause()
	main.set_process(false)
	world.tick(0.1, Vector2.ZERO)
	_check(is_equal_approx(world._rejected_seconds, held - 0.1), "resume decays only the following tick")


func _check_reduced_toggle(world) -> void:
	TuningStore.set_value("ui.reduced_motion", false, false)
	_reject(world)
	world.tick(1.0, Vector2.ZERO)
	var remaining := float(world._rejected_seconds)
	var ordinary := float(BoundaryFeedback.pose(remaining, false).alpha)
	TuningStore.set_value("ui.reduced_motion", true, false)
	_check(is_equal_approx(world._rejected_seconds, remaining), "toggling reduced motion does not rewrite remaining time")
	var held := float(BoundaryFeedback.pose(world._rejected_seconds, true).alpha)
	_check(is_equal_approx(held, 0.80) and held > ordinary, "the same remaining time holds alpha when reduced motion turns on")
	world.queue_redraw()


func _check_rebuild(main):
	var previous = main._world.get_instance_id()
	main._start_holiday()
	var world = main._world
	_check(world.get_instance_id() != previous, "holiday rebuild replaces the yard")
	return world


func _reject(world) -> void:
	world.input_enabled = true
	world.request_pointer_action(_BAD)
	_check(world._rejected_seconds > 0.0, "unreachable tap arms boundary feedback")


func _draw_body(source: String) -> String:
	var start := source.find("func _draw()")
	var finish := source.find("func _draw_contact_shadow")
	if start < 0 or finish <= start:
		return ""
	return source.substr(start, finish - start)


func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _mode(reduced: bool) -> String:
	return "reduced" if reduced else "ordinary"


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("STILL BOUNDARY FEEDBACK PASS ", checks)
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	print("STILL BOUNDARY FEEDBACK FAIL ", failures.size())
	quit(1)
