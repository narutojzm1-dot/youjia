class_name InputHintMode
extends Node

## REQ-20261006-047: on a phone the HUD goal paper still said
## 「目标：窗台花箱 · 看看花箱（空格/按钮）」 and the near-object hints said
## 「空格拿草」/「空格浇水」. A touch player has no Space key, so the one line that
## tells them what to do next points at a key they cannot press.
##
## Lives in `scenes/main.tscn` as a child of Main, so `scripts/main.gd` is not
## edited. It only remembers which kind of input the player used last and never
## consumes an event:
## - a finger on the screen (touch press or drag) switches I18n to the `touch`
##   copy variant, so every catalog key with a `<key>.touch` entry
##   (「点它或按钮」/「点按钮浇水」…) is shown instead;
## - a real key press (not echo) switches back to the original Space wording;
## - mouse events are ignored on purpose: browsers synthesise a mouse click after
##   every tap, and a desktop mouse player still has a keyboard.
## The starting mode follows `DisplayServer.is_touchscreen_available()`.
##
## Copy only: targets, actions, buttons, the action button label and every input
## route are unchanged.

signal changed(touch: bool)

const VARIANT := "touch"

var touch := false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	touch = DisplayServer.is_touchscreen_available()
	_apply()


func _exit_tree() -> void:
	var i18n := _i18n()
	if i18n != null:
		i18n.call("set_input_variant", "")


func _input(event: InputEvent) -> void:
	note(event)


## Returns true when the event changed the mode. Never marks the event handled.
func note(event: InputEvent) -> bool:
	var next := touch
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		next = true
	elif event is InputEventScreenDrag:
		next = true
	elif event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		next = false
	if next == touch:
		return false
	set_touch(next)
	return true


func set_touch(value: bool) -> void:
	if value == touch:
		_apply()
		return
	touch = value
	_apply()
	changed.emit(touch)
	# Main rebuilds the goal paper from I18n; refresh it once so the new copy
	# shows straight away instead of on the next target change.
	var host := get_parent()
	if host != null and host.has_method("_refresh_hud"):
		host.call("_refresh_hud")


func _apply() -> void:
	var i18n := _i18n()
	if i18n != null:
		i18n.call("set_input_variant", VARIANT if touch else "")


func _i18n() -> Node:
	return get_node_or_null("/root/I18n") if is_inside_tree() else null
