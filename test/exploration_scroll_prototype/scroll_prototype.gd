extends Node2D
# 画卷漫步隔离原型（#199）：几何占位的横向画卷、左右行走、停下观察、相机跟随与视口适配。
# 只在独立最小项目里运行；不接 SaveStore / Main / AudioDirector，也不引用探索核心。

const ScrollWalkModel := preload("res://test/exploration_scroll_prototype/scroll_walk_model.gd")
const ScrollInput := preload("res://test/exploration_scroll_prototype/scroll_input.gd")
## 独立项目装配时会带上主项目已有的中文字体；不存在时退回引擎默认字体
const CJK_FONT := "res://assets/template/fonts/NotoSansSC-VF.subset.woff2"

const PAPER := Color(0.95, 0.91, 0.82)
const INK := Color(0.29, 0.32, 0.30)
const BOB_HEIGHT := 4.0
const BOB_RATE := 9.0

var model := ScrollWalkModel.new()
var input := ScrollInput.new()
var low_motion := false
var camera: Camera2D
var walker: Node2D
var _body: Node2D
var _hint: Label
var _near: Label
var _touch_zones: Array[ColorRect] = []
## 每根手指当前所在的半边，用来处理拖动跨过中线
var _touch_dirs := {}
var _walk_time := 0.0


func _ready() -> void:
	_build_scroll()
	_build_walker()
	camera = Camera2D.new()
	camera.name = "Camera"
	add_child(camera)
	camera.make_current()
	_build_hud()
	get_viewport().size_changed.connect(layout)
	layout()


func _process(delta: float) -> void:
	model.set_direction(input.direction())
	model.step(delta)
	if model.is_walking():
		_walk_time += delta
	else:
		_walk_time = 0.0
	_sync()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo:
		var key := (event as InputEventKey)
		var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
		## 每个物理键各算一个来源：按住 ← 时按下又松开 A，仍回到 ←
		if code == KEY_LEFT or code == KEY_A:
			_key("key_%d" % code, -1, key.pressed)
		elif code == KEY_RIGHT or code == KEY_D:
			_key("key_%d" % code, 1, key.pressed)
		elif code == KEY_L and key.pressed:
			low_motion = not low_motion
			_update_hint()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var source := "touch_%d" % touch.index
		if touch.pressed and not touch.canceled:
			_touch(source, touch.position.x)
		else:
			_touch_dirs.erase(source)
			input.release(source)
		_update_touch_zones()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		var source := "touch_%d" % drag.index
		if _touch_dirs.has(source):
			_touch(source, drag.position.x)
			_update_touch_zones()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			release_all()


## 失焦、切后台、触摸系统取消时统一调用：清掉所有按住的来源，回来后要重新按才会走
func release_all() -> void:
	input.clear()
	_touch_dirs.clear()
	model.set_direction(0)
	_update_touch_zones()


func layout() -> void:
	layout_for(get_viewport().get_visible_rect().size)


func layout_for(size: Vector2) -> void:
	var frame := model.view(size)
	camera.zoom = Vector2.ONE * float(frame["zoom"])
	camera.position = frame["camera"]
	for index in _touch_zones.size():
		var zone := _touch_zones[index]
		zone.position = Vector2(size.x * 0.5 * index, 0)
		zone.size = Vector2(size.x * 0.5, size.y)


## 行走时的轻微起伏；低动效下恒为 0
func body_offset() -> float:
	if low_motion or not model.is_walking():
		return 0.0
	return -absf(sin(_walk_time * BOB_RATE)) * BOB_HEIGHT


func _key(source: String, dir: int, pressed: bool) -> void:
	if pressed:
		input.press(source, dir)
	else:
		input.release(source)


func _touch(source: String, screen_x: float) -> void:
	var dir := -1 if screen_x < get_viewport().get_visible_rect().size.x * 0.5 else 1
	if _touch_dirs.get(source, 0) != dir:
		_touch_dirs[source] = dir
		input.press(source, dir)


func _sync() -> void:
	walker.position = Vector2(model.x, ScrollWalkModel.GROUND_Y)
	_body.position.y = body_offset()
	_body.scale.x = model.facing
	camera.position = model.view(get_viewport().get_visible_rect().size)["camera"]
	var stop := model.nearby_stop()
	_near.visible = not stop.is_empty()
	if _near.visible:
		_near.text = "可以在这里停下看看（%s）" % stop["label"]


func _update_touch_zones() -> void:
	var sides := {}
	for dir: int in _touch_dirs.values():
		sides[dir] = true
	if _touch_zones.size() == 2:
		_touch_zones[0].visible = sides.has(-1)
		_touch_zones[1].visible = sides.has(1)


func _update_hint() -> void:
	_hint.text = "← → / A D，或按住屏幕左右半边行走 · 松开即停 · L 低动效：%s" % ("开" if low_motion else "关")


