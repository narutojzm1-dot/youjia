extends Node
# 首条画卷体验研究的脚本化演示（#201 体验证据）：按时间表把真实键盘 / 触摸事件和假宿主结果送进研究切片，
# 配合 --write-movie 按横屏、竖屏分别录制。顶部字幕说明当前步骤，触摸处画一个圆圈，底部滚动显示事件顺序。
# 不参与 Web 导出。

const EXPERIENCE := preload("res://test/exploration_first_experience/first_experience.tscn")

## [开始秒数, 动作, 字幕]
const TIMELINE := [
	[0.0, "", "模拟小院：保存结果由假宿主决定"],
	[1.5, "key_o", "出门：进入画卷"],
	[2.5, "skip:700", ""],
	[2.5, "right_down", "向右走向占位停留点 A"],
	[4.0, "right_up", "松手即停"],
	[4.5, "key_e", "停下看看：相机收进这一处小景，这里只是看看"],
	[7.5, "key_e", "看够了，继续走"],
	[7.8, "skip:2000", ""],
	[8.0, "right_down", "走向占位停留点 B"],
	[9.3, "right_up", ""],
	[9.6, "key_e", "停下看：这里有一样占位物，带不带都行"],
	[12.0, "key_e", "不带，继续走"],
	[12.5, "key_r", "随时回院：空手回来"],
	[14.0, "host_ok", "假宿主确认 → 这趟散步已记下（空手不说「已收好」）"],
	[17.0, "key_o", "再出门一趟"],
	[17.2, "skip:2200", ""],
	[17.5, "tap_top", "点顶部：停下看看"],
	[19.5, "key_f", "F 对照：跟随取景"],
	[22.0, "key_f", "F 回到收景：停稳就看全这一处小景"],
	[24.5, "stray_down", "观察中误触半屏：角色不会继续走"],
	[25.5, "stray_up", ""],
	[26.0, "tap_pick", "点左下：带上占位物"],
	[28.0, "tap_pick", "改主意：放回"],
	[29.5, "tap_pick", "还是带上"],
	[31.0, "tap_return", "点右上：中途回院，不必走回起点"],
	[33.0, "host_ok", "假宿主确认 → 已收好"],
	[36.0, "quit", ""],
]

var _experience: Node
var _caption: Label
var _trail: Label
var _rings: Node2D
var _time := 0.0
var _next := 0
var _taps: Array[Dictionary] = []


func _ready() -> void:
	_experience = EXPERIENCE.instantiate()
	add_child(_experience)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_rings = Node2D.new()
	_rings.draw.connect(_draw_rings)
	layer.add_child(_rings)
	_caption = _label(layer, Control.PRESET_TOP_WIDE, 140, 20)
	_trail = _label(layer, Control.PRESET_BOTTOM_WIDE, -180, 12)
	## 事件行放在观察态底部按钮之上，不遮住按钮
	_trail.offset_bottom = -124


func _process(delta: float) -> void:
	_time += delta
	while _next < TIMELINE.size() and _time >= float(TIMELINE[_next][0]):
		var step: Array = TIMELINE[_next]
		_next += 1
		if not String(step[2]).is_empty():
			_caption.text = step[2]
		_act(step[1])
	var tail: Array = _experience.events.slice(maxi(0, _experience.events.size() - 6))
	_trail.text = "事件：" + " → ".join(PackedStringArray(tail))
	_taps = _taps.filter(func(tap: Dictionary) -> bool: return _time - float(tap["at"]) < 0.8 or tap.get("held", false))
	_rings.queue_redraw()


func _act(action: String) -> void:
	var size := get_viewport().get_visible_rect().size
	match action:
		"key_o", "key_e", "key_r", "key_f":
			var code: Key = {"key_o": KEY_O, "key_e": KEY_E, "key_r": KEY_R, "key_f": KEY_F}[action]
			Input.parse_input_event(_key(code, true))
			Input.parse_input_event(_key(code, false))
		"right_down", "right_up":
			Input.parse_input_event(_key(KEY_RIGHT, action == "right_down"))
		"tap_top":
			_tap(0, Vector2(size.x * 0.3, 40.0))
		"tap_pick":
			_tap(1, Vector2(size.x * 0.25, size.y - 40.0))
		"tap_return":
			_tap(2, Vector2(size.x - 40.0, 40.0))
		"stray_down", "stray_up":
			var at := Vector2(size.x * 0.8, size.y * 0.5)
			Input.parse_input_event(_touch(3, at, action == "stray_down"))
			if action == "stray_down":
				_taps.append({"at": _time, "pos": at, "held": true})
			else:
				_taps = _taps.filter(func(tap: Dictionary) -> bool: return not tap.get("held", false))
		"host_ok":
			_experience.host_action("ok")
		"quit":
			get_tree().quit()
		_:
			if action.begins_with("skip:") and _experience.scroll != null:
				_experience.scroll.model.x = float(action.trim_prefix("skip:"))


func _tap(index: int, at: Vector2) -> void:
	Input.parse_input_event(_touch(index, at, true))
	Input.parse_input_event(_touch(index, at, false))
	_taps.append({"at": _time, "pos": at})


func _draw_rings() -> void:
	for tap: Dictionary in _taps:
		_rings.draw_arc(tap["pos"], 26.0, 0.0, TAU, 32, Color(0.75, 0.25, 0.20, 0.9), 4.0)


func _key(code: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	return event


func _touch(index: int, at: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = pressed
	return event


func _label(layer: CanvasLayer, preset: Control.LayoutPreset, offset: float, size: int) -> Label:
	var label := Label.new()
	label.set_anchors_and_offsets_preset(preset)
	label.offset_top = offset
	if preset == Control.PRESET_BOTTOM_WIDE:
		label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(0.15, 0.12, 0.10))
	var font := "res://assets/template/fonts/NotoSansSC-VF.subset.woff2"
	if ResourceLoader.exists(font):
		label.add_theme_font_override("font", load(font))
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1.0, 0.97, 0.88, 0.9)
	box.set_content_margin_all(6)
	label.add_theme_stylebox_override("normal", box)
	layer.add_child(label)
	return label
