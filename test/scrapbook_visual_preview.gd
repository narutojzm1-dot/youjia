extends SceneTree

# xvfb-run godot --path . --resolution 1280x720 --script res://test/scrapbook_visual_preview.gd -- --output /tmp/journal-preview
# Draws actual captured sprites in the real main scene; stores evidence only in /tmp.

func _initialize() -> void:
	call_deferred("_run")


func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	await process_frame
	var image: Image = root.get_texture().get_image()
	var result := image.save_png(path)
	print("[scrapbook-preview] ", path, " ", image.get_size(), " result=", result)


func _run() -> void:
	seed(1002)
	var args := OS.get_cmdline_user_args()
	var prefix := args[args.find("--output") + 1] if "--output" in args else "/tmp/youjia-scrapbook"
	root.size = Vector2i(1280, 720)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.set_process(false)
	main._start_holiday()
	var world = main._world
	world.holiday_day = 3
	world._weather_timer = 10000.0
	world.debug_place_actor("goose", Vector2(766, 508))
	world.debug_place_actor("duck_a", Vector2(768, 536))
	world.debug_place_player(Vector2(746, 522))
	var goose = world.actor_named("goose")
	goose.state = "rest"
	goose._idle_time = 8.0
	goose._velocity = Vector2.ZERO
	goose._gait.weight = 0.0
	world.tick(1.0 / 60.0, Vector2.ZERO)
	world._evaluate_expressions()
	world.debug_place_player(Vector2(330, 503))
	world.debug_place_actor("sheep_a", Vector2(306, 508))
	world.debug_place_actor("sheep_b", Vector2(357, 506))
	world.tick(1.0 / 60.0, Vector2.ZERO)
	world._evaluate_expressions()
	goose.state = "graze"
	goose._idle_time = 10.0
	goose._velocity = Vector2.ZERO
	goose._gait.weight = 0.0
	world.debug_place_player(Vector2(746, 522))
	world.tick(1.0 / 60.0, Vector2.ZERO)
	world._evaluate_expressions()
	main._show_album()
	main._layout()
	main._process(1.0 / 60.0)
	await process_frame
	await process_frame
	await _capture(prefix + "-desktop.png")
	main._flip_album(1)
	await process_frame
	await _capture(prefix + "-desktop-next.png")
	main._flip_album(1)
	await process_frame
	await _capture(prefix + "-desktop-last.png")
	root.size = Vector2i(390, 844)
	main._layout()
	main._flip_album(1)
	main._process(1.0 / 60.0)
	await process_frame
	await process_frame
	await _capture(prefix + "-portrait.png")
	root.get_node("I18n").call("set_locale", "en")
	await process_frame
	await _capture(prefix + "-portrait-en.png")
	root.get_node("AudioDirector").call("release_streams")
	quit()
