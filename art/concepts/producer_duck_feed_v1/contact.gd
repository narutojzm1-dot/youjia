extends Node2D
func _ready() -> void:
	var paper := ColorRect.new()
	paper.size = Vector2(1280,720)
	paper.color = Color("ebe9e2")
	add_child(paper)
	for face in [1.0,-1.0]:
		var origin := Vector2(330 if face>0 else 950,610)
		for spec in [["idle.png",Vector2(670,1205),0.25],["feed.png",Vector2(590,1177),0.85]]:
			var sprite := Sprite2D.new()
			sprite.texture=load("res://"+spec[0])
			sprite.centered=false
			sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
			sprite.scale=Vector2(face,1)*0.35
			sprite.position=origin-spec[1]*sprite.scale
			sprite.modulate.a=spec[2]
			add_child(sprite)
		var mark := Line2D.new()
		mark.default_color=Color("a33c38")
		mark.width=1.5
		mark.points=PackedVector2Array([origin+Vector2(-170,0),origin+Vector2(170,0)])
		add_child(mark)
		var mouth := origin+(Vector2(1110,807)-Vector2(590,1177))*Vector2(face,1)*0.35
		var cross := Line2D.new()
		cross.width=2
		cross.default_color=Color("186b8d")
		cross.points=PackedVector2Array([mouth-Vector2(6,0),mouth+Vector2(6,0),mouth,mouth-Vector2(0,6),mouth+Vector2(0,6)])
		add_child(cross)
	var label := Label.new()
	label.text="CONTACT STUDY - idle ghost + feed / mirrored / ground red, mouth candidate blue"
	label.position=Vector2(30,30)
	label.add_theme_color_override("font_color",Color("252525"))
	add_child(label)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png("res://contact.png")==OK)
	get_tree().quit()
