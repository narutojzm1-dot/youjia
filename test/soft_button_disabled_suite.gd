extends SceneTree

## REQ-20261006-038: the warm paper buttons built by Main._soft_button() had no
## disabled styling, so whenever one was disabled (album page-turn buttons on
## the first/last spread or with no photos yet, "再确认一次" while a save is
## being written, the backup-recovery buttons while busy) Godot drew its default
## grey-brown slab (#aa9d8b) with half-transparent pale text, about 1.4:1: a
## blank grey brick on the warm paper UI. Disabled now has its own warm paper
## fill, a thinner soft tan edge and a muted ink label that still reads
## (>= 4.5:1) but stays lighter than the enabled label, with the same size,
## corner radius, copy and behaviour.

const VIEWPORTS := [Vector2i(390, 844), Vector2i(360, 640), Vector2i(568, 320), Vector2i(844, 390), Vector2i(1280, 720)]
const TEXT_MIN := 4.5
const GODOT_DEFAULT_FILL := Color(0.1, 0.1, 0.1, 0.3)
const BUTTONS := ["_play_button", "_album_button", "_resume_button", "_restart_button", "_pause_title_button", "_music_toggle", "_ambience_toggle", "_mute_toggle", "_confirm_accept_button", "_confirm_cancel_button", "_album_previous_button", "_album_next_button", "_album_back_button", "_save_retry_button"]

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
			for fresh: Button in [main._soft_button(), main._chip_button()]:
				_check_theme(fresh, "%s %s fresh %s" % [dims, locale, "chip" if fresh.custom_minimum_size.y < 44 else "soft"])
				fresh.free()
			await _check_album(dims, locale)
			await _check_save_retry(dims, locale)
			main._show_title()
			await _settle()
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


static func _same(a: Color, b: Color) -> bool:
	return a.is_equal_approx(b)


func _check_theme(button: Button, tag: String) -> void:
	_check(button != null, "%s: button exists" % tag)
	if button == null:
		return
	_check(button.has_theme_stylebox_override("disabled"), "%s: has its own disabled stylebox (not Godot default)" % tag)
	_check(button.has_theme_color_override("font_disabled_color"), "%s: has its own disabled text colour" % tag)
	var box := button.get_theme_stylebox("disabled") as StyleBoxFlat
	var normal := button.get_theme_stylebox("normal") as StyleBoxFlat
	_check(box != null and normal != null, "%s: disabled and normal are StyleBoxFlat" % tag)
	if box == null or normal == null:
		return
	var fill := box.bg_color
	_check(box.draw_center and fill.a >= 0.99, "%s: disabled fill opaque (#%s a=%.2f)" % [tag, fill.to_html(false), fill.a])
	_check(not _same(fill, GODOT_DEFAULT_FILL) and _lum(fill) > 0.6, "%s: disabled fill is light warm paper, not the grey slab (#%s)" % [tag, fill.to_html(false)])
	_check(fill.r >= fill.g and fill.g >= fill.b, "%s: disabled fill is warm (r>=g>=b) #%s" % [tag, fill.to_html(false)])
	_check(not _same(fill, normal.bg_color), "%s: disabled fill differs from enabled fill" % tag)
	var text := button.get_theme_color("font_disabled_color")
	_check(text.a >= 0.99, "%s: disabled text opaque (a=%.2f)" % [tag, text.a])
	var ratio := contrast(text, fill)
	_check(ratio >= TEXT_MIN, "%s: disabled text #%s on #%s contrast %.2f >= %.1f" % [tag, text.to_html(false), fill.to_html(false), ratio, TEXT_MIN])
	var enabled_text := button.get_theme_color("font_color")
	var enabled_ratio := contrast(enabled_text, normal.bg_color)
	_check(ratio < enabled_ratio, "%s: disabled label quieter than enabled (%.2f < %.2f)" % [tag, ratio, enabled_ratio])
	_check(_lum(text) > _lum(enabled_text), "%s: disabled text lighter than enabled text" % tag)
	_check(not _same(box.border_color, normal.border_color), "%s: disabled edge is not the enabled apricot edge" % tag)
	_check(box.border_color.a >= 0.99 and _lum(box.border_color) < _lum(fill), "%s: disabled edge visible and darker than its fill" % tag)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_check(box.get_border_width(side) >= 1 and box.get_border_width(side) <= normal.get_border_width(side), "%s: disabled edge side %d 1..%dpx" % [tag, side, normal.get_border_width(side)])
		_check(is_equal_approx(box.get_content_margin(side), normal.get_content_margin(side)), "%s: disabled content margin side %d unchanged" % [tag, side])
	for corner in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_RIGHT, CORNER_BOTTOM_LEFT]:
		_check(box.get_corner_radius(corner) == normal.get_corner_radius(corner), "%s: disabled corner %d keeps the enabled radius" % [tag, corner])


func _check_disabled_shows(button: Button, tag: String) -> void:
	_check(button.is_visible_in_tree(), "%s: visible" % tag)
	_check(not button.text.is_empty(), "%s: label kept ('%s')" % [tag, button.text])
	var enabled_size := button.size
	_check(button.disabled, "%s: is disabled" % tag)
	button.disabled = false
	await process_frame
	_check(button.size.is_equal_approx(enabled_size), "%s: same size enabled/disabled (%s vs %s)" % [tag, enabled_size, button.size])
	button.disabled = true
	await process_frame


func _check_album(dims: Vector2i, locale: String) -> void:
	var tag := "%s %s album" % [dims, locale]
	await main._start_holiday()
	await _settle()
	main._show_album()
	await _settle()
	_check(main._album_screen.visible and main._album_panel.is_visible_in_tree(), "%s: album open" % tag)
	if main._album_entries.is_empty():
		await _check_disabled_shows(main._album_previous_button, tag + " previous (no photos)")
		await _check_disabled_shows(main._album_next_button, tag + " next (no photos)")
	_check(not main._album_back_button.disabled, "%s: close stays enabled" % tag)
	var hits := [0]
	var count := func() -> void: hits[0] += 1
	main._album_previous_button.pressed.connect(count)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = main._album_previous_button.get_global_rect().get_center()
	click.pressed = true
	root.push_input(click)
	var release := click.duplicate()
	release.pressed = false
	root.push_input(release)
	await _settle()
	_check(hits[0] == 0, "%s: disabled previous still ignores a click" % tag)
	main._album_previous_button.pressed.disconnect(count)
	main._hide_album()
	await _settle()


func _check_save_retry(dims: Vector2i, locale: String) -> void:
	var tag := "%s %s save retry" % [dims, locale]
	main._show_save_pending(false)
	await _settle()
	for state in ["writing", "acknowledging", "resolving"]:
		main._on_save_state_changed(state)
		await _settle()
		await _check_disabled_shows(main._save_retry_button, "%s while %s" % [tag, state])
	main._on_save_state_changed("failed")
	await _settle()
	_check(not main._save_retry_button.disabled, "%s: enabled again after the write settles" % tag)
	if main._save_status_panel != null:
		main._save_status_panel.hide()
	main._save_problem_active = false


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	if failures.is_empty():
		print("PASS: soft_button_disabled %d checks" % checks)
		quit(0)
	else:
		print("FAIL: soft_button_disabled %d/%d failed" % [failures.size(), checks])
		for f in failures.slice(0, 40):
			print("  - " + f)
		quit(1)
