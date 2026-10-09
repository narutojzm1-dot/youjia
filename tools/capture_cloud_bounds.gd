extends SceneTree
# Deterministic actual-renderer evidence, with an isolated user profile supplied
# by the runner. This fixture does not claim ordinary player-path coverage.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var folder := OS.get_environment("YOUJIA_CAPTURE_DIR")
	if folder.is_empty():
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(folder)
	seed(72)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await main._start_holiday()
	await process_frame
	main.set_process(false)
	var world = main._world
	root.get_node("TuningStore").set_value("ui.reduced_motion", true, false)
	world.set_weather("overcast")
	world._cloud_scroll = 320.0
	world._layout_cloud_bands()
	for frame in 8: await process_frame
	await create_timer(0.1).timeout
	var error := root.get_texture().get_image().save_png(folder.path_join("overcast-bounds.png"))
	print("[cloud-bounds-capture] ", root.get_visible_rect().size, " ", error_string(error))
	root.get_node("AudioDirector").release_streams()
	quit(0 if error == OK else 1)
