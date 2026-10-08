extends SceneTree
# REQ-20261008-075: the bottom paper notice used to appear and vanish in one
# frame. It now fades in over 0.2s and fades out over the last 0.35s of its
# remaining time; reduced motion stays fully opaque while shown. Paper colour,
# ink, size, keys, pause hiding and durations are unchanged.

const STEP := 1.0 / 60.0
const FADE := preload("res://scripts/ui/notice_fade.gd")

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)


func _run() -> void:
	_curve()
	await _live()
	_finish()


func _curve() -> void:
	_check(is_equal_approx(FADE.alpha(0.0, 0.0, false), 0.0), "gone when remaining is 0")
	_check(float(FADE.alpha(3.2, 0.0, false)) < 0.05, "tap frame starts transparent")
	_check(is_equal_approx(FADE.alpha(3.0, 0.2, false), 1.0), "full after 0.2s fade in")
	_check(is_equal_approx(FADE.alpha(1.0, 2.2, false), 1.0), "full through the middle of the hold")
	_check(float(FADE.alpha(0.175, 3.0, false)) > 0.4 and float(FADE.alpha(0.175, 3.0, false)) < 0.6, "half way through fade out is half alpha")
	_check(float(FADE.alpha(0.05, 3.15, false)) < 0.2, "nearly clear near the end")
	_check(is_equal_approx(FADE.alpha(3.2, 0.0, true), 1.0), "reduced motion is full on the first frame")
	_check(is_equal_approx(FADE.alpha(0.05, 5.0, true), 1.0), "reduced motion stays full until gone")
	var previous := -1.0
	var rising := true
	for i: int in 11:
		var a := float(FADE.alpha(3.2 - float(i) * 0.02, float(i) * 0.02, false))
		if a + 0.0001 < previous:
			rising = false
		previous = a
	_check(rising, "fade in rises monotonically")
	previous = 2.0
	var falling := true
	for i: int in 8:
		var rem := 0.35 - float(i) * 0.05
		var a := float(FADE.alpha(rem, 5.0, false))
		if a > previous + 0.0001:
			falling = false
		previous = a
	_check(falling, "fade out falls monotonically")


func _live() -> void:
	var tuning := root.get_node("TuningStore")
	for reduced: bool in [false, true]:
		tuning.reset_defaults()
		tuning.set_value("ui.reduced_motion", reduced)
		root.size = Vector2i(1280, 720)
		var main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		await process_frame
		await process_frame
		await main._start_holiday()
		main.set_process(false)
		var tag := " (reduced=%s)" % reduced
		var n: Label = main._notice
		_check(n != null, "main has the bottom notice" + tag)
		main._show_notice_key("notice.fishing.miss")
		_check(main._notice_time > 3.0 and is_zero_approx(main._notice_age), "new notice starts at age 0" + tag)
		_check(n.visible, "notice is visible after show" + tag)
		if reduced:
			_check(is_equal_approx(n.modulate.a, 1.0), "reduced motion: full on the show frame" + tag)
		else:
			_check(n.modulate.a < 0.05, "show frame is nearly transparent" + tag)
		# Advance ~0.2s of owned clock.
		for _i: int in 12:
			main._process(STEP)
		_check(absf(main._notice_age - 12.0 * STEP) < 0.001, "process advances notice age" + tag)
		_check(is_equal_approx(n.modulate.a, 1.0), "fully shown by ~0.2s" + tag)
		# Mid hold still full.
		for _i: int in 30:
			main._process(STEP)
		_check(is_equal_approx(n.modulate.a, 1.0), "stays full mid-hold" + tag)
		# Drive into the fade-out window.
		while main._notice_time > 0.2:
			main._process(STEP)
		if reduced:
			_check(is_equal_approx(n.modulate.a, 1.0), "reduced motion stays full near the end" + tag)
		else:
			_check(n.modulate.a > 0.05 and n.modulate.a < 0.95, "mid fade-out near the end (a=%.2f)" % n.modulate.a + tag)
		while main._notice_time > 0.0:
			main._process(STEP)
		main._process(STEP)
		_check(not n.visible, "notice gone once remaining hits 0" + tag)
		# Pause still hides instantly and preserves remaining (regression).
		main._show_notice_key("notice.first_hint")
		for _i: int in 20:
			main._process(STEP)
		var before: float = main._notice_time
		main._toggle_pause()
		_check(main._pause_screen.visible and not n.visible, "pause hides the notice at once" + tag)
		main._process(1.0)
		_check(is_equal_approx(main._notice_time, before), "pause preserves remaining time" + tag)
		main._toggle_pause()
		_check(n.visible, "resume shows the preserved notice" + tag)
		# Extending remaining (fish catch) keeps a running fade age.
		main._show_notice_key("notice.fishing.miss")
		for _i: int in 30:
			main._process(STEP)
		var age_before: float = main._notice_age
		main._notice_time = maxf(main._notice_time, 6.5)
		main._sync_notice_visibility()
		_check(is_equal_approx(main._notice_age, age_before), "extending remaining does not restart the fade" + tag)
		_check(is_equal_approx(n.modulate.a, 1.0), "extended notice stays fully shown mid-hold" + tag)
		# Paper style still present.
		var style = n.get_theme_stylebox("normal")
		_check(style is StyleBoxFlat, "paper backing unchanged" + tag)
		main.queue_free()
		await process_frame
	tuning.reset_defaults()
	_check(checks >= 30, "suite ran enough checks (%d)" % checks)


func _finish() -> void:
	if root.has_node("AudioDirector"):
		root.get_node("AudioDirector").release_streams()
	if failures.is_empty():
		print("[notice-fade] PASS: %d checks" % checks)
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		print("[notice-fade] FAIL: %d of %d" % [failures.size(), checks])
		quit(1)
