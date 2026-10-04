extends "res://test/exploration_return_adapter/adapted_scroll.gd"
# 首条画卷体验研究用的画卷（#201）：在 #200 回院画卷上把「停下看看」与「带不带」分开。
# 停下看时进入观察态：角色不动，相机按取景方案收景；画面下方出现「带上 / 放回」与「继续走」，
# 观察态里触到半屏不会让角色继续走，只有点「继续走」、按 E 或按方向键（键盘视为有意操作）才退出。
# 只发请求，带不带、能否回院都由适配器问核心；数值与按区划分都是实验参数。

const FramingModel := preload("res://test/exploration_first_experience/framing_model.gd")

signal pick_toggled(stop_id: String)
signal observe_ended(stop_id: String)

## 观察态底部操作条高度（屏幕像素）：左半「带上 / 放回」，右半「继续走」
const CHOICE_BAR := 120.0
## 收景过渡速度；低动效下直接切到目标取景
const FRAME_RATE := 6.0
const MOUNT := Color(0.80, 0.76, 0.68)

## 当前正在看的停留点；空表示不在观察态
var observing_stop := ""
## 当前停留点可带的东西 / 已从这里带上的东西（由适配器按核心视图告知）
var offer := ""
var carried_here := ""
var framing_mode := FramingModel.MODE_FIT
## 观察态里被拦下、没有变成行走的触摸次数（研究记录用）
var suppressed_touches := 0
var title_tag: Label
var _pick_tag: Label
var _go_tag: Label
var _cam_zoom := 1.0
var _cam_pos := Vector2.ZERO


func _ready() -> void:
	_build_mount()
	super()
	var hud := get_node("Hud")
	## 390 宽竖屏下原型标签与右上角「回院」重叠，研究画卷用短标签
	for child: Node in hud.get_children():
		if child is Label and (child as Label).text.begins_with("占位原型"):
			(child as Label).text = "占位原型 · 不接存档"
			title_tag = child
	_pick_tag = _bar_tag(hud, 0)
	_go_tag = _bar_tag(hud, 1)
	_go_tag.text = "继续走（E）"
	_snap_camera()
	_refresh_bar()


func request_signals() -> Array[Signal]:
	var signals := super()
	signals.append_array([pick_toggled, observe_ended])
	return signals


func is_observing() -> bool:
	return not observing_stop.is_empty()


## 适配器确认停下看后调用：清掉所有按住的来源，角色立刻停住
func enter_observe(stop_id: String, stop_offer: String, stop_carried: String) -> void:
	if not active:
		return
	release_all()
	observing_stop = stop_id
	update_choice(stop_offer, stop_carried)


## 带上 / 放回之后由适配器刷新底部按钮文字
func update_choice(stop_offer: String, stop_carried: String) -> void:
	offer = stop_offer
	carried_here = stop_carried
	_refresh_bar()


func end_observe() -> void:
	if not is_observing():
		return
	var stop := observing_stop
	observing_stop = ""
	offer = ""
	carried_here = ""
	release_all()
	_refresh_bar()
	show_note("")
	observe_ended.emit(stop)


func target_frame() -> Dictionary:
	return FramingModel.frame(framing_mode, model, get_viewport().get_visible_rect().size, observing_stop)


func camera_zoom() -> float:
	return _cam_zoom


func set_framing_mode(value: String) -> void:
	framing_mode = value
	if low_motion:
		_snap_camera()
	_update_hint()


func deactivate() -> void:
	super()
	observing_stop = ""


func _process(delta: float) -> void:
	if not active:
		return
	super(delta)
	var target := target_frame()
	var weight := 1.0 if low_motion else 1.0 - exp(-FRAME_RATE * delta)
	_cam_zoom = lerpf(_cam_zoom, float(target["zoom"]), weight)
	_cam_pos = _cam_pos.lerp(target["camera"], weight)
	_apply_camera()


