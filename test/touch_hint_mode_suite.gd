extends SceneTree

## REQ-20261006-047: touch players are no longer told to press Space.
## A finger on the screen switches every HUD hint that names the Space key to
## its `.touch` copy (served by I18n's input variant); a real key press switches
## back. Mouse input never changes the mode, Main itself is not edited, and the
## goal paper still fits. The HUD refreshes on the switch without a target change.

const VIEWPORTS := [Vector2i(390, 844), Vector2i(844, 390), Vector2i(1280, 720), Vector2i(568, 320)]
const LOCALES := ["zh-CN", "en"]
const KEY_WORDS := ["空格", "Space"]
const TOUCH_WORDS := {"zh-CN": "点", "en": "tap"}

var checks := 0
var failures: Array[String] = []
var main
var i18n


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	i18n = root.get_node("/root/I18n")
	var original_locale: String = i18n.get_locale()
	_check_catalogs()
	_check_mode_rules()
	for dims in VIEWPORTS:
		await _spawn(dims)
		for locale in LOCALES:
			i18n.set_locale(locale)
			await _settle()
			await _check_live_hud(dims, locale)
		i18n.set_locale(original_locale)
		await _despawn()
	await _check_real_input_path()
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


func _despawn() -> void:
	main.queue_free()
	await process_frame


func _settle() -> void:
	for i in 4:
		await process_frame


func _mentions_key(text: String) -> bool:
	for word: String in KEY_WORDS:
		if text.contains(word):
			return true
	return false


func _check_catalogs() -> void:
	for locale: String in LOCALES:
		var keys: Array = i18n.call("catalog_keys", locale)
		i18n.set_locale(locale)
		var with_key := 0
		for key: String in keys:
			if not key.begins_with("hud.hint") or key.ends_with(".touch"):
				continue
			var text: String = i18n.t(key)
			if not _mentions_key(text):
				continue
			with_key += 1
			var touch_key := key + ".touch"
			_check(keys.has(touch_key), "%s %s has touch copy" % [locale, key])
			if not keys.has(touch_key):
				continue
			var touch_text: String = i18n.t(touch_key)
			_check(not _mentions_key(touch_text), "%s %s touch copy does not mention Space (%s)" % [locale, key, touch_text])
			_check(touch_text.contains(TOUCH_WORDS[locale]), "%s %s touch copy says tap (%s)" % [locale, key, touch_text])
			_check(touch_text.count("\n") == text.count("\n"), "%s %s touch copy keeps line breaks" % [locale, key])
			for placeholder: String in ["{target}", "{action}"]:
				_check(touch_text.contains(placeholder) == text.contains(placeholder), "%s %s touch copy keeps %s" % [locale, key, placeholder])
			_check(touch_text.length() <= text.length() + 6, "%s %s touch copy is about as long (%d vs %d)" % [locale, key, touch_text.length(), text.length()])
		_check(with_key >= 14, "%s found every Space hint (%d)" % [locale, with_key])
		# #508 put-down / release hints: keyboard copy names Space, touch copy keeps the tap wording.
		for key: String in ["hud.hint.carrying", "hud.hint.carrying_fish", "hud.hint.leading"]:
			_check(_mentions_key(i18n.t(key)), "%s %s keyboard copy names Space" % [locale, key])
			_check(keys.has(key + ".touch"), "%s %s keeps a tap version" % [locale, key])
		for key: String in keys:
			if key.ends_with(".touch"):
				_check(keys.has(key.trim_suffix(".touch")), "%s %s has a base key" % [locale, key])


func _check_mode_rules() -> void:
	var mode := InputHintMode.new()
	root.add_child(mode)
	mode.set_touch(false)
	var seen: Array = []
	mode.changed.connect(func(touch: bool) -> void: seen.append(touch))
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	_check(mode.note(tap) and mode.touch, "touch press switches to touch copy")
	_check(i18n.get_input_variant() == "touch", "touch mode sets the I18n touch variant")
	_check(i18n.t("hud.hint.near_grass") == i18n.t("hud.hint.near_grass.touch"), "I18n serves the touch copy for a key that has one")
	_check(i18n.t("hud.hint.fishing").contains("鱼线") or i18n.t("hud.hint.fishing").contains("Line"), "key without touch copy is unchanged")
	_check(i18n.t("no.such.key") == "no.such.key", "unknown key still falls back to itself")
	var release := InputEventScreenTouch.new()
	release.pressed = false
	_check(not mode.note(release) and mode.touch, "touch release keeps touch copy")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	_check(not mode.note(click) and mode.touch, "synthesised mouse click after a tap keeps touch copy")
	var motion := InputEventMouseMotion.new()
	_check(not mode.note(motion) and mode.touch, "mouse motion keeps touch copy")
	var echo := InputEventKey.new()
	echo.keycode = KEY_SPACE
	echo.pressed = true
	echo.echo = true
	_check(not mode.note(echo) and mode.touch, "key echo alone does not switch")
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	_check(mode.note(key) and not mode.touch, "real key press switches back to Space copy")
	_check(i18n.get_input_variant() == "", "keyboard mode clears the I18n variant")
	_check(_mentions_key(i18n.t("hud.hint.near_grass")), "keyboard mode serves the Space copy")
	var drag := InputEventScreenDrag.new()
	_check(mode.note(drag) and mode.touch, "touch drag switches to touch copy")
	_check(not mode.note(drag), "repeated touch does not re-emit")
	_check(seen == [true, false, true], "changed emitted once per real switch (%s)" % str(seen))
	root.remove_child(mode)
	_check(i18n.get_input_variant() == "", "leaving the tree clears the I18n variant")
	mode.free()


