extends SceneTree

## REQ-20261006-039: the new-photo "shutter" line ("旅人随手拍下了这一刻。" /
## "The traveler caught this little moment.") used to float straight on the
## live yard with only a thin cream outline. On portrait phones it sat over the
## dark roof timbers; on short landscape screens it ran across the target
## hint's text. It now has a small warm paper slip behind it, fitted to the
## text, that fades together with the line. Line position, size, text, the
## print and the fit layout stay unchanged.
## Fixture only: temporary yard world, never loads or writes the player's save.

const VIEW_MARGIN := 8.0
const VIEWPORTS := [
	Vector2i(1280, 720), Vector2i(1024, 600), Vector2i(390, 844), Vector2i(360, 640), Vector2i(320, 568),
	Vector2i(844, 390), Vector2i(667, 375), Vector2i(568, 320), Vector2i(640, 300), Vector2i(844, 340),
]
const LOCALES := ["zh-CN", "en"]
const MIN_PAD_X := 10.0
const MIN_CONTRAST := 4.5
const EPS := 0.75

var checks := 0
var failures: Array[String] = []
var arrival: Control


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
	var locale: Node = root.get_node("I18n")
	var snapshot := _capture_snapshot()
	check(not snapshot.is_empty(), "fixture captured a genuine yard photo snapshot")
	if snapshot.is_empty():
		_finish()
		return
	arrival = load("res://scripts/ui/photo_arrival.gd").new()
	arrival.name = "PhotoArrival"
	root.add_child(arrival)
	await _settle()
	for language: String in LOCALES:
		locale.call("set_locale", language)
		for dims: Vector2i in VIEWPORTS:
			for reduced: bool in [true, false]:
				root.size = dims
				await _settle()
				check(arrival.play(snapshot, reduced), "%s %s reduced=%s: print plays" % [language, dims, reduced])
				await _settle()
				_check_slip(dims, "%s reduced=%s" % [language, reduced])
				if not reduced:
					_check_fade(dims, language)
				arrival.dismiss()
	# Language switch and rotation while the print is on screen.
	locale.call("set_locale", "zh-CN")
	root.size = Vector2i(1280, 720)
	await _settle()
	arrival.play(snapshot, true)
	await _settle()
	var zh_width := _slip_width()
	locale.call("set_locale", "en")
	arrival.call("refresh_locale")
	await _settle()
	check(_slip_width() > zh_width + 20.0, "live switch to English refits the slip to the longer line (%.1f -> %.1f)" % [zh_width, _slip_width()])
	_check_slip(Vector2i(1280, 720), "en after live switch")
	for dims: Vector2i in [Vector2i(390, 844), Vector2i(568, 320), Vector2i(1280, 720)]:
		root.size = dims
		await _settle()
		_check_slip(dims, "en resized while showing")
	arrival.dismiss()
	locale.call("set_locale", "zh-CN")
	_finish()


func _slip_width() -> float:
	var slip := arrival.get_node_or_null("ShutterCaption/ShutterPaper") as Control
	return slip.size.x if slip != null else 0.0


