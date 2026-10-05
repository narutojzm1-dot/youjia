class_name NearPathScroll
extends Node2D
# 画卷漫步的正式表现适配器（契约 §2、§9）：把输入翻译成核心事件，把核心视图画出来。
# 不直接改会话字段，只经 ExplorationHost 调核心；回院只发请求，由宿主导航。
# 看景总能进入；只有带上 / 放回依赖核心（首片研究建议第 10 节第 6 项）。

const L := preload("res://scripts/exploration/near_path_layout.gd")
const PAPER := Color("fff6e8")
const INK := Color("5b4637")
const MUTED := Color("8a7060")
const APRICOT := Color("f3b27a")
const CREAM := Color("fffaf1")
const MOUNT := Color(0.85, 0.80, 0.70)
const EASE_TIME := 0.4
const TOUCH_DEDUPE_MS := 400

signal return_requested(reason: String)

var host: ExplorationHost
var walker: SequenceResident
var camera: Camera2D
var painter: NearPathPainter
var items: Node2D
var hud: CanvasLayer
var x := L.START_X
var facing := 1.0
var observing := ""
var leaving := false
var suppressed_touches := 0
# 停下看过的停留点 → 核心给出的东西（可能为空）；被带走的从这里画不出来
var revealed: Dictionary = {}
var origins: Dictionary = {}
var _hold_direction := 0
var _home_hold := 0.0
var _walked := false
var _last_touch_ms := -10000
var _cam_zoom := 1.0
var _cam_pos := Vector2.ZERO
var _ease := -1.0
var _ease_from_zoom := 1.0
var _ease_from_pos := Vector2.ZERO
var _caption_time := 0.0

var _place_label: Label
var _caption: Label
var _hint: Label
var _return_button: Button
var _look_button: Button
var _pick_button: Button
var _go_button: Button
var _basket: Control


func setup(trip_host: ExplorationHost, weather: String) -> void:
	host = trip_host
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var mount := Polygon2D.new()
	mount.polygon = PackedVector2Array([Vector2(-3000, -3000), Vector2(L.SIZE.x + 3000, -3000), Vector2(L.SIZE.x + 3000, L.SIZE.y + 3000), Vector2(-3000, L.SIZE.y + 3000)])
	mount.color = MOUNT
	add_child(mount)
	painter = NearPathPainter.new()
	add_child(painter)
	painter.setup(weather)
	items = Node2D.new()
	items.name = "Finds"
	add_child(items)
	items.draw.connect(_draw_items)
	walker = SequenceResident.new()
	walker.z_index = 5
	add_child(walker)
	walker.position = Vector2(x, L.GROUND_Y)
	camera = Camera2D.new()
	camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	add_child(camera)
	camera.make_current()
	_build_hud()
	_snap_camera()
	_show_caption(I18n.t("exploration.caption.arrive"), 5.0)
	_refresh()


func release() -> void:
	set_process(false)
	set_process_unhandled_input(false)
	if camera != null:
		camera.enabled = false
	for connection: Dictionary in return_requested.get_connections():
		return_requested.disconnect(connection.callable)


func reduced_motion() -> bool:
	return bool(TuningStore.get_value("ui.reduced_motion", false))


func _process(delta: float) -> void:
	if leaving:
		return
	var direction := 0
	if observing.is_empty():
		var axis := Input.get_axis("move_left", "move_right")
		direction = int(signf(axis)) if absf(axis) > 0.2 else _hold_direction
	var before := x
	if direction != 0:
		facing = float(direction)
		x = clampf(x + direction * L.WALK_SPEED * delta, L.WALK_MIN, L.WALK_MAX)
		if not _walked and absf(x - L.START_X) > 24.0:
			_walked = true
	if direction < 0 and x <= L.WALK_MIN + 0.5:
		_home_hold += delta
		if _home_hold >= L.HOME_HOLD:
			_request_return("player")
			return
	else:
		_home_hold = 0.0
	walker.position = Vector2(x, L.GROUND_Y)
	walker.advance(delta, Vector2(x - before, 0.0), 1.04, facing, reduced_motion())
	_update_camera(delta, direction != 0)
	if _caption_time > 0.0:
		_caption_time -= delta
		if _caption_time <= 0.0 and observing.is_empty():
			_caption.visible = false
	_refresh()


