extends SceneTree

## REQ-20261006-045: when every line of the HUD goal text (split at the copy's
## own line breaks) fits inside the maximum width, the goal paper (目标纸片)
## hugs the widest line instead of always stretching to the maximum (up to
## 520px). On 844x390 the default windowbox hint used to fill only the left half
## of the paper, leaving ~250px of empty paper over the mountains; on 640x360 the
## two short compact lines sat on a 478px paper. Text that needs automatic
## wrapping keeps the original maximum width, the left edge never moves, the
## paper is never narrower than 120px, the number of lines never changes, and
## nothing is re-shaped every frame unless the text, available width, font size
## or visibility changed.

const VIEWPORTS := [Vector2i(844, 390), Vector2i(915, 412), Vector2i(640, 360), Vector2i(568, 320), Vector2i(1280, 720), Vector2i(1024, 600), Vector2i(700, 400), Vector2i(390, 844), Vector2i(360, 640), Vector2i(412, 915)]
const TARGETS := ["llama", "cow", "horse", "sheep_a", "sheep_b", "goose", "duck_a", "grass", "plant", "fishing", "windowbox", "shore_stones", "fence_gate", "path_out"]
const ACTIONS := ["fish", "fish_waiting", "reel", "pet", "observe_windowbox", "touch_shore", "observe_fence", "open_gate", "close_gate", "plant", "water", "harvest", "toss_fish", "release", "feed", "grass", "lead", "go_out"]
const CONTEXTS := ["hud.hint.default", "hud.hint.leading", "hud.hint.carrying", "hud.hint.near_grass", "hud.hint.near_llama", "hud.hint.near_pond", "hud.hint.fishing", "hud.hint.fish_bite", "hud.hint.plant_empty", "hud.hint.plant_water", "hud.hint.plant_bloomed", "hud.hint.near_animal", "hud.hint.carrying_fish"]
const MIN_WIDTH := 120.0
const PAPER_PAD := 18.0

var checks := 0
var failures: Array[String] = []
var main
var i18n
var probe: Label


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	i18n = root.get_node("/root/I18n")
	var original_locale: String = i18n.get_locale()
	for dims in VIEWPORTS:
		await _spawn(dims)
		for locale in ["zh-CN", "en"]:
			i18n.set_locale(locale)
			await _settle()
			_check_matrix(dims, locale)
		i18n.set_locale(original_locale)
		await _despawn()
	await _check_real_hud()
	await _check_short_then_long()
	await _check_hidden_hud()
	await _check_resize()
	i18n.set_locale(original_locale)
	_finish()


func _spawn(dims: Vector2i) -> void:
	root.size = dims
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _settle()
	main.set_process(false)
	await main._start_holiday()
	await _settle()
	probe = Label.new()
	probe.add_theme_font_size_override("font_size", main._hint_label.get_theme_font_size("font_size"))
	probe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	probe.modulate.a = 0.0
	probe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main._hud.add_child(probe)


func _despawn() -> void:
	main.queue_free()
	await process_frame


func _settle() -> void:
	for i in 4:
		await process_frame


func _max_width() -> float:
	return minf(520.0, maxf(120.0, main.size.x - main._pause_button.size.x - 60.0))


func _lines_at(text: String, width: float) -> int:
	probe.text = text
	probe.size = Vector2(width, 32)
	return maxi(1, probe.get_line_count())


