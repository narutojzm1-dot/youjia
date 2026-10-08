extends SceneTree
var folder := ""
func _initialize() -> void: call_deferred("run")
func shot(label: String) -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(folder.path_join(label+".png")) == OK)
	print("RAIN_CAPTURE ",label)
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
	world.set_weather("rain")
	await root.get_node("SaveStore").flush_pending()
	for i in 240: main._process(1.0/60.0)
	await shot("yard-rain-a")
	for i in 30: main._process(1.0/60.0)
	await shot("yard-rain-b")
	main._pause_screen.show()
	var clock: float = world.rain.clock
	main._process(5.0)
	assert(world.rain.clock == clock)
	main._pause_screen.hide()
	root.get_node("TuningStore").set_value("ui.reduced_motion",true)
	await shot("yard-reduced")
	root.get_node("TuningStore").set_value("ui.reduced_motion",false)
	var photo := PhotoMoment.new()
	photo.size = Vector2(420,420)
	photo.position = Vector2(430,120)
	main._ui_layer.add_child(photo)
	photo.setup(PhotoMoment.capture(world,ExpressionCatalog.find_rule("cow_pet_gentle")))
	await shot("rain-photo")
	photo.queue_free()
	main._on_exploration_requested()
	await root.get_node("SaveStore").flush_pending()
	main._process(0.5)
	await shot("near-path-rain")
	main.queue_free()
	await process_frame
	root.get_node("AudioDirector").release_streams()
	quit(0)