func _hint_fits(dims: Vector2i) -> bool:
	var panel: Rect2 = main._hint_panel.get_global_rect()
	var label: Rect2 = main._hint_label.get_global_rect()
	return panel.position.x >= 0.0 and panel.end.x <= float(dims.x) + 0.5 and label.end.x <= panel.end.x + 0.5 and label.end.y <= panel.end.y + 0.5


func _check_live_hud(dims: Vector2i, locale: String) -> void:
	var tag := "%dx%d %s" % [dims.x, dims.y, locale]
	var mode: InputHintMode = main.get_node_or_null("InputHintMode")
	_check(mode != null, "%s main.tscn carries the hint mode node" % tag)
	mode.set_touch(false)
	main._refresh_hud()
	await process_frame
	var keyboard_text: String = main._hint_label.text
	var keyboard_lines: int = main._hint_label.get_line_count()
	var action_text: String = main._action_button.text
	_check(_mentions_key(keyboard_text), "%s keyboard goal still names Space (%s)" % [tag, keyboard_text])
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	mode.note(tap)
	await process_frame
	var touch_text: String = main._hint_label.text
	_check(not _mentions_key(touch_text), "%s touch goal no longer names Space (%s)" % [tag, touch_text])
	_check(touch_text.contains(TOUCH_WORDS[locale]), "%s touch goal says tap" % tag)
	_check(main._action_button.text == action_text, "%s action button label unchanged" % tag)
	_check(main._hint_label.get_line_count() <= keyboard_lines, "%s touch goal no taller (%d vs %d)" % [tag, main._hint_label.get_line_count(), keyboard_lines])
	_check(_hint_fits(dims), "%s touch goal paper stays on screen and holds its text" % tag)
	# Context hints (no current target) follow the same rule.
	for context: String in ["hud.hint.near_grass", "hud.hint.near_animal", "hud.hint.plant_water"]:
		_check(not _mentions_key(i18n.t(context)), "%s %s touch context copy" % [tag, context])
	var key := InputEventKey.new()
	key.keycode = KEY_SHIFT
	key.pressed = true
	mode.note(key)
	await process_frame
	_check(main._hint_label.text == keyboard_text, "%s key press restores the original goal copy" % tag)
	_check(_hint_fits(dims), "%s keyboard goal paper still fits" % tag)


func _check_real_input_path() -> void:
	await _spawn(Vector2i(390, 844))
	i18n.set_locale("zh-CN")
	var mode: InputHintMode = main.get_node("InputHintMode")
	mode.set_touch(false)
	main._refresh_hud()
	await _settle()
	_check(_mentions_key(main._hint_label.text), "real path starts with Space copy")
	# A real touch through the engine input pipeline, on the yard (not a button).
	var tap := InputEventScreenTouch.new()
	tap.index = 0
	tap.position = Vector2(195, 520)
	tap.pressed = true
	Input.parse_input_event(tap)
	await _settle()
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = tap.position
	up.pressed = false
	Input.parse_input_event(up)
	await _settle()
	_check(mode.touch, "engine touch event reaches the hint mode")
	main._refresh_hud()
	await process_frame
	_check(not _mentions_key(main._hint_label.text), "real touch path shows tap copy (%s)" % main._hint_label.text)
	var key := InputEventKey.new()
	key.keycode = KEY_SHIFT
	key.physical_keycode = KEY_SHIFT
	key.pressed = true
	Input.parse_input_event(key)
	await _settle()
	var key_up := key.duplicate()
	key_up.pressed = false
	Input.parse_input_event(key_up)
	await _settle()
	_check(not mode.touch, "engine key event restores Space copy")
	_check(_mentions_key(main._hint_label.text), "real key path shows Space copy again (%s)" % main._hint_label.text)
	await _despawn()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: ", label)


func _finish() -> void:
	if failures.is_empty():
		print("PASS: touch_hint_mode %d checks" % checks)
		quit(0)
	else:
		print("FAIL: touch_hint_mode %d of %d checks failed" % [failures.size(), checks])
		quit(1)