## ───────────── 看景、带上、回院 ─────────────

func nearby_stop() -> String:
	return L.nearby(x)


func observe(stop_id: String = "") -> bool:
	if leaving or not observing.is_empty():
		return false
	var target := stop_id if not stop_id.is_empty() else nearby_stop()
	if target.is_empty():
		return false
	_hold_direction = 0
	observing = target
	host.visit(target)
	var view := host.view()
	if view.get("current_stop", "") == target:
		revealed[target] = str(view.get("offer", ""))
		for find_id: String in view.get("carried", []):
			if origins.get(find_id, "") == target:
				revealed[target] = find_id
	_begin_ease()
	_show_caption(_observe_caption(), 0.0)
	items.queue_redraw()
	_refresh()
	return true


func end_observe() -> void:
	if observing.is_empty():
		return
	observing = ""
	_hold_direction = 0
	_caption.visible = false
	_begin_ease()
	_refresh()


## 有东西时：带上 / 换成这个 / 放回；全由核心判定，界面只按结果刷新
func pick() -> bool:
	if observing.is_empty():
		return false
	var choice := pick_choice()
	var ok := false
	match choice.kind:
		"take":
			ok = host.take(choice.find_id).ok
		"swap":
			var old: String = choice.old
			if host.release(old).ok:
				ok = host.take(choice.find_id).ok
				if not ok:
					host.take(old)
		"release":
			ok = host.release(choice.find_id).ok
	if ok:
		if choice.kind in ["take", "swap"]:
			origins[choice.find_id] = observing
			walker.begin_action(&"pickup", reduced_motion())
		_show_caption(_observe_caption(), 0.0)
		items.queue_redraw()
		_refresh()
	return ok


func pick_choice() -> Dictionary:
	if observing.is_empty():
		return {"kind": "none"}
	var view := host.view()
	var carried: Array = view.get("carried", [])
	var offer := str(view.get("offer", "")) if view.get("current_stop", "") == observing else ""
	if not offer.is_empty():
		if carried.size() >= int(view.get("carry_limit", 1)) and not carried.is_empty():
			return {"kind": "swap", "find_id": offer, "old": carried[0]}
		return {"kind": "take", "find_id": offer}
	for find_id: String in carried:
		if origins.get(find_id, "") == observing:
			return {"kind": "release", "find_id": find_id}
	return {"kind": "none"}


func carried() -> Array:
	return host.view().get("carried", [])


func _request_return(reason: String) -> void:
	if leaving:
		return
	leaving = true
	_hold_direction = 0
	return_requested.emit(reason)


## ───────────── 输入 ─────────────

func _unhandled_input(event: InputEvent) -> void:
	if leaving:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
		if code == KEY_R:
			_request_return("player")
		elif event.is_action_pressed("ui_accept") or code == KEY_E:
			if observing.is_empty():
				observe()
			else:
				end_observe()
		elif code == KEY_T:
			pick()
		elif not observing.is_empty() and (event.is_action("move_left") or event.is_action("move_right")):
			end_observe()
		else:
			return
		get_viewport().set_input_as_handled()
		return
	var point := Vector2.INF
	var pressed := false
	if event is InputEventScreenTouch:
		point = event.position
		pressed = event.pressed and not event.canceled
		_last_touch_ms = Time.get_ticks_msec()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if Time.get_ticks_msec() - _last_touch_ms < TOUCH_DEDUPE_MS:
			get_viewport().set_input_as_handled()
			return
		point = event.position
		pressed = event.pressed
	else:
		return
	get_viewport().set_input_as_handled()
	if not pressed:
		_hold_direction = 0
		return
	press_at(point)


## 屏幕坐标的一次按下：先命中按钮；观察态里其余位置不走路（计数，免得误以为卡住时再提示）
func press_at(point: Vector2) -> void:
	for button: Button in [_return_button, _look_button, _pick_button, _go_button]:
		if button.is_visible_in_tree() and button.get_global_rect().has_point(point):
			button.pressed.emit()
			return
	if not observing.is_empty():
		suppressed_touches += 1
		_show_caption(_observe_caption() + "\n" + I18n.t("exploration.caption.continue_hint"), 0.0)
		return
	var size := get_viewport().get_visible_rect().size
	_hold_direction = -1 if point.x < size.x * 0.5 else 1