func _build_scroll() -> void:
	var length := ScrollWalkModel.SCROLL_LENGTH
	var height := ScrollWalkModel.SCROLL_HEIGHT
	_rect(Vector2.ZERO, Vector2(length, height), PAPER)
	_rect(Vector2.ZERO, Vector2(length, 260), Color(0.88, 0.90, 0.88))
	## 远山：连续起伏的淡墨色带
	var hills := PackedVector2Array([Vector2(0, 470)])
	var step := 80.0
	var px := 0.0
	while px <= length:
		hills.append(Vector2(px, 360 - 70 * sin(px / 430.0) - 40 * sin(px / 170.0 + 1.3)))
		px += step
	hills.append(Vector2(length, 470))
	_polygon(hills, Color(0.70, 0.75, 0.70))
	_rect(Vector2(0, 470), Vector2(length, height - 470), Color(0.84, 0.79, 0.66))
	_rect(Vector2(0, ScrollWalkModel.GROUND_Y + 6), Vector2(length, 10), Color(0.74, 0.66, 0.52))
	## 占位停留点：各用一个简单几何形，标明“占位”
	var shapes := [Color(0.55, 0.70, 0.78), Color(0.45, 0.58, 0.42), Color(0.60, 0.58, 0.55)]
	for index in ScrollWalkModel.STOPS.size():
		var stop: Dictionary = ScrollWalkModel.STOPS[index]
		var sx := float(stop["x"])
		match index:
			0:
				_polygon(_ellipse(Vector2(sx, 520), Vector2(130, 34)), shapes[0])
			1:
				_rect(Vector2(sx - 10, 400), Vector2(20, 160), Color(0.45, 0.36, 0.28))
				_polygon(_ellipse(Vector2(sx, 380), Vector2(90, 80)), shapes[1])
			_:
				_polygon(PackedVector2Array([Vector2(sx - 90, 560), Vector2(sx - 60, 470), Vector2(sx + 40, 455), Vector2(sx + 95, 560)]), shapes[2])
		var label := Label.new()
		label.text = stop["label"]
		label.position = Vector2(sx - 70, 170)
		label.add_theme_color_override("font_color", INK)
		_apply_font(label, 22)
		add_child(label)
	## 卷轴两端的轴头：画卷到此为止，相机永远不越过
	_rect(Vector2.ZERO, Vector2(28, height), Color(0.42, 0.30, 0.22))
	_rect(Vector2(length - 28, 0), Vector2(28, height), Color(0.42, 0.30, 0.22))


func _build_walker() -> void:
	walker = Node2D.new()
	walker.name = "Walker"
	_body = Node2D.new()
	walker.add_child(_body)
	var torso := Polygon2D.new()
	torso.polygon = PackedVector2Array([Vector2(-16, 0), Vector2(-18, -52), Vector2(0, -64), Vector2(18, -52), Vector2(16, 0)])
	torso.color = Color(0.36, 0.42, 0.52)
	_body.add_child(torso)
	var head := Polygon2D.new()
	head.polygon = _ellipse(Vector2(0, -80), Vector2(15, 15))
	head.color = Color(0.93, 0.80, 0.68)
	_body.add_child(head)
	var nose := Polygon2D.new()
	nose.polygon = PackedVector2Array([Vector2(13, -84), Vector2(22, -80), Vector2(13, -76)])
	nose.color = Color(0.80, 0.60, 0.50)
	_body.add_child(nose)
	add_child(walker)


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "Hud"
	add_child(hud)
	for index in 2:
		var zone := ColorRect.new()
		zone.color = Color(1, 1, 1, 0.10)
		zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		zone.visible = false
		hud.add_child(zone)
		_touch_zones.append(zone)
	var tag := Label.new()
	tag.text = "占位原型 · 非正式美术 · 不接存档"
	tag.position = Vector2(16, 12)
	tag.add_theme_color_override("font_color", INK)
	_apply_font(tag, 18)
	_backing(tag)
	hud.add_child(tag)
	_hint = Label.new()
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.offset_top = -40
	_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_color_override("font_color", INK)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(_hint, 16)
	_backing(_hint)
	hud.add_child(_hint)
	_near = Label.new()
	_near.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_near.offset_top = 48
	_near.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_near.add_theme_color_override("font_color", INK)
	_near.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_near.visible = false
	_apply_font(_near, 18)
	hud.add_child(_near)
	_update_hint()


## 界面文字垫一层半透明纸色，走到轴头附近时仍然看得清
func _backing(label: Label) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(PAPER, 0.82)
	box.set_content_margin_all(6)
	box.set_corner_radius_all(4)
	label.add_theme_stylebox_override("normal", box)


func _rect(origin: Vector2, size: Vector2, color: Color) -> void:
	_polygon(PackedVector2Array([origin, origin + Vector2(size.x, 0), origin + size, origin + Vector2(0, size.y)]), color)


func _polygon(points: PackedVector2Array, color: Color) -> void:
	var shape := Polygon2D.new()
	shape.polygon = points
	shape.color = color
	add_child(shape)


func _ellipse(center: Vector2, radius: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 24:
		var angle := TAU * index / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return points


func _apply_font(label: Label, size: int) -> void:
	label.add_theme_font_size_override("font_size", size)
	if ResourceLoader.exists(CJK_FONT):
		label.add_theme_font_override("font", load(CJK_FONT))
