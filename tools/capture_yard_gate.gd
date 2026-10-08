extends SceneTree
# Controlled rendering evidence; ordinary browser play is recorded separately.
var folder := ""
func _initialize() -> void: call_deferred("run")
func shot(label: String) -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(folder.path_join(label + ".png")) == OK)
	print("GATE_CAPTURE ",label)
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
	world._day_elapsed = 150.0
	world.debug_place_player(Vector2(914,516))
	main._process(0.0)
	await shot("closed-outside")
	world._interact_with_target("fence_gate")
	await root.get_node("SaveStore").flush_pending()
	main._process(0.0)
	await shot("open-outside")
	world.debug_place_player(Vector2(1000,471))
	main._process(0.0)
	await shot("inside-sunny")
	world.set_weather("overcast")
	world._tick_weather_transition(10.0)
	main._process(0.0)
	await shot("inside-overcast")
	root.size = Vector2i(390,844)
	for i in 90: main._process(1.0/60.0)
	await shot("inside-portrait")
	root.get_node("AudioDirector").release_streams()
	quit(0)
