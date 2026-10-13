extends Node
## 记下最近一次按下的是鼠标 / 触屏还是键盘 / 手柄按键，界面交焦点时用：
## 点按触发时交 Godot 隐藏焦点（不画焦点圈，键盘一导航再显出来），键盘触发时照常画圈。
## 挂在要交焦点的界面下；它比 Main 先收到同一次输入，界面隐藏、游戏暂停时也照常记。

var pointer := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed: pointer = true
	elif event is InputEventKey or event is InputEventJoypadButton:
		if event.pressed: pointer = false


func grab(control: Control) -> void:
	control.grab_focus(pointer)
