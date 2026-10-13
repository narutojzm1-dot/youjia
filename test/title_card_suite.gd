extends SceneTree

## REQ-20261005-028: the title screen text sits on a soft paper card so the
## subtitle, tagline and controls hint stay readable over the pressed-flower
## art at phone sizes. The subtitle uses a deeper apricot that reaches 4.5:1
## on PAPER. Text, font sizes and buttons are unchanged.

const PAPER := Color("fff6e8")
const VIEWPORTS := [Vector2i(390, 844), Vector2i(844, 390), Vector2i(1280, 720), Vector2i(360, 640), Vector2i(700, 400), Vector2i(320, 568), Vector2i(280, 653)]

var checks := 0
var failures: Array[String] = []
var main


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var i18n = root.get_node("/root/I18n")
	var original_locale: String = i18n.get_locale()
	for dims in VIEWPORTS:
		root.size = dims
		main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		await _settle()
		main.set_process(false)
		_check_style(dims)
		for locale in ["zh-CN", "en"]:
			i18n.set_locale(locale)
			await _settle()
			_check_layout("%s %s" % [dims, locale])
		main.queue_free()
		await process_frame
	await _check_resize_and_return()
	i18n.set_locale(original_locale)
	_finish()


func _settle() -> void:
	for i in 4:
		await process_frame


func _luminance(c: Color) -> float:
	var out := 0.0
	var weights := [0.2126, 0.7152, 0.0722]
	var channels := [c.r, c.g, c.b]
	for i in 3:
		var v: float = channels[i]
		v = v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
		out += weights[i] * v
	return out


func _contrast(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _grect(c: Control) -> Rect2:
	return c.get_global_rect()


func _check_style(dims: Vector2i) -> void:
	var card: Panel = main.get("_title_card")
	_check(card != null, "%s title card exists" % dims)
	if card == null:
		return
	var style = card.get_theme_stylebox("panel")
	_check(style is StyleBoxFlat, "%s title card has a flat paper style" % dims)
	if style is StyleBoxFlat:
		_check(style.bg_color.a >= 0.8, "%s card mostly opaque (a=%.2f)" % [dims, style.bg_color.a])
		_check(Color(style.bg_color, 1.0).is_equal_approx(PAPER), "%s card uses PAPER" % dims)
	_check(card.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s card ignores taps" % dims)
	var column: Control = main._title_label.get_parent()
	_check(card.get_parent() == column.get_parent() and card.get_index() < column.get_index(), "%s card drawn behind the title column" % dims)
	var sub: Label = main._subtitle_label
	var ratio := _contrast(sub.get_theme_color("font_color"), PAPER)
	_check(ratio >= 4.5, "%s subtitle contrast on PAPER %.2f >= 4.5" % [dims, ratio])
	_check(sub.get_theme_font_size("font_size") == 18, "%s subtitle font size unchanged (18)" % dims)


func _check_layout(tag: String) -> void:
	var card: Panel = main.get("_title_card")
	if card == null:
		_check(false, "%s title card exists" % tag)
		return
	_check(main._title_screen.visible, "%s title screen visible" % tag)
	_check(card.visible, "%s title card visible" % tag)
	var c := _grect(card)
	var screen := Rect2(Vector2.ZERO, main.size)
	_check(screen.encloses(c), "%s card on screen %s in %s" % [tag, c, screen.size])
	for node in [main._title_label, main._subtitle_label, main._tagline_label, main._play_button, main._album_button, main._licenses_button, main._title_hint]:
		var n: Control = node
		if not n.visible:
			continue
		var r := _grect(n)
		_check(c.grow(0.5).encloses(r), "%s card covers %s %s" % [tag, n.name if not (n is Label or n is Button) else n.text.left(12), r])
	var tag_label: Label = main._tagline_label
	_check(tag_label.get_minimum_size().y <= tag_label.size.y + 0.5, "%s tagline fully shown" % tag)
	var hint: Label = main._title_hint
	_check(hint.get_minimum_size().y <= hint.size.y + 0.5, "%s controls hint fully shown" % tag)
	# The card hugs content; it is not a full-screen wash.
	_check(c.size.y < main.size.y - 8.0 or main.size.y < 500.0, "%s card hugs content height %.0f of %.0f" % [tag, c.size.y, main.size.y])
	_check(c.size.x <= minf(480.0, main.size.x - 40.0) + 36.5, "%s card no wider than column + padding" % tag)
	# Play button still takes a tap through the card.
	var play: Button = main._play_button
	var hits := [false]
	var cb := func() -> void: hits[0] = true
	play.pressed.connect(cb)
	play.pressed.disconnect(main._on_play_pressed)
	var center := _grect(play).get_center()
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = center
		e.global_position = center
		root.push_input(e, true)
	play.pressed.disconnect(cb)
	play.pressed.connect(main._on_play_pressed)
	_check(hits[0], "%s play button still receives a click through the card" % tag)


func _check_resize_and_return() -> void:
	root.size = Vector2i(844, 390)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _settle()
	main.set_process(false)
	for dims in [Vector2i(390, 844), Vector2i(1280, 720), Vector2i(844, 390)]:
		root.size = dims
		await _settle()
		_check_layout("resize->%s" % dims)
	await main._start_holiday()
	await _settle()
	_check(not main._title_screen.visible, "card hidden with the title screen during play")
	main._show_title(false)
	await _settle()
	_check_layout("back to title 844x390")
	main.queue_free()
	await process_frame


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: ", label)


func _finish() -> void:
	if failures.is_empty():
		print("title_card suite: %d checks passed" % checks)
		quit(0)
	else:
		print("title_card suite: %d of %d checks FAILED" % [failures.size(), checks])
		quit(1)
