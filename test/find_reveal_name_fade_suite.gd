extends SceneTree

## REQ-20261008-073: during the find reveal on the near path, the name slip used
## to appear in one frame at half opacity the moment the halo passed 0.5 while
## rising, and to vanish in one frame from half opacity as the find flew into
## the basket. The slip and its text now fade from clear at halo 0.5 to full at
## halo 1.0, and back to clear on the way to the basket.
## Unchanged: when the name is drawn (halo > 0.5), full opacity during the hold,
## reduced motion (halo stays 1, the whole reveal fades via modulate), the
## reveal's path, timing and the settle signal.
##
## On unmodified main FindReveal has no name_fade(), so the suite fails.

const PaperTooltipStyle := preload("res://scripts/ui/paper_tooltip_style.gd")
const FRAME := 1.0 / 60.0
const MAX_STEP := 0.25

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


func run() -> void:
	var probe := FindReveal.new()
	var has_api := probe.has_method("name_fade")
	check(has_api, "the reveal exposes the name fade")
	probe.free()
	if not has_api:
		finish()
		return
	_curve()
	_normal_frames()
	_reduced_frames()
	await _drawn_alpha()
	finish()


func _curve() -> void:
	check(is_equal_approx(FindReveal.name_fade(0.0), 0.0) and is_equal_approx(FindReveal.name_fade(0.5), 0.0), "the name is clear up to halo 0.5")
	check(is_equal_approx(FindReveal.name_fade(0.75), 0.5), "the name is half shown at halo 0.75")
	check(is_equal_approx(FindReveal.name_fade(1.0), 1.0) and is_equal_approx(FindReveal.name_fade(1.4), 1.0), "the name is fully shown at halo 1")
	var last := -1.0
	var rising := true
	for i in 101:
		var f := FindReveal.name_fade(i / 100.0)
		rising = rising and f >= last
		last = f
	check(rising, "the fade never drops while the halo grows")


func _play(reveal: FindReveal, reduced: bool) -> void:
	reveal.title = "x"
	reveal.find_id = "feather"
	reveal.calm = reduced
	reveal.elapsed = 0.0
	reveal.from = Vector2(200, 400)
	reveal.top = Vector2(200, 260)
	reveal.basket = Vector2(40, 40)
	reveal.from_size = 1.0


func _normal_frames() -> void:
	var reveal := FindReveal.new()
	_play(reveal, false)
	var total := reveal.total()
	check(is_equal_approx(total, FindReveal.RISE + FindReveal.HOLD + FindReveal.FLY) and is_equal_approx(total, 1.65), "normal reveal timing unchanged (1.65s)")
	var alphas: Array[float] = []
	var hold_full := true
	var hold_frames := 0
	var t := 0.0
	while t < total:
		reveal.elapsed = t
		var pose := reveal.pose()
		var halo := float(pose.halo)
		var a := FindReveal.name_fade(halo) if halo > 0.5 else 0.0
		alphas.append(a)
		if t >= FindReveal.RISE and t < FindReveal.RISE + FindReveal.HOLD:
			hold_frames += 1
			hold_full = hold_full and is_equal_approx(a, 1.0)
		t += FRAME
	var first := -1
	var last := -1
	for i in alphas.size():
		if alphas[i] > 0.0:
			if first < 0:
				first = i
			last = i
	check(first > 0 and last > first, "the name shows during the reveal")
	if first > 0:
		check(alphas[first] <= MAX_STEP, "the name first appears nearly clear, not at half opacity (%.2f)" % alphas[first])
		check(alphas[last] <= MAX_STEP, "the name is nearly clear on its last frame, not cut at half opacity (%.2f)" % alphas[last])
	var worst := 0.0
	for i in range(1, alphas.size()):
		worst = maxf(worst, absf(alphas[i] - alphas[i - 1]))
	check(worst <= MAX_STEP, "at 60fps the name never jumps more than %.2f opacity in one frame (%.2f)" % [MAX_STEP, worst])
	check(hold_frames > 40 and hold_full, "the name stays fully shown through the hold")
	var peak_up := 0
	for i in range(1, alphas.size()):
		if alphas[i] < alphas[i - 1] - 0.0001 and alphas[i - 1] < 1.0 and i < first + 20:
			peak_up += 1
	check(peak_up == 0, "the name only grows while rising")
	reveal.free()


func _reduced_frames() -> void:
	var reveal := FindReveal.new()
	_play(reveal, true)
	check(is_equal_approx(reveal.total(), FindReveal.CALM_IN + FindReveal.CALM_HOLD + FindReveal.CALM_OUT), "reduced reveal timing unchanged")
	var full := true
	var t := 0.0
	while t < reveal.total():
		reveal.elapsed = t
		var pose := reveal.pose()
		full = full and float(pose.halo) > 0.5 and is_equal_approx(FindReveal.name_fade(float(pose.halo)), 1.0) and pose.at == reveal.top
		t += FRAME
	check(full, "reduced motion keeps the name at full slip opacity in place (the reveal itself fades)")
	reveal.free()


func _drawn_alpha() -> void:
	var paper: StyleBoxFlat = PaperTooltipStyle.panel()
	var reveal := FindReveal.new()
	reveal.label_font = load("res://assets/template/fonts/ui_regular.tres") as Font
	root.add_child(reveal)
	await process_frame
	reveal.set_process(false)
	_play(reveal, false)
	reveal.visible = true
	var settled: Array[String] = []
	reveal.settled.connect(func(id: String) -> void: settled.append(id))
	var samples := 0
	var matched := 0
	for t: float in [0.05, 0.12, 0.2, 0.3, 0.6, 1.0, 1.3, 1.4, 1.5, 1.6]:
		reveal.elapsed = t
		var halo := float(reveal.pose().halo)
		if halo <= 0.5:
			continue
		reveal.queue_redraw()
		await process_frame
		samples += 1
		var want := FindReveal.name_fade(halo)
		var slip: StyleBoxFlat = reveal._name_slip
		if slip != null and is_equal_approx(slip.bg_color.a, paper.bg_color.a * want) and is_equal_approx(slip.border_color.a, paper.border_color.a * want) and is_equal_approx(slip.shadow_color.a, paper.shadow_color.a * want):
			matched += 1
	check(samples >= 5, "several reveal frames draw the name (%d)" % samples)
	check(matched == samples, "the drawn slip uses the name fade, not the raw halo (%d/%d)" % [matched, samples])
	reveal.set_process(true)
	reveal.elapsed = reveal.total() - 0.001
	await process_frame
	await process_frame
	check(settled == ["feather"] and not reveal.is_active() and not reveal.visible, "the reveal still settles once into the basket")
	reveal.queue_free()
	await process_frame


func finish() -> void:
	if root.has_node("AudioDirector"):
		root.get_node("AudioDirector").release_streams()
	if failures.is_empty():
		print("PASS find_reveal_name_fade_suite: %d checks" % checks)
		quit(0)
	else:
		print("FAIL find_reveal_name_fade_suite: %d/%d failed" % [failures.size(), checks])
		for failure in failures.slice(0, 20):
			print("  - " + failure)
		quit(1)
