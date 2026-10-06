extends Node2D
func _ready() -> void:
	var background := Sprite2D.new()
	background.texture=load("res://yard.png")
	background.centered=false
	background.scale=Vector2(1280,720)/background.texture.get_size()
	add_child(background)
	var sheep := Sprite2D.new()
	sheep.centered=false
	sheep.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sheep)
	var player := Sprite2D.new()
	player.texture=load("res://player.png")
	player.centered=false
	player.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(player)
	var depth := .82+.36*((480.0-420.0)/230.0)
	for pair in [["sheep_clingy","sheep_clingy_attend_v2",Vector2(576,1178),1083.0,1.0],["sheep_dull","sheep_dull_glance_v3",Vector2(732.5,1124),916.0,-1.0]]:
		var base_scale: float = .36 if pair[0] == "sheep_clingy" else .34
		var factor: float=base_scale*(70.0/float(pair[3])/.36)*depth
		sheep.scale=Vector2.ONE*factor
		sheep.position=Vector2(600,480)-pair[2]*factor
		player.scale=Vector2(-float(pair[4]),1)*.25*depth
		player.position=Vector2(600+110*float(pair[4]),480)-Vector2(192,420)*player.scale
		for file in [pair[0],pair[1],pair[0]]:
			sheep.position=Vector2(600,480)-(Vector2(732.5,1124) if file == "sheep_dull_glance_v3" else pair[2])*factor
			sheep.texture=load("res://"+file+".png")
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			assert(get_viewport().get_texture().get_image().save_png("res://scene_"+file+".png")==OK)
	get_tree().quit()
