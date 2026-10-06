extends SceneTree
# Controlled production UI renders; not an ordinary-input playtest.
var folder := ""
func _initialize() -> void:
	call_deferred("capture")

func shot(name: String) -> void:
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(folder.path_join(name + ".png")) == OK)
	print("BASKET_CAPTURE ", name)

func capture() -> void:
	folder = OS.get_environment("YOUJIA_CAPTURE_DIR")
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if folder.is_empty() or isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(390, 844)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for frame in 3: await process_frame
	await main._start_holiday()
	main._world._reel_in_fish()
	await root.get_node("SaveStore").flush_pending()
	main._show_basket()
	await shot("basket-390")
	root.size = Vector2i(568, 320)
	root.get_node("I18n").set_locale("en")
	await shot("basket-en-568")
	main._basket_panel.scroll.scroll_vertical = 999
	await shot("basket-en-568-scrolled")
	main._hide_basket()
	root.size = Vector2i(390, 844)
	root.get_node("I18n").set_locale("zh-CN")
	await shot("yard-hud-390")
	root.size = Vector2i(320, 568)
	root.get_node("I18n").set_locale("en")
	await shot("yard-hud-en-320")
	root.get_node("AudioDirector").release_streams()
	quit(0)