## ───────────── 相机 ─────────────

func target_frame() -> Dictionary:
	var size := get_viewport().get_visible_rect().size
	return L.fit(x, size, observing) if not observing.is_empty() else L.follow(x, size)


func camera_zoom() -> float:
	return _cam_zoom


func _begin_ease() -> void:
	_ease = 0.0
	_ease_from_zoom = _cam_zoom
	_ease_from_pos = _cam_pos


func _update_camera(delta: float, walking: bool) -> void:
	if _ease < 0.0 or reduced_motion() or walking:
		_ease = -1.0
		_snap_camera()
		return
	_ease += delta
	var target := target_frame()
	if _ease >= EASE_TIME:
		_ease = -1.0
		_snap_camera()
		return
	var weight := smoothstep(0.0, EASE_TIME, _ease)
	_cam_zoom = lerpf(_ease_from_zoom, float(target.zoom), weight)
	_cam_pos = _ease_from_pos.lerp(target.camera, weight)
	_apply_camera()


func _snap_camera() -> void:
	var target := target_frame()
	_cam_zoom = float(target.zoom)
	_cam_pos = target.camera
	_apply_camera()


func _apply_camera() -> void:
	if camera == null:
		return
	camera.zoom = Vector2.ONE * _cam_zoom
	camera.position = _cam_pos
	var visible := get_viewport().get_visible_rect().size / maxf(_cam_zoom, 0.001)
	painter.follow_camera(_cam_pos.x - visible.x * 0.5)


## ───────────── 画面与界面 ─────────────

func _draw_items() -> void:
	var held: Array = carried() if host != null else []
	for stop_id: String in revealed:
		var find_id: String = revealed[stop_id]
		var anchor: Vector2 = L.stop(stop_id).get("item", Vector2.ZERO)
		if find_id.is_empty() or held.has(find_id) or anchor == Vector2.ZERO:
			continue
		KeepsakeArt.draw(items, find_id, anchor, 1.15)


func _observe_caption() -> String:
	var text := I18n.t("exploration.stop.%s" % observing)
	var choice := pick_choice()
	match choice.kind:
		"take", "swap":
			text += "\n" + I18n.t("exploration.caption.found", {"item": _find_name(choice.find_id)})
		"release":
			text += "\n" + I18n.t("exploration.caption.in_basket", {"item": _find_name(choice.find_id)})
		_:
			text += "\n" + I18n.t("exploration.caption.just_look")
	return text


func _find_name(find_id: String) -> String:
	return I18n.t(ExplorationRoutes.find_name_key(find_id))


func _show_caption(text: String, seconds: float) -> void:
	_caption.text = text
	_caption.visible = true
	_caption_time = seconds


func _refresh() -> void:
	if _return_button == null:
		return
	var size := get_viewport().get_visible_rect().size
	var compact := size.x < 700.0
	var near := nearby_stop()
	var choice := pick_choice()
	_look_button.visible = observing.is_empty() and not near.is_empty() and not leaving
	if _look_button.visible:
		_look_button.text = I18n.t("exploration.action.look", {"place": I18n.t("exploration.place.%s" % near)})
	_pick_button.visible = not observing.is_empty() and choice.kind != "none"
	match choice.kind:
		"take":
			_pick_button.text = I18n.t("exploration.action.take", {"item": _find_name(choice.find_id)})
		"swap":
			_pick_button.text = I18n.t("exploration.action.swap", {"item": _find_name(choice.find_id)})
		"release":
			_pick_button.text = I18n.t("exploration.action.release", {"item": _find_name(choice.find_id)})
	_go_button.visible = not observing.is_empty()
	_hint.visible = not _walked and observing.is_empty()
	_place_label.text = I18n.t("exploration.place.title") if near.is_empty() or not observing.is_empty() else I18n.t("exploration.place.%s" % near)
	_layout(size, compact)
	_basket.queue_redraw()


