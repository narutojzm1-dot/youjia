extends Node2D
## GROK #705 隔离演示：只拨烟囱叶子的开关，不进入 Main，也不假装有做饭事件。

@onready var _smoke: Node2D = $CookingSmoke

var _status: Label


func _ready() -> void:
	_build_hud()
	_refresh_status()


func _process(_delta: float) -> void:
	_refresh_status()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := (event as InputEventKey).keycode
	if key == KEY_C:
		_smoke.set_cooking(not _smoke.is_cooking())
	elif key == KEY_P:
		_smoke.set_paused(not _smoke.is_paused())
	elif key == KEY_N:
		var night := bool(_smoke.debug_snapshot().get("night_tint", false))
		_smoke.set_night_tint(not night)
	elif key == KEY_M:
		_toggle_reduced_motion()
	else:
		return
	_refresh_status()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(0.93, 0.88, 0.78, 1))
	var mouth: Vector2 = _smoke.position
	# 只是烟囱嘴的参照，不是院子原画。
	draw_rect(Rect2(mouth + Vector2(-70, 8), Vector2(150, 70)), Color(0.62, 0.45, 0.34, 1))
	draw_rect(Rect2(mouth + Vector2(-14, -2), Vector2(28, 22)), Color(0.40, 0.28, 0.22, 1))


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var column := VBoxContainer.new()
	column.position = Vector2(24, 24)
	column.add_theme_constant_override("separation", 8)
	layer.add_child(column)
	_status = Label.new()
	_status.add_theme_color_override("font_color", Color(0.28, 0.2, 0.14, 1))
	column.add_child(_status)
	_add_button(column, "做饭冒烟 (C)", func() -> void:
		_smoke.set_cooking(not _smoke.is_cooking())
	)
	_add_button(column, "暂停发射 (P)", func() -> void:
		_smoke.set_paused(not _smoke.is_paused())
	)
	_add_button(column, "夜色 (N)", func() -> void:
		var night := bool(_smoke.debug_snapshot().get("night_tint", false))
		_smoke.set_night_tint(not night)
	)
	_add_button(column, "减少动态 (M)", _toggle_reduced_motion)


func _add_button(parent: Node, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)


func _toggle_reduced_motion() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var store := tree.root.get_node_or_null("/root/TuningStore")
	if store == null or not store.has_method("get_value") or not store.has_method("set_value"):
		return
	var current := bool(store.get_value("ui.reduced_motion", false))
	store.set_value("ui.reduced_motion", not current, false)


func _refresh_status() -> void:
	if _status == null or _smoke == null:
		return
	var snap: Dictionary = _smoke.debug_snapshot()
	_status.text = "隔离演示，未接主流程做饭事件。\n锚点 %s\n做饭 %s　暂停 %s　夜色 %s　减少动态 %s　正在发射 %s" % [
		snap.get("anchor", Vector2.ZERO),
		snap.get("cooking", false),
		snap.get("paused", false),
		snap.get("night_tint", false),
		snap.get("reduced_motion", false),
		snap.get("emitting", false),
	]
