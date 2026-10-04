extends SceneTree
# 画卷漫步隔离原型（#199）的隔离测试：只在独立最小项目里运行。
# 覆盖：停下不自动推进、两端夹住、各种视口不露空白且角色在画面内、
# 键盘 / 触屏按住松开与取消、失焦不粘键、低动效无起伏、重复加载不累积节点与连接。

const ScrollWalkModel := preload("res://test/exploration_scroll_prototype/scroll_walk_model.gd")
const ScrollInput := preload("res://test/exploration_scroll_prototype/scroll_input.gd")
const PROTOTYPE := "res://test/exploration_scroll_prototype/scroll_prototype.tscn"

## 桌面、宽屏、手机竖屏 / 横屏、超宽矮条、极小窗口
const VIEWPORTS := [
	Vector2(1280, 720), Vector2(1920, 1080), Vector2(390, 844), Vector2(844, 390),
	Vector2(6000, 400), Vector2(200, 160), Vector2(1, 1),
]

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_model_stays_put()
	_model_clamps()
	_model_frames()
	_input_sources()
	await _scene_keyboard()
	await _scene_touch()
	await _scene_focus()
	await _scene_resize()
	await _scene_low_motion()
	await _scene_reload()
	for failure: String in failures:
		push_error(failure)
	print("EXPLORATION SCROLL PROTOTYPE %s %d" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)


## 1. 停下即停留：没有方向输入时多次推进时间也不移动
func _model_stays_put() -> void:
	var m = ScrollWalkModel.new()
	var start: float = m.x
	for i in 600:
		m.step(1.0 / 60.0)
	_check(m.x == start, "no input never advances the walker")
	m.set_direction(1)
	m.step(1.0)
	_check(is_equal_approx(m.x, start + ScrollWalkModel.WALK_SPEED), "holding right walks at the experimental speed")
	m.set_direction(0)
	var stopped: float = m.x
	m.step(5.0)
	_check(m.x == stopped and not m.is_walking(), "letting go stops on the spot")
	_check(m.facing == 1, "facing stays where the walker stopped")


## 2. 两端夹住：走到可走区两端停住，不越界、不触发任何结束
func _model_clamps() -> void:
	var m = ScrollWalkModel.new()
	m.set_direction(-1)
	m.step(1000.0)
	_check(m.x == m.walk_min() and not m.is_walking(), "the left end clamps")
	m.set_direction(1)
	m.step(1000.0)
	_check(m.x == m.walk_max() and not m.is_walking(), "the right end clamps")
	_check(m.facing == 1, "facing follows the last direction")


## 3. 取景：任何视口下相机窗口都在画卷内（两端和上下不露空白），角色始终在画面内
func _model_frames() -> void:
	var m = ScrollWalkModel.new()
	for size: Vector2 in VIEWPORTS:
		for spot: float in [m.walk_min(), ScrollWalkModel.SCROLL_LENGTH * 0.5, m.walk_max()]:
			m.x = spot
			var frame: Dictionary = m.view(size)
			var half: Vector2 = frame["visible"] * 0.5
			var cam: Vector2 = frame["camera"]
			var tag := "%dx%d at %d" % [size.x, size.y, spot]
			_check(cam.x - half.x >= -0.01 and cam.x + half.x <= ScrollWalkModel.SCROLL_LENGTH + 0.01, "%s: no blank past either end" % tag)
			_check(cam.y - half.y >= -0.01 and cam.y + half.y <= ScrollWalkModel.SCROLL_HEIGHT + 0.01, "%s: no blank above or below" % tag)
			_check(absf(m.x - cam.x) <= half.x + 0.01, "%s: the walker stays in view" % tag)
			_check(absf(ScrollWalkModel.GROUND_Y - cam.y) <= half.y + 0.01, "%s: the ground stays in view" % tag)


## 4. 输入聚合：最近按下的来源优先，松开回到仍按住的来源，清空后为 0
func _input_sources() -> void:
	var i = ScrollInput.new()
	i.press("key_right", 1)
	_check(i.direction() == 1, "a held right key walks right")
	i.press("key_left", -1)
	_check(i.direction() == -1, "the latest press wins")
	i.release("key_left")
	_check(i.direction() == 1, "releasing the latest falls back to the one still held")
	i.release("touch_9")
	_check(i.direction() == 1, "releasing an unknown source changes nothing")
	i.press("key_right", 1)
	_check(i.held_count() == 1, "pressing the same source twice does not stack")
	i.clear()
	_check(i.direction() == 0 and i.held_count() == 0, "clearing drops every source")


## 5. 场景键盘：按住走、松开停、按键重复（echo）不额外入栈
func _scene_keyboard() -> void:
	var p = await _spawn()
	var start: float = p.model.x
	p._unhandled_input(_key(KEY_RIGHT, true))
	p._process(0.5)
	_check(p.model.x > start, "holding the right arrow walks right")
	var echo := _key(KEY_RIGHT, true)
	echo.echo = true
	p._unhandled_input(echo)
	_check(p.input.held_count() == 1, "key echo does not stack a source")
	p._unhandled_input(_key(KEY_RIGHT, false))
	var held: float = p.model.x
	p._process(2.0)
	_check(p.model.x == held, "releasing the key stops on the spot")
	p._unhandled_input(_key(KEY_A, true))
	p._process(0.5)
	_check(p.model.x < held and p.model.facing == -1, "A walks left and turns the walker")
	p._unhandled_input(_key(KEY_A, false))
	await _despawn(p)


