class_name NearGroundFindArt
extends RefCounted
## Near-scene feather keeps the author's contact paint on the ground only.
const FEATHER := preload("res://assets/holiday/exploration/finds/feather_ground_643.png")
const FEATHER_SCALE := 0.72
static var _feather_reveal_scale := -1.0

static func draw(canvas: CanvasItem, find_id: String, at: Vector2, size: float) -> void:
	if find_id.get_slice(".",2) != "feather":
		KeepsakeArt.draw(canvas,find_id,at,size,true)
		return
	var span := KeepsakeArt.TEXTURE_SPAN * size * FEATHER_SCALE / maxf(FEATHER.get_width(),FEATHER.get_height())
	var extent := FEATHER.get_size() * span
	canvas.draw_texture_rect(FEATHER,Rect2(at-extent*0.5,extent),false)

static func reveal_scale(find_id: String) -> float:
	if find_id.get_slice(".",2) != "feather":return 1.0
	if _feather_reveal_scale < 0.0:
		var original := KeepsakeArt.texture(find_id)
		_feather_reveal_scale = FEATHER_SCALE
		if original != null:
			var old_edge := visible_span(original)
			if old_edge > 0.0:_feather_reveal_scale *= visible_span(FEATHER)/old_edge
	return _feather_reveal_scale

static func visible_span(texture: Texture2D) -> float:
	var image := texture.get_image()
	if image == null or image.is_empty():return 1.0
	var bounds := image.get_used_rect().size
	return float(maxi(bounds.x,bounds.y))/maxf(texture.get_width(),texture.get_height())
