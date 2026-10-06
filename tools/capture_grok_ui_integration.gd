extends SceneTree
# Controlled integration renders. Runner must supply an isolated user profile.
var folder := ""
func _initialize() -> void:
	call_deferred("capture")

func shot(name: String) -> void:
	for frame in 8: await process_frame
	await create_timer(0.1).timeout
	var result := root.get_texture().get_image().save_png(folder.path_join(name + ".png"))
	assert(result == OK)
	print("[grok-ui-capture] ", name, " ", root.get_visible_rect().size)

func capture() -> void:
	folder = OS.get_environment("YOUJIA_CAPTURE_DIR")
	if folder.is_empty():
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(folder)
	seed(72)
	root.size = Vector2i(390, 844)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await shot("title-390")
	main._start_holiday()
	await shot("yard-hint-390")
	main._show_save_pending()
	await shot("save-pending-390")
	main._save_status_panel.hide()
	main._toggle_pause()
	root.size = Vector2i(844, 390)
	await shot("pause-844")
	main._toggle_pause()
	root.size = Vector2i(1280, 720)
	root.get_node("I18n").set_locale("en")
	var snapshot: Dictionary = load("res://scripts/ui/photo_moment.gd").capture(main._world, ExpressionCatalog.find_rule("duck_pond_chorus"))
	snapshot["caption_variant"] = 1
	var arrival = main._photo_arrival
	assert(arrival.play(snapshot, true))
	await shot("photo-caption-en")
	arrival.dismiss()
	root.get_node("AudioDirector").release_streams()
	quit(0)