## 6. 场景触屏：左右半屏按住、拖过中线换向、松开或系统取消即停、多指以最近为准
func _scene_touch() -> void:
	var p = await _spawn()
	var width: float = p.get_viewport().get_visible_rect().size.x
	p._unhandled_input(_touch(0, width * 0.8, true))
	_check(p.input.direction() == 1, "holding the right half walks right")
	p._unhandled_input(_drag(0, width * 0.2))
	_check(p.input.direction() == -1, "dragging across the middle turns around")
	p._unhandled_input(_touch(1, width * 0.9, true))
	_check(p.input.direction() == 1, "a second finger takes over")
	p._unhandled_input(_touch(1, width * 0.9, false))
	_check(p.input.direction() == -1, "lifting the second finger returns to the first")
	var cancel := _touch(0, width * 0.2, false)
	cancel.canceled = true
	p._unhandled_input(cancel)
	var spot: float = p.model.x
	p._process(1.0)
	_check(p.input.direction() == 0 and p.model.x == spot, "a cancelled touch stops on the spot")
	p._unhandled_input(_drag(0, width * 0.9))
	_check(p.input.direction() == 0, "a stray drag after the finger is gone does nothing")
	await _despawn(p)


## 7. 失焦不粘键：按住时失焦，回来后不会自己继续走
func _scene_focus() -> void:
	for what: int in [Node.NOTIFICATION_APPLICATION_FOCUS_OUT, Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT, Node.NOTIFICATION_APPLICATION_PAUSED]:
		var p = await _spawn()
		var width: float = p.get_viewport().get_visible_rect().size.x
		p._unhandled_input(_key(KEY_RIGHT, true))
		p._unhandled_input(_touch(0, width * 0.1, true))
		p.notification(what)
		var spot: float = p.model.x
		p.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
		p._process(1.0)
		_check(p.input.held_count() == 0 and p.model.x == spot, "notification %d clears held keys and touches" % what)
		## 失焦期间松开的键会以 released 到达，不能把方向翻回来
		p._unhandled_input(_key(KEY_RIGHT, false))
		p._process(1.0)
		_check(p.model.x == spot, "a late key release after focus loss stays still (%d)" % what)
		await _despawn(p)


## 8. 视口变化：相机随尺寸重新取景，角色不被丢出画面
func _scene_resize() -> void:
	var p = await _spawn()
	for size: Vector2 in VIEWPORTS:
		for spot: float in [p.model.walk_min(), p.model.walk_max()]:
			p.model.x = spot
			p.layout_for(size)
			var half: Vector2 = size / p.camera.zoom.x * 0.5
			_check(absf(p.model.x - p.camera.position.x) <= half.x + 0.01, "%dx%d: the walker is on screen after a resize" % [size.x, size.y])
			_check(p.camera.position.x - half.x >= -0.01 and p.camera.position.x + half.x <= ScrollWalkModel.SCROLL_LENGTH + 0.01, "%dx%d: the camera stays inside the scroll" % [size.x, size.y])
	await _despawn(p)


## 9. 低动效：行走起伏归零，相机缩放不随行走变化
func _scene_low_motion() -> void:
	var p = await _spawn()
	p._unhandled_input(_key(KEY_RIGHT, true))
	var zoom: Vector2 = p.camera.zoom
	var bobbed := false
	for i in 20:
		p._process(1.0 / 30.0)
		bobbed = bobbed or p.body_offset() != 0.0
	_check(bobbed, "normal motion has a gentle walking bob")
	p._unhandled_input(_key(KEY_L, true))
	var still := true
	for i in 20:
		p._process(1.0 / 30.0)
		still = still and p.body_offset() == 0.0
	_check(p.low_motion and still, "low motion removes the walking bob")
	_check(p.camera.zoom == zoom, "walking never changes the camera zoom")
	p._unhandled_input(_key(KEY_RIGHT, false))
	p._process(0.1)
	_check(p.body_offset() == 0.0, "standing still has no bob")
	await _despawn(p)


## 10. 重复加载：反复实例化与释放后，节点数、孤儿节点与视口信号连接回到基线
func _scene_reload() -> void:
	await process_frame
	var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	var links := root.size_changed.get_connections().size()
	for i in 12:
		var p = await _spawn()
		p._unhandled_input(_key(KEY_RIGHT, true))
		p._process(0.2)
		await _despawn(p)
	await process_frame
	_check(Performance.get_monitor(Performance.OBJECT_NODE_COUNT) == nodes, "repeated loads leave no extra nodes")
	_check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) == orphans, "repeated loads leave no orphan nodes")
	_check(root.size_changed.get_connections().size() == links, "repeated loads leave no viewport connections")


func _spawn():
	var p = (load(PROTOTYPE) as PackedScene).instantiate()
	root.add_child(p)
	await process_frame
	return p


func _despawn(p: Node) -> void:
	p.queue_free()
	await process_frame
	await process_frame


func _key(code: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	return event


func _touch(index: int, x: float, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = Vector2(x, 300)
	event.pressed = pressed
	return event


func _drag(index: int, x: float) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = Vector2(x, 300)
	return event


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
