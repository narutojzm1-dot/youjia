extends Node
## 触屏点按后，手指下的按钮一直停在鼠标「悬停」样式（浅杏底 + 鼠尾草描边）：
## 点「大太阳」换成「阴天」后它像被选中一样亮着；从近郊点「回院」，同一位置的「歇一会儿」也亮着。
## Godot 把每次触屏合成一次鼠标按键（浏览器也会补发鼠标事件），悬停就落在那里；
## 手机上没有鼠标移开，悬停永远不散。
##
## 与 InputHintMode 一样挂在 `scenes/main.tscn`，不改 `scripts/main.gd`，只读事件、不吞事件：
## 最近一次指点是触屏、手指都已抬起、仍有控件处于悬停时，向视口补一个落在画面外的鼠标移动，
## 让 Godot 自己撤掉悬停。只补移动、不补按键，不会让任何按钮多触发一次；按下态、焦点、点按路由都不变。
## 真鼠标一动（不是触屏合成的）就停止，桌面鼠标照常有悬停。

## 抬指后这段时间内到达的鼠标事件按触屏合成的算，不当作玩家换回了鼠标。
const SYNTH_MS := 700
const AWAY := Vector2(-10000, -10000)

var touch := false
var _down := {}
var _touch_ms := -100000
var _pushing := false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if _pushing:
		return
	if event is InputEventScreenTouch:
		touch = true
		_touch_ms = Time.get_ticks_msec()
		if event.pressed: _down[event.index] = true
		else: _down.erase(event.index)
	elif event is InputEventScreenDrag:
		touch = true
		_touch_ms = Time.get_ticks_msec()
	elif touch and (event is InputEventMouseMotion or event is InputEventMouseButton):
		if event.device != InputEvent.DEVICE_ID_EMULATION and Time.get_ticks_msec() - _touch_ms > SYNTH_MS:
			touch = false


func _process(_delta: float) -> void:
	if not touch or not _down.is_empty():
		return
	var viewport := get_viewport()
	if viewport == null or viewport.gui_get_hovered_control() == null:
		return
	var away := InputEventMouseMotion.new()
	away.device = InputEvent.DEVICE_ID_EMULATION
	away.position = AWAY
	away.global_position = AWAY
	_pushing = true
	viewport.push_input(away)
	_pushing = false
