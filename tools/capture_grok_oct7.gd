extends SceneTree
# Controlled GPU render evidence for the combined UI; not ordinary input or
# production-save acceptance. Always use an isolated profile.
var folder := ""
func _initialize() -> void: call_deferred("capture")
func shot(name: String) -> void:
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(folder.path_join(name + ".png")) == OK)
	print("GROK_OCT7_CAPTURE ", name)
func capture() -> void:
	folder = OS.get_environment("YOUJIA_CAPTURE_DIR")
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if folder.is_empty() or isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(280,653)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for frame in 4: await process_frame
	await main._start_holiday()
	root.get_node("I18n").set_locale("en")
	main._show_basket()
	await shot("basket-en-280")
	root.size = Vector2i(568,320)
	await shot("basket-en-568")
	main._basket_panel.scroll.scroll_vertical = 999
	await shot("basket-en-568-bottom")
	root.size = Vector2i(390,844)
	await shot("basket-rotated-390")
	main._hide_basket()
	root.size = Vector2i(280,653)
	main._toggle_pause()
	main._request_destructive_action("title")
	await shot("confirm-en-280")
	main._cancel_destructive_action()
	main._toggle_pause()
	root.get_node("I18n").set_locale("zh-CN")
	root.size = Vector2i(390,844)
	main.get_node("InputHintMode").set_touch(true)
	await shot("touch-hint-390")
	main.get_node("InputHintMode").set_touch(false)
	root.get_node("AudioDirector").release_streams()
	print("GROK_OCT7_CAPTURE_DONE")
	quit(0)