func _check_slip(dims: Vector2i, tag: String) -> void:
	var line: Label = arrival.get_node("ShutterCaption")
	var card: Control = arrival.get_node("PhotoCard")
	var slip := arrival.get_node_or_null("ShutterCaption/ShutterPaper") as Control
	check(slip != null, "%s %s: shutter line has a paper slip" % [dims, tag])
	# Unchanged: line geometry follows the original fit layout and keeps its text/colour.
	var fit: Dictionary = arrival.call("fit_layout", Vector2(dims))
	check(line.position.is_equal_approx(fit.shutter_position) and line.size.is_equal_approx(fit.shutter_size), "%s %s: line rect still follows fit_layout" % [dims, tag])
	check(not line.text.is_empty() and line.text == str(root.get_node("I18n").call("t", "photo.arrival.shutter")), "%s %s: line text unchanged" % [dims, tag])
	var ink: Color = line.get_theme_color("font_color")
	check(ink.is_equal_approx(Color("5b4637")), "%s %s: line ink unchanged %s" % [dims, tag, ink.to_html(false)])
	check(line.get_minimum_size().y <= line.size.y + 0.5, "%s %s: one line still fits the label height" % [dims, tag])
	if slip == null:
		return
	check(slip is Panel and slip.show_behind_parent, "%s %s: slip draws behind the text" % [dims, tag])
	check(slip.visible and slip.is_visible_in_tree() == line.is_visible_in_tree(), "%s %s: slip shows exactly when the line shows" % [dims, tag])
	check(slip.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s %s: slip never blocks input" % [dims, tag])
	check(is_equal_approx(slip.modulate.a, 1.0) and is_equal_approx(slip.self_modulate.a, 1.0), "%s %s: slip inherits the line's fade" % [dims, tag])
	var style := slip.get_theme_stylebox("panel") as StyleBoxFlat
	check(style != null, "%s %s: slip uses a flat paper style" % [dims, tag])
	if style != null:
		var paper := style.bg_color
		check(paper.a >= 0.9 and paper.a <= 1.0, "%s %s: slip is nearly opaque (a=%.2f)" % [dims, tag, paper.a])
		check(paper.get_luminance() > 0.85 and paper.r >= paper.g and paper.g >= paper.b, "%s %s: slip is warm light paper %s" % [dims, tag, paper.to_html(false)])
		check(style.border_width_top == 1 and style.border_width_bottom == 1 and style.border_width_left == 1 and style.border_width_right == 1, "%s %s: slip has a thin 1px edge" % [dims, tag])
		check(style.border_color.r > style.border_color.b and style.border_color.a > 0.3, "%s %s: slip edge is apricot" % [dims, tag])
		check(style.corner_radius_top_left >= 8 and style.corner_radius_bottom_right >= 8, "%s %s: slip has rounded corners" % [dims, tag])
		for backdrop: Color in [Color.BLACK, Color.WHITE, Color("3a2a20"), Color("7a5a3a")]:
			var surface := backdrop.lerp(Color(paper, 1.0), paper.a)
			var ratio := _contrast(ink, surface)
			check(ratio >= MIN_CONTRAST, "%s %s: text on slip over %s reads at %.2f:1" % [dims, tag, backdrop.to_html(false), ratio])
	# Fitted to the text: covers it with padding, not wider than the label, centred.
	var font := line.get_theme_font("font")
	var text_size := font.get_string_size(line.text, HORIZONTAL_ALIGNMENT_LEFT, -1, line.get_theme_font_size("font_size"))
	var rect := Rect2(slip.position, slip.size)
	var label_rect := Rect2(Vector2.ZERO, line.size)
	check(label_rect.grow(0.01).encloses(rect), "%s %s: slip %s stays inside the line box %s" % [dims, tag, rect, line.size])
	var room := minf(line.size.x, text_size.x + MIN_PAD_X * 2.0)
	check(rect.size.x >= room - EPS, "%s %s: slip %.1f covers text %.1f plus padding" % [dims, tag, rect.size.x, text_size.x])
	check(rect.size.x <= text_size.x + 40.0, "%s %s: slip hugs the text rather than spanning the line box (%.1f vs text %.1f)" % [dims, tag, rect.size.x, text_size.x])
	check(rect.size.y >= minf(line.size.y, text_size.y) - EPS, "%s %s: slip is at least one text line tall" % [dims, tag])
	check(absf(rect.get_center().x - label_rect.get_center().x) <= EPS and absf(rect.get_center().y - label_rect.get_center().y) <= EPS, "%s %s: slip is centred on the line" % [dims, tag])
	check(line.vertical_alignment == VERTICAL_ALIGNMENT_CENTER, "%s %s: text is vertically centred on the slip" % [dims, tag])
	# On screen: inside the margin, above the print, never over the photo.
	var global := slip.get_global_rect()
	var viewport := Vector2(dims)
	check(global.position.x >= VIEW_MARGIN - EPS and global.position.y >= VIEW_MARGIN - EPS and global.end.x <= viewport.x - VIEW_MARGIN + EPS and global.end.y <= viewport.y - VIEW_MARGIN + EPS,
		"%s %s: slip %s inside the screen margin" % [dims, tag, global])
	check(global.end.y <= card.get_global_rect().position.y + EPS, "%s %s: slip stays above the print" % [dims, tag])


func _check_fade(dims: Vector2i, language: String) -> void:
	var line: Label = arrival.get_node("ShutterCaption")
	var slip := arrival.get_node_or_null("ShutterCaption/ShutterPaper") as CanvasItem
	if slip == null:
		check(false, "%s %s: no slip to fade" % [language, dims])
		return
	var tween: Tween = arrival.get("_tween")
	check(tween != null, "%s %s: normal print has its fade tween" % [language, dims])
	if tween == null:
		return
	tween.pause()
	tween.custom_step(1.45)
	var faded := line.modulate.a
	check(faded < 0.9 and faded > 0.0, "%s %s: line is mid-fade (a=%.2f)" % [language, dims, faded])
	check(slip.get_parent() == line and is_equal_approx(slip.modulate.a, 1.0), "%s %s: slip fades with the line, not on its own" % [language, dims])


static func _luminance(c: Color) -> float:
	var channel := func(v: float) -> float:
		return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * channel.call(c.r) + 0.7152 * channel.call(c.g) + 0.0722 * channel.call(c.b)


static func _contrast(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


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
		print("[photo-arrival-shutter-paper] PASS: %d checks" % checks)
	else:
		for failure in failures:
			printerr("[photo-arrival-shutter-paper] " + failure)
		print("[photo-arrival-shutter-paper] FAIL: %d failures across %d checks" % [failures.size(), checks])
	root.get_node("AudioDirector").call("release_streams")
	quit(0 if failures.is_empty() else 1)
