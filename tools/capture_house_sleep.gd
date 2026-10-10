extends SceneTree
# Controlled layout evidence, separate from normal-player path evidence.
var folder := ""
func _initialize() -> void: call_deferred("run")
func shot(label: String) -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(folder.path_join(label+".png")) == OK)
	print("HOUSE_CAPTURE ",label)
func run() -> void:
	folder = OS.get_environment("YOUJIA_CAPTURE_DIR")
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
	if folder.is_empty() or isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated):
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(1280,720)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	var world = main._world
	world.collected.append("goose_horse_mount")
	world._day_elapsed = 400.0
	world.set_weather("sun")
	await root.get_node("SaveStore").flush_pending()
	world.debug_place_player(world.house.APPROACH)
	for i in 180: main._process(1.0/60.0)
	await shot("night-windows")
	world._interact_with_target("house_door")
	for i in 1200:
		main._process(1.0/60.0)
		if world.house.stage == "in": break
	await shot("open-room")
	for i in 1200:
		main._process(1.0/60.0)
		if world.house.stage == "saving": break
	await root.get_node("SaveStore").flush_pending()
	for i in 30: main._process(1.0/60.0)
	await shot("asleep-dark")
	for i in 1800:
		main._process(1.0/60.0)
		if not world.house.busy(): break
	await shot("morning-return")
	main.queue_free()
	await process_frame
	root.get_node("AudioDirector").release_streams()
	quit(0)
