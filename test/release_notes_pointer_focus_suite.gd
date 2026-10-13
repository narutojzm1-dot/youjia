extends SceneTree
## 「歇一下」里的版本公告：点按「公告」打开时焦点照样交给「返回歇一下」，但先不画焦点圈；
## 点「返回歇一下」关上后焦点回到「公告」，也不画圈。键盘一导航圈就显出来；
## 键盘走到「公告」按回车打开 / 关上时照常亮圈。
## 走真实 Main，用 Input.parse_input_event 发真实鼠标 / 触屏（触屏会由引擎合成鼠标）。

const VIEWS := [Vector2i(1280, 720), Vector2i(390, 844), Vector2i(844, 390)]

var checks := 0
var failures: Array[String] = []
var main


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for dims: Vector2i in VIEWS:
		for mode: String in ["mouse", "touch", "keyboard"]:
			await _spawn(dims)
			if mode == "keyboard": await _check_keyboard(dims)
			else: await _check_pointer(dims, mode == "touch")
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
	main._toggle_pause()
	await _settle()


func _settle(frames := 6) -> void:
	for i in frames:
		await process_frame


func _owner() -> Control:
	return root.gui_get_focus_owner()


func _ring() -> bool:
	return _owner() != null and _owner().has_focus(true)


func _name(c: Control) -> String:
	return "<none>" if c == null else "%s '%s'" % [c.name, (c as Button).text.replace("\n", " ") if c is Button else ""]


func _key(code: Key) -> void:
	for down: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.pressed = down
		Input.parse_input_event(ev)
		await process_frame


func _tap(control: Control, touch: bool) -> void:
	# Main 在触屏后 400ms 内吞掉同源合成鼠标；两次点按之间留够间隔。
	await create_timer(0.45).timeout
	var at := control.get_global_rect().get_center()
	for down: bool in [true, false]:
		var ev: InputEvent
		if touch:
			var t := InputEventScreenTouch.new()
			t.position = at
			t.pressed = down
			ev = t
		else:
			var m := InputEventMouseButton.new()
			m.button_index = MOUSE_BUTTON_LEFT
			m.position = at
			m.global_position = at
			m.pressed = down
			ev = m
		Input.parse_input_event(ev)
		await process_frame
	await _settle()


func _check_pointer(dims: Vector2i, touch: bool) -> void:
	var entry: Button = main._release_button
	for round: int in 2:
		var tag := "%s %s round %d" % [dims, "touch" if touch else "mouse", round + 1]
		_check(entry.is_visible_in_tree(), "%s: 公告 entry visible" % tag)
		await _tap(entry, touch)
		var panel = main._release_panel
		_check(panel != null and panel.visible, "%s: tapping 公告 opens the notes" % tag)
		if panel == null or not panel.visible:
			return
		_check(_owner() == panel.back, "%s: focus goes to 返回歇一下, got %s" % [tag, _name(_owner())])
		_check(not _ring(), "%s: pointer-opened notes draw no focus ring" % tag)
		await _tap(panel.back, touch)
		_check(not panel.visible and main._pause_screen.visible, "%s: 返回歇一下 returns to the pause menu" % tag)
		_check(_owner() == entry, "%s: focus returns to 公告, got %s" % [tag, _name(_owner())])
		_check(not _ring(), "%s: pointer-closed notes leave no ring on 公告" % tag)
	var etag := "%s %s-closed then Enter" % [dims, "touch" if touch else "mouse"]
	await _key(KEY_ENTER)
	await _settle()
	var reopened = main._release_panel
	_check(reopened.visible, "%s: Enter on the hidden-focused 公告 reopens the notes" % etag)
	_check(_owner() == reopened.back and _ring(), "%s: keyboard reopen rings 返回歇一下, got %s" % [etag, _name(_owner())])
	await _key(KEY_ESCAPE)
	_check(not reopened.visible and _owner() == entry and _ring(), "%s: Escape returns a ringed focus to 公告, got %s" % [etag, _name(_owner())])
	var ktag := "%s %s then keyboard" % [dims, "touch" if touch else "mouse"]
	await _tap(entry, touch)
	var notes = main._release_panel
	await _key(KEY_TAB)
	_check(_ring() and notes.is_ancestor_of(_owner()), "%s: first Tab shows the ring inside the notes, got %s" % [ktag, _name(_owner())])
	await _key(KEY_ESCAPE)
	_check(not notes.visible and _owner() == entry, "%s: Escape returns focus to 公告, got %s" % [ktag, _name(_owner())])
	_check(_ring(), "%s: keyboard-closed notes show the ring on 公告" % ktag)


func _check_keyboard(dims: Vector2i) -> void:
	var tag := "%s keyboard" % dims
	var entry: Button = main._release_button
	await _key(KEY_DOWN)
	entry.grab_focus()
	await _settle()
	_check(_ring() and _owner() == entry, "%s: keyboard focus on 公告 shows the ring" % tag)
	await _key(KEY_ENTER)
	await _settle()
	var panel = main._release_panel
	_check(panel != null and panel.visible, "%s: Enter on 公告 opens the notes" % tag)
	if panel == null or not panel.visible:
		return
	_check(_owner() == panel.back and _ring(), "%s: keyboard-opened notes ring 返回歇一下, got %s" % [tag, _name(_owner())])
	await _key(KEY_ENTER)
	await _settle()
	_check(not panel.visible and main._pause_screen.visible, "%s: Enter on 返回歇一下 returns to the pause menu" % tag)
	_check(_owner() == entry and _ring(), "%s: keyboard-closed notes ring 公告, got %s" % [tag, _name(_owner())])


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error(label)


func _finish() -> void:
	if main != null:
		main.queue_free()
	_check(checks >= 60, "suite ran enough checks (%d)" % checks)
	for failure in failures:
		print("FAIL: ", failure)
	print("RELEASE_NOTES_POINTER_FOCUS checks=%d failures=%d" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)
