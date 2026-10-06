extends SceneTree

## REQ-20261006-044: on narrow or short screens the title page tagline and the
## controls hint used to leave the last two or three characters alone on their
## own line (360x640 hint ended with a lone "互动。", 844x390 tagline with a
## lone "出现。"). Both labels now take a balanced width: the same number of
## lines, as narrow as possible, still centred, and where the line count
## allows it every automatic break lands after punctuation or a space (so
## 844x390 reads "...溜草泥马，/或者..."). Copy, font sizes, line counts, buttons
## and the paper card rules are unchanged.

const VIEWS := [Vector2i(360, 640), Vector2i(390, 844), Vector2i(412, 915), Vector2i(1280, 720), Vector2i(844, 390), Vector2i(915, 412), Vector2i(640, 360), Vector2i(568, 320), Vector2i(667, 375)]
## Viewports where both zh-CN paragraphs have room to break only at punctuation.
const CLEAN_BREAKS := [Vector2i(390, 844), Vector2i(412, 915), Vector2i(844, 390), Vector2i(915, 412), Vector2i(640, 360), Vector2i(568, 320), Vector2i(667, 375)]
const PAUSES := "，。、：；！？）」,.;:!?) "
const EPS := 0.51

var checks := 0
var failures: Array[String] = []
var main
var i18n


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	i18n = root.get_node("/root/I18n")
	var original_locale: String = i18n.get_locale()
	for dims in VIEWS:
		await _spawn(dims)
		for locale in ["zh-CN", "en"]:
			i18n.set_locale(locale)
			await _settle()
			_check_title(dims, locale, "%s %s" % [dims, locale])
		i18n.set_locale(original_locale)
		main.queue_free()
		await process_frame
	await _check_resize_and_play()
	i18n.set_locale(original_locale)
	_finish()


func _spawn(dims: Vector2i) -> void:
	root.size = dims
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _settle()
	main.set_process(false)


func _settle() -> void:
	for i in 5:
		await process_frame


func _inside(inner: Rect2, outer: Rect2) -> bool:
	return inner.position.x >= outer.position.x - EPS and inner.position.y >= outer.position.y - EPS \
		and inner.end.x <= outer.end.x + EPS and inner.end.y <= outer.end.y + EPS


## Lines of one paragraph at a width, as [start, end] pairs, using the same
## word-smart rules as the label.
func _lines(para: String, label: Label, width: float) -> Array:
	var ts := TextServerManager.get_primary_interface()
	var font: Font = label.get_theme_font("font")
	var shaped := ts.create_shaped_text()
	ts.shaped_text_add_string(shaped, para, font.get_rids(), label.get_theme_font_size("font_size"))
	var breaks := ts.shaped_text_get_line_breaks(shaped, width, 0, TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE)
	ts.free_rid(shaped)
	var out := []
	for i in range(0, breaks.size(), 2):
		out.append([breaks[i], breaks[i + 1]])
	return out


func _line_total(label: Label, width: float) -> int:
	var total := 0
	for para: String in label.text.split("\n"):
		total += maxi(1, _lines(para, label, width).size())
	return total


func _check_title(dims: Vector2i, locale: String, tag: String) -> void:
	var screen := Rect2(Vector2.ZERO, Vector2(dims))
	var column: Control = main._title_label.get_parent()
	var avail: float = column.offset_right - column.offset_left
	var card: Rect2 = main._title_card.get_global_rect()
	_check(main._title_screen.visible and main._title_card.visible, "%s: title page and paper card showing" % tag)
	_check(main._tagline_label.text == i18n.t("app.tagline") and main._title_hint.text == i18n.t("menu.hint"), "%s: copy unchanged" % tag)
	var short := dims.y < 500
	_check(main._tagline_label.get_theme_font_size("font_size") == (14 if short else 16) and main._title_hint.get_theme_font_size("font_size") == (12 if short else 14), "%s: font sizes unchanged" % tag)
	for label: Label in [main._tagline_label, main._title_hint]:
		var r := label.get_global_rect()
		var name := "tagline" if label == main._tagline_label else "hint"
		_check(_inside(r, card) and _inside(r, screen), "%s: %s %s inside the card %s and on screen" % [tag, name, r, card])
		_check(r.size.x <= avail + EPS, "%s: %s width %.1f within the column %.1f" % [tag, name, r.size.x, avail])
		_check(absf(r.get_center().x - dims.x * 0.5) <= 1.0, "%s: %s centred" % [tag, name])
		var full := _line_total(label, avail)
		var now := _line_total(label, r.size.x)
		_check(now == full, "%s: %s keeps its line count (%d at %.1f vs %d at full width)" % [tag, name, now, r.size.x, full])
		_check(label.get_line_count() == full, "%s: %s label renders %d lines (expected %d)" % [tag, name, label.get_line_count(), full])
		var clean := true
		for para: String in label.text.split("\n"):
			var lines := _lines(para, label, r.size.x)
			if lines.size() < 2:
				continue
			var last: Array = lines[lines.size() - 1]
			var tail := para.substr(last[0], last[1] - last[0]).strip_edges()
			if locale == "zh-CN":
				_check(tail.length() >= 4, "%s: %s last line '%s' is not a lone 1-3 character orphan" % [tag, name, tail])
			else:
				_check(tail.split(" ", false).size() >= 2, "%s: %s last line '%s' is not a single orphan word" % [tag, name, tail])
			for i in lines.size() - 1:
				var end: int = lines[i][1]
				if not PAUSES.contains(para.substr(end - 1, 1)):
					clean = false
		if locale == "zh-CN" and dims in CLEAN_BREAKS:
			_check(clean, "%s: %s every automatic break lands after punctuation" % [tag, name])
	for node: Control in [main._title_label, main._subtitle_label, main._tagline_label, main._play_button, main._album_button, main._licenses_button, main._title_hint]:
		_check(_inside(node.get_global_rect(), card), "%s: %s stays on the paper card" % [tag, node.name])
	_check(_inside(card, screen.grow(-4.0 + EPS)), "%s: paper card %s on screen" % [tag, card])


func _check_resize_and_play() -> void:
	await _spawn(Vector2i(1280, 720))
	for dims in [Vector2i(844, 390), Vector2i(360, 640), Vector2i(568, 320), Vector2i(390, 844), Vector2i(844, 390)]:
		root.size = dims
		await _settle()
		_check_title(dims, "zh-CN", "resize->%s" % [dims])
	i18n.set_locale("en")
	await _settle()
	_check_title(Vector2i(844, 390), "en", "locale switch to en at 844x390")
	i18n.set_locale("zh-CN")
	await _settle()
	_check_title(Vector2i(844, 390), "zh-CN", "locale switch back at 844x390")
	main._play_button.pressed.emit()
	await _settle()
	_check(not main._title_screen.visible, "walking into the yard still leaves the title page")
	main.queue_free()
	await process_frame


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: ", label)


func _finish() -> void:
	if failures.is_empty():
		print("PASS: title_copy_balance %d checks" % checks)
		quit(0)
	else:
		print("title_copy_balance: %d of %d checks FAILED" % [failures.size(), checks])
		quit(1)
