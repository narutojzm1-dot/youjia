extends Node2D
## GROK #705 隔离演示：院子原画上的烟囱叶子。不进入 Main，也不假装有做饭事件。

const YARD := preload("res://assets/holiday/environment/yard_sunny.png")
const WORLD_SIZE := Vector2(1280.0, 720.0)
## Main 夜色键 Color(0.26, 0.34, 0.55) 按强度 0.80 乘进白色后的结果。只乘院子原画。
const NIGHT_MULTIPLY := Color(0.408, 0.472, 0.640, 1.0)

@onready var _backdrop: Sprite2D = $Backdrop
@onready var _smoke: Node2D = $CookingSmoke
@onready var _camera: Camera2D = $FrameCamera

var _status: Label
var _column: VBoxContainer
var _night := false
var _capture_layout := false


func _ready() -> void:
	_backdrop.centered = false
	_backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_backdrop.z_index = -1
	# 与 YardWorld 同一张晴天院子、同一世界缩放，烟才落在画出来的烟囱上。
	var tex_size := YARD.get_size()
	if tex_size.x > 0.0 and tex_size.y > 0.0:
		_backdrop.scale = WORLD_SIZE / tex_size
	_smoke.set_chimney_anchor(CookingSmoke.DEFAULT_CHIMNEY_ANCHOR)
	_build_hud()
	_apply_frame()
	_refresh_status()


func _process(_delta: float) -> void:
	_refresh_status()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_apply_frame()


func _unhandled_input(event: InputEvent) -> void:
	if _capture_layout:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := (event as InputEventKey).keycode
	if key == KEY_C:
		_smoke.set_cooking(not _smoke.is_cooking())
	elif key == KEY_P:
		_smoke.set_paused(not _smoke.is_paused())
	elif key == KEY_N:
		set_demo_night(not _night)
	elif key == KEY_M:
		_toggle_reduced_motion()
	else:
		return
	_refresh_status()


## 截图时收起按钮，只留一行说明，避免字盖住烟囱。
func use_capture_layout() -> void:
	_capture_layout = true
	if _column != null:
		for child in _column.get_children():
			if child is Button:
				child.visible = false
	_apply_frame()
	_refresh_status()


## 昼/夜只切原画乘色和叶子的 set_night_tint。不是 Main 的时间轴。
func set_demo_night(night: bool) -> void:
	_night = night
	_backdrop.modulate = NIGHT_MULTIPLY if night else Color.WHITE
	_smoke.set_night_tint(night)
	_refresh_status()


func apply_frame() -> void:
	_apply_frame()


## 视口比世界窄（例如宽 390）时，把烟囱留在画面里；1280×720 则一比一铺满。
func _apply_frame() -> void:
	var view := get_viewport().get_visible_rect().size
	if view.x < 2.0 or view.y < 2.0:
		return
	var wide := absf(view.x - WORLD_SIZE.x) < 8.0 and absf(view.y - WORLD_SIZE.y) < 8.0
	_camera.enabled = not wide
	if not wide:
		var half := view * 0.5
		var center := Vector2(_smoke.position.x, WORLD_SIZE.y * 0.5)
		center.x = clampf(center.x, half.x, maxf(half.x, WORLD_SIZE.x - half.x))
		center.y = clampf(center.y, half.y, maxf(half.y, WORLD_SIZE.y - half.y))
		_camera.position = center
	_layout_hud(view)


func _layout_hud(view: Vector2) -> void:
	if _column == null:
		return
	# 烟囱在左上。宽屏说明放右侧，窄屏放底部草地，都不压屋顶。
	if view.x < 700.0:
		_column.position = Vector2(12, maxf(12.0, view.y - 168.0))
	else:
		_column.position = Vector2(maxf(24.0, view.x - 340.0), 24)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 8)
	layer.add_child(_column)
	_status = Label.new()
	_status.add_theme_color_override("font_color", Color(0.28, 0.2, 0.14, 1))
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(300, 0)
	_column.add_child(_status)
	_add_button(_column, "做饭冒烟 (C)", func() -> void:
		_smoke.set_cooking(not _smoke.is_cooking())
	)
	_add_button(_column, "暂停发射 (P)", func() -> void:
		_smoke.set_paused(not _smoke.is_paused())
	)
	_add_button(_column, "夜色 (N)", func() -> void:
		set_demo_night(not _night)
	)
	_add_button(_column, "减少动态 (M)", _toggle_reduced_motion)


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
	var view := get_viewport().get_visible_rect().size
	if _capture_layout:
		_status.text = "组件演示，没有主流程做饭事件。%s  %dx%d" % [
			"夜" if _night else "昼",
			int(view.x),
			int(view.y),
		]
		return
	_status.text = "组件演示，没有主流程做饭事件。\n锚点 %s　视口 %dx%d\n做饭 %s　暂停 %s　夜色 %s　减少动态 %s　正在发射 %s" % [
		snap.get("anchor", Vector2.ZERO),
		int(view.x),
		int(view.y),
		snap.get("cooking", false),
		snap.get("paused", false),
		snap.get("night_tint", false),
		snap.get("reduced_motion", false),
		snap.get("emitting", false),
	]
