extends SceneTree
var main
func _initialize(): call_deferred("run")
func tap(point):
	for pressed in [true,false]:
		var e:=InputEventScreenTouch.new();e.position=point;e.pressed=pressed;e.index=0;root.push_input(e,true)
func button(key):
	var b:Button=main.get(key)
	tap(b.get_global_transform_with_canvas()*(b.size*0.5))
func shot(path):
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run():
	var folder:=OS.get_environment("YOUJIA_CAPTURE_DIR")
	DirAccess.make_dir_recursive_absolute(folder)
	for dimensions in [Vector2i(390,844),Vector2i(844,390)]:
		root.size=dimensions
		main=load("res://scenes/main.tscn").instantiate();root.add_child(main)
		for i in 4: await process_frame
		var prefix:=folder.path_join(str(dimensions.x)+"x"+str(dimensions.y))
		await shot(prefix+"-title.png")
		button("_play_button")
		for i in 5: await process_frame
		tap(root.get_canvas_transform()*Vector2(340,600))
		for i in 20: await process_frame
		await shot(prefix+"-yard.png")
		button("_album_chip")
		for i in 4: await process_frame
		await shot(prefix+"-album.png")
		button("_album_back_button")
		await process_frame
		button("_pause_button")
		for i in 4: await process_frame
		await shot(prefix+"-pause.png")
		button("_resume_button")
		main.queue_free();await process_frame
	root.get_node("AudioDirector").call("release_streams")
	quit()
