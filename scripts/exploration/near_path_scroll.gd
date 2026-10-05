class_name NearPathScroll
extends Node2D
# 院外近郊的正式表现适配器（契约 §2、§9）：在原画透视里沿画中道路走，把输入翻译成核心事件，把核心视图画出来。
# 不直接改会话字段，只经 ExplorationHost 调核心；回院只发请求，由宿主导航。
# 看景总能进入；只有带上 / 放回依赖核心（首片研究建议第 10 节第 6 项）。

const L := preload("res://scripts/exploration/near_path_layout.gd")
const PAPER := Color("fff6e8")
const INK := Color("5b4637")
const MUTED := Color("8a7060")
const APRICOT := Color("f3b27a")
const CREAM := Color("fffaf1")
const TOUCH_DEDUPE_MS := 400

signal return_requested(reason: String)
signal pause_requested

var host: ExplorationHost
var walker: SequenceResident
var camera: Camera2D
var painting: Sprite2D
var items: Node2D
var hud: CanvasLayer
# 人物在路上的位置：哪条路、离岔口多远（原画像素）
var spot: Dictionary = L.START.duplicate()
var facing := -1.0
var observing := ""
var leaving := false
var suppressed_touches := 0
# 停下看过的停留点 → 核心给出的东西（可能为空）；被带走的从这里画不出来
var revealed: Dictionary = {}
# 点按路面后要走去的位置；方向键一按就取消
var walk_target: Dictionary = {}
var _home_hold := 0.0
var _walked := false
var _last_touch_ms := -10000
var _cam_zoom := 1.0
var _cam_pos := Vector2.ZERO
var _caption_time := 0.0

var _place_label: Label
var _caption: Label
var _hint: Label
var _return_button: Button
var _pause_button: Button
var _look_button: Button
var _pick_button: Button
var _go_button: Button
var _basket: Control


## 原画只有一版晴秋，天气暂不改画面
func setup(trip_host: ExplorationHost, _weather: String) -> void:
	host = trip_host
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var paper := Polygon2D.new()
	paper.polygon = PackedVector2Array([Vector2(-3000, -3000), Vector2(L.SIZE.x + 3000, -3000), Vector2(L.SIZE.x + 3000, L.SIZE.y + 3000), Vector2(-3000, L.SIZE.y + 3000)])
	paper.color = PAPER
	add_child(paper)
	painting = Sprite2D.new()
	painting.name = "Painting"
	painting.texture = load(L.ART)
	painting.centered = false
	painting.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(painting)
	items = Node2D.new()
	items.name = "Finds"
	add_child(items)
	items.draw.connect(_draw_items)
	walker = SequenceResident.new()
	walker.z_index = 5
	add_child(walker)
	walker.position = foot()
	walker.advance(0.0, Vector2.ZERO, L.depth(foot().y), facing, true)
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


