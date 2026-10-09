extends SceneTree

## REQ-20261006-036: the warm paper buttons built by Main._soft_button() (title,
## pause, leave-confirmation, album, save retry) only set the normal and hover
## text colours. Keyboard focus and pressed fell back to Godot's default
## near-white text (about 1.1:1 on CREAM), so after clicking a button that keeps
## its page open (for example the pause page music toggle) and moving the mouse
## away, its label all but vanished; the focus box was a 3px pale lavender that
## covered the fill (about 1.8:1). Every text state now keeps >= 4.5:1 on the
## background drawn in that state, hover/hover-pressed stay darker than normal,
## and focus is an unfilled 2px TITLE_ACCENT ring drawn just outside the button
## (>= 3:1 on the button and on the panel behind it) so the normal fill and
## apricot border still show. Size, copy, layout and behaviour are unchanged.

const VIEWPORTS := [Vector2i(390, 844), Vector2i(360, 640), Vector2i(568, 320), Vector2i(844, 390), Vector2i(1280, 720)]
const TEXT_MIN := 4.5
const RING_MIN := 3.0
const EPS := 0.51
const BUTTONS := ["_play_button", "_album_button", "_resume_button", "_restart_button", "_pause_title_button", "_music_toggle", "_ambience_toggle", "_mute_toggle", "_confirm_accept_button", "_confirm_cancel_button", "_album_previous_button", "_album_next_button", "_album_back_button", "_save_retry_button"]
## [text colour, stylebox drawn underneath in that state]
const STATES := [["font_color", "normal"], ["font_hover_color", "hover"], ["font_focus_color", "normal"], ["font_pressed_color", "pressed"], ["font_hover_pressed_color", "pressed"]]

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
			for name: String in BUTTONS:
				_check_theme(main.get(name), "%s %s %s" % [dims, locale, name])
			await _check_paths(dims, locale)
			await _back_to_title()
		i18n.set_locale(original_locale)
		main.queue_free()
		await process_frame
	i18n.set_locale(original_locale)
	_finish()


func _spawn(dims: Vector2i) -> void:
	root.size = dims
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _settle()


func _settle() -> void:
	for i in 4:
		await process_frame


static func _lum(c: Color) -> float:
	var l := Color(c.r, c.g, c.b).srgb_to_linear()
	return 0.2126 * l.r + 0.7152 * l.g + 0.0722 * l.b


static func contrast(a: Color, b: Color) -> float:
	var la := _lum(a)
	var lb := _lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _check_theme(button: Button, tag: String) -> void:
	_check(button != null, "%s: button exists" % tag)
	if button == null:
		return
	_check(button.focus_mode == Control.FOCUS_ALL, "%s: keyboard focus still allowed" % tag)
	_check(button.get_theme_font_size("font_size") == 16 or button.has_theme_font_size_override("font_size"), "%s: font size kept" % tag)
	for pair: Array in STATES:
		var color := button.get_theme_color(pair[0])
		var box := button.get_theme_stylebox(pair[1]) as StyleBoxFlat
		_check(box != null, "%s: %s stylebox is flat" % [tag, pair[1]])
		if box == null:
			continue
		_check(color.a >= 0.99, "%s: %s opaque" % [tag, pair[0]])
		var ratio := contrast(color, box.bg_color)
		_check(ratio >= TEXT_MIN, "%s: %s #%s on %s #%s contrast %.2f >= %.1f" % [tag, pair[0], color.to_html(false), pair[1], box.bg_color.to_html(false), ratio, TEXT_MIN])
	var normal := button.get_theme_color("font_color")
	_check(_lum(button.get_theme_color("font_hover_color")) <= _lum(normal), "%s: hover not lighter than normal" % tag)
	_check(_lum(button.get_theme_color("font_hover_pressed_color")) <= _lum(normal), "%s: hover-pressed not lighter than normal" % tag)
	var ring := button.get_theme_stylebox("focus") as StyleBoxFlat
	_check(ring != null, "%s: focus ring is a StyleBoxFlat" % tag)
	if ring == null:
		return
	_check(not ring.draw_center or ring.bg_color.a <= 0.01, "%s: focus ring has no fill, normal paper still shows" % tag)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_check(ring.get_border_width(side) >= 2, "%s: focus ring side %d >= 2px" % [tag, side])
		_check(ring.get_expand_margin(side) >= 1.0, "%s: focus ring side %d drawn outside the button" % [tag, side])
	_check(ring.border_color.a >= 0.99, "%s: focus ring opaque" % tag)
	var backs: Array = [(button.get_theme_stylebox("normal") as StyleBoxFlat).bg_color]
	backs.append_array(_panel_backgrounds(button))
	for bg: Color in backs:
		var r := contrast(ring.border_color, bg)
		_check(r >= RING_MIN, "%s: focus ring #%s on #%s contrast %.2f >= %.1f" % [tag, ring.border_color.to_html(false), bg.to_html(false), r, RING_MIN])


