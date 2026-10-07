class_name NearPathScroll
extends Node2D
# 院外近郊的正式表现适配器（契约 §2、§9）：在原画透视里沿画中道路走，把输入翻译成核心事件，把核心视图画出来。
# 不直接改会话字段，只经 ExplorationHost 调核心；回院只发请求，由宿主导航。
# 看景总能进入；只有带上 / 放回依赖核心（首片研究建议第 10 节第 6 项）。

const L := preload("res://scripts/exploration/near_path_layout.gd")
var layout: PaintedPath = L.geometry()
var village := false
var residents: RefCounted
var stray: PathCompanion
var _rescue_requested := false
var _rescued_here := false
var _resident_caption := ""
var turtle: Sprite2D
var _turtle_caption := ""
const PAPER := Color("fff6e8")
const INK := Color("5b4637")
const MUTED := Color("8a7060")
const APRICOT := Color("f3b27a")
const CREAM := Color("fffaf1")
const TOUCH_DEDUPE_MS := 400
const BASKET_LABEL_AT := Vector2(84, 46)
const BASKET_LABEL_WIDTH := 200.0
# 篮子名称放不下时：先逐 1px 缩到 13px 保持一行，再不行就 13px 折两行往上长，不再截掉尾字
const BASKET_LABEL_FONT_SIZE := 15
const BASKET_LABEL_MIN_FONT_SIZE := 13
const BASKET_LABEL_MAX_LINES := 2
const BASKET_LABEL_MIN_WIDTH := 120.0

signal return_requested(reason: String)
signal pause_requested

var host: ExplorationHost
var walker: SequenceResident
var companion: PathCompanion
var camera: Camera2D
var painting: Sprite2D
var items: Node2D
var hud: CanvasLayer
# 人物在路上的位置：哪条路、离岔口多远（原画像素）
var spot: Dictionary = layout.START.duplicate()
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
var _search_started := false
var _hidden_caption_dirty := false

var _place_label: Label
var _caption: Label
var _hint: Label
var _return_button: Button
var _pause_button: Button
var _look_button: Button
var _pick_button: Button
var _go_button: Button
var _basket: Control
var _basket_label_width := BASKET_LABEL_WIDTH
var _view_size := Vector2.ZERO
var reveal: FindReveal
var leaf_texture: Texture2D


## 原画只有一版晴秋，天气暂不改画面
func setup(trip_host: ExplorationHost, _weather: String, resident_controller: RefCounted = null) -> void:
	host = trip_host
	residents = resident_controller
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var paper := Polygon2D.new()
	paper.polygon = PackedVector2Array([Vector2(-3000, -3000), Vector2(layout.SIZE.x + 3000, -3000), Vector2(layout.SIZE.x + 3000, layout.SIZE.y + 3000), Vector2(-3000, layout.SIZE.y + 3000)])
	paper.color = PAPER
	add_child(paper)
	painting = Sprite2D.new()
	painting.name = "Painting"
	painting.texture = load(layout.ART)
	painting.centered = false
	painting.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(painting)
	items = Node2D.new()
	items.name = "Finds"
	add_child(items)
	items.draw.connect(_draw_items)
	leaf_texture = load("res://assets/holiday/exploration/finds/leaf_pile.png")
	walker = SequenceResident.new()
	walker.z_index = 5
	add_child(walker)
	walker.position = foot()
	walker.advance(0.0, Vector2.ZERO, layout.depth(foot().y), facing, true)
	walker.z_index = roundi(foot().y)
	var partner: Dictionary = host.view().get("companion", {})
	if not partner.is_empty():
		companion = PathCompanion.new()
		add_child(companion)
		companion.setup(partner, spot)
		companion.advance(0.0, spot, walker, reduced_motion())
	camera = Camera2D.new()
	camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	add_child(camera)
	camera.make_current()
	_build_hud()
	_snap_camera()
	_show_caption(I18n.t("exploration.caption.arrive"), 5.0)
	if companion != null:
		_show_caption(I18n.t("exploration.caption.companion", {"animal": I18n.t("target." + companion.choice.actor_id)}), 5.0)
	_view_size = get_viewport().get_visible_rect().size
	get_viewport().size_changed.connect(_on_view_resized)
	_refresh()


