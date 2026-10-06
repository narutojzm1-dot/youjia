extends SceneTree
const Memory := preload("res://test/fixtures/exploration_memory_store.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var out := OS.get_environment("YOUJIA_CAPTURE_DIR")
	if out.is_empty(): quit(2); return
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(1280, 720)
	var memory := Memory.new()
	root.add_child(memory)
	var host := ExplorationHost.new(memory)
	host.restore()
	host.begin({"day": 2, "elapsed": 20.0}, 7, {"nearby": [], "rope": "llama"})
	memory.pump()
	var scene = load("res://scripts/exploration/near_path_scroll.gd").new()
	root.add_child(scene)
	scene.setup(host, "sunny")
	scene.set_process(false)
	scene.place_at("leaf_pile")
	for i in 60: scene.walk(Vector2.ZERO, 0.1)
	await capture(out + "/standing-1280.jpeg")
	scene.observe()
	memory.pump()
	scene._update_search()
	for i in 100:
		scene.walk(Vector2.ZERO, 0.05)
		scene._update_search()
		memory.pump()
		if scene.companion.search_elapsed > 1.0: break
	scene._refresh()
	await capture(out + "/searching-1280.jpeg")
	for i in 100:
		scene.walk(Vector2.ZERO, 0.05)
		scene._update_search()
		memory.pump()
	scene._refresh()
	await capture(out + "/revealed-1280.jpeg")
	for size: Vector2i in [Vector2i(390, 844), Vector2i(568, 320)]:
		root.size = size
		await process_frame
		scene.walk(Vector2.ZERO, 0.0)
		scene._refresh()
		await capture(out + "/revealed-%d.jpeg" % size.x)
	print("HIDDEN_FIND_CAPTURE complete")
	quit()
func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg(path, 0.9)
