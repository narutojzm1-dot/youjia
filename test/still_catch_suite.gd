extends SceneTree
# REQ-20261003-018: reduced motion holds the target glow and catch rings still.

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var overlay = load("res://scripts/game/world_effects_overlay.gd")
	var still_target: Dictionary = overlay.celebration_pose("target", 1.2, true)
	var live_target_a: Dictionary = overlay.celebration_pose("target", 0.2, false)
	var live_target_b: Dictionary = overlay.celebration_pose("target", 1.1, false)
	_check(is_equal_approx(float(still_target.glow_radius), 18.0), "reduced motion holds the target glow at a fixed radius")
	_check(not is_equal_approx(float(live_target_a.glow_radius), float(live_target_b.glow_radius)), "ordinary target glow still breathes")
	var still_catch: Dictionary = overlay.celebration_pose("catch", 0.1, true)
	var still_later: Dictionary = overlay.celebration_pose("catch", 0.8, true)
	var live_early: Dictionary = overlay.celebration_pose("catch", 0.1, false)
	var live_late: Dictionary = overlay.celebration_pose("catch", 0.9, false)
	_check(is_equal_approx(float(still_catch.outer_radius), float(still_later.outer_radius)), "reduced motion keeps the catch ring from traveling")
	_check(int(still_catch.particle_count) == 0 and bool(still_catch.show_banner), "reduced motion drops specks but keeps the caught mark")
	_check(float(live_late.outer_radius) > float(live_early.outer_radius), "ordinary catch ring still expands")
	_check(int(live_early.particle_count) == 12 and int(live_late.particle_count) == 0, "ordinary specks only fly during the opening of the catch")
	if failures.is_empty():
		print("STILL CATCH PASS ", checks)
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
