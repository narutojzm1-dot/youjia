extends SceneTree

## REQ-20261007-049: the English shutter line ("The traveler caught this
## little moment.", about 272px at 16px) sits in a label viewport width - 24
## wide, and its paper slip is capped at that label. On a 280px fold cover
## screen the words ran past both paper edges; at 300px the outline touched
## them; at 320px the side padding was 12px instead of 14px. The line now
## steps down to 15/14/13px only when the text plus the slip's side padding
## does not fit; every viewport and language where 16px already fits keeps
## 16px. Position, text, colour and the print's fit layout are unchanged.
## Fixture only: temporary yard world, never loads or writes the player's save.

const VIEWPORTS := [
	Vector2i(1280, 720), Vector2i(1024, 600), Vector2i(412, 915), Vector2i(390, 844), Vector2i(375, 667),
	Vector2i(360, 640), Vector2i(320, 568), Vector2i(320, 480), Vector2i(300, 560), Vector2i(280, 653),
	Vector2i(844, 390), Vector2i(568, 320), Vector2i(640, 300),
]
const LOCALES := ["zh-CN", "en"]
const FULL_SIZE := 16
const MIN_SIZE := 13
## Clear paper left of and right of the ink (outline included).
const MIN_PAD_X := 10.0
const EPS := 0.75

var checks := 0
var failures: Array[String] = []
var arrival: Control
var shrunk_cases := 0


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
				_check_line(dims, "%s reduced=%s" % [language, reduced])
				arrival.dismiss()
	check(shrunk_cases > 0, "at least one narrow English case actually needed a smaller line (%d)" % shrunk_cases)
	# The case that used to overflow: 320 portrait, English.
	locale.call("set_locale", "en")
	root.size = Vector2i(320, 568)
	await _settle()
	arrival.play(snapshot, true)
	await _settle()
	var line: Label = arrival.get_node("ShutterCaption")
	var narrow_size := line.get_theme_font_size("font_size")
	check(narrow_size < FULL_SIZE and narrow_size >= MIN_SIZE, "en 320x568 steps the line down to %d px" % narrow_size)
	# Rotate to landscape while showing: back to full size.
	root.size = Vector2i(568, 320)
	await _settle()
	check(line.get_theme_font_size("font_size") == FULL_SIZE, "rotating to 568x320 restores %d px (got %d)" % [FULL_SIZE, line.get_theme_font_size("font_size")])
	_check_line(Vector2i(568, 320), "en rotated while showing")
	root.size = Vector2i(320, 568)
	await _settle()
	check(line.get_theme_font_size("font_size") == narrow_size, "rotating back to 320x568 shrinks again")
	_check_line(Vector2i(320, 568), "en rotated back while showing")
	# Live language switch at the narrow width.
	locale.call("set_locale", "zh-CN")
	arrival.call("refresh_locale")
	await _settle()
	check(line.get_theme_font_size("font_size") == FULL_SIZE, "switching to Chinese at 320 restores %d px" % FULL_SIZE)
	_check_line(Vector2i(320, 568), "zh after live switch")
	locale.call("set_locale", "en")
	arrival.call("refresh_locale")
	await _settle()
	check(line.get_theme_font_size("font_size") == narrow_size, "switching back to English at 320 shrinks again")
	_check_line(Vector2i(320, 568), "en after live switch")
	arrival.dismiss()
	# Pure helper contract.
	var font := line.get_theme_font("font")
	check(arrival.has_method("shutter_font_size"), "PhotoArrival exposes shutter_font_size")
	if not arrival.has_method("shutter_font_size"):
		locale.call("set_locale", "zh-CN")
		_finish()
		return
	check(int(arrival.call("shutter_font_size", "", font, 10.0)) == FULL_SIZE, "empty text keeps full size")
	check(int(arrival.call("shutter_font_size", line.text, null, 10.0)) == FULL_SIZE, "missing font keeps full size")
	check(int(arrival.call("shutter_font_size", line.text, font, 10.0)) == MIN_SIZE, "impossibly narrow box floors at %d px" % MIN_SIZE)
	check(int(arrival.call("shutter_font_size", line.text, font, 2000.0)) == FULL_SIZE, "wide box keeps full size")
	locale.call("set_locale", "zh-CN")
	_finish()


