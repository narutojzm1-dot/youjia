extends SceneTree

# Deterministic integration fixture, not a natural-user or screenshot reproducer.
# Drives the real Main._process -> YardWorld.tick -> camera signal consumers.
# Known production before-fix expectation: short goose prewarm interruption may
# leave the preceding quiet-sky target behind. A nonzero result must stay FAIL.
const STEP := 1.0 / 60.0
const EVENT := "goose_horse_mount"
var checks := 0
var failures: Array[String] = []
var main: Control
var store: Node
var tuning: Node
var events: Array[Dictionary] = []
var case_name := ""


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		var message := case_name + ": " + label
		failures.append(message)
		push_error(message)


func isolated_data() -> bool:
	var data := OS.get_environment("XDG_DATA_HOME")
	return not data.is_empty() and OS.get_environment("YOUJIA_TEST_ISOLATED_DATA") == data


func point(value: Vector2) -> Array:
	return [value.x, value.y]


func record_focus(at: Vector2, zoom: float) -> void:
	events.append({"kind": "focus", "point": point(at), "zoom": zoom})


func record_release() -> void:
	events.append({"kind": "release"})


func trace(w, stage: String) -> void:
	print("CAMERA400_TRACE ", JSON.stringify({
		"case": case_name, "stage": stage, "phase": w._goose_mount_phase,
		"wait": w._goose_mount_wait, "quiet_active": w._quiet_sky_active,
		"focus_seconds": w._focus_seconds, "quiet_cooldown": w._quiet_sky_cooldown,
		"target_zoom": main._cam_target_zoom, "target_offset": point(main._cam_target_offset),
		"interpolated_offset": point(main._cam_offset), "camera_position": point(main._camera.position),
		"player": point(w.get_player().position), "events": events.duplicate(true)
	}))


func tick(moving := false) -> void:
	if moving:
		Input.action_press("move_right")
	else:
		Input.action_release("move_right")
	main._process(STEP)
	Input.action_release("move_right")


func advance(seconds: float, moving := false) -> void:
	for _i in ceili(seconds / STEP):
		tick(moving)


func fresh(reduced: bool):
	Input.action_release("move_right")
	store._data = store._default_data()
	await main._start_holiday(false)
	tuning.set_value("ui.reduced_motion", reduced)
	var w = main._world
	w._day_elapsed = 0.0
	w._weather_timer = 10000.0
	w._pulse = -10000.0
	w.debug_place_actor("horse", Vector2(620, 480))
	w.debug_place_actor("goose", Vector2(745, 505))
	w.debug_place_player(Vector2(695, 510))
	for actor_id in w._actors:
		var actor = w.actor_named(actor_id)
		actor.state = "graze"
		actor._idle_time = 10000.0
		actor._velocity = Vector2.ZERO
	events.clear()
	w.camera_focus_requested.connect(record_focus)
	w.camera_release_requested.connect(record_release)
	check(main._cam_target_offset.is_zero_approx() and main._cam_offset.is_zero_approx(), "fresh camera starts without offset")
	check(EVENT not in w.collected, "event has not been collected in this isolated fixture")
	return w


func start_quiet(w, seconds := 6.25) -> Vector2:
	# Day-zero grace prevents the eligible, still actors from taking over first.
	advance(seconds)
	check(w._quiet_sky_active and w._focus_seconds > 0.0, "quiet look really starts through World.tick")
	check(events.size() == 1 and events[0]["kind"] == "focus", "quiet emits exactly one initial focus")
	check(main._cam_target_zoom == 1.0 and not main._cam_target_offset.is_zero_approx(), "normal camera scale can still have a focus offset")
	check(main._cam_offset.length() > 1.0, "Main camera interpolation actually consumes quiet focus")
	trace(w, "quiet_holds_camera")
	return main._cam_target_offset


func start_prewarm(w) -> void:
	# Explicit fixture clock change, not a normal-play claim.
	var old_target: Vector2 = main._cam_target_offset
	w._day_elapsed = 46.0
	tick()
	check(w._goose_mount_phase == -1 and w._goose_mount_wait > 0.0 and w._goose_mount_wait < 3.5, "one genuine tick reaches prewarm without starting the encounter")
	check(events.size() >= 1, "initial focus remains in the event trace")
	check(w._quiet_sky_active and w._focus_seconds > 0.0, "prewarm alone preserves the active sky focus and its remaining hold")
	check(main._cam_target_offset.is_equal_approx(old_target) and events.back()["kind"] == "focus", "prewarm alone does not snap the camera back or invent a takeover")
	trace(w, "partial_prewarm")


func assert_recovered(w, stage: String) -> void:
	check(w._goose_mount_phase == -1 and is_zero_approx(w._goose_mount_wait), "interruption clears the prewarm or active encounter")
	check(main._cam_target_offset.is_zero_approx(), "interruption releases the previous focus target")
	check(events.any(func(event: Dictionary) -> bool: return event["kind"] == "release"), "camera consumer receives a release event")
	trace(w, stage)
	# More than the old four-second hold: distinguishes an orphan from a tween.
	advance(4.2, true)
	check(main._cam_target_offset.is_zero_approx() and main._cam_offset.length() < 0.01, "continued movement settles the real interpolated offset to zero")
	check(EVENT not in w.collected, "interruption does not invent an encounter photo")
	trace(w, stage + "_after_old_hold")


