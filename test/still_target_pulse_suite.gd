extends SceneTree
# REQ-20261003-019: reduced motion holds the target brightness/alpha pulse still.

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var overlay = load("res://scripts/game/world_effects_overlay.gd")
	var still_a: Dictionary = overlay.celebration_pose("target", 0.2, true)
	var still_b: Dictionary = overlay.celebration_pose("target", 1.1, true)
	var live_a: Dictionary = overlay.celebration_pose("target", 0.2, false)
	var live_b: Dictionary = overlay.celebration_pose("target", 1.1, false)
	_check(is_equal_approx(float(still_a.alpha_pulse), 1.0), "reduced motion holds target brightness at a fixed readable pulse")
	_check(is_equal_approx(float(still_a.alpha_pulse), float(still_b.alpha_pulse)), "reduced motion keeps target brightness from drifting over time")
	_check(is_equal_approx(float(still_a.glow_radius), 18.0), "reduced motion still keeps the target glow radius fixed")
	_check(not is_equal_approx(float(live_a.alpha_pulse), float(live_b.alpha_pulse)), "ordinary target brightness still pulses")
	_check(float(live_a.alpha_pulse) >= 0.75 and float(live_a.alpha_pulse) <= 1.0, "ordinary target pulse stays in the original 0.75–1.0 band")
	if failures.is_empty():
		print("STILL TARGET PULSE PASS ", checks)
		quit(0)
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
