extends SceneTree

## REQ-20261005-030: the "Leave for now?" confirmation paper (确认纸片) used to
## be a fixed 420x240 panel. On 360/390-wide portrait phones it ran off both
## screen edges, cutting its rounded corners, border and button ends. It now
## stays inside the screen with a 12px margin on every side and stays centred;
## screens with room keep the original 420x240. Copy, font sizes, buttons and
## behaviour are unchanged.

const VIEWPORTS := [Vector2i(320, 568), Vector2i(360, 640), Vector2i(390, 844), Vector2i(412, 915), Vector2i(844, 390), Vector2i(700, 400), Vector2i(1280, 720)]
const DESIGN := Vector2(420, 240)
const MARGIN := 12.0
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
			for action in ["title", "restart"]:
				await _open(action)
				_check_panel(dims, "%s %s %s" % [dims, locale, action])
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


func _open(action: String) -> void:
	if not main._pause_screen.visible:
		main._toggle_pause()
	main._request_destructive_action(action)
	await _settle()


func _close() -> void:
	main._cancel_destructive_action()
	if main._pause_screen.visible:
		main._toggle_pause()
	await _settle()


func _inside(inner: Rect2, outer: Rect2) -> bool:
	return inner.position.x >= outer.position.x - EPS and inner.position.y >= outer.position.y - EPS \
		and inner.end.x <= outer.end.x + EPS and inner.end.y <= outer.end.y + EPS


func _check_panel(dims: Vector2i, tag: String) -> void:
	var screen := Rect2(Vector2.ZERO, Vector2(dims))
	var safe := screen.grow(-MARGIN)
	var panel: Control = main._confirm_title.get_parent().get_parent()
	var rect := panel.get_global_rect()
	_check(main._confirm_screen.visible and panel.is_visible_in_tree(), "%s: confirmation paper is showing" % tag)
	_check(_inside(rect, safe), "%s: paper %s stays inside the screen with %dpx margin" % [tag, rect, int(MARGIN)])
	_check(absf(rect.get_center().x - dims.x * 0.5) <= 1.0 and absf(rect.get_center().y - dims.y * 0.5) <= 1.0, "%s: paper %s stays centred" % [tag, rect])
	var expected := Vector2(minf(DESIGN.x, dims.x - MARGIN * 2.0), minf(DESIGN.y, dims.y - MARGIN * 2.0))
	_check(absf(rect.size.x - expected.x) <= EPS, "%s: paper width %.1f == %.1f (design 420 when it fits)" % [tag, rect.size.x, expected.x])
	_check(rect.size.y >= expected.y - EPS, "%s: paper height %.1f >= %.1f" % [tag, rect.size.y, expected.y])
	for node: Control in [main._confirm_title, main._confirm_message, main._confirm_accept_button, main._confirm_cancel_button]:
		var r := node.get_global_rect()
		_check(_inside(r, rect), "%s: %s %s inside the paper %s" % [tag, node.name, r, rect])
		_check(_inside(r, screen), "%s: %s %s fully on screen" % [tag, node.name, r])
	var msg: Label = main._confirm_message
	_check(msg.get_visible_line_count() >= msg.get_line_count(), "%s: every message line visible (%d/%d)" % [tag, msg.get_visible_line_count(), msg.get_line_count()])
	_check(main._confirm_accept_button.size.x >= 260.0 - EPS and main._confirm_cancel_button.size.x >= 260.0 - EPS, "%s: buttons keep their 260px minimum" % tag)
	_check(main._confirm_title.get_theme_font_size("font_size") == 22 and msg.get_theme_font_size("font_size") == 15 and main._confirm_accept_button.get_theme_font_size("font_size") == 16, "%s: font sizes unchanged (22/15/16)" % tag)
	_check(main._confirm_title.text == i18n.t("confirm.heading") and msg.text == i18n.t("confirm." + tag.get_slice(" ", tag.get_slice_count(" ") - 1)), "%s: copy unchanged" % tag)


func _check_resize_and_behaviour() -> void:
	await _spawn(Vector2i(1280, 720))
	i18n.set_locale("en")
	await _open("restart")
	for dims in [Vector2i(390, 844), Vector2i(844, 390), Vector2i(320, 568), Vector2i(1280, 720), Vector2i(360, 640)]:
		root.size = dims
		await _settle()
		_check_panel(dims, "resize->%s en restart" % [dims])
	# Cancel still closes only the confirmation and keeps the pause page.
	main._confirm_cancel_button.pressed.emit()
	await _settle()
	_check(not main._confirm_screen.visible and main._pause_screen.visible, "cancel closes the confirmation and returns to the pause page")
	main._toggle_pause()
	await _settle()
	main.queue_free()
	await process_frame


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: ", label)


func _finish() -> void:
	if failures.is_empty():
		print("confirm_panel_fit suite: %d checks passed" % checks)
		quit(0)
	else:
		print("confirm_panel_fit suite: %d of %d checks FAILED" % [failures.size(), checks])
		quit(1)
