extends SceneTree

## REQ-20261006-042: the "save can't continue yet" paper was a fixed 352 px
## column at y=90 centred on screen. On 360/390 portrait it sat on the
## "Day N" label (and on 360 English on the wrapped goal paper too), ran 2 px
## off the right edge at 360, and on 568x320 it also covered the day label.
## The message was left-aligned under a centred button, the button read a
## hard-coded "再确认一次" in English, and neither text followed a language
## switch. This suite drives the real Main through the real save-problem entry
## and checks, per viewport and locale, that the paper stays on screen, clears
## the goal paper, the day label and the bottom chip row, centres its message
## (left-aligned beside the button on short landscape), and that message and
## button follow the language, including a switch while the paper is showing.
## It also checks the retry wiring and the disabled/hide behaviour are unchanged.

const VIEWPORTS := [Vector2i(360, 640), Vector2i(390, 844), Vector2i(568, 320), Vector2i(640, 300), Vector2i(844, 390), Vector2i(1280, 720)]

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
		root.size = dims
		main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		await _settle()
		await main._start_holiday()
		await _settle()
		for locale in ["zh-CN", "en"]:
			i18n.set_locale(locale)
			await _settle()
			main._on_save_problem("suite-%s" % locale, "yard", "suite")
			await _settle()
			_check_paper(dims, locale)
			# Switch language while the paper is up: both texts follow at once.
			var other := "en" if locale == "zh-CN" else "zh-CN"
			i18n.set_locale(other)
			await _settle()
			_check_paper(dims, "%s->%s" % [locale, other])
			_check_behaviour_unchanged(dims, locale)
			i18n.set_locale(locale)
			await _settle()
		main.queue_free()
		await _settle()
	await _check_resize_while_showing()
	i18n.set_locale(original_locale)
	_finish()


func _settle() -> void:
	for i in 5:
		await process_frame


func _check_paper(dims: Vector2i, tag_locale: String) -> void:
	var tag := "%s %s" % [dims, tag_locale]
	var panel: PanelContainer = main.get("_save_status_panel")
	var message: Label = main.get("_save_status_message")
	var button: Button = main.get("_save_retry_button")
	var box: BoxContainer = main.get("_save_status_box")
	_check(panel != null and message != null and button != null and box != null, "%s: save paper nodes exist" % tag)
	if panel == null or message == null or button == null or box == null:
		return
	_check(panel.visible, "%s: paper shows for a save problem" % tag)
	_check(message.text == i18n.t("notice.save.pending"), "%s: message is the current language" % tag)
	_check(button.text == i18n.t("save.retry"), "%s: retry button is the current language (%s)" % [tag, button.text])
	_check(i18n.t("save.retry") != "save.retry", "%s: retry key exists" % tag)
	var screen := Rect2(Vector2.ZERO, Vector2(dims))
	var rect := panel.get_global_rect()
	_check(screen.encloses(rect), "%s: paper %s stays on screen" % [tag, rect])
	_check(rect.size.x <= dims.x - 20.0 + 0.5, "%s: paper keeps a 10 px side margin" % tag)
	for name in ["_hint_panel", "_day_label"]:
		var other: Control = main.get(name)
		if other != null and other.is_visible_in_tree():
			_check(not rect.intersects(other.get_global_rect()), "%s: paper %s clears %s %s" % [tag, rect, name, other.get_global_rect()])
	for name in ["_album_chip", "_weather_chip", "_action_button"]:
		var chip: Control = main.get(name)
		if chip != null and chip.is_visible_in_tree():
			_check(rect.end.y <= chip.get_global_rect().position.y, "%s: paper bottom %.0f stays above %s top %.0f" % [tag, rect.end.y, name, chip.get_global_rect().position.y])
	var row: bool = dims.y <= 360 and dims.x > dims.y
	_check(box.vertical == (not row), "%s: %s layout" % [tag, "row" if row else "column"])
	var expected_align := HORIZONTAL_ALIGNMENT_LEFT if row else HORIZONTAL_ALIGNMENT_CENTER
	_check(message.horizontal_alignment == expected_align, "%s: message alignment matches the layout" % tag)
	_check(rect.encloses(message.get_global_rect()), "%s: message stays on the paper" % tag)
	_check(rect.encloses(button.get_global_rect()), "%s: button stays on the paper" % tag)
	_check(message.get_line_count() <= 3, "%s: message wraps to at most 3 lines (%d)" % [tag, message.get_line_count()])
	_check(message.get_line_count() <= message.get_visible_line_count() or message.get_visible_line_count() < 0, "%s: no message line is cut" % tag)
	_check(button.size.y >= 44.0, "%s: retry button keeps a 44 px touch height" % tag)


func _check_behaviour_unchanged(dims: Vector2i, locale: String) -> void:
	var tag := "%s %s behaviour" % [dims, locale]
	var button: Button = main._save_retry_button
	_check(button.pressed.is_connected(main._retry_save), "%s: retry still calls _retry_save" % tag)
	main._on_save_state_changed("writing")
	_check(button.disabled, "%s: retry disabled while writing" % tag)
	main._on_save_state_changed("failed")
	_check(not button.disabled, "%s: retry enabled after the write settles" % tag)
	_check(main._save_status_panel.visible and main._save_problem_active, "%s: an unresolved problem keeps the paper" % tag)
	main._save_problems.clear()
	if main.get_node("/root/SaveStore").is_save_idle():
		main._on_save_state_changed("ready")
		_check(not main._save_status_panel.visible and not main._save_problem_active, "%s: paper still closes once the problem clears" % tag)
	else:
		main._save_status_panel.hide()
		main._save_problem_active = false


func _check_resize_while_showing() -> void:
	root.size = Vector2i(1280, 720)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _settle()
	await main._start_holiday()
	await _settle()
	i18n.set_locale("en")
	main._on_save_problem("suite-resize", "yard", "suite")
	await _settle()
	for dims in [Vector2i(360, 640), Vector2i(568, 320), Vector2i(1280, 720)]:
		root.size = dims
		await _settle()
		_check_paper(dims, "en resized while showing")
	main.queue_free()
	await _settle()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	if failures.is_empty():
		print("PASS: save_status_paper %d checks" % checks)
		quit(0)
	else:
		print("FAIL: save_status_paper %d/%d failed" % [failures.size(), checks])
		for f in failures.slice(0, 40):
			print("  - " + f)
		quit(1)