func layout_for(size: Vector2) -> void:
	super(size)
	if _pick_tag != null:
		_snap_camera()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
		if code == KEY_F:
			set_framing_mode(FramingModel.MODE_FOLLOW if framing_mode == FramingModel.MODE_FIT else FramingModel.MODE_FIT)
			return
		if is_observing():
			if code == KEY_T:
				_request_pick()
				return
			if code == KEY_E or code == KEY_SPACE:
				end_observe()
				return
			if code in [KEY_LEFT, KEY_RIGHT, KEY_A, KEY_D]:
				end_observe()
	elif event is InputEventScreenTouch and is_observing():
		var touch := event as InputEventScreenTouch
		if touch.pressed and not touch.canceled:
			var size := get_viewport().get_visible_rect().size
			if touch.position.y < TOP_BAR:
				## 顶部只保留回院；其余部分在观察态里不再重复「停下看看」
				if touch.position.x > size.x - RETURN_ZONE_WIDTH:
					return_requested.emit()
				return
			if touch.position.y > size.y - CHOICE_BAR:
				if touch.position.x < size.x * 0.5:
					_request_pick()
				else:
					end_observe()
				return
			suppressed_touches += 1
			return
	elif event is InputEventScreenDrag and is_observing():
		return
	super(event)


func _update_hint() -> void:
	if _hint == null:
		return
	_hint.text = "← → / A D 或按住屏幕左右半边行走 · E 或点顶部提示停下看看 · R 或点右上角回院 · F 取景：%s" % ("收景" if framing_mode == FramingModel.MODE_FIT else "跟随")


func _sync() -> void:
	super()
	if is_observing():
		_near.visible = true
		_near.text = "正在看：%s · 看够了就继续走" % _stop_label(observing_stop)


func _request_pick() -> void:
	if offer.is_empty() and carried_here.is_empty():
		show_note("这里只是看看，没有要带走的东西")
		return
	pick_toggled.emit(observing_stop)


func _refresh_bar() -> void:
	if _pick_tag == null:
		return
	_pick_tag.visible = is_observing()
	_go_tag.visible = is_observing()
	## 观察态不提示行走；竖屏下两行的行走提示会盖住底部按钮
	_hint.visible = not is_observing()
	if not carried_here.is_empty():
		_pick_tag.text = "放回（T）"
	elif not offer.is_empty():
		_pick_tag.text = "带上（T）"
	else:
		_pick_tag.text = "只是看看"
	_update_hint()


func _snap_camera() -> void:
	var target := target_frame()
	_cam_zoom = float(target["zoom"])
	_cam_pos = target["camera"]
	_apply_camera()


func _apply_camera() -> void:
	camera.zoom = Vector2.ONE * _cam_zoom
	camera.position = _cam_pos


func _stop_label(stop_id: String) -> String:
	for stop: Dictionary in ScrollWalkModel.STOPS:
		if stop["id"] == stop_id:
			return String(stop["label"])
	return stop_id


## 底部两个按区：index 0 左半，1 右半；只在观察态显示
func _bar_tag(hud: Node, index: int) -> Label:
	var tag := Label.new()
	tag.anchor_left = 0.5 * index
	tag.anchor_right = 0.5 * (index + 1)
	tag.anchor_top = 1.0
	tag.anchor_bottom = 1.0
	tag.offset_left = 12
	tag.offset_right = -12
	tag.offset_top = -CHOICE_BAR + 12
	tag.offset_bottom = -52
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag.add_theme_color_override("font_color", INK)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.visible = false
	_apply_font(tag, 20)
	_backing(tag)
	hud.add_child(tag)
	return tag


## 画卷以外的装裱底色：竖屏收景时上下露出的部分显示为纸边，而不是引擎清屏色
func _build_mount() -> void:
	var length := ScrollWalkModel.SCROLL_LENGTH
	var height := ScrollWalkModel.SCROLL_HEIGHT
	var mount := Polygon2D.new()
	mount.name = "Mount"
	mount.polygon = PackedVector2Array([Vector2(-2000, -2000), Vector2(length + 2000, -2000), Vector2(length + 2000, height + 2000), Vector2(-2000, height + 2000)])
	mount.color = MOUNT
	add_child(mount)
