extends SceneTree

## REQ-20261005-029: the goal paper (目标纸片) behind the HUD hint grows and
## shrinks with the real number of text lines. Short landscape phones no longer
## carry a half-empty paper over the mountains, and narrow portrait phones no
## longer let three- or four-line English hints spill off the paper onto the
## yard. The paper is never shorter than the 48px HUD buttons, and the text is
## vertically centred on it. Copy, font size, width and position are unchanged.

const VIEWPORTS := [Vector2i(390, 844), Vector2i(844, 390), Vector2i(1280, 720), Vector2i(360, 640), Vector2i(700, 400)]
const TARGETS := ["llama", "cow", "horse", "sheep_a", "sheep_b", "goose", "duck_a", "grass", "plant", "fishing", "windowbox", "shore_stones", "fence_gate", "path_out"]
const ACTIONS := ["fish", "fish_waiting", "reel", "pet", "observe_windowbox", "touch_shore", "observe_fence", "plant", "water", "harvest", "toss_fish", "release", "feed", "grass", "lead", "go_out"]
const CONTEXTS := ["hud.hint.default", "hud.hint.leading", "hud.hint.carrying", "hud.hint.near_grass", "hud.hint.near_llama", "hud.hint.near_pond", "hud.hint.fishing", "hud.hint.fish_bite", "hud.hint.plant_empty", "hud.hint.plant_water", "hud.hint.plant_bloomed", "hud.hint.near_animal", "hud.hint.carrying_fish"]
const MIN_PAPER := 48.0
const MARGIN := 16.0

var checks := 0
var failures: Array[String] = []
var main
var i18n


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
		main.queue_free()
		await process_frame
	await _check_real_hud()
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


func _settle() -> void:
	for i in 4:
		await process_frame


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


func _text_height(label: Label) -> float:
	var lines := maxi(1, label.get_line_count())
	return lines * float(label.get_line_height()) + (lines - 1) * float(label.get_theme_constant("line_spacing"))


## Same rules for every hint string: lay out as the game does, then measure.
func _measure(tag: String) -> Dictionary:
	var label: Label = main._hint_label
	var paper: Panel = main._hint_panel
	var text_h := _text_height(label)
	var paper_rect := paper.get_global_rect()
	var label_rect := label.get_global_rect()
	var expected := maxf(MIN_PAPER, ceilf(text_h) + MARGIN)
	var problems: Array[String] = []
	if not paper_rect.grow(0.5).encloses(label_rect):
		problems.append("text box %s spills off paper %s" % [label_rect, paper_rect])
	if label.size.y + 0.5 < text_h:
		problems.append("text box %.0f shorter than %d lines (%.0f)" % [label.size.y, label.get_line_count(), text_h])
	if label.get_visible_line_count() < label.get_line_count():
		problems.append("only %d/%d lines visible" % [label.get_visible_line_count(), label.get_line_count()])
	if absf(paper.size.y - expected) > 0.5:
		problems.append("paper %.0fpx tall, content needs %.0fpx" % [paper.size.y, expected])
	if paper.size.y < MIN_PAPER - 0.5:
		problems.append("paper below button height")
	if absf(label_rect.get_center().y - paper_rect.get_center().y) > 1.5:
		problems.append("text not centred on paper")
	var screen := Rect2(Vector2.ZERO, main.size)
	if not screen.encloses(paper_rect):
		problems.append("paper leaves the screen")
	for other in [main._pause_button, main._day_label]:
		if paper_rect.intersects(other.get_global_rect()):
			problems.append("paper overlaps %s" % other.name)
	return {"ok": problems.is_empty(), "why": ", ".join(problems), "lines": label.get_line_count()}


func _check_matrix(dims: Vector2i, locale: String) -> void:
	var compact: bool = main.size.x < 700.0
	var label: Label = main._hint_label
	var width_before: float = label.size.x
	var pos_before: Vector2 = label.position
	var font_before: int = label.get_theme_font_size("font_size")
	var seen := {}
	var max_lines := 0
	for text in _texts(compact):
		if seen.has(text):
			continue
		seen[text] = true
		label.text = text
		main._layout()
		var m := _measure("%s %s" % [dims, locale])
		max_lines = maxi(max_lines, m.lines)
		_check(m.ok, "%s %s「%s」: %s" % [dims, locale, text.replace("\n", "/"), m.why])
	_check(is_equal_approx(label.size.x, width_before) and label.position.is_equal_approx(pos_before), "%s %s width/position unchanged" % [dims, locale])
	_check(label.get_theme_font_size("font_size") == font_before, "%s %s font size unchanged" % [dims, locale])
	_check(label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "%s %s still wraps words" % [dims, locale])
	print("%s %s: %d strings, up to %d lines" % [dims, locale, seen.size(), max_lines])


## The real per-frame HUD path (_refresh_hud) must fit the paper too, not only _layout.
func _check_real_hud() -> void:
	await _spawn(Vector2i(390, 844))
	var w = main._world
	i18n.set_locale("en")
	w._pending_interaction = "shore_stones"
	w.tick(0.016, Vector2.ZERO)
	main._refresh_hud()
	await process_frame
	var text: String = main._hint_label.text
	_check(text.contains("Pond-side stones"), "390x844 en real HUD names the pond-side stones (%s)" % text.replace("\n", "/"))
	_check(main._hint_label.get_line_count() >= 3, "390x844 en pond-stone hint really wraps to 3+ lines (%d)" % main._hint_label.get_line_count())
	var m := _measure("real")
	_check(m.ok, "390x844 en real HUD pond-stone hint stays on paper: %s" % m.why)
	w._pending_interaction = ""
	i18n.set_locale("zh-CN")
	w.tick(0.016, Vector2.ZERO)
	main._refresh_hud()
	await process_frame
	m = _measure("real")
	_check(m.ok, "390x844 zh real HUD default hint fits paper: %s" % m.why)
	main.queue_free()
	await process_frame
	await _spawn(Vector2i(844, 390))
	main._refresh_hud()
	await process_frame
	m = _measure("real")
	_check(m.ok, "844x390 zh real HUD one-line hint has no half-empty paper: %s" % m.why)
	_check(main._hint_panel.size.y <= MIN_PAPER + 0.5, "844x390 one-line goal paper is button height (%.0f)" % main._hint_panel.size.y)
	main.queue_free()
	await process_frame


func _check_resize() -> void:
	await _spawn(Vector2i(390, 844))
	i18n.set_locale("en")
	main._world._pending_interaction = "shore_stones"
	for dims in [Vector2i(390, 844), Vector2i(844, 390), Vector2i(360, 640), Vector2i(1280, 720), Vector2i(390, 844)]:
		root.size = dims
		await _settle()
		main._world.tick(0.016, Vector2.ZERO)
		main._refresh_hud()
		await process_frame
		var m := _measure("resize")
		_check(m.ok, "resize->%s en paper refits: %s" % [dims, m.why])
	main._world._pending_interaction = ""
	main._show_title(false)
	await _settle()
	_check(not main._hint_panel.is_visible_in_tree(), "goal paper hidden on the title screen")
	_check(main._hint_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE and main._hint_label.mouse_filter == Control.MOUSE_FILTER_IGNORE, "goal paper and text still ignore taps")
	main.queue_free()
	await process_frame


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: ", label)


func _finish() -> void:
	if failures.is_empty():
		print("hint_paper_fit suite: %d checks passed" % checks)
		quit(0)
	else:
		print("hint_paper_fit suite: %d of %d checks FAILED" % [failures.size(), checks])
		quit(1)
