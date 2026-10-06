extends SceneTree

## REQ-20261007-048: the album polaroid's caption ("Holiday day N" + moment)
## stays on the frame's bottom paper strip (24,227 192×56 in 240×300 card
## units) and never runs down to the card edge; wrapped lines never end on a
## lone word / two characters; captions that fit on their own lines keep the
## original 24,232 192×52 box, size and spacing. Every polaroid rule × caption
## variant × day 1/12/365, Chinese and English, several page sizes, a live
## locale switch and the empty-slot / legacy title fallback. Fixture only:
## SaveStore data is replaced in memory, never loaded from or written to disk.

const ORIGINAL := Rect2(24, 232, 192, 52)
const STRIP := Rect2(24, 227, 192, 56)
const EPS := 0.75
const DAYS := [1, 12, 365]
const VIEWS := [Vector2i(1280, 720), Vector2i(390, 844), Vector2i(360, 640), Vector2i(1920, 1080), Vector2i(700, 500), Vector2i(844, 390)]

var checks := 0
var failures: Array[String] = []
var stats := {}
var framed := 0
var default_spacing := 0


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


func _run() -> void:
	var actual: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://test/fixtures/album_landscape_photo.json"))
	for variant in range(3):
		var moments := {}
		for rule: Dictionary in ExpressionCatalog.RULES:
			if not bool(rule.get("polaroid", false)):
				continue
			var record: Dictionary = actual.values()[0].duplicate(true)
			record.rule_id = rule.id
			record.caption_variant = variant % int(rule.get("caption_variants", 1))
			moments[rule.id] = record
		for day: int in DAYS:
			await _scenario(moments, day, "v%d day%d" % [variant, day])
	await _legacy_and_switch(actual)
	check(framed > 0, "album rendered framed captions (%d)" % framed)
	print("album caption stats ", stats)
	_finish()


func _scenario(moments: Dictionary, day: int, tag: String) -> void:
	var store = root.get_node("SaveStore")
	store._data = store._default_data()
	for photo: Dictionary in moments.values():
		photo.day = day
	store._data.album = moments.keys()
	store._data.photo_moments = moments
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	default_spacing = main.get_theme_constant("line_spacing", "Label")
	main._show_album()
	for loc in ["zh-CN", "en"]:
		root.get_node("I18n").call("set_locale", loc)
		for dims: Vector2i in VIEWS:
			root.size = dims
			await process_frame
			main._layout()
			var step := 2 if main._album_two_pages else 1
			for index in range(0, store._data.album.size(), step):
				main._album_index = index
				main._render_album_pages()
				for f in range(3):
					await process_frame
				_inspect(main, "%s %s %s #%d" % [tag, loc, dims, index], loc)
	main.queue_free()
	await process_frame


## Old saves without a recorded photo use the title; an empty grid slot never
## appears on a page but the same card builder must still fit. Then switch the
## language with the album open.
func _legacy_and_switch(actual: Dictionary) -> void:
	var store = root.get_node("SaveStore")
	store._data = store._default_data()
	var moments := {}
	var legacy: Array = []
	for rule: Dictionary in ExpressionCatalog.RULES:
		if not bool(rule.get("polaroid", false)):
			continue
		legacy.append(rule.id)
	var record: Dictionary = actual.values()[0].duplicate(true)
	record.rule_id = "duck_pond_chorus"
	record.caption_variant = 1
	record.day = 12
	moments["duck_pond_chorus"] = record
	store._data.album = ["duck_pond_chorus"] + legacy.filter(func(id): return id != "duck_pond_chorus")
	store._data.photo_moments = moments
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	default_spacing = main.get_theme_constant("line_spacing", "Label")
	main._show_album()
	root.size = Vector2i(1280, 720)
	for loc in ["en", "zh-CN", "en", "zh-CN"]:
		root.get_node("I18n").call("set_locale", loc)
		await process_frame
		main._layout()
		for index in [0, 2, 4]:
			main._album_index = index
			main._render_album_pages()
			for f in range(3):
				await process_frame
			_inspect(main, "switch %s #%d" % [loc, index], loc, false)
	for loc in ["zh-CN", "en"]:
		root.get_node("I18n").call("set_locale", loc)
		for owned in [true, false]:
			for rule_id in legacy.slice(0, 6):
				var card: Control = main._photo_card(ExpressionCatalog.find_rule(rule_id), owned, 240.0, true)
				main.add_child(card)
				await process_frame
				for c in card.get_children():
					if c is Label and not c.text.is_empty():
						_check_caption(c, 1.0, "card %s %s owned=%s" % [loc, rule_id, owned], loc)
				card.queue_free()
	main.queue_free()
	await process_frame


