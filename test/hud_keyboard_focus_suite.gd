extends SceneTree

## 院内底栏按钮（翻开手帐 / 天气 / 大背篓 / 行动 / 歇一会儿）平时不拿焦点，纯键盘玩家原来打不开
## 手帐、背篓、天气。现在 Tab / Shift+Tab 在可见按钮间轮转并显示焦点框，回车/空格按下；
## 方向键、鼠标一操作就放下焦点并恢复不可聚焦，之后空格仍是互动。

const VIEWS := [Vector2i(1280, 720), Vector2i(390, 844), Vector2i(640, 300)]

var checks := 0
var failures: Array[String] = []
var main


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for dims in VIEWS:
		await _spawn(dims)
		await _check_cycle(dims)
		await _check_press(dims)
		await _check_release(dims)
	_finish()


func _spawn(dims: Vector2i) -> void:
	if main != null:
		main.queue_free()
		await process_frame
	root.size = dims
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _settle()
	main.set_process(false)
	await main._start_holiday()
	await _settle()


func _settle(frames := 4) -> void:
	for i in frames:
		await process_frame


func _key(code: Key, shift := false) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.shift_pressed = shift
		event.pressed = pressed
		root.push_input(event)
		await process_frame
	await process_frame


func _click(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		root.push_input(event)
		await process_frame
	await process_frame


func _chips() -> Array:
	return [main._album_chip, main._weather_chip, main._basket_chip, main._action_button, main._pause_button]


func _focus() -> Control:
	return root.gui_get_focus_owner()


func _name(control: Control) -> String:
	if control == null: return "<none>"
	return "%s '%s'" % [control.name, (control as Button).text if control is Button else ""]


func _all_unfocusable(tag: String) -> void:
	for chip: Button in _chips():
		_check(chip.focus_mode == Control.FOCUS_NONE, "%s: %s back to FOCUS_NONE" % [tag, _name(chip)])


func _check_cycle(dims: Vector2i) -> void:
	var tag := "%s cycle" % dims
	_check(_focus() == null, "%s: yard opens without a focused HUD button" % tag)
	_all_unfocusable("%s start" % tag)
	var expected: Array = []
	for chip: Button in _chips():
		if chip.is_visible_in_tree() and not chip.disabled and chip.self_modulate.a > 0.0:
			expected.append(chip)
	_check(expected.size() >= 4, "%s: at least album/weather/basket/pause reachable, got %d" % [tag, expected.size()])
	for chip: Button in [main._album_chip, main._weather_chip, main._basket_chip, main._pause_button]:
		_check(chip in expected, "%s: %s is in the Tab ring" % [tag, _name(chip)])
	for i in expected.size() + 1:
		await _key(KEY_TAB)
		var want: Button = expected[i % expected.size()]
		_check(_focus() == want, "%s: Tab %d focuses %s, got %s" % [tag, i, _name(want), _name(_focus())])
		_check(want.focus_mode == Control.FOCUS_ALL, "%s: focused %s can show its ring" % [tag, _name(want)])
		var ring := want.get_theme_stylebox("focus") as StyleBoxFlat
		_check(ring != null and ring.border_color.a > 0.5 and ring.get_border_width(SIDE_TOP) >= 2, "%s: %s has a visible focus ring" % [tag, _name(want)])
		var others := 0
		for chip: Button in _chips():
			if chip != want and chip.focus_mode != Control.FOCUS_NONE: others += 1
		_check(others == 0, "%s: only the focused chip is focusable (%d others)" % [tag, others])
	await _key(KEY_TAB, true)
	_check(_focus() == expected[-1], "%s: Shift+Tab from the first wraps to %s, got %s" % [tag, _name(expected[-1]), _name(_focus())])
	await _key(KEY_TAB, true)
	_check(_focus() == expected[-2], "%s: Shift+Tab steps back to %s, got %s" % [tag, _name(expected[-2]), _name(_focus())])
	await _key(KEY_D)
	_check(_focus() == null, "%s: a walk key drops HUD focus, got %s" % [tag, _name(_focus())])
	_all_unfocusable("%s after walk key" % tag)


func _focus_chip(chip: Button) -> void:
	for i in 8:
		if _focus() == chip: return
		await _key(KEY_TAB)


func _check_press(dims: Vector2i) -> void:
	var tag := "%s press" % dims
	await _focus_chip(main._basket_chip)
	_check(_focus() == main._basket_chip, "%s: Tab reaches 大背篓" % tag)
	await _key(KEY_ENTER)
	await _settle()
	_check(main._basket_panel.visible, "%s: Enter on 大背篓 opens the basket" % tag)
	_check(_focus() != main._basket_chip, "%s: the basket takes focus from the chip" % tag)
	await _key(KEY_ESCAPE)
	await _settle()
	_check(not main._basket_panel.visible, "%s: Esc closes the basket" % tag)
	_all_unfocusable("%s after basket" % tag)

	await _focus_chip(main._album_chip)
	await _key(KEY_SPACE)
	await _settle()
	_check(main._album_screen.visible, "%s: Space on 翻开手帐 opens the album" % tag)
	await _key(KEY_TAB)
	_check(_focus() == main._album_back_button, "%s: next key in the album lands on 合上, got %s" % [tag, _name(_focus())])
	await _key(KEY_ESCAPE)
	await _settle()
	_check(not main._album_screen.visible, "%s: Esc closes the album" % tag)
	_all_unfocusable("%s after album" % tag)

	await _focus_chip(main._weather_chip)
	var before: String = main._weather_chip.text
	await _key(KEY_ENTER)
	await _settle()
	_check(main._weather_chip.text != before, "%s: Enter on the weather chip changes the weather (%s -> %s)" % [tag, before, main._weather_chip.text])
	_check(_focus() == main._weather_chip, "%s: weather chip keeps focus for another press" % tag)

	await _focus_chip(main._pause_button)
	await _key(KEY_ENTER)
	await _settle()
	_check(main._pause_screen.visible, "%s: Enter on 歇一会儿 opens pause" % tag)
	await _key(KEY_DOWN)
	_check(_focus() == main._resume_button, "%s: next key in pause lands on 继续待着, got %s" % [tag, _name(_focus())])
	await _key(KEY_ENTER)
	await _settle()
	_check(not main._pause_screen.visible, "%s: 继续待着 resumes" % tag)
	_all_unfocusable("%s after pause" % tag)


func _check_release(dims: Vector2i) -> void:
	var tag := "%s release" % dims
	await _focus_chip(main._basket_chip)
	_check(_focus() == main._basket_chip, "%s: Tab reaches 大背篓 again" % tag)
	await _click(Vector2(dims.x * 0.5, dims.y * 0.45))
	await _settle()
	_check(_focus() == null or not (_focus() in _chips()), "%s: a click drops HUD focus, got %s" % [tag, _name(_focus())])
	_all_unfocusable("%s after click" % tag)
	if main._basket_panel.visible:
		main._hide_basket()
		await _settle()
	await _key(KEY_SPACE)
	await _settle()
	_check(not main._basket_panel.visible and not main._album_screen.visible, "%s: with no HUD focus Space interacts instead of pressing a chip" % tag)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error(label)


func _finish() -> void:
	if main != null:
		main.queue_free()
	for failure in failures:
		print("FAIL: ", failure)
	print("HUD_KEYBOARD_FOCUS checks=%d failures=%d" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)
