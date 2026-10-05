class_name KeepsakeArt
extends RefCounted
# 圆石、松果、落羽的占位画法：静止时就认得出来，不靠飘、转或闪光。
# 画卷路边、提篮与拾起展示共用；finds/ 下有制作人小物贴图时用贴图，没有就用占位画法。

const INK := Color(0.29, 0.22, 0.16)
const TEXTURE_DIR := "res://assets/holiday/exploration/finds/"
## 贴图在 size 1 时的长边，与占位画法大致同一占地
const TEXTURE_SPAN := 30.0

static var _textures := {}


static func texture(find_id: String) -> Texture2D:
	var slug := find_id.get_slice(".", 2)
	if not _textures.has(slug):
		var path := TEXTURE_DIR + slug + ".webp"
		_textures[slug] = load(path) if ResourceLoader.exists(path) else null
	return _textures[slug]


static func draw(canvas: CanvasItem, find_id: String, at: Vector2, size: float = 1.0) -> void:
	var tex := texture(find_id)
	if tex != null:
		var span := TEXTURE_SPAN * size / maxf(tex.get_width(), tex.get_height())
		var extent := Vector2(tex.get_width(), tex.get_height()) * span
		canvas.draw_texture_rect(tex, Rect2(at - extent * 0.5, extent), false)
		return
	match find_id.get_slice(".", 2):
		"brook_stone":
			_stone(canvas, at, size)
		"pine_cone":
			_pine_cone(canvas, at, size)
		"feather":
			_feather(canvas, at, size)


static func _stone(canvas: CanvasItem, at: Vector2, s: float) -> void:
	canvas.draw_set_transform(at, 0.0, Vector2(1.0, 0.62) * s)
	canvas.draw_circle(Vector2(1.5, 4.0), 15.0, Color(0.20, 0.22, 0.20, 0.18))
	canvas.draw_circle(Vector2.ZERO, 14.0, Color(0.55, 0.58, 0.58))
	canvas.draw_circle(Vector2(-2.0, -2.0), 11.5, Color(0.66, 0.69, 0.68))
	canvas.draw_circle(Vector2(-5.0, -5.5), 4.5, Color(0.84, 0.86, 0.84, 0.85))
	canvas.draw_arc(Vector2.ZERO, 14.0, 0.2, PI - 0.2, 18, Color(0.36, 0.38, 0.38, 0.7), 1.6)
	canvas.draw_set_transform(Vector2.ZERO)


static func _pine_cone(canvas: CanvasItem, at: Vector2, s: float) -> void:
	canvas.draw_set_transform(at, -0.5, Vector2.ONE * s)
	canvas.draw_circle(Vector2(2.0, 3.0), 9.0, Color(0.18, 0.14, 0.10, 0.16))
	for row in 5:
		var y := -10.0 + row * 4.8
		var half := 5.0 + sin(float(row) / 4.0 * PI) * 3.6
		for col in 3:
			var x := (col - 1) * half * 0.62
			canvas.draw_circle(Vector2(x, y), 3.4, Color(0.47, 0.30, 0.17).lerp(Color(0.63, 0.43, 0.25), float(row % 2) * 0.5))
			canvas.draw_arc(Vector2(x, y), 3.4, 0.3, PI - 0.3, 6, Color(0.30, 0.18, 0.10, 0.8), 1.0)
	canvas.draw_line(Vector2(0, -12), Vector2(0, -16), Color(0.35, 0.24, 0.14), 1.6)
	canvas.draw_set_transform(Vector2.ZERO)


static func _feather(canvas: CanvasItem, at: Vector2, s: float) -> void:
	canvas.draw_set_transform(at, -0.35, Vector2.ONE * s)
	var vane := PackedVector2Array()
	for i in 13:
		var t := float(i) / 12.0
		vane.append(Vector2(lerpf(-16.0, 16.0, t), -sin(t * PI) * 6.5 - t * 1.5))
	for i in range(12, -1, -1):
		var t := float(i) / 12.0
		vane.append(Vector2(lerpf(-16.0, 16.0, t), sin(t * PI) * 4.5 - t * 1.5))
	canvas.draw_colored_polygon(vane, Color(0.93, 0.91, 0.86))
	canvas.draw_polyline(vane, Color(0.62, 0.60, 0.58, 0.8), 1.0, true)
	for i in range(2, 11, 2):
		var x := lerpf(-16.0, 16.0, float(i) / 12.0)
		canvas.draw_line(Vector2(x, -0.8), Vector2(x + 4.0, -4.6), Color(0.64, 0.66, 0.70, 0.55), 1.0)
	canvas.draw_line(Vector2(-20, 1.0), Vector2(16, -1.5), Color(0.52, 0.45, 0.38), 1.3)
	canvas.draw_set_transform(Vector2.ZERO)