func release() -> void:
	_cancel_search()
	if reveal != null:
		reveal.settle(true)
	set_process(false)
	set_process_unhandled_input(false)
	if camera != null:
		camera.enabled = false
	if get_viewport() != null and get_viewport().size_changed.is_connected(_on_view_resized):
		get_viewport().size_changed.disconnect(_on_view_resized)
	for connection: Dictionary in return_requested.get_connections():
		return_requested.disconnect(connection.callable)


## 暂停或失焦时丢掉点按目标，恢复后不自己走起来
func _notification(what: int) -> void:
	if what in [NOTIFICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		_cancel_search()
		walk_target = {}
		if reveal != null:
			reveal.settle(true)


## 拾起短展示的起点、停留点和篮位都是开始时的屏幕坐标：视口一变（转屏、拖窗）就按可打断规则收进篮子，
## 不在旧位置画完，也不按新尺寸重播
func _on_view_resized() -> void:
	var size := get_viewport().get_visible_rect().size
	if size == _view_size:
		return
	_view_size = size
	if reveal != null:
		reveal.settle()


func reduced_motion() -> bool:
	return bool(TuningStore.get_value("ui.reduced_motion", false))


func foot() -> Vector2:
	return layout.position(spot)


func _process(delta: float) -> void:
	if leaving:
		return
	var direction := Vector2.ZERO
	if observing.is_empty():
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down", 0.2)
	walk(direction, delta)
	if leaving:
		return
	_update_search()
	_update_resident()
	_update_turtle()
	if _caption_time > 0.0:
		_caption_time -= delta
		if _caption_time <= 0.0 and observing.is_empty():
			_caption.visible = false
	_refresh()


## 走一帧：方向键沿路投影；没有方向时朝点按的目标走；在院门口继续往院里走、或点院门走到门口，就回院
func walk(direction: Vector2, delta: float) -> void:
	var before := foot()
	var step := layout.WALK_SPEED * delta
	var tap_home := false
	var inspect_stop := ""
	if direction.length() > 0.01:
		walk_target = {}
		spot = layout.step_input(spot, direction, step)
	elif not walk_target.is_empty():
		spot = layout.step_toward(spot, walk_target, step)
		if layout.route_length(spot, walk_target) < 0.5:
			tap_home = bool(walk_target.get("home", false)) and layout.at_home(spot)
			inspect_stop = str(walk_target.get("inspect_stop", ""))
			walk_target = {}
	var moved := foot() - before
	if moved.length() > 0.01 and reveal != null:
		reveal.settle()
	if absf(moved.x) > 0.01:
		facing = signf(moved.x)
	if not _walked and layout.route_length(spot, layout.START) > 24.0:
		_walked = true
	if tap_home:
		_request_return("player")
		return
	if layout.at_home(spot) and direction.normalized().dot(layout.home_direction()) > layout.MIN_ALIGN:
		_home_hold += delta
		if _home_hold >= layout.HOME_HOLD:
			_request_return("player")
			return
	else:
		_home_hold = 0.0
	walker.position = foot()
	walker.advance(delta, moved, layout.depth(foot().y), facing, reduced_motion())
	walker.z_index = roundi(foot().y)
	if companion != null: companion.advance(delta, spot, walker, reduced_motion())
	if stray != null and _rescued_here: stray.advance(delta, spot, walker, reduced_motion())
	_snap_camera()
	if not inspect_stop.is_empty(): observe(inspect_stop)


## ───────────── 看景、带上、回院 ─────────────

func nearby_stop() -> String:
	return layout.nearby(spot)


func place_at(stop_id: String) -> void:
	var entry := layout.stop(stop_id)
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
	_hidden_caption_dirty = target == "leaf_pile"
	host.visit(target)
	var view := host.view()
	if view.get("current_stop", "") == target:
		if target != "leaf_pile" or not view.get("unsaved_changes", false):
			revealed[target] = str(view.get("taken", {}).get(target, view.get("offer", "")))
		if target == "leaf_pile" and view.get("unsaved_changes", false) and not view.get("offer", "").is_empty():
			host.uncover()
	_show_caption(_observe_caption(), 0.0)
	items.queue_redraw()
	_refresh()
	return true


func end_observe() -> void:
	_cancel_search()
	if reveal != null:
		reveal.settle()
	if observing.is_empty():
		return
	observing = ""
	_caption.visible = false
	items.queue_redraw()
	_refresh()


## 有东西时：带上 / 换成这个 / 放回；全由核心判定，界面只按结果刷新
func pick() -> bool:
	if observing == "village_lake" and residents != null:
		if residents.busy():
			if residents.pending.get("action", "") not in ["find_turtle", "adopt_turtle"]: return false
			return residents.retry() if residents.state in ["failed", "unknown"] else false
		if not _turtle_found(): return false
		var accepted: bool = residents.request("adopt_turtle")
		if accepted: walker.begin_action(&"pickup", reduced_motion())
		return accepted
	if observing == "village_stray" and residents != null:
		if residents.state == "failed": return residents.retry()
		if residents.busy() or residents.view().is_empty() or residents.view().beibei.stage != "unmet": return false
		_rescue_requested = residents.request("adopt_beibei")
		return _rescue_requested
	if observing.is_empty():
		return false
	var choice := pick_choice()
	var ok := false
	if reveal != null:
		reveal.settle()
	match choice.kind:
		"take":
			ok = host.take(choice.find_id).ok
		"swap":
			ok = host.swap(choice.old, choice.find_id).ok
		"release":
			ok = host.release(choice.find_id).ok
	if ok:
		if observing == "leaf_pile": _hidden_caption_dirty = true
		if choice.kind in ["take", "swap"]:
			walker.begin_action(&"pickup", reduced_motion())
		_show_caption(_observe_caption(), 0.0)
		items.queue_redraw()
		_refresh()
		if choice.kind in ["take", "swap"]:
			_start_reveal(choice.find_id)
	return ok


## 只在核心已接受带上 / 换成之后调用；起点是路边那件东西，停在人物头顶上方，终点是篮子里它的位置
func _start_reveal(find_id: String) -> void:
	if reveal == null:
		return
	var anchor: Vector2 = layout.stop(observing).get("item", foot())
	var depth := layout.depth(foot().y)
	var size := get_viewport().get_visible_rect().size
	var top := art_to_screen(foot() + Vector2(0, -layout.WALKER_BOX.size.y * depth)) - Vector2(0, FindReveal.HALO + 6.0)
	var margin := FindReveal.HALO + 8.0
	var ceiling := margin + FindReveal.LABEL_ROOM
	if _caption.visible and top.x + margin > _caption.position.x and top.x - margin < _caption.position.x + _caption.size.x:
		# 名字画在物件上方 HALO+6；纸片下沿以下再留光晕和名字行，避免竖屏压到看景字幕
		ceiling = _caption.position.y + _caption.size.y + margin + FindReveal.LABEL_ROOM
	var floor_y := size.y - margin
	if _pick_button.visible:
		floor_y = minf(floor_y, _pick_button.position.y - FindReveal.HALO - 30.0)
	elif _go_button.visible:
		floor_y = minf(floor_y, _go_button.position.y - FindReveal.HALO - 30.0)
	var min_y := ceiling
	if min_y > floor_y:
		min_y = floor_y
	top.x = clampf(top.x, margin, size.x - margin)
	top.y = clampf(top.y, min_y, maxf(min_y, floor_y))
	var slot := maxi(carried().size() - 1, 0)
	reveal.label_font = _basket.get_theme_default_font()
	reveal.play(find_id, art_to_screen(anchor), top, _basket.position + Vector2(24 + slot * 16, 22),
		1.6 * layout.depth(anchor.y) * _cam_zoom, _find_name(find_id), reduced_motion())


func pick_choice() -> Dictionary:
	if observing == "village_lake":
		if residents != null and residents.busy() and residents.pending.get("action", "") in ["find_turtle", "adopt_turtle"] and residents.state in ["failed", "unknown"]:
			return {"kind": "turtle_retry"}
		return {"kind": "turtle_adopt" if _turtle_found() else "none"}
	if observing == "village_stray" and residents != null and not residents.view().is_empty():
		if residents.view().beibei.stage == "unmet": return {"kind": "adopt"}
	if observing.is_empty():
		return {"kind": "none"}
	var view := host.view()
	if observing == "leaf_pile" and (view.get("hidden_search", false) or view.get("unsaved_changes", false)):
		return {"kind": "none"}
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
	_cancel_search()
	if leaving:
		return
	leaving = true
	walk_target = {}
	if reveal != null:
		reveal.settle(true)
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
				look_or_cross()
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
## 其余点按沿路走到离按下处最近的路面；点在院门一带（NearPathLayout.is_home_tap），走到门口就回院
func press_at(point: Vector2) -> void:
	for button: Button in [_return_button, _pause_button, _look_button, _pick_button, _go_button]:
		if button.is_visible_in_tree() and button.get_global_rect().has_point(point):
			if not button.disabled: button.pressed.emit()
			return
	if not observing.is_empty():
		suppressed_touches += 1
		_show_caption(_observe_caption() + "\n" + I18n.t("exploration.caption.continue_hint"), 0.0)
		return
	var art := screen_to_art(point)
	# A visible place marker is an invitation to walk there and look, never an
	# automatic pickup. Hidden animal finds remain hidden until searched.
	for entry: Dictionary in layout.STOPS:
		if entry.id == "leaf_pile" or not entry.has("item"): continue
		if point.distance_to(art_to_screen(entry.item)) <= 28.0:
			walk_target = layout.nearest(layout.position(entry))
			walk_target["inspect_stop"] = entry.id
			return
	var target := layout.nearest(art)
	walk_target = target.duplicate()
	walk_target["home"] = layout.is_home_tap(art)


func screen_to_art(point: Vector2) -> Vector2:
	var size := get_viewport().get_visible_rect().size
	return _cam_pos + (point - size * 0.5) / maxf(_cam_zoom, 0.001)


func art_to_screen(art: Vector2) -> Vector2:
	var size := get_viewport().get_visible_rect().size
	return (art - _cam_pos) * _cam_zoom + size * 0.5


## ───────────── 相机 ─────────────

func target_frame() -> Dictionary:
	return layout.frame(foot(), get_viewport().get_visible_rect().size)


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
	for entry: Dictionary in layout.STOPS:
		if entry.id == "leaf_pile" or not entry.has("item") or revealed.has(entry.id): continue
		var anchor: Vector2 = entry.item
		items.draw_circle(anchor, 14.0, Color(1.0, 0.97, 0.85, 0.82))
		items.draw_arc(anchor, 14.0, 0, TAU, 24, Color(0.48, 0.35, 0.18, 0.8), 2.0, true)
		items.draw_circle(anchor, 3.0, Color(0.48, 0.35, 0.18, 0.8))
	if leaf_texture != null and not layout.stop("leaf_pile").is_empty():
		var anchor: Vector2 = layout.stop("leaf_pile").item
		var spread := 1.0 if not str(revealed.get("leaf_pile", "")).is_empty() else 0.0
		if companion != null and _search_started and not reduced_motion():
			spread = maxf(spread, clampf((companion.search_elapsed - 0.7) / 1.7, 0.0, 1.0))
		var leaf_size := leaf_texture.get_size() * (56.0 / leaf_texture.get_width()) * layout.depth(anchor.y)
		items.draw_texture_rect(leaf_texture, Rect2(anchor - leaf_size * 0.5 + Vector2(24, 4) * spread, leaf_size), false, Color(1, 1, 1, lerpf(1.0, 0.65, spread)))
	var taken: Dictionary = host.view().get("taken", {}) if host != null else {}
	for stop_id: String in revealed:
		var find_id: String = revealed[stop_id]
		var anchor: Vector2 = layout.stop(stop_id).get("item", Vector2.ZERO)
		if find_id.is_empty() or taken.has(stop_id) or anchor == Vector2.ZERO:
			continue
		var depth := layout.depth(anchor.y)
		if stop_id == observing:
			# 静止的柔光地影，只在停下看的这一处；不闪、不动
			items.draw_set_transform(anchor + Vector2(0, 6) * depth, 0.0, Vector2(depth, 0.4 * depth))
			items.draw_circle(Vector2.ZERO, 34.0, Color(1.0, 0.96, 0.82, 0.55))
			items.draw_circle(Vector2.ZERO, 24.0, Color(1.0, 0.98, 0.90, 0.6))
			items.draw_set_transform(Vector2.ZERO)
		KeepsakeArt.draw(items, find_id, anchor, 1.6 * depth, true)


func _observe_caption() -> String:
	if observing == "village_lake": return _pond_caption()
	if observing == "village_stray": return _stray_caption()
	var text := I18n.t("exploration.stop.%s" % observing)
	if observing == "leaf_pile":
		var view := host.view()
		if view.get("hidden_search", false): return text + "\n" + I18n.t("exploration.caption.searching")
		if view.get("unsaved_changes", false) and (not view.get("offer", "").is_empty() or view.get("taken", {}).has(observing)): return text + "\n" + I18n.t("exploration.caption.search_wait")
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


func _cancel_search() -> void:
	_search_started = false
	if companion != null: companion.cancel_search()


func _update_search() -> void:
	if observing != "leaf_pile" or companion == null: return
	var view := host.view()
	if view.get("current_stop", "") != observing: return
	if view.get("hidden_search", false):
		if not _search_started:
			companion.start_search(layout.stop(observing))
			_search_started = true
		if companion.search_complete():
			host.uncover()
			_hidden_caption_dirty = true
			_show_caption(_observe_caption(), 0.0)
		items.queue_redraw()
	elif not view.get("unsaved_changes", false):
		var find_id := str(view.get("taken", {}).get(observing, view.get("offer", "")))
		if revealed.get(observing, "") != find_id:
			revealed[observing] = find_id
			_hidden_caption_dirty = true
			items.queue_redraw()
		if _hidden_caption_dirty:
			_show_caption(_observe_caption(), 0.0)
			_hidden_caption_dirty = false
		if _search_started: _cancel_search()


## The page boundary is reached on foot; it keeps the same trip and basket.
func at_page_edge() -> bool:
	return float(spot.d) <= 12.0

func look_or_cross() -> void:
	if at_page_edge() and observing.is_empty(): cross_page()
	else: observe()

func cross_page() -> bool:
	if leaving or not observing.is_empty() or not at_page_edge(): return false
	_cancel_search()
	if reveal != null: reveal.settle(true)
	village = not village
	layout = VillagePathLayout.geometry() if village else L.geometry()
	spot = {"arm": "lane", "d": 24.0}
	walk_target = {}
	_home_hold = 0.0
	painting.texture = load(layout.ART)
	walker.position = foot()
	walker.advance(0.0, Vector2.ZERO, layout.depth(foot().y), facing, true)
	walker.z_index = roundi(foot().y)
	for partner: PathCompanion in [companion, stray if _rescued_here else null]:
		if partner == null: continue
		partner.layout = layout
		partner.spot = {"arm": "lane", "d": 90.0}
		partner.advance(0.0, spot, walker, reduced_motion())
	_update_resident()
	_snap_camera()
	items.queue_redraw()
	_show_caption(I18n.t("exploration.caption.village" if village else "exploration.caption.arrive"), 5.0)
	_refresh()
	return true

func _stray_caption() -> String:
	if residents == null or residents.view().is_empty(): return I18n.t("beibei.unavailable")
	if residents.view().beibei.stage != "unmet":
		return I18n.t("beibei.following" if _rescued_here else "beibei.home")
	if residents.busy(): return I18n.t("beibei.retry_caption" if residents.state == "failed" else "beibei.saving")
	return I18n.t("beibei.meet")

func _turtle_eligible() -> bool:
	if residents == null or companion == null or residents.view().is_empty(): return false
	return village and residents.view().beibei.stage == "grown" and companion.choice.actor_id == "beibei"

func _turtle_found() -> bool:
	if not _turtle_eligible(): return false
	var value: Dictionary = residents.view().turtle
	return value.stage == "found" and value.found_trip == host.view().get("trip_id", "")

func _pond_caption() -> String:
	if residents == null or residents.view().is_empty(): return I18n.t("exploration.stop.village_lake")
	if residents.view().turtle.stage == "pond": return I18n.t("turtle.home")
	if not _turtle_eligible(): return I18n.t("exploration.stop.village_lake")
	if residents.busy(): return I18n.t("turtle.retry_caption" if residents.state in ["failed", "unknown"] else "turtle.saving")
	return I18n.t("turtle.found" if _turtle_found() else "turtle.searching")

func _update_turtle() -> void:
	if not village or residents == null or residents.view().is_empty():
		if turtle != null: turtle.visible = false
		return
	if observing == "village_lake" and _turtle_eligible() and residents.view().turtle.stage != "pond":
		if _turtle_found():
			if _search_started: _cancel_search()
		elif not residents.busy() and not host.view().get("unsaved_changes", false) and host.view().get("current_stop", "") == observing:
			if not _search_started:
				companion.start_search(layout.stop(observing))
				_search_started = true
			if companion.search_complete(): residents.request("find_turtle")
	if _turtle_found() and turtle == null:
		turtle = Sprite2D.new()
		turtle.texture = load(TurtleArt.TEXTURE)
		turtle.centered = false
		turtle.offset = -TurtleArt.ANCHOR
		turtle.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(turtle)
	if turtle != null:
		turtle.visible = _turtle_found()
		var stop := layout.stop("village_lake")
		var bank := layout.point(stop.arm, stop.d)
		turtle.position = bank + Vector2(110, 25) * layout.depth(bank.y)
		turtle.scale = Vector2.ONE * TurtleArt.SCALE * layout.depth(turtle.position.y)
		turtle.z_index = roundi(turtle.position.y)
	if observing == "village_lake":
		var text := _pond_caption()
		if text != _turtle_caption:
			_turtle_caption = text
			_show_caption(text, 0.0)

func _update_resident() -> void:
	if residents == null or residents.view().is_empty(): return
	var stage: String = residents.view().beibei.stage
	if _rescue_requested and stage != "unmet": _rescued_here = true
	var should_show := _rescued_here or (village and stage == "unmet")
	if not should_show and stray != null:
		remove_child(stray)
		stray.queue_free()
		stray = null
	if should_show and stray == null:
		stray = PathCompanion.new()
		add_child(stray)
		var start := spot if _rescued_here else layout.stop("village_stray")
		stray.setup({"actor_id": "beibei", "mode": "nearby"}, start, layout, "puppy")
		stray.spot = {"arm": start.arm, "d": maxf(0.0, float(start.d) + (-40.0 if not _rescued_here else 65.0))}
		stray.actor.position = stray.feet()
		stray.actor.advance_path(0.0, Vector2.ZERO, layout.depth(stray.actor.position.y), true)
	if observing == "village_stray":
		var text := _stray_caption()
		if text != _resident_caption:
			_resident_caption = text
			_show_caption(text, 0.0)


func _find_name(find_id: String) -> String:
	return I18n.t(ExplorationRoutes.find_name_key(find_id))


func _show_caption(text: String, seconds: float) -> void:
	_caption.text = text
	_caption.visible = true
	_caption_time = seconds


func _refresh() -> void:
	if _return_button == null:
		return
	_return_button.text = I18n.t("exploration.action.return")
	_pause_button.text = I18n.t("hud.pause")
	_go_button.text = I18n.t("exploration.action.continue")
	_hint.text = I18n.t("exploration.caption.free_walk_hint" if layout.free_walk() else "exploration.caption.walk_hint")
	var size := get_viewport().get_visible_rect().size
	var compact := size.x < 700.0
	var near := nearby_stop()
	var choice := pick_choice()
	_look_button.visible = observing.is_empty() and (at_page_edge() or not near.is_empty()) and not leaving
	if _look_button.visible:
		_look_button.text = I18n.t("exploration.action.look", {"place": I18n.t("exploration.place.%s" % near)})
	if _look_button.visible and at_page_edge():
		_look_button.text = I18n.t("exploration.action.near_path" if village else "exploration.action.village")
	_pick_button.visible = not observing.is_empty() and choice.kind != "none"
	_pick_button.disabled = choice.kind == "adopt" and (residents.busy() and residents.state != "failed" or host.view().get("unsaved_changes", false))
	if choice.kind == "turtle_adopt": _pick_button.disabled = residents.busy() or host.view().get("unsaved_changes", false)
	match choice.kind:
		"turtle_adopt":
			_pick_button.text = I18n.t("turtle.adopt")
		"turtle_retry":
			_pick_button.text = I18n.t("beibei.retry")
		"adopt":
			_pick_button.text = I18n.t("beibei.retry" if residents.state == "failed" else "beibei.adopt")
		"take":
			_pick_button.text = I18n.t("exploration.action.take", {"item": _find_name(choice.find_id)})
		"swap":
			_pick_button.text = I18n.t("exploration.action.swap", {"item": _find_name(choice.find_id)})
		"release":
			_pick_button.text = I18n.t("exploration.action.release", {"item": _find_name(choice.find_id)})
	_go_button.visible = not observing.is_empty()
	_hint.visible = not _walked and observing.is_empty()
	_place_label.text = I18n.t("exploration.place.village" if village else "exploration.place.title") if near.is_empty() or not observing.is_empty() else I18n.t("exploration.place.%s" % near)
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
	var side_caption := observing == "leaf_pile" and size.y < 400.0 and size.x > size.y
	if side_caption: caption_w = minf(caption_w, size.x * 0.43)
	# 先定宽度再按实际行数长高：StyleBox 的纸片要包住字，展示安全区也按纸片下沿算
	_fit_caption(caption_w)
	# 字幕放在上方天空里，路面和路边的东西不被挡住；走路时让出“停下看看”按钮的位置
	var caption_top := pad + button_h + 12.0
	_caption.position = Vector2((size.x - caption_w) * 0.5, caption_top if not observing.is_empty() else caption_top + button_h + 12.0)
	if side_caption: _caption.position.x = pad
	_hint.size = Vector2(size.x - pad * 2, 24)
	_hint.position = Vector2(pad, size.y - pad - 30)
	_basket.position = Vector2(pad, size.y - pad - 64 - (button_h + 10 if not observing.is_empty() else 0) - (34 if _hint.visible else 0))
	# 名称底板右缘 = 篮子左缘 + 文字起点 + 文字宽 + 6，窄屏时也留出右侧 pad
	_basket_label_width = basket_label_width_for(size.x, pad, _basket.position.x)


## 看景纸片按当前宽度的实际行数长高，不再把高度写成 0（字会溢出纸外，展示安全区也会按空高度算）
func _fit_caption(width: float) -> void:
	_caption.size = Vector2(width, 0.0)
	var lines := maxi(1, _caption.get_line_count())
	var spacing := float(_caption.get_theme_constant("line_spacing"))
	var text_height := lines * float(_caption.get_line_height()) + (lines - 1) * spacing
	var paper := _caption.get_theme_stylebox("normal")
	var pad_y := 0.0
	if paper != null:
		pad_y = paper.get_margin(SIDE_TOP) + paper.get_margin(SIDE_BOTTOM)
	_caption.size = Vector2(width, text_height + pad_y)


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
	_pause_button = _button(I18n.t("hud.pause"), func() -> void:
		reveal.settle(true)
		pause_requested.emit())
	_look_button = _button("", look_or_cross)
	_pick_button = _button("", func() -> void: pick())
	_go_button = _button(I18n.t("exploration.action.continue"), end_observe)
	_basket = Control.new()
	_basket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_basket.size = Vector2(290, 60)
	_basket.draw.connect(_draw_basket)
	hud.add_child(_basket)
	reveal = FindReveal.new()
	reveal.name = "FindReveal"
	hud.add_child(reveal)


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
	var text := basket_text()
	var fit := basket_label_fit(font, text, _basket_label_width)
	_basket.draw_rect(basket_label_rect(font, text, _basket_label_width), Color(1.0, 0.97, 0.88, 0.86))
	_basket.draw_multiline_string(font, fit.baseline, text, HORIZONTAL_ALIGNMENT_LEFT, fit.wrap_width, fit.font_size, BASKET_LABEL_MAX_LINES, INK)


func basket_text() -> String:
	var held: Array = carried() if host != null else []
	return I18n.t("exploration.basket.empty") if held.is_empty() else ExplorationDirector.items_text(PackedStringArray(held))


## 名称一行可用的宽度：最宽 200；窄屏让底板右缘停在屏宽 - pad 以内
static func basket_label_width_for(view_width: float, pad: float, basket_x: float) -> float:
	return clampf(view_width - pad - basket_x - BASKET_LABEL_AT.x - 6.0, BASKET_LABEL_MIN_WIDTH, BASKET_LABEL_WIDTH)


## 篮子名称怎么排：一行放得下就 15px 原样；放不下逐 1px 缩到 13px；仍放不下就 13px 折行（最多两行），
## 第二行留在原来的基线上，第一行往上长，篮子和下面的按钮位置都不动
static func basket_label_fit(font: Font, text: String, max_width: float = BASKET_LABEL_WIDTH) -> Dictionary:
	var font_size := BASKET_LABEL_FONT_SIZE
	while font_size > BASKET_LABEL_MIN_FONT_SIZE and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_width:
		font_size -= 1
	var one_line := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	if one_line.x <= max_width:
		return {"font_size": font_size, "lines": 1, "size": one_line, "wrap_width": -1.0, "baseline": BASKET_LABEL_AT}
	var block := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, max_width, font_size, BASKET_LABEL_MAX_LINES)
	var lines := clampi(roundi(block.y / font.get_height(font_size)), 1, BASKET_LABEL_MAX_LINES)
	var baseline := BASKET_LABEL_AT - Vector2(0, (lines - 1) * font.get_height(font_size))
	return {"font_size": font_size, "lines": lines, "size": Vector2(minf(block.x, max_width), block.y), "wrap_width": max_width, "baseline": baseline}


## 篮子名称的小底板：每帧都画、只随文字宽度变，背景再花也读得清
static func basket_label_rect(font: Font, text: String, max_width: float = BASKET_LABEL_WIDTH) -> Rect2:
	var fit := basket_label_fit(font, text, max_width)
	var ascent := font.get_ascent(fit.font_size)
	var text_size: Vector2 = fit.size
	return Rect2(fit.baseline + Vector2(-6, -ascent - 3), text_size + Vector2(12, 6))


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
