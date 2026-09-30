extends SceneTree
func _initialize() -> void:
	call_deferred("_record")
func _record() -> void:
	var folder:=OS.get_environment("YOUJIA_CAPTURE_DIR")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_node("TuningStore").call("set_value","ui.reduced_motion",true)
	var background:=ColorRect.new()
	background.color=Color("eee9df")
	background.size=Vector2(1280,720)
	root.add_child(background)
	var expressions: Array[String]=["idle","happy","annoyed","smirk"]
	for index: int in 4:
		var config:=CastArt.configure({"id":"llama","species":"llama","position":Vector2(160+index*305,530),"scale":0.36,"textures":{}})
		var actor=load("res://scripts/entities/felt_actor.gd").new()
		root.add_child(actor)
		actor.setup(config)
		actor.set_pose(config.position,float(config.scale)*2.7,1.0)
		actor.set_expression(expressions[index])
		actor.tick(0.0,Vector2(1280,720))
		var label:=Label.new()
		label.text=expressions[index]
		label.position=Vector2(115+index*305,160)
		label.add_theme_color_override("font_color",Color("334953"))
		label.add_theme_font_size_override("font_size",25)
		root.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join("llama-expression-check.png"))
	root.get_node("AudioDirector").call("release_streams")
	quit(0)
