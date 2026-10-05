extends Node2D
func _ready() -> void:
	var bg := Sprite2D.new()
	bg.texture = load("res://near_path.png")
	bg.centered = false
	bg.scale = Vector2.ONE * (1280.0/1672.0)
	add_child(bg)
	var cone := Sprite2D.new()
	cone.texture = load("res://feather.png")
	cone.centered = false
	cone.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var s := (24.0/913.0)*(1280.0/1672.0)
	cone.scale = Vector2.ONE*s
	cone.position = Vector2(880,752)*(1280.0/1672.0)-Vector2(684,1086)*s
	add_child(cone)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png("res://world.png") == OK)
	var card := ColorRect.new()
	card.position = Vector2(495,260)
	card.size = Vector2(290,170)
	card.color = Color("f5efdf")
	add_child(card)
	var detail := Sprite2D.new()
	detail.texture = cone.texture
	detail.centered = false
	detail.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	detail.scale = Vector2.ONE*(64.0/913.0)
	detail.position = Vector2(640,365)-Vector2(684,1086)*detail.scale
	add_child(detail)
	var text := Label.new()
	text.text = "FEATHER / PRESENTATION STUDY"
	text.position = Vector2(510,390)
	text.add_theme_color_override("font_color",Color("48382c"))
	text.add_theme_font_size_override("font_size",14)
	add_child(text)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png("res://presentation.png") == OK)
	get_tree().quit()

