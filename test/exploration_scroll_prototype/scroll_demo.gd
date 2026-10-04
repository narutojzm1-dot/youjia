extends Node
# 画卷原型的脚本化演示（#199 体验证据）：按时间表把真实输入事件送进输入管线，
# 配合 --write-movie 录制；顶部字幕说明当前步骤。不参与 Web 导出。

const PROTOTYPE := preload("res://test/exploration_scroll_prototype/scroll_prototype.tscn")

## [开始秒数, 动作, 字幕]
const TIMELINE := [
	[0.0, "", "停在原地：没有输入就不会前进"],
	[2.0, "right_down", "按住 → 向右走，相机跟随"],
	[4.0, "right_up", "松开即停，可以停下看"],
	[7.5, "right_down", "继续走到占位停留点 A"],
	[8.6, "right_up", "停在停留点：只有轻提示，不计进度"],
	[12.0, "touch_left_down", "触屏：按住左半屏向左走"],
	[14.0, "touch_cancel", "系统取消触摸：立即停住"],
	[15.5, "left_down", "按住 ← 一直走到画卷左端"],
	[19.0, "", "左端：相机停在轴头内，不露空白"],
	[20.5, "left_up", ""],
	[21.0, "low_motion", "L 切换低动效：行走不再起伏"],
	[21.5, "right_down", "低动效下向右走"],
	[24.0, "focus_out", "模拟窗口失焦：按住的键被清掉"],
	[25.5, "focus_in", "回到窗口：不会自己继续走"],
	[27.5, "right_up", ""],
	[28.0, "quit", ""],
]

var _prototype: Node
var _caption: Label
var _time := 0.0
var _next := 0


func _ready() -> void:
	_prototype = PROTOTYPE.instantiate()
	add_child(_prototype)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_caption = Label.new()
	_caption.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_caption.offset_top = 84
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.add_theme_font_size_override("font_size", 22)
	_caption.add_theme_color_override("font_color", Color(0.55, 0.20, 0.15))
	if ResourceLoader.exists(_prototype.CJK_FONT):
		_caption.add_theme_font_override("font", load(_prototype.CJK_FONT))
	layer.add_child(_caption)


func _process(delta: float) -> void:
	_time += delta
	while _next < TIMELINE.size() and _time >= float(TIMELINE[_next][0]):
		var entry: Array = TIMELINE[_next]
		_next += 1
		if String(entry[2]) != "":
			_caption.text = "演示：" + String(entry[2])
		_act(String(entry[1]))


func _act(action: String) -> void:
	var width: float = get_viewport().get_visible_rect().size.x
	match action:
		"right_down", "right_up":
			_key(KEY_RIGHT, action == "right_down")
		"left_down", "left_up":
			_key(KEY_LEFT, action == "left_down")
		"low_motion":
			_key(KEY_L, true)
			_key(KEY_L, false)
		"touch_left_down":
			_touch(width * 0.2, true, false)
		"touch_cancel":
			_touch(width * 0.2, false, true)
		"focus_out":
			_prototype.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
		"focus_in":
			_prototype.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
		"quit":
			get_tree().quit()


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func _touch(x: float, pressed: bool, canceled: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = Vector2(x, get_viewport().get_visible_rect().size.y * 0.6)
	event.pressed = pressed
	event.canceled = canceled
	Input.parse_input_event(event)