func _text_width(text: String) -> float:
	var label: Label = main._hint_label
	var widest := 0.0
	for segment: String in text.split("\n"):
		widest = maxf(widest, label.get_theme_font("font").get_string_size(segment, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x)
	return widest


func _texts(compact: bool) -> Array[String]:
	var out: Array[String] = []
	var suffix := ".compact" if compact else ""
	for t in TARGETS:
		for a in ACTIONS:
			for key in ["hud.hint.marked_target", "hud.hint.action_target"]:
				out.append(i18n.t(key + suffix, {"target": i18n.t("target." + t), "action": i18n.t("action." + a)}))
	for c in CONTEXTS:
		out.append(i18n.t(c))
	return out


## One layout of the current hint, checked against the rules above.
func _measure(tag: String) -> Dictionary:
	var label: Label = main._hint_label
	var paper: Panel = main._hint_panel
	var text := label.text
	var max_w := _max_width()
	var tw := _text_width(text)
	var wraps := ceilf(tw) + 2.0 > max_w
	var lines_at_max := _lines_at(text, max_w)
	var problems: Array[String] = []
	if not label.position.is_equal_approx(Vector2(20, 16)):
		problems.append("text moved to %s" % label.position)
	if not paper.position.is_equal_approx(Vector2(11, 9)):
		problems.append("paper moved to %s" % paper.position)
	if absf(paper.size.x - (label.size.x + PAPER_PAD)) > 0.5:
		problems.append("paper %.0f not text box + 18 (%.0f)" % [paper.size.x, label.size.x])
	if label.size.x > max_w + 0.5:
		problems.append("text box %.0f wider than max %.0f" % [label.size.x, max_w])
	if label.size.x < minf(MIN_WIDTH, max_w) - 0.5:
		problems.append("text box %.0f below the 120px floor" % label.size.x)
	if label.get_line_count() != lines_at_max:
		problems.append("%d lines, max width gives %d" % [label.get_line_count(), lines_at_max])
	if wraps:
		if absf(label.size.x - max_w) > 0.5:
			problems.append("auto-wrapping text narrowed to %.0f (max %.0f)" % [label.size.x, max_w])
	else:
		var want := clampf(ceilf(tw) + 2.0, minf(MIN_WIDTH, max_w), max_w)
		if absf(label.size.x - want) > 0.5:
			problems.append("text box %.0f, widest line needs %.0f" % [label.size.x, want])
		var right_gap: float = paper.position.x + paper.size.x - (label.position.x + tw)
		if tw + 2.0 >= MIN_WIDTH and (right_gap < 8.0 or right_gap > 13.0):
			problems.append("right paper margin %.1f (left is 9)" % right_gap)
	if label.get_visible_line_count() < label.get_line_count():
		problems.append("only %d/%d lines visible" % [label.get_visible_line_count(), label.get_line_count()])
	var paper_rect: Rect2 = paper.get_global_rect()
	if not paper_rect.grow(0.5).encloses(label.get_global_rect()):
		problems.append("text spills off paper")
	if not Rect2(Vector2.ZERO, main.size).encloses(paper_rect):
		problems.append("paper leaves the screen")
	for other in [main._pause_button, main._day_label]:
		if paper_rect.intersects(other.get_global_rect()):
			problems.append("paper overlaps %s" % other.name)
	return {"ok": problems.is_empty(), "why": ", ".join(problems), "wraps": wraps}


func _check_matrix(dims: Vector2i, locale: String) -> void:
	var compact: bool = main.size.x < 700.0
	var seen := {}
	var one_line := 0
	for text in _texts(compact):
		if seen.has(text):
			continue
		seen[text] = true
		main._hint_label.text = text
		main._layout()
		var m := _measure("%s %s" % [dims, locale])
		if not m.wraps:
			one_line += 1  # hugged (no automatic wrapping)
		_check(m.ok, "%s %s「%s」: %s" % [dims, locale, text, m.why])
	print("%s %s: %d strings, %d hug their widest line" % [dims, locale, seen.size(), one_line])


## The real per-frame HUD path, including the default first-arrival hint.
func _check_real_hud() -> void:
	await _spawn(Vector2i(844, 390))
	i18n.set_locale("zh-CN")
	main._refresh_hud()
	await process_frame
	var m := _measure("real")
	_check(m.ok, "844x390 zh real HUD: %s" % m.why)
	var text: String = main._hint_label.text
	_check(not m.wraps and main._hint_label.get_line_count() == 1, "844x390 zh real hint is one line (%s)" % text)
	_check(main._hint_panel.size.x < 400.0, "844x390 zh goal paper no longer stretches to 538px (now %.0f)" % main._hint_panel.size.x)
	var before_size: Vector2 = main._hint_label.size
	for i in 3:
		main._refresh_hud()
	_check(main._hint_label.size.is_equal_approx(before_size), "repeated per-frame refresh keeps the same width")
	await _despawn()
	await _spawn(Vector2i(1280, 720))
	main._refresh_hud()
	await process_frame
	m = _measure("real")
	_check(m.ok, "1280x720 zh real HUD: %s" % m.why)
	_check(main._hint_panel.size.x < 400.0, "1280x720 zh goal paper hugs its text (%.0f)" % main._hint_panel.size.x)
	await _despawn()
	for dims in [Vector2i(640, 360), Vector2i(568, 320)]:
		await _spawn(dims)
		main._refresh_hud()
		await process_frame
		m = _measure("real")
		_check(m.ok, "%s zh real compact HUD: %s" % [dims, m.why])
		_check(main._hint_label.get_line_count() == 2 and main._hint_panel.size.x < 300.0, "%s zh two short compact lines sit on a narrow paper (%.0f, %d lines)" % [dims, main._hint_panel.size.x, main._hint_label.get_line_count()])
		await _despawn()


## A short hint followed by a long one must not keep the short paper and wrap early.
func _check_short_then_long() -> void:
	for dims in [Vector2i(844, 390), Vector2i(1280, 720), Vector2i(390, 844)]:
		await _spawn(dims)
		for locale in ["zh-CN", "en"]:
			i18n.set_locale(locale)
			await _settle()
			var compact: bool = main.size.x < 700.0
			var texts := _texts(compact)
			var shortest := texts[0]
			var longest := texts[0]
			for t in texts:
				if t.length() < shortest.length(): shortest = t
				if t.length() > longest.length(): longest = t
			for t in [shortest, longest, shortest, longest]:
				main._hint_label.text = t
				main._fit_hint_panel()
				var m := _measure("seq")
				_check(m.ok, "%s %s short/long sequence「%s」: %s" % [dims, locale, t, m.why])
		await _despawn()


## Measuring while the HUD is hidden (album/pause open) must not leave a stale width.
func _check_hidden_hud() -> void:
	await _spawn(Vector2i(700, 400))
	i18n.set_locale("en")
	await _settle()
	var texts := _texts(false)
	var long_text := ""
	for t in texts:
		if ceilf(_text_width(t)) + 2.0 > _max_width():
			long_text = t
			break
	_check(not long_text.is_empty(), "700x400 en has a hint that needs automatic wrapping")
	main._hud.visible = false
	main._hint_label.text = long_text
	main._fit_hint_panel()
	main._hud.visible = true
	await process_frame
	main._fit_hint_panel()
	var m := _measure("hidden")
	_check(m.ok, "700x400 en long hint fitted while hidden, then shown: %s" % m.why)
	i18n.set_locale("zh-CN")
	await _despawn()


func _check_resize() -> void:
	await _spawn(Vector2i(844, 390))
	i18n.set_locale("zh-CN")
	for dims in [Vector2i(844, 390), Vector2i(390, 844), Vector2i(360, 640), Vector2i(1280, 720), Vector2i(568, 320), Vector2i(844, 390)]:
		root.size = dims
		await _settle()
		main._refresh_hud()
		await process_frame
		var m := _measure("resize")
		_check(m.ok, "resize->%s zh real HUD refits: %s" % [dims, m.why])
	main._show_title(false)
	await _settle()
	_check(not main._hint_panel.is_visible_in_tree(), "goal paper hidden on the title screen")
	_check(main._hint_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE and main._hint_label.mouse_filter == Control.MOUSE_FILTER_IGNORE, "goal paper and text still ignore taps")
	await _despawn()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		if failures.size() <= 40:
			print("FAIL: ", label)


func _finish() -> void:
	if failures.is_empty():
		print("PASS: hint_paper_width %d checks" % checks)
		quit(0)
	else:
		print("FAIL: hint_paper_width %d of %d checks failed" % [failures.size(), checks])
		quit(1)
