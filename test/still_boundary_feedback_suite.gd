extends SceneTree
# REQ-20261003-024: reduced motion holds unreachable-tap boundary feedback still and readable.

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var still_early: Dictionary = BoundaryFeedback.pose(1.2, true)
	var still_late: Dictionary = BoundaryFeedback.pose(0.12, true)
	var live_early: Dictionary = BoundaryFeedback.pose(1.2, false)
	var live_late: Dictionary = BoundaryFeedback.pose(0.12, false)
	_check(is_equal_approx(float(still_early.alpha), 0.80), "reduced motion holds the rejection mark at a fixed readable alpha")
	_check(is_equal_approx(float(still_early.alpha), float(still_late.alpha)), "reduced motion keeps the rejection mark from fading mid-cue")
	_check(is_equal_approx(float(still_early.radius), 12.0) and is_equal_approx(float(still_late.radius), 12.0), "reduced motion keeps the rejection mark radius fixed")
	_check(is_equal_approx(float(live_early.alpha), 0.80), "ordinary rejection mark stays bright for most of the cue")
	_check(float(live_early.alpha) > float(live_late.alpha), "ordinary rejection mark still fades near the end")
	_check(is_equal_approx(float(live_late.alpha), minf(1.0, 0.12 / 0.35) * 0.80), "ordinary late fade matches the original 0.35s ramp")
	if failures.is_empty():
		print("STILL BOUNDARY FEEDBACK PASS ", checks)
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
