extends "res://test/exploration_scroll_prototype/scroll_prototype.gd"
# 回院适配用的画卷（#200）：在 #199 原型上加「停下看看」与「回院」两个请求信号和整体失效开关。
# 只发请求，不碰探索核心与宿主；是否真的回院由适配器根据核心结果决定。

signal observe_requested(stop_id: String)
signal return_requested

## 顶部操作条高度（屏幕像素）：右端是回院，其余部分在停留点附近时是「停下看看」
const TOP_BAR := 96.0
const RETURN_ZONE_WIDTH := 180.0

## 失效后忽略一切输入与处理；只会从 true 变 false，不复用
var active := true
var _return_tag: Label
var _note: Label


func _ready() -> void:
	super()
	var hud := get_node("Hud")
	_return_tag = Label.new()
	_return_tag.text = "回院（R）"
	_return_tag.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_return_tag.offset_left = -RETURN_ZONE_WIDTH + 16
	_return_tag.offset_top = 12
	_return_tag.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_return_tag.add_theme_color_override("font_color", INK)
	_return_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(_return_tag, 18)
	_backing(_return_tag)
	hud.add_child(_return_tag)
	_note = Label.new()
	_note.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_note.offset_top = 88
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.add_theme_color_override("font_color", INK)
	_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(_note, 16)
	hud.add_child(_note)
	_hint.text = "← → / A D 或按住屏幕左右半边行走 · E 或点顶部提示停下看看 · R 或点右上角回院"


func _process(delta: float) -> void:
	if not active:
		return
	super(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
		if code == KEY_R or code == KEY_ESCAPE:
			return_requested.emit()
			return
		if code == KEY_E or code == KEY_SPACE:
			_request_observe()
			return
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		## 顶部操作条只认按下，不当作行走；松开 / 取消仍交给原型清理来源
		if touch.pressed and not touch.canceled and touch.position.y < TOP_BAR:
			if touch.position.x > get_viewport().get_visible_rect().size.x - RETURN_ZONE_WIDTH:
				return_requested.emit()
			else:
				_request_observe()
			return
	super(event)


## 适配器确认回院后调用：先停输入和处理，再关相机、断开视口连接；之后由适配器移出并释放
func deactivate() -> void:
	if not active:
		return
	active = false
	release_all()
	set_process(false)
	set_process_unhandled_input(false)
	camera.enabled = false
	var viewport := get_viewport()
	if viewport != null and viewport.size_changed.is_connected(layout):
		viewport.size_changed.disconnect(layout)


## 适配器连接、回院时逐个断开的请求信号；子类新增请求信号时在这里追加
func request_signals() -> Array[Signal]:
	return [return_requested, observe_requested]


func show_note(text: String) -> void:
	_note.text = text
	if not text.is_empty():
		_backing(_note)


func _request_observe() -> void:
	var stop := model.nearby_stop()
	if not stop.is_empty():
		observe_requested.emit(String(stop["id"]))
