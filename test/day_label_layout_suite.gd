extends SceneTree

## #338: the holiday-day label sits on a small paper tag right under the pause
## button, so it never overlaps the goal paper (landscape) and stays readable
## over foliage/sky (portrait). Font size and text are unchanged.

const INK := Color("5b4637")
const PAPER := Color("fff6e8")
const VIEWPORTS := [Vector2i(390, 844), Vector2i(844, 390), Vector2i(1280, 720), Vector2i(360, 640), Vector2i(700, 400)]

var checks := 0
var failures: Array[String] = []
var main


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var original_locale: String = root.get_node("/root/I18n").get_locale()
	for dims in VIEWPORTS:
		root.size = dims
		main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		await process_frame
		await process_frame
		main.set_process(false)
		await main._start_holiday()
		main._layout()
		main._refresh_hud()
		_check_style(dims)
		for locale in ["zh-CN", "en"]:
			root.get_node("/root/I18n").set_locale(locale)
			main._world.holiday_day = 99
			main._refresh_hud()
			main._layout()
			_check_layout("%s %s" % [dims, locale])
		main.queue_free()
		await process_frame
	await _check_resize()
	root.get_node("/root/I18n").set_locale(original_locale)
	_finish()


func _rect(c: Control) -> Rect2:
	return Rect2(c.position, c.size)


func _check_style(dims: Vector2i) -> void:
	var d: Label = main._day_label
	var style = d.get_theme_stylebox("normal")
	_check(style is StyleBoxFlat, "%s day label has a paper backing" % dims)
	if style is StyleBoxFlat:
		_check(style.bg_color.a >= 0.85, "%s backing mostly opaque (a=%.2f)" % [dims, style.bg_color.a])
		_check(Color(style.bg_color, 1.0).is_equal_approx(PAPER), "%s backing uses PAPER" % dims)
	_check(d.get_theme_color("font_color").is_equal_approx(INK), "%s day text uses INK for contrast" % dims)
	_check(d.get_theme_font_size("font_size") == 14, "%s day font size unchanged (14)" % dims)
	_check(d.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s day label ignores taps" % dims)


func _check_layout(tag: String) -> void:
	var d: Label = main._day_label
	var day := _rect(d)
	var screen := Rect2(Vector2.ZERO, main.size)
	_check(screen.encloses(day), "%s day label on screen %s" % [tag, day])
	_check(not day.intersects(_rect(main._hint_panel)), "%s day label clear of goal paper %s vs %s" % [tag, day, _rect(main._hint_panel)])
	_check(not day.intersects(_rect(main._hint_label)), "%s day label clear of goal text" % tag)
	for b in [main._pause_button, main._album_chip, main._weather_chip, main._action_button]:
		_check(not day.intersects(_rect(b)), "%s day label clear of %s" % [tag, b.text])
	_check(d.get_minimum_size().x <= day.size.x + 0.5, "%s day text fits its tag (%.0f <= %.0f): %s" % [tag, d.get_minimum_size().x, day.size.x, d.text])
	_check(d.get_minimum_size().y <= day.size.y + 0.5, "%s day tag height holds the text" % tag)
	_check(absf(day.position.x - main._pause_button.position.x) < 0.5 and day.position.y > main._pause_button.position.y + main._pause_button.size.y, "%s day tag hangs under the pause button" % tag)
	_check(day.end.y < main.size.y * 0.5, "%s day tag stays in the top half, away from bottom notice" % tag)


func _check_resize() -> void:
	root.size = Vector2i(844, 390)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.set_process(false)
	await main._start_holiday()
	for dims in [Vector2i(390, 844), Vector2i(1280, 720), Vector2i(844, 390)]:
		root.size = dims
		await process_frame
		await process_frame
		main._layout()
		_check_layout("resize->%s" % dims)
	main.queue_free()
	await process_frame


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: ", label)


func _finish() -> void:
	if failures.is_empty():
		print("day_label_layout suite: %d checks passed" % checks)
		quit(0)
	else:
		print("day_label_layout suite: %d of %d checks FAILED" % [failures.size(), checks])
		quit(1)
