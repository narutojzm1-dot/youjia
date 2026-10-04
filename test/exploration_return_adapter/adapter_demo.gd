extends Node
# 回院适配的脚本化演示（#200 体验证据）：按时间表把真实输入事件和假宿主结果送进适配器，
# 配合 --write-movie 录制；顶部字幕说明当前步骤，底部滚动显示事件顺序。不参与 Web 导出。

const ADAPTER := preload("res://test/exploration_return_adapter/return_adapter.tscn")

## [开始秒数, 动作, 字幕]
const TIMELINE := [
	[0.0, "", "模拟小院：保存状态由假宿主决定"],
	[2.0, "key_o", "O 出门：进入画卷"],
	[3.0, "skip_to_b", "（演示快进到占位停留点 B 附近）"],
	[3.5, "right_down", "向右走到停留点 B"],
	[5.0, "right_up", ""],
	[5.5, "key_e", "E 停下看看：经核心带上一样东西"],
	[8.0, "key_r", "R 回院：核心进入待提交后，先拆画卷再开放小院"],
	[10.5, "right_down", "保存中也能在院里走"],
	[12.0, "right_up", ""],
	[12.5, "host_unknown", "假宿主：结果未知 → 只说还在确认，不显示已收好"],
	[15.0, "left_down", "院里照常走动"],
	[16.5, "left_up", ""],
	[17.0, "key_o", "持有未定的保存时出门被拒"],
	[20.0, "host_resolve", "假宿主：静止核验确认已落盘 → 这时才显示已收好"],
	[23.0, "key_o", "再出门一趟"],
	[23.5, "skip_to_b", ""],
	[24.0, "key_e", "带上东西"],
	[25.0, "key_r", "回院"],
	[26.5, "host_fail", "假宿主：写入失败 → 说明没收好，院里照常"],
	[29.5, "host_retry", "重试：重新写入，显示保存中"],
	[31.5, "host_ok", "重试成功 → 已收好"],
	[34.5, "quit", ""],
]

var _adapter: Node
var _caption: Label
var _trail: Label
var _time := 0.0
var _next := 0


func _ready() -> void:
	_adapter = ADAPTER.instantiate()
	add_child(_adapter)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_caption = _label(layer, Control.PRESET_TOP_WIDE, 140, 20)
	_trail = _label(layer, Control.PRESET_BOTTOM_WIDE, -96, 13)


func _process(delta: float) -> void:
	_time += delta
	while _next < TIMELINE.size() and _time >= float(TIMELINE[_next][0]):
		var step: Array = TIMELINE[_next]
		_next += 1
		if not String(step[2]).is_empty():
			_caption.text = step[2]
		_act(step[1])
	var tail: Array = _adapter.events.slice(maxi(0, _adapter.events.size() - 9))
	_trail.text = "事件顺序：" + " → ".join(PackedStringArray(tail))


func _act(action: String) -> void:
	match action:
		"key_o", "key_e", "key_r":
			var code: Key = {"key_o": KEY_O, "key_e": KEY_E, "key_r": KEY_R}[action]
			Input.parse_input_event(_key(code, true))
			Input.parse_input_event(_key(code, false))
		"right_down", "right_up":
			Input.parse_input_event(_key(KEY_RIGHT, action == "right_down"))
		"left_down", "left_up":
			Input.parse_input_event(_key(KEY_LEFT, action == "left_down"))
		"skip_to_b":
			if _adapter.scroll != null:
				_adapter.scroll.model.x = 1990.0
		"host_unknown", "host_resolve", "host_fail", "host_retry", "host_ok":
			_adapter.host_action(action.trim_prefix("host_"))
		"quit":
			get_tree().quit()


func _key(code: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	return event


func _label(layer: CanvasLayer, preset: Control.LayoutPreset, offset: float, size: int) -> Label:
	var label := Label.new()
	label.set_anchors_and_offsets_preset(preset)
	if preset == Control.PRESET_BOTTOM_WIDE:
		label.offset_top = offset
		label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	else:
		label.offset_top = offset
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
