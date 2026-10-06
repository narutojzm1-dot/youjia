extends SceneTree

## REQ-20261006-046: the new-photo print's caption ("Holiday day N" + moment)
## must stay inside its 192×56 slot on the paper strip, never leave one lone
## word / two characters on a wrapped line, and keep the original 13px full-width
## box when nothing wraps. Every expression rule × caption variant × day 1/12/365,
## Chinese and English, through PhotoArrival.play and through a live locale
## switch (refresh_locale). Fixture only: temporary yard world, never loads or
## writes the player's save.

const CAPTION_RECT := Rect2(24, 227, 192, 56)
const EPS := 0.75
const DAYS := [1, 12, 365]

var checks := 0
var failures: Array[String] = []
var arrival: Control
var stats := {}


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.get_node("TuningStore").call("end_run")
	var base := _capture_snapshot()
	check(not base.is_empty(), "fixture captured a genuine yard photo snapshot")
	if base.is_empty():
		_finish()
		return
	arrival = load("res://scripts/ui/photo_arrival.gd").new()
	arrival.name = "PhotoArrival"
	root.add_child(arrival)
	await _settle()
	var i18n = root.get_node("I18n")
	for loc in ["zh-CN", "en"]:
		i18n.call("set_locale", loc)
		for id in ExpressionCatalog.all_ids():
			var rule := ExpressionCatalog.find_rule(id)
			var variants := clampi(int(rule.get("caption_variants", 1)), 1, 3)
			for v in range(variants):
				for day: int in DAYS:
					var snap := base.duplicate(true)
					snap["rule_id"] = id
					snap["caption_variant"] = v
					snap["day"] = day
					var tag := "%s %s v%d day%d" % [loc, id, v, day]
					check(arrival.play(snap, true), "%s: print plays" % tag)
					await process_frame
					_check_caption(tag, loc)
					arrival.dismiss()
	await _check_locale_switch(base)
	i18n.call("set_locale", "zh-CN")
	print("caption stats ", stats)
	_finish()


func _check_locale_switch(base: Dictionary) -> void:
	var i18n = root.get_node("I18n")
	var snap := base.duplicate(true)
	snap["rule_id"] = "duck_pond_chorus"
	snap["caption_variant"] = 1
	snap["day"] = 12
	i18n.call("set_locale", "zh-CN")
	check(arrival.play(snap, true), "switch: print plays in Chinese")
	await process_frame
	_check_caption("switch zh", "zh-CN")
	for loc in ["en", "zh-CN", "en"]:
		i18n.call("set_locale", loc)
		arrival.refresh_locale()
		await process_frame
		_check_caption("switch -> %s" % loc, loc)
	# Rotations while showing keep the caption fit (it is inside the scaled card).
	for dims: Vector2i in [Vector2i(568, 320), Vector2i(360, 640), Vector2i(1280, 720)]:
		root.size = dims
		await _settle()
		_check_caption("switch en %s" % dims, "en")
	arrival.dismiss()


func _check_caption(tag: String, loc: String) -> void:
	var caption: Label = arrival.get_node("PhotoCard/Caption")
	check(not caption.text.is_empty(), "%s: caption text present" % tag)
	var rect := Rect2(caption.position, caption.size)
	var text_h := caption.get_minimum_size().y
	var font_size := caption.get_theme_font_size("font_size")
	var paragraphs := caption.text.split("\n")
	var lines := caption.get_line_count()
	var wrapped := lines > paragraphs.size()
	# Would the original 13px / 192px box have shown it without wrapping?
	var fits_original: bool = _line_count(caption.text, caption.get_theme_font("font"), 13, CAPTION_RECT.size.x) <= paragraphs.size()
	var key := "%s fs%d lines%d" % [loc, font_size, lines]
	stats[key] = stats.get(key, 0) + 1
	check(text_h <= CAPTION_RECT.size.y + EPS, "%s: caption text %.0fpx tall fits the 56px slot" % [tag, text_h])
	check(rect.position.x >= CAPTION_RECT.position.x - EPS and rect.end.x <= CAPTION_RECT.end.x + EPS, "%s: caption box %s stays inside the slot horizontally" % [tag, rect])
	check(absf(rect.position.y - CAPTION_RECT.position.y) <= EPS and absf(rect.size.y - CAPTION_RECT.size.y) <= EPS, "%s: caption box keeps the slot's top and height %s" % [tag, rect])
	check(absf(rect.get_center().x - CAPTION_RECT.get_center().x) <= EPS, "%s: caption box centred in the slot" % tag)
	check(font_size == 13 or font_size == 12, "%s: caption font stays 12-13px (%d)" % [tag, font_size])
	check(caption.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and caption.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "%s: caption stays centred text" % tag)
	check(lines == caption.get_line_count(), "%s: line count stable" % tag)
	if fits_original:
		check(rect.is_equal_approx(CAPTION_RECT), "%s: unwrapped caption keeps the original box" % tag)
		check(font_size == 13, "%s: unwrapped caption keeps 13px" % tag)
		check(not caption.has_theme_constant_override("line_spacing"), "%s: unwrapped caption keeps default line spacing" % tag)
		return
	if not wrapped:
		return
	# Every automatically wrapped paragraph ends with a real phrase, not a lone word.
	var font := caption.get_theme_font("font")
	var ts := TextServerManager.get_primary_interface()
	for para: String in paragraphs:
		var shaped := ts.create_shaped_text()
		ts.shaped_text_add_string(shaped, para, font.get_rids(), font_size)
		var breaks := ts.shaped_text_get_line_breaks(shaped, rect.size.x, 0, TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE)
		ts.free_rid(shaped)
		if breaks.size() < 4:
			continue
		var last := para.substr(breaks[breaks.size() - 2]).strip_edges()
		if loc == "en":
			check(last.split(" ", false).size() >= 2, "%s: last wrapped line has at least two words (%s)" % [tag, last])
		else:
			check(last.length() >= 3, "%s: last wrapped line has at least three characters (%s)" % [tag, last])


## Independent of the production helper: AUTOWRAP_WORD_SMART line count incl. \n.
func _line_count(text: String, font: Font, font_size: int, width: float) -> int:
	var ts := TextServerManager.get_primary_interface()
	var total := 0
	for para: String in text.split("\n"):
		var shaped := ts.create_shaped_text()
		ts.shaped_text_add_string(shaped, para, font.get_rids(), font_size)
		var breaks := ts.shaped_text_get_line_breaks(shaped, width, 0, TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE)
		ts.free_rid(shaped)
		total += maxi(1, breaks.size() / 2)
	return total


func _capture_snapshot() -> Dictionary:
	seed(3303)
	var world = load("res://scripts/game/yard_world.gd").new()
	root.add_child(world)
	world.setup()
	world.holiday_day = 2
	world._weather_timer = 10000.0
	world.debug_place_player(Vector2(830, 530))
	world.tick(1.0 / 60.0, Vector2.ZERO)
	world.debug_force_rule("duck_pond_chorus")
	var found: Dictionary = world.photo_moments.get("duck_pond_chorus", {}).duplicate(true)
	root.remove_child(world)
	world.free()
	return found


func _settle() -> void:
	for i in 4:
		await process_frame


func _finish() -> void:
	if failures.is_empty():
		print("PASS photo_caption_fit_suite: %d checks" % checks)
		quit(0)
	else:
		print("FAIL photo_caption_fit_suite: %d/%d checks failed" % [failures.size(), checks])
		for f in failures.slice(0, 40):
			print("  - ", f)
		quit(1)
