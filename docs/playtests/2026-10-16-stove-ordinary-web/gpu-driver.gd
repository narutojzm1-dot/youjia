extends "res://test/stove_director_suite.gd"
func shot(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var folder := OS.get_environment("YOUJIA_STOVE_CAPTURE")
	if root.get_texture().get_image().save_jpg(folder+"/"+name+".jpg",0.9) != OK: quit(4)
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated.trim_suffix("/")+"/"):
		quit(2)
		return
	root.size = Vector2i(1280,720)
	store = root.get_node("SaveStore")
	await reset(2,6)
	world._day_elapsed = 160.0
	for stage in 3:
		if not begin(16.0): quit(3); return
		reach("walking")
		await shot("carry-"+str(stage))
		reach("working")
		for frame in 481:
			world.tick(1.0/30,Vector2.ZERO)
			if frame == 120 or frame == 360: await shot("work-"+str(stage)+"-"+str(frame))
		if not await store.flush_pending(): quit(5); return
		await shot("sun-stage-"+str(stage+1))
		world.stove_view.sync_environment(1.0,Color.WHITE,Color(0.96,0.94,0.98))
		await shot("overcast-projection-"+str(stage+1))
		world.stove_view.sync_environment(0.0,Color.WHITE,Color.WHITE)
	print("STOVE_GPU stages=3 captures=15 failures=0")
	quit(0)
