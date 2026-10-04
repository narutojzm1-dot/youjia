extends Node2D
# 模拟小院（#200）：只为验证回院适配，提供可走动的院子、自己的相机、保存状态文字和「出门」请求。
# 不是正式小院，不接 Main / SaveStore；保存状态完全由适配器按核心与假宿主结果填写。

const ScrollInput := preload("res://test/exploration_scroll_prototype/scroll_input.gd")
const CJK_FONT := "res://assets/template/fonts/NotoSansSC-VF.subset.woff2"

signal set_out_requested
## 假宿主控制键（测试 / 演示用）：把按键翻译成动作名交给适配器
signal host_action_requested(action: String)
## 小院相机与输入刚接管时发出；测试在这一刻核对旧画卷是否已拆干净
signal activated

const WIDTH := 1800.0
const HEIGHT := 720.0
const GROUND_Y := 560.0
const MARGIN := 120.0
const SPEED := 160.0
const TOP_BAR := 96.0
const SET_OUT_ZONE_WIDTH := 180.0
const PAPER := Color(0.95, 0.91, 0.82)
const INK := Color(0.29, 0.32, 0.30)
## 数字键 → 假宿主动作；只在隔离原型里存在，真实平台没有这些按钮
const HOST_KEYS := {
	KEY_1: "ok", KEY_2: "fail", KEY_3: "lost", KEY_4: "unknown",
	KEY_5: "resolve", KEY_6: "next", KEY_7: "retry",
	KEY_8: "unknown_lost", KEY_9: "terminate", KEY_0: "settle",
}

var input := ScrollInput.new()
var x := WIDTH * 0.5
var active := false
var camera: Camera2D
var walker: Node2D
var _status: Label
## CanvasLayer 不随父节点隐藏，需要单独开关
var _hud: CanvasLayer
var _touch_dirs := {}


func _ready() -> void:
	_build_ground()
	walker = Node2D.new()
	walker.name = "Walker"
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-16, 0), Vector2(-18, -52), Vector2(0, -64), Vector2(18, -52), Vector2(16, 0)])
	body.color = Color(0.36, 0.42, 0.52)
	walker.add_child(body)
	add_child(walker)
	camera = Camera2D.new()
	camera.name = "YardCamera"
	camera.enabled = false
	add_child(camera)
	_build_hud()
	deactivate()


func _process(delta: float) -> void:
	if not active:
		return
	x = clampf(x + input.direction() * SPEED * delta, MARGIN, WIDTH - MARGIN)
	walker.position = Vector2(x, GROUND_Y)
	var half := get_viewport().get_visible_rect().size.x * 0.5
	camera.position = Vector2(clampf(x, minf(half, WIDTH * 0.5), maxf(WIDTH - half, WIDTH * 0.5)), HEIGHT * 0.5)


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventKey and not event.echo:
		var key := event as InputEventKey
		var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
		if code == KEY_LEFT or code == KEY_A:
			_key("key_%d" % code, -1, key.pressed)
		elif code == KEY_RIGHT or code == KEY_D:
			_key("key_%d" % code, 1, key.pressed)
		elif key.pressed and code == KEY_O:
			set_out_requested.emit()
		elif key.pressed and HOST_KEYS.has(code):
			host_action_requested.emit(HOST_KEYS[code])
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var source := "touch_%d" % touch.index
		if touch.pressed and not touch.canceled:
			if touch.position.y < TOP_BAR:
				if touch.position.x > get_viewport().get_visible_rect().size.x - SET_OUT_ZONE_WIDTH:
					set_out_requested.emit()
				return
			_touch(source, touch.position.x)
		else:
			_touch_dirs.erase(source)
			input.release(source)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		var source := "touch_%d" % drag.index
		## 只跟随在院内按下过的手指：画卷里按住、回院后才拖动的手指不会让人自己走
		if _touch_dirs.has(source):
			_touch(source, drag.position.x)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			release_all()


func release_all() -> void:
	input.clear()
	_touch_dirs.clear()


