extends SceneTree

# Native renderer evidence only; tools/ is excluded from every playable export.

func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var capture_path := OS.get_environment("GENERIC2D_CAPTURE_PATH")
	if capture_path.is_empty():
		push_error("GENERIC2D_CAPTURE_PATH must name an output PNG")
		quit(1)
		return
	var main: Variant = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var i18n: Variant = root.get_node("I18n")
	i18n.set_locale("zh-CN")
	if OS.get_environment("GENERIC2D_CAPTURE_PAUSE") == "1":
		main._start_holiday()
		await process_frame
		main._toggle_pause()
	elif OS.get_environment("GENERIC2D_CAPTURE_GAME") == "1":
		main._start_holiday()
	elif OS.get_environment("GENERIC2D_CAPTURE_CONFIRM") == "1":
		main._start_holiday()
		await process_frame
		main._toggle_pause()
		main._request_destructive_action("restart")
	for _frame: int in 8:
		await process_frame
	await create_timer(0.25).timeout
	var image := root.get_texture().get_image()
	var error := image.save_png(capture_path)
	print("[capture] %s (%s)" % [capture_path, error_string(error)])
	root.get_node("AudioDirector").call("release_streams")
	await process_frame
	quit(0 if error == OK else 1)
