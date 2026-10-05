extends SceneTree

## REQ-20261006-035 (#413): the title-page open-source licenses link is a flat
## text button on the translucent paper card. Only its normal colour was set
## (MUTED 8a7060, about 4.3:1 on PAPER), so hover, keyboard focus and pressed
## fell back to Godot's default near-white text and a near-white focus ring,
## which nearly vanish on the light card (seen after returning from the Web
## licenses tab). Every state now uses a dark ink colour that keeps >= 4.5:1
## both on solid PAPER and on the card's own colour composited over black
## (the darkest the 84% card can get), hover is darker than normal, and focus
## draws a 2px TITLE_ACCENT outline (>= 3:1) without a fill. Size, copy, order,
## layout and the open/return behaviour are unchanged.

const VIEWPORTS := [Vector2i(568, 320), Vector2i(640, 300), Vector2i(844, 390), Vector2i(1280, 720), Vector2i(390, 844)]
const TEXT_MIN := 4.5
const RING_MIN := 3.0
const STATES := ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]
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
	for dims in VIEWPORTS:
		await _spawn(dims)
		for locale in ["zh-CN", "en"]:
			i18n.set_locale(locale)
			await _settle()
			_check_link(dims, "%s %s" % [dims, locale])
		i18n.set_locale(original_locale)
		await _check_open_and_return(dims)
		main.queue_free()
		await process_frame
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


static func _lum(c: Color) -> float:
	var l := Color(c.r, c.g, c.b).srgb_to_linear()
	return 0.2126 * l.r + 0.7152 * l.g + 0.0722 * l.b


static func contrast(a: Color, b: Color) -> float:
	var la := _lum(a)
	var lb := _lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _card_backgrounds() -> Array:
	var style: StyleBoxFlat = main._title_card.get_theme_stylebox("panel") as StyleBoxFlat
	var bg: Color = style.bg_color
	# Light end: solid paper. Dark end: the translucent card over pure black.
	return [Color(bg.r, bg.g, bg.b), Color(bg.r * bg.a, bg.g * bg.a, bg.b * bg.a)]


func _inside(inner: Rect2, outer: Rect2) -> bool:
	return inner.position.x >= outer.position.x - EPS and inner.position.y >= outer.position.y - EPS \
		and inner.end.x <= outer.end.x + EPS and inner.end.y <= outer.end.y + EPS


func _check_link(dims: Vector2i, tag: String) -> void:
	var link: Button = main._licenses_button
	var card: Control = main._title_card
	_check(main._title_screen.visible and card.visible, "%s: title screen and card showing" % tag)
	_check(link.is_visible_in_tree() and not link.text.is_empty(), "%s: licenses link visible with text '%s'" % [tag, link.text])
	_check(link.flat, "%s: link stays a flat text button" % tag)
	_check(link.focus_mode == Control.FOCUS_ALL, "%s: link reachable by keyboard focus" % tag)
	_check(_inside(link.get_global_rect(), card.get_global_rect()), "%s: link %s on the paper card %s" % [tag, link.get_global_rect(), card.get_global_rect()])
	var expect_size := 12 if dims.y <= 360 else 14
	_check(link.get_theme_font_size("font_size") == expect_size, "%s: link font size %d unchanged (got %d)" % [tag, expect_size, link.get_theme_font_size("font_size")])
	var backgrounds := _card_backgrounds()
	for state: String in STATES:
		var color := link.get_theme_color(state)
		_check(color.a >= 0.99, "%s: %s opaque (a=%.2f)" % [tag, state, color.a])
		for bg: Color in backgrounds:
			var ratio := contrast(color, bg)
			_check(ratio >= TEXT_MIN, "%s: %s #%s on #%s contrast %.2f >= %.1f" % [tag, state, color.to_html(false), bg.to_html(false), ratio, TEXT_MIN])
	var normal := link.get_theme_color("font_color")
	var hover := link.get_theme_color("font_hover_color")
	_check(_lum(hover) < _lum(normal), "%s: hover #%s darker than normal #%s" % [tag, hover.to_html(false), normal.to_html(false)])
	var ring := link.get_theme_stylebox("focus") as StyleBoxFlat
	_check(ring != null, "%s: focus ring is a StyleBoxFlat" % tag)
	if ring == null:
		return
	_check(not ring.draw_center or ring.bg_color.a <= 0.01, "%s: focus ring has no fill" % tag)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_check(ring.get_border_width(side) >= 2, "%s: focus ring side %d >= 2px (got %d)" % [tag, side, ring.get_border_width(side)])
	_check(ring.border_color.a >= 0.99, "%s: focus ring opaque" % tag)
	for bg: Color in backgrounds:
		var r := contrast(ring.border_color, bg)
		_check(r >= RING_MIN, "%s: focus ring #%s on #%s contrast %.2f >= %.1f" % [tag, ring.border_color.to_html(false), bg.to_html(false), r, RING_MIN])


func _dialogs() -> Array:
	var found: Array = []
	for node in root.find_children("OpenSourceLicensesDialog", "AcceptDialog", true, false):
		if not node.is_queued_for_deletion():
			found.append(node)
	return found


func _check_open_and_return(dims: Vector2i) -> void:
	var tag := "%s open/return" % dims
	var link: Button = main._licenses_button
	link.grab_focus()
	await process_frame
	_check(link.has_focus(), "%s: keyboard focus lands on link" % tag)
	link.pressed.emit()
	await _settle()
	var dialogs := _dialogs()
	_check(dialogs.size() == 1, "%s: one licenses dialog opens (got %d)" % [tag, dialogs.size()])
	for dialog: AcceptDialog in dialogs:
		_check(dialog.visible, "%s: licenses dialog visible" % tag)
		dialog.get_ok_button().pressed.emit()
	await _settle()
	_check(_dialogs().is_empty(), "%s: dialog closes on OK" % tag)
	_check(main._screen == "title" and main._title_screen.visible, "%s: back on the title screen" % tag)
	_check(link.is_visible_in_tree() and not link.disabled, "%s: link still usable after return" % tag)


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	if failures.is_empty():
		print("PASS: title_licenses_link_contrast %d checks" % checks)
		quit(0)
	else:
		print("FAIL: title_licenses_link_contrast %d/%d failed" % [failures.size(), checks])
		for f in failures:
			print("  - " + f)
		quit(1)
