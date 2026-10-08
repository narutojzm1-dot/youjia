extends SceneTree
# Controlled layout evidence, separate from normal-player path evidence.
var folder := ""
func _initialize() -> void: call_deferred("run")
func shot(label: String) -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(folder.path_join(label+".png")) == OK)
	print("LARGE_SHELTER_CAPTURE ",label)
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
	world._day_elapsed = 150.0
	world.set_weather("rain")
	await root.get_node("SaveStore").flush_pending()
	for id in world.shelter.ALL_IDS: world.actor_named(id).position = world.shelter.BEDS[id]
	for i in 180: main._process(1.0/60.0)
	for id in world.shelter.GUESTS:
		var a = world.actor_named(id)
		print("CEL ",id," ",a._posture_id," ",a._sprite.texture.resource_path," ",a.has_meta("shelter_rest")," ",a.state)
	await shot("rain-five-beds")
	world.set_weather("sun")
	world._day_elapsed = 400.0
	for id in world.shelter.GUESTS: world.actor_named(id).position = world.shelter.HOME_REST[id]
	for i in 180: main._process(1.0/60.0)
	await shot("night-home-rest")
	main.queue_free()
	await process_frame
	root.get_node("AudioDirector").release_streams()
	quit(0)
