class_name NearPathPainter
extends Node2D
# 近郊小路的占位画面：远景直接取小院原画的同一路山（同一画风与天气），
# 中景、路面与每处小景用水彩式多层淡彩绘制。只是可替换的占位，不是正式原画；
# 正式长卷交付后替换本节点即可，几何仍以 NearPathLayout 为准。

const L := preload("res://scripts/exploration/near_path_layout.gd")
const SUNNY := preload("res://assets/holiday/environment/yard_sunny.png")
const OVERCAST := preload("res://assets/holiday/environment/yard_overcast.png")
# 小院原画中央的远山与天空（避开左侧屋顶和右侧树冠）
const FAR_REGION := Rect2(691, 0, 845, 475)
const FAR_HEIGHT := 470.0
const FAR_FACTOR := 0.22
const MID_FACTOR := 0.55

var weather := "sunny"
var far: Node2D
var mid: Node2D
var near: Node2D
var _rng := RandomNumberGenerator.new()
var _mid_shapes: Array = []
var _near_shapes: Array = []
var _tufts: Array = []


func setup(current_weather: String) -> void:
	weather = current_weather
	_build_far()
	mid = Node2D.new()
	mid.name = "Mid"
	add_child(mid)
	near = Node2D.new()
	near.name = "Near"
	add_child(near)
	_rng.seed = 20261005
	_plan_mid()
	_plan_near()
	mid.draw.connect(_draw_shapes.bind(mid, _mid_shapes))
	near.draw.connect(_draw_near)
	mid.queue_redraw()
	near.queue_redraw()


## 视差：远景与中景按相机左缘的一部分速度移动；内容画满 0..SIZE.x 宽，任何取景都不露边
func follow_camera(camera_left: float) -> void:
	if far != null:
		far.position.x = camera_left * (1.0 - FAR_FACTOR)
	if mid != null:
		mid.position.x = camera_left * (1.0 - MID_FACTOR)


func _build_far() -> void:
	far = Node2D.new()
	far.name = "Far"
	add_child(far)
	var sky := Polygon2D.new()
	sky.polygon = PackedVector2Array([Vector2(-200, -400), Vector2(L.SIZE.x + 200, -400), Vector2(L.SIZE.x + 200, 460), Vector2(-200, 460)])
	sky.color = Color(0.56, 0.71, 0.86) if weather != "overcast" else Color(0.70, 0.74, 0.78)
	far.add_child(sky)
	var picture := AtlasTexture.new()
	picture.atlas = OVERCAST if weather == "overcast" else SUNNY
	picture.region = FAR_REGION
	var scale_factor := FAR_HEIGHT / FAR_REGION.size.y
	var tile_width := FAR_REGION.size.x * scale_factor
	var x := -tile_width * 0.5
	var index := 0
	while x < L.SIZE.x + tile_width:
		var sprite := Sprite2D.new()
		sprite.texture = picture
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.flip_h = index % 2 == 1
		sprite.scale = Vector2.ONE * scale_factor
		sprite.position = Vector2(x, 0)
		far.add_child(sprite)
		x += tile_width
		index += 1


func _plan_mid() -> void:
	var hill_tones := [Color(0.55, 0.66, 0.42, 0.55), Color(0.47, 0.60, 0.36, 0.6), Color(0.62, 0.70, 0.45, 0.5)]
	for layer in 3:
		var base := 400.0 + layer * 26.0
		var points := PackedVector2Array([Vector2(-50, 720)])
		var x := -50.0
		while x <= L.SIZE.x + 60.0:
			points.append(Vector2(x, base + sin(x / (260.0 + layer * 70.0) + layer) * (18.0 - layer * 3.0) + _rng.randf_range(-4, 4)))
			x += 40.0
		points.append(Vector2(L.SIZE.x + 60, 720))
		_mid_shapes.append({"poly": points, "color": hill_tones[layer]})
	for i in 46:
		var cx := _rng.randf_range(0.0, L.SIZE.x)
		var cy := 418.0 + _rng.randf_range(-10, 24)
		var tone := Color(0.24, 0.36, 0.24, 0.55).lerp(Color(0.33, 0.45, 0.27, 0.5), _rng.randf())
		_mid_shapes.append({"tree": Vector2(cx, cy), "height": _rng.randf_range(26, 52), "color": tone})


