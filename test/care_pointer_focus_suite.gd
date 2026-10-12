extends SceneTree
## 小鸡照料纸、菜地纸：在院里点按打开时，焦点照样交给「回到院子」（键盘随时能接着按），
## 但先不画焦点圈；键盘一导航圈就显出来。走过去按空格打开时照常亮圈。
## 走真实 Main：世界发出 chick_care_requested / plant_bed_requested，与点到小鸡 / 菜地相同。

const VIEWS := [Vector2i(1280, 720), Vector2i(390, 844), Vector2i(844, 390)]

var checks := 0
var failures: Array[String] = []
var main


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for dims: Vector2i in VIEWS:
		await _spawn(dims)
		for which: String in ["chick", "crops"]:
			await _check_panel(dims, which)
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


func _owner() -> Control:
	return root.gui_get_focus_owner()


func _ring() -> bool:
	return _owner() != null and _owner().has_focus(true)


func _name(c: Control) -> String:
	return "<none>" if c == null else "%s '%s'" % [c.name, (c as Button).text if c is Button else ""]


func _key(code: Key) -> void:
	for down: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.pressed = down
		root.push_input(ev)
		await process_frame


func _pointer(touch: bool) -> void:
	var at := Vector2(root.size) * Vector2(0.5, 0.45)
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
		root.push_input(ev)
		await process_frame


func _open(which: String) -> void:
	if which == "chick": main._world.chick_care_requested.emit()
	else: main._world.plant_bed_requested.emit()
	await _settle()


func _close(which: String) -> void:
	if which == "chick": main._hide_chick_care()
	else: main._hide_crops()
	await _settle()


func _check_panel(dims: Vector2i, which: String) -> void:
	var panel: Control = main._chick_panel if which == "chick" else main._crop_panel
	var close: Button = panel.close_button
	for touch: bool in [false, true]:
		var tag := "%s %s %s" % [dims, which, "touch" if touch else "mouse"]
		await _pointer(touch)
		await _open(which)
		_check(panel.visible, "%s: panel opens" % tag)
		_check(_owner() == close, "%s: focus still goes to 回到院子, got %s" % [tag, _name(_owner())])
		_check(not _ring(), "%s: pointer-opened panel draws no focus ring" % tag)
		await _key(KEY_TAB)
		_check(_ring() and panel.is_ancestor_of(_owner()), "%s: first Tab shows the ring inside the panel, got %s" % [tag, _name(_owner())])
		await _close(which)
		_check(not panel.visible, "%s: panel closes" % tag)
	var ktag := "%s %s keyboard" % [dims, which]
	await _key(KEY_SPACE)
	await _open(which)
	_check(panel.visible and _owner() == close, "%s: keyboard-opened panel focuses 回到院子, got %s" % [ktag, _name(_owner())])
	_check(_ring(), "%s: keyboard-opened panel shows the ring" % ktag)
	await _key(KEY_ENTER)
	await _settle()
	_check(not panel.visible, "%s: Enter on 回到院子 closes the panel" % ktag)
	if panel.visible: await _close(which)


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
	print("CARE_POINTER_FOCUS checks=%d failures=%d" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)
