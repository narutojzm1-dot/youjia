extends SceneTree
## 触屏点按 HUD 按钮后，按钮不再停在鼠标悬停样式；按钮照常生效。
## 走真实 Main 与 Godot 输入管线（Input.parse_input_event，引擎照常由触屏合成鼠标按键）：
## - 点「大太阳」：天气切换，按钮不留悬停；
## - 手指按住时不提前撤悬停 / 按下态，抬起后再撤；
## - 抬指后浏览器补发的鼠标移动（同一位置、很快到达）不算换回鼠标；
## - 真鼠标移上去照常悬停，从没碰过触屏的鼠标玩家不受影响。

const VIEWS := [Vector2i(1280, 720), Vector2i(390, 844), Vector2i(844, 390)]

var checks := 0
var failures: Array[String] = []
var main


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for dims: Vector2i in VIEWS:
		await _spawn(dims)
		await _check_mouse_only(dims)
		await _check_touch_tap(dims)
		await _check_touch_hold(dims)
		await _check_synth_mouse(dims)
		await _check_real_mouse_after_touch(dims)
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


func _chip() -> Button:
	return main._weather_chip


func _at() -> Vector2:
	return _chip().get_global_rect().get_center()


func _hovered() -> bool:
	return _chip().is_hovered() or root.gui_get_hovered_control() == _chip()


func _send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await process_frame


func _touch(down: bool, at: Vector2) -> void:
	var t := InputEventScreenTouch.new()
	t.position = at
	t.pressed = down
	await _send(t)


func _mouse_move(at: Vector2) -> void:
	var m := InputEventMouseMotion.new()
	m.position = at
	m.global_position = at
	await _send(m)


func _mouse_click(at: Vector2) -> void:
	await _mouse_move(at)
	for down: bool in [true, false]:
		var m := InputEventMouseButton.new()
		m.button_index = MOUSE_BUTTON_LEFT
		m.position = at
		m.global_position = at
		m.pressed = down
		await _send(m)


## 先离开触屏合成窗口，避免上一项的触屏把这一项的鼠标当成合成事件。
func _cool() -> void:
	await create_timer(0.8).timeout
	await _mouse_move(Vector2(-50, -50))
	await _settle()


func _check_mouse_only(dims: Vector2i) -> void:
	var tag := "%s mouse only" % dims
	await _mouse_move(_at())
	await _settle()
	_check(_hovered(), "%s: a desktop mouse over the chip still shows hover" % tag)
	var before := _chip().text
	await _mouse_click(_at())
	await _settle()
	_check(_chip().text != before, "%s: mouse click toggles the weather (%s -> %s)" % [tag, before, _chip().text])
	_check(_hovered(), "%s: after a mouse click the pointer is still over the chip, hover stays" % tag)
	await _cool()


func _check_touch_tap(dims: Vector2i) -> void:
	var tag := "%s touch tap" % dims
	var before := _chip().text
	await _touch(true, _at())
	await _touch(false, _at())
	await _settle()
	_check(_chip().text != before, "%s: tap toggles the weather (%s -> %s)" % [tag, before, _chip().text])
	_check(not _hovered(), "%s: after the finger lifts the chip is not left in hover" % tag)
	_check(_chip().get_draw_mode() == BaseButton.DRAW_NORMAL, "%s: chip draws normal, got draw mode %d" % [tag, _chip().get_draw_mode()])
	await _cool()


func _check_touch_hold(dims: Vector2i) -> void:
	var tag := "%s touch hold" % dims
	await _touch(true, _at())
	await _settle()
	_check(_chip().get_draw_mode() != BaseButton.DRAW_NORMAL, "%s: while the finger is down the chip keeps its pressed look, got %d" % [tag, _chip().get_draw_mode()])
	await _touch(false, _at())
	await _settle()
	_check(not _hovered() and _chip().get_draw_mode() == BaseButton.DRAW_NORMAL, "%s: lifting the finger clears it" % tag)
	await _cool()


func _check_synth_mouse(dims: Vector2i) -> void:
	var tag := "%s browser mouse after tap" % dims
	await _touch(true, _at())
	await _touch(false, _at())
	await _mouse_move(_at())
	await _settle()
	_check(not _hovered(), "%s: a compat mouse move right after the tap does not bring hover back" % tag)
	await _cool()


func _check_real_mouse_after_touch(dims: Vector2i) -> void:
	var tag := "%s real mouse after touch" % dims
	await _touch(true, _at())
	await _touch(false, _at())
	await _settle()
	await create_timer(0.8).timeout
	await _mouse_move(_at() + Vector2(6, 0))
	await _settle()
	_check(_hovered(), "%s: once a real mouse moves, hover works again" % tag)
	await _cool()


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error(label)


func _finish() -> void:
	if main != null:
		main.queue_free()
	_check(checks >= 24, "suite ran enough checks (%d)" % checks)
	for failure in failures:
		print("FAIL: ", failure)
	print("TOUCH_HOVER_RESET checks=%d failures=%d" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)