func _plan_near() -> void:
	var meadow := PackedVector2Array([Vector2(-60, 720)])
	var path_top := PackedVector2Array()
	var path_bottom := PackedVector2Array()
	var x := -60.0
	while x <= L.SIZE.x + 60.0:
		meadow.append(Vector2(x, 476.0 + sin(x / 330.0) * 10.0 + sin(x / 97.0) * 3.0))
		path_top.append(Vector2(x, L.GROUND_Y - 24.0 + sin(x / 210.0) * 4.0 + _rng.randf_range(-1.5, 1.5)))
		path_bottom.append(Vector2(x, L.GROUND_Y + 30.0 + sin(x / 180.0 + 1.0) * 5.0 + _rng.randf_range(-1.5, 1.5)))
		x += 30.0
	meadow.append(Vector2(L.SIZE.x + 60, 720))
	_near_shapes.append({"poly": meadow, "color": Color(0.53, 0.66, 0.36)})
	var lower := PackedVector2Array([Vector2(-60, 720)])
	for point: Vector2 in path_bottom:
		lower.append(point + Vector2(0, 18))
	lower.append(Vector2(L.SIZE.x + 60, 720))
	_near_shapes.append({"poly": lower, "color": Color(0.45, 0.60, 0.31, 0.75)})
	var path := path_top.duplicate()
	var reversed := path_bottom.duplicate()
	reversed.reverse()
	path.append_array(reversed)
	_near_shapes.append({"poly": path, "color": Color(0.80, 0.70, 0.52)})
	_near_shapes.append({"line": path_top, "color": Color(0.55, 0.46, 0.30, 0.45), "width": 2.0})
	_near_shapes.append({"line": path_bottom, "color": Color(0.50, 0.42, 0.28, 0.5), "width": 2.5})
	for i in 70:
		_tufts.append({"at": Vector2(_rng.randf_range(0, L.SIZE.x), _rng.randf_range(600, 712)), "size": _rng.randf_range(0.7, 1.4), "flower": _rng.randf() < 0.28, "hue": _rng.randf()})
	for i in 40:
		_tufts.append({"at": Vector2(_rng.randf_range(0, L.SIZE.x), _rng.randf_range(486, 528)), "size": _rng.randf_range(0.45, 0.8), "flower": _rng.randf() < 0.35, "hue": _rng.randf()})


func _draw_near() -> void:
	_draw_shapes(near, _near_shapes)
	_draw_gate(near, L.stop("gate").x)
	_draw_brook(near, L.stop("brook").x)
	_draw_shade(near, L.stop("shade").x)
	_draw_slope(near, L.stop("slope").x)
	for tuft: Dictionary in _tufts:
		_draw_tuft(near, tuft)


func _draw_shapes(canvas: CanvasItem, shapes: Array) -> void:
	for shape: Dictionary in shapes:
		if shape.has("poly"):
			_wash(canvas, shape.poly, shape.color)
		elif shape.has("line"):
			canvas.draw_polyline(shape.line, shape.color, shape.width, true)
		elif shape.has("tree"):
			_distant_tree(canvas, shape.tree, shape.height, shape.color)


## 同一形状错开几次、降低不透明度叠画，边缘像水彩一样柔和
func _wash(canvas: CanvasItem, points: PackedVector2Array, color: Color) -> void:
	var offsets := [Vector2.ZERO, Vector2(2.5, -1.5), Vector2(-2.0, 2.0)]
	for i in offsets.size():
		var moved := PackedVector2Array()
		for point: Vector2 in points:
			moved.append(point + offsets[i])
		canvas.draw_colored_polygon(moved, Color(color, color.a * (0.62 if i == 0 else 0.3)))


func _distant_tree(canvas: CanvasItem, at: Vector2, height: float, color: Color) -> void:
	var half := height * 0.28
	canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(-half, 0), at + Vector2(0, -height), at + Vector2(half, 0)]), color)
	canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(-half * 0.8, -height * 0.3), at + Vector2(0, -height * 1.08), at + Vector2(half * 0.8, -height * 0.3)]), Color(color, color.a * 0.7))


func _draw_gate(canvas: CanvasItem, x: float) -> void:
	var wood := Color(0.48, 0.34, 0.22)
	var light := Color(0.64, 0.48, 0.32)
	for i in 6:
		var px := x - 230.0 + i * 46.0
		if absf(px - (x - 20.0)) < 40.0:
			continue
		canvas.draw_line(Vector2(px, 534), Vector2(px, 470), wood, 6.0)
		canvas.draw_line(Vector2(px - 1.5, 532), Vector2(px - 1.5, 474), light, 2.0)
	canvas.draw_line(Vector2(x - 236, 488), Vector2(x - 66, 484), wood, 4.5)
	canvas.draw_line(Vector2(x - 236, 512), Vector2(x - 66, 510), wood, 4.5)
	canvas.draw_line(Vector2(x + 26, 486), Vector2(x + 30, 486), wood, 4.0)
	# 敞开的院门：两根门柱，一扇门板斜靠
	canvas.draw_line(Vector2(x - 62, 540), Vector2(x - 62, 458), wood, 8.0)
	canvas.draw_line(Vector2(x + 22, 540), Vector2(x + 22, 458), wood, 8.0)
	_wash(canvas, PackedVector2Array([Vector2(x - 58, 470), Vector2(x - 110, 480), Vector2(x - 110, 532), Vector2(x - 58, 534)]), Color(0.58, 0.42, 0.27, 0.8))
	canvas.draw_line(Vector2(x - 58, 492), Vector2(x - 110, 500), wood, 2.5)
	canvas.draw_line(Vector2(x - 58, 516), Vector2(x - 110, 520), wood, 2.5)
	for i in 5:
		_draw_tuft(canvas, {"at": Vector2(x - 200 + i * 52.0, 538), "size": 1.0, "flower": i % 2 == 0, "hue": float(i) / 5.0})


