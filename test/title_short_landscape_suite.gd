extends SceneTree

## REQ-20261005-031: on short landscape phones (568x320, or a 360/390-tall
## phone in landscape with the browser bars taking 40-60px) the title column
## needed 321px. Its controls hint dropped below the screen and off the paper
## card. Screens up to 360px tall now use a tighter layout: 8px top/bottom
## margin, 4px gaps, 24px title, 15px subtitle, 14px button text in 40px-tall
## main buttons, and a 12px licenses link. The whole column now stays on
## screen and on the card. Taller screens keep the previous sizes exactly.
## Copy, order, colours and button behaviour are unchanged.

const TIGHT := [Vector2i(568, 320), Vector2i(568, 300), Vector2i(640, 360), Vector2i(640, 300), Vector2i(740, 360), Vector2i(844, 340), Vector2i(800, 360)]
const REGULAR := [Vector2i(667, 375), Vector2i(844, 390), Vector2i(700, 400), Vector2i(1280, 720), Vector2i(390, 844), Vector2i(360, 640), Vector2i(320, 568)]
const EDGE := 4.0
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
	for dims in TIGHT + REGULAR:
		await _spawn(dims)
		for locale in ["zh-CN", "en"]:
			i18n.set_locale(locale)
			await _settle()
			_check_title(dims, "%s %s" % [dims, locale])
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
	for i in 4:
		await process_frame


func _inside(inner: Rect2, outer: Rect2) -> bool:
	return inner.position.x >= outer.position.x - EPS and inner.position.y >= outer.position.y - EPS \
		and inner.end.x <= outer.end.x + EPS and inner.end.y <= outer.end.y + EPS


func _nodes() -> Array:
	return [main._title_label, main._subtitle_label, main._tagline_label, main._play_button, main._album_button, main._licenses_button, main._title_hint]


func _check_title(dims: Vector2i, tag: String) -> void:
	var tight: bool = dims.y <= 360
	var short: bool = dims.y < 500
	var screen := Rect2(Vector2.ZERO, Vector2(dims))
	var safe := screen.grow(-EDGE)
	var card: Control = main._title_card
	var c := card.get_global_rect()
	_check(main._title_screen.visible and card.visible, "%s: title screen and card showing" % tag)
	_check(_inside(c, screen), "%s: card %s on screen" % [tag, c])
	var content := Rect2()
	var first := true
	for node in _nodes():
		var n: Control = node
		_check(n.is_visible_in_tree(), "%s: %s visible" % [tag, n.name])
		var r := n.get_global_rect()
		var label: String = n.text.left(12).replace("\n", "/")
		_check(_inside(r, safe), "%s: '%s' %s fully on screen with %dpx edge" % [tag, label, r, int(EDGE)])
		_check(_inside(r, c), "%s: '%s' %s on the paper card %s" % [tag, label, r, c])
		_check(n.get_combined_minimum_size().y <= r.size.y + EPS, "%s: '%s' not squashed (min %.0f > %.0f)" % [tag, label, n.get_combined_minimum_size().y, r.size.y])
		content = r if first else content.merge(r)
		first = false
	_check(absf(content.get_center().y - dims.y * 0.5) <= 1.0, "%s: column content %s vertically centred" % [tag, content])
	for label: Label in [main._tagline_label, main._title_hint]:
		_check(label.get_visible_line_count() >= label.get_line_count(), "%s: every line of '%s' visible (%d/%d)" % [tag, label.text.left(10), label.get_visible_line_count(), label.get_line_count()])
	for button: Button in [main._play_button, main._album_button]:
		var r := button.get_global_rect()
		_check(r.size.x >= 260.0 - EPS and r.size.y >= (40.0 if tight else 44.0) - EPS, "%s: '%s' keeps a %dx%d tap target (%s)" % [tag, button.text, 260, 40 if tight else 44, r.size])
	var column: Control = main._title_label.get_parent()
	var expect := {
		"separation": 4 if tight else (8 if short else 14),
		"title": 24 if tight else (28 if short else 40),
		"subtitle": 15 if tight else 18,
		"tagline": 14 if short else 16,
		"hint": 12 if short else 14,
		"button": 14 if tight else 16,
		"licenses": 12 if tight else 14,
		"button_h": 40.0 if tight else 44.0,
	}
	var got := {
		"separation": column.get_theme_constant("separation"),
		"title": main._title_label.get_theme_font_size("font_size"),
		"subtitle": main._subtitle_label.get_theme_font_size("font_size"),
		"tagline": main._tagline_label.get_theme_font_size("font_size"),
		"hint": main._title_hint.get_theme_font_size("font_size"),
		"button": main._play_button.get_theme_font_size("font_size"),
		"licenses": main._licenses_button.get_theme_font_size("font_size"),
		"button_h": main._album_button.custom_minimum_size.y,
	}
	for key in expect:
		_check(is_equal_approx(float(got[key]), float(expect[key])), "%s: %s %s == %s (%s)" % [tag, key, got[key], expect[key], "tight" if tight else ("short" if short else "regular")])
	_check(main._title_label.text == i18n.t("app.title") and main._subtitle_label.text == i18n.t("app.subtitle"), "%s: copy unchanged" % tag)


func _check_resize_and_play() -> void:
	await _spawn(Vector2i(1280, 720))
	i18n.set_locale("en")
	for dims in [Vector2i(568, 320), Vector2i(844, 390), Vector2i(640, 300), Vector2i(390, 844), Vector2i(844, 340), Vector2i(1280, 720)]:
		root.size = dims
		await _settle()
		_check_title(dims, "resize->%s en" % [dims])
	root.size = Vector2i(568, 320)
	await _settle()
	# A real click on the tightened play button still starts the holiday.
	var center: Vector2 = main._play_button.get_global_rect().get_center()
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = center
		e.global_position = center
		root.push_input(e, true)
	await _settle()
	_check(main._screen == "game" and not main._title_screen.visible, "568x320: clicking the play button enters the yard")
	main._show_title(false)
	await _settle()
	_check_title(Vector2i(568, 320), "back to title 568x320 en")
	main.queue_free()
	await process_frame


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: ", label)


func _finish() -> void:
	if failures.is_empty():
		print("title_short_landscape suite: %d checks passed" % checks)
		quit(0)
	else:
		print("title_short_landscape suite: %d of %d checks FAILED" % [failures.size(), checks])
		quit(1)