func _check_line(dims: Vector2i, tag: String) -> void:
	var line: Label = arrival.get_node("ShutterCaption")
	var slip := arrival.get_node_or_null("ShutterCaption/ShutterPaper") as Control
	check(slip != null, "%s %s: slip exists" % [dims, tag])
	if slip == null:
		return
	var fit: Dictionary = arrival.call("fit_layout", Vector2(dims))
	check(line.position.is_equal_approx(fit.shutter_position) and line.size.is_equal_approx(fit.shutter_size), "%s %s: line rect still follows fit_layout" % [dims, tag])
	check(line.text == str(root.get_node("I18n").call("t", "photo.arrival.shutter")), "%s %s: text unchanged" % [dims, tag])
	check(line.get_theme_color("font_color").is_equal_approx(Color("5b4637")), "%s %s: ink unchanged" % [dims, tag])
	var font := line.get_theme_font("font")
	var size := line.get_theme_font_size("font_size")
	var outline := float(line.get_theme_constant("outline_size"))
	var full_width := ceilf(font.get_string_size(line.text, HORIZONTAL_ALIGNMENT_LEFT, -1, FULL_SIZE).x)
	var text := font.get_string_size(line.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	check(size >= MIN_SIZE and size <= FULL_SIZE, "%s %s: size %d within %d..%d" % [dims, tag, size, MIN_SIZE, FULL_SIZE])
	if full_width + 28.0 <= line.size.x:
		check(size == FULL_SIZE, "%s %s: 16px fits, so the line keeps 16px (got %d)" % [dims, tag, size])
	else:
		shrunk_cases += 1
		check(size < FULL_SIZE, "%s %s: 16px does not fit %.0f, so the line steps down (got %d)" % [dims, tag, line.size.x, size])
		check(size == FULL_SIZE - 1 or ceilf(font.get_string_size(line.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size + 1).x) + 28.0 > line.size.x, "%s %s: uses the largest size that fits" % [dims, tag])
	check(line.get_minimum_size().y <= line.size.y + 0.5, "%s %s: still one line inside the label height" % [dims, tag])
	var slip_rect := Rect2(slip.position, slip.size)
	var ink := Rect2((line.size.x - text.x) * 0.5 - outline, 0.0, text.x + outline * 2.0, line.size.y)
	check(Rect2(Vector2.ZERO, line.size).grow(0.01).encloses(slip_rect), "%s %s: slip inside the label" % [dims, tag])
	check(ink.position.x - slip_rect.position.x >= MIN_PAD_X - EPS and slip_rect.end.x - ink.end.x >= MIN_PAD_X - EPS,
		"%s %s: ink %.1f..%.1f has >=%.0fpx paper both sides of slip %.1f..%.1f" % [dims, tag, ink.position.x, ink.end.x, MIN_PAD_X, slip_rect.position.x, slip_rect.end.x])
	check(slip_rect.size.x <= text.x + 40.0, "%s %s: slip still hugs the text" % [dims, tag])
	var global := slip.get_global_rect()
	check(global.position.x >= 8.0 - EPS and global.end.x <= float(dims.x) - 8.0 + EPS, "%s %s: slip inside the screen margin %s" % [dims, tag, global])


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
		print("[photo-arrival-shutter-fit] PASS: %d checks" % checks)
	else:
		for failure in failures:
			printerr("[photo-arrival-shutter-fit] " + failure)
		print("[photo-arrival-shutter-fit] FAIL: %d failures across %d checks" % [failures.size(), checks])
	root.get_node("AudioDirector").call("release_streams")
	quit(0 if failures.is_empty() else 1)