## 暂停或失焦时丢掉点按目标，恢复后不自己走起来
func _notification(what: int) -> void:
	if what in [NOTIFICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		walk_target = {}


func reduced_motion() -> bool:
	return bool(TuningStore.get_value("ui.reduced_motion", false))


func foot() -> Vector2:
	return L.point(spot.arm, spot.d)


func _process(delta: float) -> void:
	if leaving:
		return
	var direction := Vector2.ZERO
	if observing.is_empty():
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down", 0.2)
	walk(direction, delta)
	if leaving:
		return
	if _caption_time > 0.0:
		_caption_time -= delta
		if _caption_time <= 0.0 and observing.is_empty():
			_caption.visible = false
	_refresh()


## 走一帧：方向键沿路投影；没有方向时朝点按的目标走；在院门口继续往院里走就回院
func walk(direction: Vector2, delta: float) -> void:
	var before := foot()
	var step := L.WALK_SPEED * delta
	if direction.length() > 0.01:
		walk_target = {}
		spot = L.step_input(spot, direction, step)
	elif not walk_target.is_empty():
		spot = L.step_toward(spot, walk_target, step)
		if L.route_length(spot, walk_target) < 0.5:
			walk_target = {}
	var moved := foot() - before
	if absf(moved.x) > 0.01:
		facing = signf(moved.x)
	if not _walked and L.route_length(spot, L.START) > 24.0:
		_walked = true
	if L.at_home(spot) and direction.normalized().dot(L.home_direction()) > L.MIN_ALIGN:
		_home_hold += delta
		if _home_hold >= L.HOME_HOLD:
			_request_return("player")
			return
	else:
		_home_hold = 0.0
	walker.position = foot()
	walker.advance(delta, moved, L.depth(foot().y), facing, reduced_motion())
	_snap_camera()


## ───────────── 看景、带上、回院 ─────────────

func nearby_stop() -> String:
	return L.nearby(spot)


func place_at(stop_id: String) -> void:
	var entry := L.stop(stop_id)
	if entry.is_empty():
		return
	spot = {"arm": entry.arm, "d": entry.d}
	walk_target = {}
	walker.position = foot()
	_snap_camera()
	_refresh()


func observe(stop_id: String = "") -> bool:
	if leaving or not observing.is_empty():
		return false
	var target := stop_id if not stop_id.is_empty() else nearby_stop()
	if target.is_empty():
		return false
	walk_target = {}
	observing = target
	host.visit(target)
	var view := host.view()
	if view.get("current_stop", "") == target:
		revealed[target] = str(view.get("taken", {}).get(target, view.get("offer", "")))
	_show_caption(_observe_caption(), 0.0)
	items.queue_redraw()
	_refresh()
	return true


func end_observe() -> void:
	if observing.is_empty():
		return
	observing = ""
	_caption.visible = false
	items.queue_redraw()
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
			ok = host.swap(choice.old, choice.find_id).ok
		"release":
			ok = host.release(choice.find_id).ok
	if ok:
		if choice.kind in ["take", "swap"]:
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
	var here := str(view.get("taken", {}).get(observing, "")) if view.get("current_stop", "") == observing else ""
	if not here.is_empty():
		return {"kind": "release", "find_id": here}
	return {"kind": "none"}


func carried() -> Array:
	return host.view().get("carried", [])


func _request_return(reason: String) -> void:
	if leaving:
		return
	leaving = true
	walk_target = {}
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
		elif not observing.is_empty() and (event.is_action("move_left") or event.is_action("move_right") or event.is_action("move_up") or event.is_action("move_down")):
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
	if pressed:
		press_at(point)


## 屏幕坐标的一次按下：先命中按钮；观察态里其余位置不走路（计数，免得误以为卡住时再提示）；
## 其余点按沿路走到离按下处最近的路面
func press_at(point: Vector2) -> void:
	for button: Button in [_return_button, _pause_button, _look_button, _pick_button, _go_button]:
		if button.is_visible_in_tree() and button.get_global_rect().has_point(point):
			button.pressed.emit()
			return
	if not observing.is_empty():
		suppressed_touches += 1
		_show_caption(_observe_caption() + "\n" + I18n.t("exploration.caption.continue_hint"), 0.0)
		return
	var target := L.nearest(screen_to_art(point))
	walk_target = {"arm": target.arm, "d": target.d}


func screen_to_art(point: Vector2) -> Vector2:
	var size := get_viewport().get_visible_rect().size
	return _cam_pos + (point - size * 0.5) / maxf(_cam_zoom, 0.001)


func art_to_screen(art: Vector2) -> Vector2:
	var size := get_viewport().get_visible_rect().size
	return (art - _cam_pos) * _cam_zoom + size * 0.5


## ───────────── 相机 ─────────────

func target_frame() -> Dictionary:
	return L.frame(foot(), get_viewport().get_visible_rect().size)


func camera_zoom() -> float:
	return _cam_zoom


func _snap_camera() -> void:
	var target := target_frame()
	_cam_zoom = float(target.zoom)
	_cam_pos = target.camera
	if camera != null:
		camera.zoom = Vector2.ONE * _cam_zoom
		camera.position = _cam_pos


## ───────────── 画面与界面 ─────────────

func _draw_items() -> void:
	var taken: Dictionary = host.view().get("taken", {}) if host != null else {}
	for stop_id: String in revealed:
		var find_id: String = revealed[stop_id]
		var anchor: Vector2 = L.stop(stop_id).get("item", Vector2.ZERO)
		if find_id.is_empty() or taken.has(stop_id) or anchor == Vector2.ZERO:
			continue
		var depth := L.depth(anchor.y)
		if stop_id == observing:
			# 静止的柔光地影，只在停下看的这一处；不闪、不动
			items.draw_set_transform(anchor + Vector2(0, 6) * depth, 0.0, Vector2(depth, 0.4 * depth))
			items.draw_circle(Vector2.ZERO, 34.0, Color(1.0, 0.96, 0.82, 0.55))
			items.draw_circle(Vector2.ZERO, 24.0, Color(1.0, 0.98, 0.90, 0.6))
			items.draw_set_transform(Vector2.ZERO)
		KeepsakeArt.draw(items, find_id, anchor, 1.6 * depth)


func _observe_caption() -> String:
	var text := I18n.t("exploration.stop.%s" % observing)
	var choice := pick_choice()
	match choice.kind:
		"take":
			text += "\n" + I18n.t("exploration.caption.found", {"item": _find_name(choice.find_id)})
		"swap":
			text += "\n" + I18n.t("exploration.caption.basket_full", {"item": _find_name(choice.find_id), "old": _find_name(choice.old)})
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
	_pause_button.size = Vector2(104 if compact else 128, button_h)
	_pause_button.position = Vector2(_return_button.position.x - _pause_button.size.x - 10, pad)
	_place_label.position = Vector2(pad, pad + 8)
	_place_label.size = Vector2(maxf(80.0, _pause_button.position.x - pad * 2), 30)
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
	# 字幕放在上方天空里，路面和路边的东西不被挡住；走路时让出“停下看看”按钮的位置
	var caption_top := pad + button_h + 12.0
	_caption.position = Vector2((size.x - caption_w) * 0.5, caption_top if not observing.is_empty() else caption_top + button_h + 12.0)
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
	# 触屏没有 Esc：暂停/音量入口在画卷里也要有
	_pause_button = _button(I18n.t("hud.pause"), func() -> void: pause_requested.emit())
	_look_button = _button("", func() -> void: observe())
	_pick_button = _button("", func() -> void: pick())
	_go_button = _button(I18n.t("exploration.action.continue"), end_observe)
	_basket = Control.new()
	_basket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_basket.size = Vector2(290, 60)
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
		KeepsakeArt.draw(_basket, held[i], Vector2(24 + i * 16, 22), 0.9)
	var font := _basket.get_theme_default_font()
	var text := I18n.t("exploration.basket.empty") if held.is_empty() else ExplorationDirector.items_text(PackedStringArray(held))
	_basket.draw_string(font, Vector2(84, 46), text, HORIZONTAL_ALIGNMENT_LEFT, 200, 15, INK)


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