## 回院时由适配器调用：输入从空开始，相机接管视口
func activate() -> void:
	release_all()
	active = true
	visible = true
	_hud.visible = true
	set_process(true)
	set_process_unhandled_input(true)
	camera.enabled = true
	camera.make_current()
	_process(0.0)
	activated.emit()


func deactivate() -> void:
	release_all()
	active = false
	visible = false
	_hud.visible = false
	set_process(false)
	set_process_unhandled_input(false)
	camera.enabled = false


func set_status(text: String) -> void:
	_status.text = text


func status_text() -> String:
	return _status.text


func _key(source: String, dir: int, pressed: bool) -> void:
	if pressed:
		input.press(source, dir)
	else:
		input.release(source)


func _touch(source: String, screen_x: float) -> void:
	var dir := -1 if screen_x < get_viewport().get_visible_rect().size.x * 0.5 else 1
	if _touch_dirs.get(source, 0) != dir:
		_touch_dirs[source] = dir
		input.press(source, dir)


func _build_ground() -> void:
	## 天和地都向外多铺一段：相机高度固定，窗口比 720 高时上下不露底色
	_rect(Vector2(-WIDTH, -HEIGHT), Vector2(WIDTH * 3, HEIGHT * 2), Color(0.86, 0.90, 0.84))
	_rect(Vector2(-WIDTH, 470), Vector2(WIDTH * 3, HEIGHT), Color(0.78, 0.72, 0.58))
	## 院墙与院门：几何占位
	_rect(Vector2(0, 380), Vector2(WIDTH, 24), Color(0.62, 0.55, 0.47))
	_rect(Vector2(WIDTH * 0.5 - 70, 330), Vector2(140, 150), Color(0.50, 0.38, 0.28))
	_rect(Vector2(260, 420), Vector2(180, 110), Color(0.55, 0.66, 0.50))
	_rect(Vector2(WIDTH - 440, 430), Vector2(200, 100), Color(0.70, 0.62, 0.50))
	var gate := Label.new()
	gate.text = "院门（占位）"
	gate.position = Vector2(WIDTH * 0.5 - 60, 290)
	gate.add_theme_color_override("font_color", INK)
	_apply_font(gate, 20)
	add_child(gate)


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "YardHud"
	add_child(hud)
	_hud = hud
	var tag := Label.new()
	tag.text = "模拟小院 · 占位 · 不接存档"
	tag.position = Vector2(16, 12)
	_style(tag, 18)
	hud.add_child(tag)
	var set_out := Label.new()
	set_out.text = "出门（O）"
	set_out.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	set_out.offset_left = -SET_OUT_ZONE_WIDTH + 16
	set_out.offset_top = 12
	set_out.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_style(set_out, 18)
	hud.add_child(set_out)
	_status = Label.new()
	_status.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_status.offset_top = 56
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style(_status, 18)
	hud.add_child(_status)
	var keys := Label.new()
	keys.text = "← → 在院里走 · 假宿主控制（测试用）：1 成功 2 写入失败 3 落盘但回调丢失 4 未知（已落盘）8 未知（未落盘）9 旧写入已终止 5 静止核验 6 重放队首 7 重试 0 空手收尾"
	keys.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	keys.offset_top = -40
	keys.grow_vertical = Control.GROW_DIRECTION_BEGIN
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keys.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style(keys, 14)
	hud.add_child(keys)


func _style(label: Label, size: int) -> void:
	label.add_theme_color_override("font_color", INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(label, size)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(PAPER, 0.82)
	box.set_content_margin_all(6)
	box.set_corner_radius_all(4)
	label.add_theme_stylebox_override("normal", box)


func _apply_font(label: Label, size: int) -> void:
	label.add_theme_font_size_override("font_size", size)
	if ResourceLoader.exists(CJK_FONT):
		label.add_theme_font_override("font", load(CJK_FONT))


func _rect(origin: Vector2, size: Vector2, color: Color) -> void:
	var shape := Polygon2D.new()
	shape.polygon = PackedVector2Array([origin, origin + Vector2(size.x, 0), origin + size, origin + Vector2(0, size.y)])
	shape.color = color
	add_child(shape)
