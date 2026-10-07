extends SceneTree

## REQ-20261006-043: on short screens (height < 500) the pause paper (暂停纸片)
## used to stretch to "screen height - 24". At 844x390 the title and the two
## button columns only filled the middle ~220px and left ~75px of empty paper
## above and below. It now hugs its content (content + paper padding + 14px
## breathing room top and bottom), still never exceeds "screen height - 24",
## stays centred, and keeps its width, fonts, buttons and two-column grouping.
##
## REQ-20261007-059: portrait and large screens used to keep a fixed
## min(620, h - 24). At 390x844 that was a 620px card around ~553px of
## single-column content (padding included), ~43px of empty paper above the
## title and below the last button, and the card's bottom pressed over the top
## of the bottom HUD row.
## Tall screens now hug too (content + padding + 20px top and bottom), still
## capped at min(620, h - 24), centred, 360 wide, single column, same fonts.

const SHORT := [Vector2i(844, 390), Vector2i(915, 412), Vector2i(700, 400), Vector2i(640, 360), Vector2i(568, 320), Vector2i(640, 300)]
const TALL := [Vector2i(360, 640), Vector2i(390, 844), Vector2i(412, 915), Vector2i(1280, 720)]
const MARGIN := 12.0
const BREATH := 14.0
const TALL_BREATH := 20.0
## Portrait screens with room for the hugged card must leave the HUD chips uncovered
## (1280x720 content alone is ~553px, so a few px of overlap with the bottom row remain there).
const HUD_CLEAR := [Vector2i(390, 844), Vector2i(412, 915)]
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
	for dims in SHORT + TALL:
		await _spawn(dims)
		for locale in ["zh-CN", "en"]:
			i18n.set_locale(locale)
			await _open()
			_check_panel(dims, "%s %s" % [dims, locale])
			await _close()
		i18n.set_locale(original_locale)
		main.queue_free()
		await process_frame
	await _check_resize_and_behaviour()
	i18n.set_locale(original_locale)
	_finish()


func _spawn(dims: Vector2i) -> void:
	root.size = dims
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _settle()
	main.set_process(false)
	await main._start_holiday()
	await _settle()


func _settle() -> void:
	for i in 4:
		await process_frame


func _open() -> void:
	if not main._pause_screen.visible:
		main._toggle_pause()
	await _settle()


func _close() -> void:
	if main._pause_screen.visible:
		main._toggle_pause()
	await _settle()


func _inside(inner: Rect2, outer: Rect2) -> bool:
	return inner.position.x >= outer.position.x - EPS and inner.position.y >= outer.position.y - EPS \
		and inner.end.x <= outer.end.x + EPS and inner.end.y <= outer.end.y + EPS


func _controls() -> Array:
	return [main._pause_title, main._resume_button, main._restart_button, main._pause_title_button, main._mute_toggle,
		main._music_toggle, main._music_volume_label, main._music_slider, main._ambience_toggle, main._ambience_volume_label, main._ambience_slider]