func _layout(size: Vector2, compact: bool) -> void:
	var pad := 14.0 if compact else 20.0
	var button_h := 46.0
	_return_button.size = Vector2(118 if compact else 140, button_h)
	_return_button.position = Vector2(size.x - _return_button.size.x - pad, pad)
	_place_label.position = Vector2(pad, pad + 8)
	_place_label.size = Vector2(maxf(120.0, size.x - _return_button.size.x - pad * 3), 30)
	var look_w := minf(size.x - pad * 2, 320.0)
	_look_button.size = Vector2(look_w, button_h)
	_look_button.position = Vector2((size.x - look_w) * 0.5, pad + button_h + 12)
	var bar_y := size.y - button_h - pad
	var half := (size.x - pad * 3) * 0.5
	_pick_button.size = Vector2(minf(half, 300.0), button_h)
	_go_button.size = Vector2(minf(half, 300.0), button_h)
	_pick_button.position = Vector2(size.x * 0.5 - pad * 0.5 - _pick_button.size.x, bar_y)
	_go_button.position = Vector2(size.x * 0.5 + pad * 0.5, bar_y)
	if not _pick_button.visible:
		_go_button.position.x = (size.x - _go_button.size.x) * 0.5
	var caption_w := minf(size.x - pad * 2, 560.0)
	_caption.size = Vector2(caption_w, 0)
	_caption.position = Vector2((size.x - caption_w) * 0.5, bar_y - 86 if not observing.is_empty() else size.y - 150)
	_hint.size = Vector2(size.x - pad * 2, 24)
	_hint.position = Vector2(pad, size.y - pad - 30)
	_basket.position = Vector2(pad, size.y - pad - 64 - (button_h + 10 if not observing.is_empty() else 0) - (34 if _hint.visible else 0))


func _build_hud() -> void:
	hud = CanvasLayer.new()
	# 在暂停/确认层（10）之下，暂停时被盖住
	hud.layer = 8
	add_child(hud)
	_place_label = _label(20, INK)
	_caption = _label(17, INK)
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var caption_style := StyleBoxFlat.new()
	caption_style.bg_color = Color(PAPER, 0.88)
	caption_style.set_corner_radius_all(14)
	caption_style.set_content_margin_all(10)
	_caption.add_theme_stylebox_override("normal", caption_style)
	_caption.visible = false
	_hint = _label(14, MUTED)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.text = I18n.t("exploration.caption.walk_hint")
	_return_button = _button(I18n.t("exploration.action.return"), func() -> void: _request_return("player"))
	_look_button = _button("", func() -> void: observe())
	_pick_button = _button("", func() -> void: pick())
	_go_button = _button(I18n.t("exploration.action.continue"), end_observe)
	_basket = Control.new()
	_basket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_basket.size = Vector2(200, 60)
	_basket.draw.connect(_draw_basket)
	hud.add_child(_basket)


## 提篮常伴：带上的东西在篮子里看得见；只画，不计数、不排格子
func _draw_basket() -> void:
	var held: Array = carried() if host != null else []
	var body := PackedVector2Array([Vector2(6, 24), Vector2(74, 24), Vector2(66, 56), Vector2(14, 56)])
	_basket.draw_colored_polygon(body, Color(0.80, 0.62, 0.40, 0.95))
	for i in 4:
		_basket.draw_line(Vector2(10 + i * 2, 32 + i * 6), Vector2(70 - i * 2, 32 + i * 6), Color(0.58, 0.42, 0.26, 0.8), 1.5)
	_basket.draw_arc(Vector2(40, 26), 26, PI, TAU, 18, Color(0.58, 0.42, 0.26), 3.0)
	for i in held.size():
		KeepsakeArt.draw(_basket, held[i], Vector2(40 + i * 16, 22), 0.9)
	var font := _basket.get_theme_default_font()
	var text := I18n.t("exploration.basket.empty") if held.is_empty() else _find_name(held[0])
	_basket.draw_string(font, Vector2(84, 46), text, HORIZONTAL_ALIGNMENT_LEFT, 120, 15, INK)


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	hud.add_child(label)
	return label


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", INK)
	var style := StyleBoxFlat.new()
	style.bg_color = CREAM
	style.border_color = APRICOT
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(action)
	hud.add_child(button)
	return button