func _inspect(main: Control, tag: String, loc: String, need_photo := true) -> void:
	for page in main._album_spread.get_children():
		for node in _descendants(page):
			if not (node is TextureRect) or node.texture != main.POLAROID:
				continue
			var holder: Control = node.get_parent()
			var scale: float = holder.custom_minimum_size.x / 240.0
			var has_photo := false
			for c in holder.get_children():
				if c is PhotoMoment:
					has_photo = true
			if need_photo:
				check(has_photo, "%s: recorded photograph present" % tag)
			for c in holder.get_children():
				if c is Label and not c.text.is_empty():
					framed += 1
					_check_caption(c, scale, tag, loc)
					var card := holder.get_global_rect()
					var lb: Rect2 = c.get_global_rect()
					check(card.grow(EPS).encloses(lb), "%s: caption box stays on the card" % tag)
					var text_h: float = c.get_minimum_size().y
					var text_bottom: float = lb.position.y + text_h if c.vertical_alignment == VERTICAL_ALIGNMENT_TOP else lb.get_center().y + text_h * 0.5
					check(text_bottom <= card.position.y + STRIP.end.y * scale + EPS, "%s: caption text ends on the paper strip, %.1fpx above the card edge" % [tag, card.end.y - text_bottom])


func _check_caption(caption: Label, scale: float, tag: String, loc: String) -> void:
	var rect := Rect2(caption.position, caption.size)
	var strip := Rect2(STRIP.position * scale, STRIP.size * scale)
	var original := Rect2(ORIGINAL.position * scale, ORIGINAL.size * scale)
	var base := maxi(12, roundi(13.0 * scale))
	var font_size := caption.get_theme_font_size("font_size")
	var font := caption.get_theme_font("font")
	var paragraphs := caption.text.split("\n")
	var text_h := caption.get_minimum_size().y
	var fits_original := _line_count(caption.text, font, base, original.size.x) <= paragraphs.size() \
		and _height(font, base, default_spacing, paragraphs.size()) <= original.size.y + EPS
	var lines := _line_count(caption.text, font, font_size, rect.size.x)
	var key := "%s fs%d lines%d %s" % [loc, font_size, lines, "orig" if rect.is_equal_approx(original) else "strip"]
	stats[key] = stats.get(key, 0) + 1
	check(text_h <= rect.size.y + EPS, "%s: caption text %.0fpx fits its %.0fpx box" % [tag, text_h, rect.size.y])
	check(rect.position.x >= strip.position.x - EPS and rect.end.x <= strip.end.x + EPS, "%s: caption box %s inside the strip horizontally" % [tag, rect])
	check(absf(rect.get_center().x - strip.get_center().x) <= EPS, "%s: caption box centred on the card" % tag)
	check(font_size >= 12 and font_size <= base, "%s: caption font %dpx within 12..%d" % [tag, font_size, base])
	check(caption.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "%s: caption text centred" % tag)
	if fits_original:
		check(rect.is_equal_approx(original), "%s: caption that fits keeps the original box %s" % [tag, rect])
		check(font_size == base, "%s: caption that fits keeps %dpx" % [tag, base])
		check(not caption.has_theme_constant_override("line_spacing"), "%s: caption that fits keeps default line spacing" % tag)
		check(caption.vertical_alignment == VERTICAL_ALIGNMENT_TOP, "%s: caption that fits keeps top alignment" % tag)
		return
	check(absf(rect.position.y - strip.position.y) <= EPS and absf(rect.size.y - strip.size.y) <= EPS, "%s: fitted caption box %s is exactly the paper strip" % [tag, rect])
	check(caption.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "%s: fitted caption centred vertically" % tag)
	if lines <= paragraphs.size():
		return
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


func _height(font: Font, font_size: int, spacing: int, lines: int) -> float:
	return (font.get_height(font_size) + spacing) * lines - spacing


func _descendants(node: Node) -> Array:
	var result := []
	for child in node.get_children():
		result.append(child)
		result.append_array(_descendants(child))
	return result


func _finish() -> void:
	if failures.is_empty():
		print("PASS album_caption_fit_suite: %d checks" % checks)
		quit(0)
	else:
		print("FAIL album_caption_fit_suite: %d/%d checks failed" % [failures.size(), checks])
		for f in failures.slice(0, 40):
			print("  - ", f)
		quit(1)