func _check_panel(dims: Vector2i, tag: String) -> void:
	var screen := Rect2(Vector2.ZERO, Vector2(dims))
	var safe := screen.grow(-MARGIN)
	var panel: Control = main._pause_panel
	var rect := panel.get_global_rect()
	var short := dims.y < 500
	_check(main._pause_screen.visible and panel.is_visible_in_tree(), "%s: pause paper is showing" % tag)
	_check(_inside(rect, safe), "%s: paper %s inside the screen with %dpx margin" % [tag, rect, int(MARGIN)])
	_check(absf(rect.get_center().x - dims.x * 0.5) <= 1.0 and absf(rect.get_center().y - dims.y * 0.5) <= 1.0, "%s: paper %s centred" % [tag, rect])
	var width := minf(680.0 if short else 360.0, dims.x - MARGIN * 2.0)
	_check(absf(rect.size.x - width) <= EPS, "%s: paper width %.1f == %.1f (unchanged)" % [tag, rect.size.x, width])
	var top := INF
	var bottom := -INF
	for node: Control in _controls():
		var r := node.get_global_rect()
		_check(node.is_visible_in_tree(), "%s: %s visible" % [tag, node.name])
		_check(_inside(r, rect), "%s: %s %s inside the paper %s" % [tag, node.name, r, rect])
		_check(_inside(r, screen), "%s: %s %s fully on screen" % [tag, node.name, r])
		top = minf(top, r.position.y)
		bottom = maxf(bottom, r.end.y)
	var style: StyleBox = panel.get_theme_stylebox("panel")
	var pad_top := style.get_margin(SIDE_TOP)
	var pad_bottom := style.get_margin(SIDE_BOTTOM)
	var content := ceilf(main._pause_box.get_combined_minimum_size().y + pad_top + pad_bottom)
	_check(rect.size.y >= content - EPS, "%s: paper height %.1f holds its content %.1f" % [tag, rect.size.y, content])
	if short:
		var expected := minf(dims.y - MARGIN * 2.0, content + BREATH * 2.0)
		_check(absf(rect.size.y - expected) <= EPS, "%s: short paper height %.1f hugs content (%.1f)" % [tag, rect.size.y, expected])
		var gap_top := top - rect.position.y
		var gap_bottom := rect.end.y - bottom
		var limit := pad_top + BREATH + 2.0
		_check(gap_top <= limit, "%s: empty paper above the title %.1f <= %.1f (was ~75px at 844x390)" % [tag, gap_top, limit])
		_check(gap_bottom <= pad_bottom + BREATH + 2.0 + 24.0, "%s: empty paper below the last control %.1f stays small" % [tag, gap_bottom])
		_check(main._pause_audio.visible and main._resume_button.get_parent() == main._pause_session and main._music_toggle.get_parent() == main._pause_audio, "%s: two-column grouping kept" % tag)
		_check(main._pause_title.get_theme_font_size("font_size") == 18 and main._resume_button.get_theme_font_size("font_size") == 13 and main._music_volume_label.get_theme_font_size("font_size") == 12, "%s: short font sizes unchanged (18/13/12)" % tag)
		_check(main._resume_button.custom_minimum_size.y == 36.0 and main._resume_button.size.y >= 36.0 - EPS, "%s: short buttons keep their 36px minimum (%.1f)" % [tag, main._resume_button.size.y])
	else:
		var expected_tall := minf(minf(620.0, dims.y - MARGIN * 2.0), content + TALL_BREATH * 2.0)
		_check(absf(rect.size.y - expected_tall) <= EPS, "%s: tall paper height %.1f hugs content (%.1f)" % [tag, rect.size.y, expected_tall])
		var tall_gap_top := top - rect.position.y
		var tall_gap_bottom := rect.end.y - bottom
		_check(tall_gap_top <= pad_top + TALL_BREATH + 2.0, "%s: empty paper above the title %.1f <= %.1f (was ~43px at 390x844)" % [tag, tall_gap_top, pad_top + TALL_BREATH + 2.0])
		_check(tall_gap_bottom <= pad_bottom + TALL_BREATH + 2.0, "%s: empty paper below the last control %.1f stays small" % [tag, tall_gap_bottom])
		if dims in HUD_CLEAR:
			for chip: Control in [main._day_label, main._pause_button, main._album_chip, main._weather_chip, main._basket_chip, main._action_button]:
				if chip != null and chip.is_visible_in_tree():
					var c := chip.get_global_rect()
					_check(not rect.intersects(c), "%s: paper %s leaves HUD %s %s uncovered" % [tag, rect, chip.name, c])
		_check(main._resume_button.custom_minimum_size.y == 44.0, "%s: tall buttons keep their 44px minimum" % tag)
		_check(not main._pause_audio.visible and main._music_toggle.get_parent() == main._pause_session, "%s: single column kept" % tag)
		_check(main._pause_title.get_theme_font_size("font_size") == 26 and main._resume_button.get_theme_font_size("font_size") == 16, "%s: tall font sizes unchanged (26/16)" % tag)
	_check(main._pause_title.text == i18n.t("pause.title") and main._resume_button.text == i18n.t("pause.resume"), "%s: copy unchanged" % tag)


func _check_resize_and_behaviour() -> void:
	await _spawn(Vector2i(1280, 720))
	await _open()
	for dims in [Vector2i(844, 390), Vector2i(390, 844), Vector2i(640, 360), Vector2i(1280, 720), Vector2i(568, 320), Vector2i(360, 640), Vector2i(844, 390)]:
		root.size = dims
		await _settle()
		_check_panel(dims, "resize->%s" % [dims])
	i18n.set_locale("en")
	await _settle()
	_check_panel(Vector2i(844, 390), "locale switch while paused 844x390")
	i18n.set_locale("zh-CN")
	await _settle()
	# Behaviour: resume still closes the pause paper and returns to the yard.
	main._resume_button.pressed.emit()
	await _settle()
	_check(not main._pause_screen.visible and not paused, "resume closes the pause paper and unpauses the tree")
	main.queue_free()
	await process_frame


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: ", label)


func _finish() -> void:
	if failures.is_empty():
		print("PASS: pause_panel_fit %d checks" % checks)
		quit(0)
	else:
		print("pause_panel_fit: %d of %d checks FAILED" % [failures.size(), checks])
		quit(1)
