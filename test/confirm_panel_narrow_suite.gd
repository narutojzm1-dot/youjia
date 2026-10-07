extends SceneTree

## REQ-20261007-052: on very narrow portrait screens the "Leave for now?"
## confirmation paper still keeps its 12px screen margin.
## Before: both buttons had a fixed 260px minimum. With the paper's 16px side
## padding that forces a 292px paper, so on screens narrower than 316px the
## paper grew past "screen width - 24": on 280x653 it was 292px wide at x=-6,
## running 6px off both screen edges (corners, border and button ends cut);
## on 300x560 only 4px of margin was left.
## Now: only when the paper's inner width is below 260px the two buttons shrink
## to that inner width (still 44px tall, same 16px text). Wider papers keep the
## 260px buttons and every existing number from REQ-20261005-030.

const NARROW := [Vector2i(280, 653), Vector2i(280, 480), Vector2i(290, 600), Vector2i(300, 560), Vector2i(304, 540), Vector2i(310, 620), Vector2i(315, 560)]
const UNCHANGED := [Vector2i(316, 560), Vector2i(320, 568), Vector2i(360, 640), Vector2i(390, 844), Vector2i(568, 320), Vector2i(640, 300), Vector2i(844, 390), Vector2i(1280, 720)]
const DESIGN := Vector2(420, 240)
const BUTTON_W := 260.0
const PADDING := 16.0
const MARGIN := 12.0
const EPS := 0.51

var checks := 0
var failures: Array[String] = []
var main
var i18n
var narrowed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	i18n = root.get_node("/root/I18n")
	var original_locale: String = i18n.get_locale()
	for dims in NARROW + UNCHANGED:
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
	_check(narrowed > 0, "narrow screens actually narrow the buttons (%d)" % narrowed)
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
	var panel: Control = main._confirm_panel
	var rect := panel.get_global_rect()
	_check(main._confirm_screen.visible and panel.is_visible_in_tree(), "%s: confirmation paper is showing" % tag)
	_check(rect.position.x >= safe.position.x - EPS and rect.end.x <= safe.end.x + EPS, "%s: paper %s keeps 12px side margins" % [tag, rect])
	_check(_inside(rect, safe), "%s: paper %s stays inside the screen with 12px margin" % [tag, rect])
	_check(absf(rect.get_center().x - dims.x * 0.5) <= 1.0 and absf(rect.get_center().y - dims.y * 0.5) <= 1.0, "%s: paper %s stays centred" % [tag, rect])
	var expected := Vector2(minf(DESIGN.x, dims.x - MARGIN * 2.0), minf(DESIGN.y, dims.y - MARGIN * 2.0))
	_check(absf(rect.size.x - expected.x) <= EPS, "%s: paper width %.1f == %.1f" % [tag, rect.size.x, expected.x])
	_check(rect.size.y >= expected.y - EPS, "%s: paper height %.1f >= %.1f" % [tag, rect.size.y, expected.y])
	var want_w := minf(BUTTON_W, floorf(expected.x - PADDING * 2.0))
	if want_w < BUTTON_W:
		narrowed += 1
	for button: Button in [main._confirm_accept_button, main._confirm_cancel_button]:
		var r := button.get_global_rect()
		_check(absf(button.custom_minimum_size.x - want_w) <= EPS, "%s: %s minimum width %.1f == %.1f" % [tag, button.name, button.custom_minimum_size.x, want_w])
		_check(r.size.x >= want_w - EPS, "%s: %s is %.1f wide (>= %.1f)" % [tag, button.name, r.size.x, want_w])
		_check(r.size.y >= 44.0 - EPS, "%s: %s keeps its 44px touch target" % [tag, button.name])
		var font := button.get_theme_font("font")
		var text_w := font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
		_check(text_w + PADDING * 2.0 <= r.size.x + EPS, "%s: %s text %.1f fits its button %.1f" % [tag, button.name, text_w, r.size.x])
		_check(absf(r.get_center().x - rect.get_center().x) <= 1.0, "%s: %s centred on the paper" % [tag, button.name])
	for node: Control in [main._confirm_title, main._confirm_message, main._confirm_accept_button, main._confirm_cancel_button]:
		var r := node.get_global_rect()
		_check(_inside(r, rect), "%s: %s %s inside the paper %s" % [tag, node.name, r, rect])
		_check(_inside(r, screen), "%s: %s %s fully on screen" % [tag, node.name, r])
	var accept: Rect2 = main._confirm_accept_button.get_global_rect()
	var cancel: Rect2 = main._confirm_cancel_button.get_global_rect()
	_check(not accept.intersects(cancel), "%s: buttons do not overlap" % tag)
	var msg: Label = main._confirm_message
	_check(msg.get_visible_line_count() >= msg.get_line_count(), "%s: every message line visible (%d/%d)" % [tag, msg.get_visible_line_count(), msg.get_line_count()])
	var title: Label = main._confirm_title
	var title_w := title.get_theme_font("font").get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title.get_theme_font_size("font_size")).x
	_check(title_w <= title.size.x + EPS, "%s: heading %.1f fits its line %.1f" % [tag, title_w, title.size.x])
	_check(title.get_theme_font_size("font_size") == 22 and msg.get_theme_font_size("font_size") == 15 and main._confirm_accept_button.get_theme_font_size("font_size") == 16, "%s: font sizes unchanged (22/15/16)" % tag)
	_check(title.text == i18n.t("confirm.heading") and msg.text == i18n.t("confirm." + tag.get_slice(" ", tag.get_slice_count(" ") - 1)), "%s: copy unchanged" % tag)
	_check(main._confirm_accept_button.text == i18n.t("confirm.accept") and main._confirm_cancel_button.text == i18n.t("confirm.cancel"), "%s: button copy unchanged" % tag)


func _check_resize_and_behaviour() -> void:
	await _spawn(Vector2i(1280, 720))
	for locale in ["en", "zh-CN"]:
		i18n.set_locale(locale)
		await _open("restart")
		# Rotate / resize while the paper is open: narrow, back to wide, narrow again.
		for dims in [Vector2i(280, 653), Vector2i(1280, 720), Vector2i(300, 560), Vector2i(390, 844), Vector2i(280, 480), Vector2i(844, 390), Vector2i(320, 568)]:
			root.size = dims
			await _settle()
			_check_panel(dims, "resize->%s %s restart" % [dims, locale])
		await _close()
	# The other soft buttons (title / pause pages) are not touched by this change.
	root.size = Vector2i(280, 653)
	await _settle()
	for name in ["_resume_button", "_restart_button", "_pause_title_button"]:
		var button: Button = main.get(name)
		_check(button.custom_minimum_size.x >= 120.0 - EPS, "%s keeps its own pause sizing" % name)
	# Accept / cancel still work on the narrow paper.
	i18n.set_locale("en")
	await _open("restart")
	main._confirm_cancel_button.pressed.emit()
	await _settle()
	_check(not main._confirm_screen.visible and main._pause_screen.visible, "280 wide: cancel closes the confirmation and returns to the pause page")
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
		print("[confirm-panel-narrow] PASS: %d checks" % checks)
		quit(0)
	else:
		print("[confirm-panel-narrow] FAIL: %d of %d checks" % [failures.size(), checks])
		quit(1)
