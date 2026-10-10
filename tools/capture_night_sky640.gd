extends SceneTree
## Controlled regional clock/weather fixtures. Not ordinary-player elapsed time.
var folder := ""
var main: Node
func _initialize() -> void: call_deferred("run")
func frame() -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
func capture(label: String) -> void:
	await frame()
	assert(root.get_texture().get_image().save_jpg(folder.path_join(label + ".jpg"), 0.88) == OK)
	print("NIGHT_SKY_CAPTURE ", label)
func run() -> void:
	folder = OS.get_environment("YOUJIA_CAPTURE_DIR")
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if folder.is_empty() or isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(1280,720)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	var world = main._world
	world.set_process(false)
	root.get_node("TuningStore").set_value("ui.reduced_motion", true)
	world.weather = "sun"
	world._day_elapsed = 19.0/24.0 * world.DAY_DURATION_SECONDS # 01:00
	main._process(0.0)
	main._update_tod_tint(world.tod_fraction())
	await capture("yard-clear-midnight")
	var with_sky: Image = root.get_texture().get_image()
	main._night_sky_overlay.visible = false
	await frame()
	var without_sky: Image = root.get_texture().get_image()
	var changed := 0
	var outside := 0
	var overlay: Sprite2D = main._night_sky_overlay
	var inverse := overlay.transform.affine_inverse()
	var dimensions := overlay.texture.get_size()
	var bounds: Vector4 = overlay.material.get_shader_parameter("sky_bounds")
	for y in with_sky.get_height():
		for x in with_sky.get_width():
			if with_sky.get_pixel(x,y) == without_sky.get_pixel(x,y): continue
			changed += 1
			var uv := (inverse * Vector2(x+0.5,y+0.5)) / dimensions
			if uv.x < bounds.x or uv.x > bounds.z or uv.y < bounds.y or uv.y > bounds.w: outside += 1
	print("NIGHT_SKY_GPU changed=%d outside_authored_sky=%d" % [changed,outside])
	assert(changed > 100 and outside == 0)
	main._update_tod_tint(world.tod_fraction())
	world.weather = "overcast"
	main._update_tod_tint(world.tod_fraction())
	await capture("yard-cloudy-midnight")
	world.weather = "sun"
	world._day_elapsed = 0.0
	main._process(0.0)
	main._update_tod_tint(world.tod_fraction())
	await capture("yard-dawn")
	world._day_elapsed = 19.0/24.0 * world.DAY_DURATION_SECONDS
	main._on_exploration_requested()
	await root.get_node("SaveStore").flush_pending()
	main._process(0.0)
	main._update_tod_tint(world.tod_fraction())
	await capture("nearby-normal-camera-midnight")
	# Reveal the authored sky for regional-mask inspection, explicitly a camera fixture.
	main._exploration.scroll.set_process(false)
	main._exploration.scroll.set_physics_process(false)
	main._exploration.scroll.camera.position = main._exploration.scroll.layout.SIZE * 0.5
	main._exploration.scroll.camera.zoom = Vector2.ONE * 0.75
	await frame()
	main._update_tod_tint(world.tod_fraction())
	await capture("nearby-sky-camera-fixture")
	main.queue_free()
	await process_frame
	root.get_node("AudioDirector").release_streams()
	quit(0)
