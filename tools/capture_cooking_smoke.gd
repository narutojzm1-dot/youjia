extends SceneTree
## GROK #705：隔离演示的原生画面。开始做饭约 3 秒截一张，约 3.5 秒停火再截一张。
## 不进入 Main，不制造做饭事件。YOUJIA_CAPTURE_DIR / W / H / NIGHT / RECORD。

var _failed := false


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var folder := OS.get_environment("YOUJIA_CAPTURE_DIR")
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if folder.is_empty() or isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		push_error("capture needs YOUJIA_CAPTURE_DIR and isolated user data")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(folder)
	var width := int(OS.get_environment("YOUJIA_CAPTURE_W"))
	var height := int(OS.get_environment("YOUJIA_CAPTURE_H"))
	if width <= 0:
		width = 1280
	if height <= 0:
		height = 720
	var night := OS.get_environment("YOUJIA_CAPTURE_NIGHT") == "1"
	var record := OS.get_environment("YOUJIA_CAPTURE_RECORD") == "1"
	var fps := int(OS.get_environment("YOUJIA_CAPTURE_FPS"))
	if fps <= 0:
		fps = 20
	var tag := OS.get_environment("YOUJIA_CAPTURE_TAG")
	if tag.is_empty():
		tag = "%s-%d" % ["night" if night else "day", width]
	DisplayServer.window_set_size(Vector2i(width, height))
	root.size = Vector2i(width, height)
	var store := root.get_node_or_null("/root/TuningStore")
	if store != null and store.has_method("set_value"):
		store.set_value("ui.reduced_motion", false, false)
	var demo: Node2D = load("res://scenes/presentation/cooking_smoke_demo.tscn").instantiate()
	root.add_child(demo)
	for _i in 4:
		await process_frame
		await RenderingServer.frame_post_draw
	demo.use_capture_layout()
	demo.set_demo_night(night)
	demo.apply_frame()
	await process_frame
	await RenderingServer.frame_post_draw
	var smoke: Node2D = demo.get_node("CookingSmoke")
	_save(folder.path_join("%s-idle.png" % tag))
	smoke.set_cooking(true)
	var cook_frame := int(round(3.0 * float(fps)))
	var stop_frame := int(round(3.5 * float(fps)))
	var fade_frame := int(round(4.5 * float(fps)))
	var end_frame := int(round(5.0 * float(fps)))
	var frame_dir := folder.path_join("%s-frames" % tag)
	if record:
		DirAccess.make_dir_recursive_absolute(frame_dir)
	var stopped := false
	for i in range(end_frame + 1):
		await process_frame
		await RenderingServer.frame_post_draw
		if record and i % 2 == 0:
			var frame: Image = root.get_texture().get_image()
			if frame.save_png(frame_dir.path_join("f%03d.png" % int(i / 2))) != OK:
				_failed = true
		if i == cook_frame:
			_save(folder.path_join("%s-cooking-3s.png" % tag))
		if i == stop_frame and not stopped:
			smoke.set_cooking(false)
			stopped = true
			# 停发后这一帧粒子还在，下一帧才开始按寿命淡出。
			await process_frame
			await RenderingServer.frame_post_draw
			_save(folder.path_join("%s-stopped-3.5s.png" % tag))
		if i == fade_frame:
			_save(folder.path_join("%s-fading-4.5s.png" % tag))
	print("COOKING_SMOKE_CAPTURE tag=%s cooking=%s emitting=%s anchor=%s" % [
		tag, smoke.is_cooking(), smoke.is_emitting(), smoke.position
	])
	demo.queue_free()
	await process_frame
	var audio := root.get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("release_streams"):
		audio.release_streams()
	quit(1 if _failed else 0)


func _save(path: String) -> void:
	var image := root.get_texture().get_image()
	if image == null or image.save_png(path) != OK:
		push_error("failed to save " + path)
		_failed = true
		return
	print("COOKING_SMOKE_CAPTURE %s %dx%d" % [path, image.get_width(), image.get_height()])