func _draw_brook(canvas: CanvasItem, x: float) -> void:
	var water := PackedVector2Array()
	var bank := PackedVector2Array()
	for i in 21:
		var t := float(i) / 20.0
		var wx := x - 300.0 + t * 600.0
		water.append(Vector2(wx, 500.0 + sin(t * PI * 2.0) * 6.0))
	for i in range(20, -1, -1):
		var t := float(i) / 20.0
		var wx := x - 300.0 + t * 600.0
		water.append(Vector2(wx, 524.0 + sin(t * PI * 2.0 + 0.8) * 5.0))
	_wash(canvas, water, Color(0.48, 0.66, 0.78, 0.9))
	for i in 7:
		var wx := x - 240.0 + i * 80.0
		canvas.draw_line(Vector2(wx, 509), Vector2(wx + 36, 507), Color(0.86, 0.93, 0.96, 0.7), 1.6)
	for i in 9:
		var at := Vector2(x - 280.0 + i * 70.0 + (i % 3) * 9.0, 527.0 + (i % 2) * 6.0)
		canvas.draw_set_transform(at, 0.0, Vector2(1.0, 0.55))
		canvas.draw_circle(Vector2.ZERO, 10.0 + (i % 3) * 3.0, Color(0.58, 0.60, 0.58))
		canvas.draw_circle(Vector2(-2, -3), 6.0, Color(0.72, 0.74, 0.72, 0.8))
		canvas.draw_set_transform(Vector2.ZERO)
	bank.append_array([Vector2(x - 90, 538), Vector2(x - 40, 530), Vector2(x + 10, 536)])
	canvas.draw_polyline(bank, Color(0.40, 0.50, 0.30, 0.6), 2.0, true)
	for i in 4:
		_draw_tuft(canvas, {"at": Vector2(x - 150.0 + i * 100.0, 498), "size": 1.1, "flower": false, "hue": 0.0})


func _draw_shade(canvas: CanvasItem, x: float) -> void:
	var trunk := Color(0.38, 0.27, 0.19)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(x + 50, 538), Vector2(x + 62, 380), Vector2(x + 74, 380), Vector2(x + 88, 538)]), trunk)
	var greens := [Color(0.20, 0.34, 0.22, 0.9), Color(0.26, 0.42, 0.26, 0.85), Color(0.32, 0.48, 0.28, 0.8)]
	for tier in 6:
		var top := 230.0 + tier * 46.0
		var half := 46.0 + tier * 24.0
		var tri := PackedVector2Array([Vector2(x + 68 - half, top + 70), Vector2(x + 68, top), Vector2(x + 68 + half, top + 70)])
		_wash(canvas, tri, greens[tier % 3])
	_wash(canvas, PackedVector2Array([Vector2(x - 120, 548), Vector2(x + 260, 548), Vector2(x + 230, 566), Vector2(x - 90, 566)]), Color(0.25, 0.32, 0.20, 0.22))
	for i in 3:
		_draw_tuft(canvas, {"at": Vector2(x - 40.0 + i * 120.0, 540), "size": 1.0, "flower": i == 1, "hue": 0.7})


func _draw_slope(canvas: CanvasItem, x: float) -> void:
	var rise := PackedVector2Array([Vector2(x - 300, 540), Vector2(x - 120, 470), Vector2(x + 60, 410), Vector2(x + 260, 390), Vector2(x + 420, 420), Vector2(x + 520, 540)])
	_wash(canvas, rise, Color(0.58, 0.70, 0.40, 0.8))
	# 歇脚的平石
	canvas.draw_set_transform(Vector2(x + 96, 528), 0.0, Vector2(1.0, 0.42))
	canvas.draw_circle(Vector2.ZERO, 38.0, Color(0.56, 0.56, 0.52))
	canvas.draw_circle(Vector2(-6, -8), 30.0, Color(0.68, 0.68, 0.64))
	canvas.draw_set_transform(Vector2.ZERO)
	for i in 9:
		var at := Vector2(x - 180.0 + i * 64.0, 470.0 - sin(float(i) / 8.0 * PI) * 50.0 + 30.0)
		_draw_tuft(canvas, {"at": at, "size": 0.9, "flower": true, "hue": float(i) / 9.0})


func _draw_tuft(canvas: CanvasItem, tuft: Dictionary) -> void:
	var at: Vector2 = tuft.at
	var s: float = tuft.size
	var blade := Color(0.32, 0.48, 0.24, 0.85)
	for i in 4:
		var lean := (float(i) - 1.5) * 4.0 * s
		canvas.draw_line(at, at + Vector2(lean, -12.0 * s - i % 2 * 4.0 * s), blade, 1.6)
	if tuft.flower:
		var palette := [Color(0.95, 0.93, 0.86), Color(0.92, 0.78, 0.40), Color(0.74, 0.62, 0.86), Color(0.92, 0.66, 0.70)]
		var color: Color = palette[int(float(tuft.hue) * palette.size()) % palette.size()]
		canvas.draw_circle(at + Vector2(1.0 * s, -14.0 * s), 2.6 * s, color)