## Colour of the nearest panel behind the button: solid, and for a translucent
## panel also composited over black (the darkest it can get).
func _panel_backgrounds(button: Control) -> Array:
	var node: Node = button.get_parent()
	while node != null and node is Control:
		if node is PanelContainer:
			var style := (node as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
			if style != null and style.bg_color.a > 0.0:
				var bg := style.bg_color
				var out: Array = [Color(bg.r, bg.g, bg.b)]
				if bg.a < 0.99:
					out.append(Color(bg.r * bg.a, bg.g * bg.a, bg.b * bg.a))
				return out
		node = node.get_parent()
	return []


func _ring_inside_view(button: Button, tag: String) -> void:
	var ring := button.get_theme_stylebox("focus") as StyleBoxFlat
	var r := button.get_global_rect().grow_individual(ring.expand_margin_left, ring.expand_margin_top, ring.expand_margin_right, ring.expand_margin_bottom)
	var view := Rect2(Vector2.ZERO, main.size)
	_check(r.position.x >= -EPS and r.position.y >= -EPS and r.end.x <= view.end.x + EPS and r.end.y <= view.end.y + EPS, "%s: focus ring %s inside viewport %s" % [tag, r, view])


func _focus_reads(button: Button, tag: String) -> void:
	button.grab_focus()
	await process_frame
	_check(button.has_focus(), "%s: focus lands" % tag)
	_check(button.is_visible_in_tree() and not button.text.is_empty(), "%s: visible with text '%s'" % [tag, button.text])
	var shown := button.get_theme_color("font_focus_color")
	var under := (button.get_theme_stylebox("normal") as StyleBoxFlat).bg_color
	_check(contrast(shown, under) >= TEXT_MIN, "%s: focused label #%s readable on #%s" % [tag, shown.to_html(false), under.to_html(false)])
	_ring_inside_view(button, tag)


func _check_paths(dims: Vector2i, locale: String) -> void:
	var tag := "%s %s" % [dims, locale]
	_check(main._screen == "title", "%s: starts on title" % tag)
	await _focus_reads(main._play_button, tag + " title play")
	await _focus_reads(main._album_button, tag + " title album")
	await main._start_holiday()
	await _settle()
	main._toggle_pause()
	await _settle()
	_check(main._pause_screen.visible, "%s: pause page open" % tag)
	await _focus_reads(main._music_toggle, tag + " pause music")
	var before: String = main._music_toggle.text
	main._music_toggle.pressed.emit()
	await _settle()
	_check(main._pause_screen.visible, "%s: pause stays open after toggling music" % tag)
	_check(main._music_toggle.has_focus(), "%s: toggled button keeps focus (the case that went white)" % tag)
	_check(main._music_toggle.text != before, "%s: music toggle still works (%s -> %s)" % [tag, before, main._music_toggle.text])
	main._music_toggle.pressed.emit()
	await _settle()
	_check(main._music_toggle.text == before, "%s: music toggle restored" % tag)
	for name: String in ["_resume_button", "_restart_button", "_pause_title_button", "_ambience_toggle", "_mute_toggle"]:
		await _focus_reads(main.get(name), "%s pause %s" % [tag, name])
	main._request_destructive_action("restart")
	await _settle()
	_check(main._confirm_screen.visible, "%s: leave confirmation open" % tag)
	await _focus_reads(main._confirm_accept_button, tag + " confirm accept")
	await _focus_reads(main._confirm_cancel_button, tag + " confirm cancel")
	main._cancel_destructive_action()
	await _settle()
	_check(not main._confirm_screen.visible and main._pause_screen.visible, "%s: cancel returns to pause" % tag)


func _back_to_title() -> void:
	if main._pause_screen.visible:
		main._toggle_pause()
		await _settle()
	main._show_title()
	await _settle()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	if failures.is_empty():
		print("PASS: soft_button_focus_contrast %d checks" % checks)
		quit(0)
	else:
		print("FAIL: soft_button_focus_contrast %d/%d failed" % [failures.size(), checks])
		for f in failures.slice(0, 40):
			print("  - " + f)
		quit(1)