func run() -> void:
	if not isolated_data():
		push_error("camera400 requires a dedicated XDG_DATA_HOME and matching YOUJIA_TEST_ISOLATED_DATA")
		quit(2)
		return
	seed(14003)
	root.size = Vector2i(1280, 720)
	store = root.get_node("SaveStore")
	tuning = root.get_node("TuningStore")
	tuning.reset_defaults()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	for reduced: bool in [false, true]:
		case_name = "quiet_only_move/reduced=%s" % reduced
		var w = await fresh(reduced)
		start_quiet(w)
		tick(true)
		assert_recovered(w, "quiet_move")

		case_name = "prewarm_then_move/reduced=%s" % reduced
		w = await fresh(reduced)
		start_quiet(w)
		start_prewarm(w)
		tick(true)
		assert_recovered(w, "prewarm_move")

		case_name = "prewarm_loses_actor_proximity/reduced=%s" % reduced
		w = await fresh(reduced)
		var sky_target := start_quiet(w)
		start_prewarm(w)
		# Explicit controlled actor relocation isolates eligibility cancellation.
		w.debug_place_actor("goose", Vector2(1100, 520))
		tick()
		check(w._goose_mount_phase == -1 and is_zero_approx(w._goose_mount_wait), "lost proximity cancels only the candidate prewarm")
		check(w._quiet_sky_active and w._focus_seconds > 0.0 and main._cam_target_offset.is_equal_approx(sky_target), "lost proximity leaves the existing quiet hold intact without an extra snap")
		trace(w, "prewarm_proximity_lost")
		advance(4.2)
		check(not w._quiet_sky_active and main._cam_target_offset.is_zero_approx(), "quiet hold still expires naturally after prewarm loses eligibility")
		check(events.back()["kind"] == "release", "natural expiry reaches the real Main release consumer")
		advance(3.0, true)
		check(main._cam_offset.length() < 0.01, "camera finishes returning after natural expiry")
		check(EVENT not in w.collected, "aborted prewarm creates no photo")
		trace(w, "proximity_lost_after_old_hold")

		case_name = "old_hold_expires_during_prewarm/reduced=%s" % reduced
		w = await fresh(reduced)
		start_quiet(w)
		advance(2.9)
		check(w._quiet_sky_active and w._focus_seconds > 0.0 and w._focus_seconds < 0.5, "controlled old sky hold is close to natural expiry")
		start_prewarm(w)
		advance(0.6)
		check(w._goose_mount_phase == -1 and w._goose_mount_wait < 3.5, "old hold expires before the encounter owns the camera")
		check(not w._quiet_sky_active and w._focus_seconds <= 0.0, "old sky hold can finish naturally during prewarm")
		check(main._cam_target_offset.is_zero_approx() and events.back()["kind"] == "release", "natural expiry releases the old sky target during prewarm")
		trace(w, "old_hold_expiry")
		tick(true)
		assert_recovered(w, "expired_prewarm_move")

		case_name = "actual_takeover_then_move/reduced=%s" % reduced
		w = await fresh(reduced)
		var old_target := start_quiet(w)
		start_prewarm(w)
		advance(3.5)
		check(w._goose_mount_phase == 0, "full prewarm reaches real wide-shot takeover")
		check(not w._quiet_sky_active, "quiet no longer owns the camera after actual takeover")
		check(events.size() >= 2 and events.back()["kind"] == "focus", "new encounter focus is not overwritten by a same-tick quiet release")
		check(not main._cam_target_offset.is_zero_approx() and not main._cam_target_offset.is_equal_approx(old_target), "Main retains the actual encounter focus rather than the old sky offset")
		trace(w, "actual_takeover")
		tick(true)
		assert_recovered(w, "actual_takeover_move")

		case_name = "live_quiet_same_tick_takeover/reduced=%s" % reduced
		w = await fresh(reduced)
		old_target = start_quiet(w, 5.6)
		start_prewarm(w)
		# Stop one real tick before crossing the encounter's 3.5s boundary.
		# The early quiet start leaves its four-second hold alive at takeover.
		for _i in 240:
			if w._goose_mount_wait + STEP >= 3.5 or w._goose_mount_phase >= 0:
				break
			tick()
		check(w._goose_mount_phase == -1, "pre-takeover sample is still prewarm")
		check(w._quiet_sky_active and w._focus_seconds > 0.0, "quiet really still owns a live hold immediately before actual takeover")
		trace(w, "live_quiet_before_takeover")
		var event_count := events.size()
		tick()
		check(w._goose_mount_phase == 0, "next real tick starts the actual encounter")
		check(not w._quiet_sky_active and is_zero_approx(w._focus_seconds), "actual takeover clears the former quiet ownership")
		check(events.size() == event_count + 1 and events.back()["kind"] == "focus", "same tick emits only the new focus with no quiet release before or after it")
		check(not main._cam_target_offset.is_zero_approx() and not main._cam_target_offset.is_equal_approx(old_target), "Main consumes and retains the new focus on the takeover tick")
		trace(w, "live_quiet_actual_takeover")
		tick(true)
		assert_recovered(w, "live_quiet_takeover_move")
	Input.action_release("move_right")
	tuning.reset_defaults()
	root.get_node("AudioDirector").release_streams()
	print("[camera400-handoff] ", "PASS" if failures.is_empty() else "FAIL", ": ", checks, " checks ", JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
