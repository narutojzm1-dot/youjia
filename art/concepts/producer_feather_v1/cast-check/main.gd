extends Node2D
const L = preload("res://scripts/exploration/near_path_layout.gd")
const Resident = preload("res://scripts/entities/sequence_resident.gd")

func _ready() -> void:
	var painting := Sprite2D.new()
	painting.texture = load("res://near_path.png")
	painting.centered = false
	add_child(painting)
	for item in [["pinecone.png",Vector2(1000,688),Vector2(636,954),611.0], ["feather.png",Vector2(880,752),Vector2(684,1086),913.0]]:
		var sprite := Sprite2D.new()
		sprite.texture = load("res://"+item[0])
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.scale = Vector2.ONE*(24.0/float(item[3]))
		sprite.position = item[1]-item[2]*sprite.scale
		add_child(sprite)
	var walker = Resident.new()
	add_child(walker)
	var camera := Camera2D.new()
	add_child(camera)
	camera.make_current()
	for viewport_size in [Vector2i(1280,720),Vector2i(390,844),Vector2i(844,390)]:
		get_window().size = viewport_size
		await get_tree().process_frame
		for distance in [663.0,365.0,195.0,0.0]:
			var point: Vector2 = L.point("lane",distance)
			walker.position = point
			walker.advance(0.0,Vector2.ZERO,L.depth(point.y),-1.0,true)
			var framing: Dictionary = L.frame(point,Vector2(viewport_size))
			camera.zoom = Vector2.ONE*float(framing.zoom)
			camera.position = framing.camera
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var file := "res://cast_%dx%d_d%d.png" % [viewport_size.x,viewport_size.y,int(distance)]
			assert(get_viewport().get_texture().get_image().save_png(file)==OK)
	get_tree().quit()
