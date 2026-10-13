extends SceneTree

## 纯键盘玩家在标题、暂停、确认和相册里按 Tab/方向键/回车原来毫无反应：菜单打开时没有任何
## 按钮拿着焦点，Godot 不会自动选中。现在第一次导航键把焦点交给该界面的默认按钮
## （走进院子 / 继续待着 / 再待一会儿 / 合上），之后由 Godot 正常移动、按下，且不越出最上层菜单；
## 打开菜单本身不抢焦点，鼠标玩家看不到多出的焦点框；游戏中回车仍是互动、方向键仍是走路。

const VIEWS := [Vector2i(1280, 720), Vector2i(390, 844), Vector2i(640, 300)]
const NAV_KEYS := [KEY_TAB, KEY_DOWN, KEY_UP, KEY_ENTER, KEY_SPACE]

var checks := 0
var failures: Array[String] = []
var main


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for dims in VIEWS:
		await _check_title(dims)
		await _check_pause_and_confirm(dims)
		await _check_album(dims)
	_finish()


func _spawn(dims: Vector2i) -> void:
	if main != null:
		main.queue_free()
		await process_frame
	root.size = dims
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _settle()


func _start_game() -> void:
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


func _focus() -> Control:
	return root.gui_get_focus_owner()


func _name(control: Control) -> String:
	if control == null: return "<none>"
	return "%s '%s'" % [control.name, (control as Button).text if control is Button else ""]


func _check_title(dims: Vector2i) -> void:
	for code: Key in NAV_KEYS:
		await _spawn(dims)
		var tag := "%s title key %s" % [dims, OS.get_keycode_string(code)]
		_check(_focus() == null, "%s: title opens without forcing a focus ring" % tag)
		await _key(code)
		_check(_focus() == main._play_button, "%s: first key focuses 走进院子, got %s" % [tag, _name(_focus())])
		_check(main._screen == "title" and main._title_screen.visible, "%s: first key only focuses, does not start" % tag)
	await _spawn(dims)
	await _key(KEY_TAB, true)
	_check(_focus() == main._play_button, "%s: Shift+Tab also lands on 走进院子, got %s" % [dims, _name(_focus())])
	var seen := {}
	for i in 8:
		await _key(KEY_TAB)
		var focused := _focus()
		_check(focused != null and main._title_screen.is_ancestor_of(focused) and focused.is_visible_in_tree(),
			"%s: title Tab %d stays on the title card, got %s" % [dims, i, _name(focused)])
		if focused != null: seen[focused] = true
	for button: Button in [main._play_button, main._album_button, main._licenses_button]:
		_check(seen.has(button), "%s: Tab reaches %s" % [dims, _name(button)])
	main._play_button.grab_focus()
	await _key(KEY_ENTER)
	await _settle(8)
	_check(main._screen == "game", "%s: Enter on 走进院子 starts the holiday (screen=%s)" % [dims, main._screen])


func _check_pause_and_confirm(dims: Vector2i) -> void:
	await _spawn(dims)
	await _start_game()
	await _key(KEY_TAB)
	_check(_focus() == main._album_chip, "%s: in the yard Tab walks the HUD row (hud_keyboard_focus_suite), got %s" % [dims, _name(_focus())])
	await _key(KEY_DOWN)
	_check(_focus() == null, "%s: in the yard arrows drop HUD focus and walk, got %s" % [dims, _name(_focus())])
	await _key(KEY_ESCAPE)
	await _settle()
	_check(main._pause_screen.visible, "%s: Esc opens the pause paper" % dims)
	_check(_focus() == null, "%s: pause opens without forcing a focus ring" % dims)
	await _key(KEY_DOWN)
	_check(_focus() == main._resume_button, "%s: first key in pause focuses 继续待着, got %s" % [dims, _name(_focus())])
	for i in 14:
		await _key(KEY_TAB)
		var focused := _focus()
		_check(focused != null and main._pause_panel.is_ancestor_of(focused) and focused.is_visible_in_tree(),
			"%s: pause Tab %d stays on the pause paper, got %s" % [dims, i, _name(focused)])
	main._restart_button.grab_focus()
	await _key(KEY_ENTER)
	await _settle()
	_check(main._confirm_screen.visible, "%s: Enter on 再过一次假期 asks to confirm" % dims)
	await _key(KEY_TAB)
	_check(_focus() == main._confirm_cancel_button,
		"%s: focus left behind the confirm paper moves to its safe 再待一会儿, got %s" % [dims, _name(_focus())])
	for i in 4:
		await _key(KEY_TAB)
		var focused := _focus()
		_check(focused != null and main._confirm_panel.is_ancestor_of(focused),
			"%s: confirm Tab %d stays on the confirm paper, got %s" % [dims, i, _name(focused)])
	main._confirm_cancel_button.grab_focus()
	await _key(KEY_ENTER)
	await _settle()
	_check(not main._confirm_screen.visible and main._pause_screen.visible, "%s: Enter on 再待一会儿 returns to pause" % dims)
	await _key(KEY_UP)
	_check(_focus() == main._resume_button, "%s: after 再待一会儿 the next key lands on 继续待着, got %s" % [dims, _name(_focus())])
	await _key(KEY_ENTER)
	await _settle()
	_check(not main._pause_screen.visible and main._screen == "game", "%s: Enter on 继续待着 resumes" % dims)
	_check(_focus() == null or not main._pause_screen.is_ancestor_of(_focus()), "%s: back in the yard no pause focus lingers, got %s" % [dims, _name(_focus())])
	await _key(KEY_TAB)
	_check(_focus() == main._album_chip, "%s: back in the yard Tab starts at 翻开手帐, got %s" % [dims, _name(_focus())])


func _check_album(dims: Vector2i) -> void:
	await _spawn(dims)
	main._album_button.grab_focus()
	await _key(KEY_ENTER)
	await _settle()
	_check(main._album_screen.visible, "%s: Enter on 翻开相册 opens the album" % dims)
	_check(_focus() == null or not main._album_screen.is_ancestor_of(_focus()),
		"%s: opening the album does not itself move focus" % dims)
	await _key(KEY_TAB)
	_check(_focus() == main._album_back_button, "%s: first key in the album focuses 合上, got %s" % [dims, _name(_focus())])
	for i in 6:
		await _key(KEY_TAB)
		var focused := _focus()
		_check(focused != null and main._album_screen.is_ancestor_of(focused) and focused.is_visible_in_tree(),
			"%s: album Tab %d stays in the album, got %s" % [dims, i, _name(focused)])
	main._album_back_button.grab_focus()
	await _key(KEY_ENTER)
	await _settle()
	_check(not main._album_screen.visible and main._title_screen.visible, "%s: Enter on 合上 returns to the title" % dims)
	await _key(KEY_DOWN)
	_check(_focus() == main._play_button, "%s: after the album the next key lands on 走进院子, got %s" % [dims, _name(_focus())])


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
	print("MENU_KEYBOARD_FOCUS checks=%d failures=%d" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)
