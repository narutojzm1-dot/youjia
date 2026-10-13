extends "res://test/pond_growth_director_suite.gd"
## GPU evidence only: isolated stock/AP fixture, not ordinary-player acceptance.
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	var output := OS.get_environment("YOUJIA_POSE_FRAMES")
	if isolated.is_empty() or output.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated.trim_suffix("/") + "/"):
		quit(2)
		return
	root.size = Vector2i(1280, 720)
	store = root.get_node("SaveStore")
	await reset()
	if not begin(12.0):
		quit(3)
		return
	approach()
	for i in 361:
		if i % 6 == 0:
			await process_frame
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_jpg(output + "/%03d.jpg" % (i / 6), 0.85) != OK:
				quit(4)
				return
		world.tick(1.0 / 30.0, Vector2.ZERO)
	await store.flush_pending()
	print("POND_WORK_MOTION frames=61 simulated_seconds=12 rate=5fps")
	quit(0)
