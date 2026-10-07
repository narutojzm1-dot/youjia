extends SceneTree
# Controlled render fixture; never ordinary-player or durable-save evidence.
const MemoryStore := preload("res://test/fixtures/exploration_memory_store.gd")
const Layout := preload("res://scripts/exploration/near_path_layout.gd")
var folder := ""
func _initialize() -> void: call_deferred("capture")
func shot(name: String) -> void:
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(folder.path_join(name + ".png")) == OK)
	print("STONE_CAPTURE ", name)
func capture() -> void:
	folder = OS.get_environment("YOUJIA_CAPTURE_DIR")
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if folder.is_empty() or isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(folder)
	var seed_value := -1
	var stop_id := ""
	for candidate in 100:
		for stop: String in ExplorationRoutes.NEAR_PATH_STOPS:
			var probe := MemoryStore.new()
			var host := ExplorationHost.new(probe)
			host.restore()
			host.begin({"day": 3, "elapsed": 12.5}, candidate)
			host.visit(stop)
			var matches: bool = host.view().get("offer", "") == ExplorationRoutes.FIND_STONE
			probe.free()
			if matches:
				seed_value = candidate
				stop_id = stop
				break
		if seed_value >= 0: break
	assert(seed_value >= 0)
	for viewport: Vector2i in [Vector2i(1280,720), Vector2i(390,844)]:
		root.size = viewport
		var memory := MemoryStore.new()
		var host := ExplorationHost.new(memory)
		host.restore()
		host.begin({"day": 3, "elapsed": 12.5}, seed_value)
		var scroll = load("res://scripts/exploration/near_path_scroll.gd").new()
		root.add_child(scroll)
		scroll.setup(host, "sunny")
		var entry := Layout.stop(stop_id)
		scroll.spot = {"arm": entry.arm, "d": entry.d}
		scroll._snap_camera()
		assert(scroll.observe(stop_id))
		await shot("stone-ground-%d" % viewport.x)
		assert(scroll.pick())
		await create_timer(0.5).timeout
		await shot("stone-reveal-%d" % viewport.x)
		await create_timer(3.0).timeout
		await shot("stone-basket-%d" % viewport.x)
		scroll.release()
		scroll.queue_free()
		await process_frame
		memory.free()
	root.get_node("AudioDirector").release_streams()
	print("STONE_CAPTURE_DONE")
	quit(0)
