extends SceneTree
var checks := 0
var failures: Array[String] = []
var main
var store
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func settle() -> void:
	check(await store.flush_pending(), "production save confirmed")
	for frame in 3: await process_frame
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		push_error("Decor integration requires isolated data")
		quit(2)
		return
	store = root.get_node("SaveStore")
	root.size = Vector2i(390, 844)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for frame in 3: await process_frame
	await main._start_holiday()
	var id: String = ExplorationRoutes.FIND_PINE_CONE
	store.request_exploration_trip(null, 1, PackedStringArray([id]), {})
	await settle()
	var occluder = main._world.actor_named("cow")
	var occluder_position: Vector2 = occluder.position
	var occluder_z: int = occluder.z_index
	var original_tint := Color(0.8, 0.9, 1.0, 0.7)
	occluder.modulate = original_tint
	occluder.position = Vector2(290, 615)
	occluder.z_index = 615
	var bystander = main._world.actor_named("horse")
	var bystander_tint: Color = bystander.modulate
	main._show_basket()
	main._basket_panel.decor_button.pressed.emit()
	check(main._decor_panel.visible and paused and not main._world.input_enabled, "editor pauses world")
	main._decor_panel.choose_find(id)
	check(main._world.decor_view.preview != null, "preview rendered in actual world")
	check(occluder.modulate.a < 0.1, "animal covering preview becomes translucent")
	check(bystander.modulate == bystander_tint, "unrelated animal keeps its appearance")
	main._decor_panel.choose_find(id)
	check(is_equal_approx(occluder.modulate.a, original_tint.a * 0.12), "repeated preview does not accumulate fading")
	main._decor_panel.choose_spot("pond_path")
	check(occluder.modulate == original_tint, "switching away restores original tint and alpha")
	main._decor_panel.choose_spot("house_edge")
	main._decor_panel.choose_find(id)
	check(store.get_yard_decor().places.is_empty(), "preview does not write")
	main._hide_decor()
	check(occluder.modulate == original_tint, "cancel restores occluding animal")
	check(main._world.decor_view.preview == null and store.get_available_keepsakes()[id] == 1, "cancel discards only preview")
	main._show_decor()
	main._decor_panel.choose_find(id)
	for frame in 3: await process_frame
	var tap := InputEventScreenTouch.new()
	tap.position = main._decor_panel.nudge_buttons[1].get_global_rect().get_center()
	tap.pressed = true
	main._input(tap)
	tap = tap.duplicate()
	tap.pressed = false
	main._input(tap)
	check(main._decor_panel.draft.dx == 1, "production touch release adjusts exactly one step")
	main._decor_panel.commit()
	check(main._decor.busy(), "confirm waits for durable commit")
	await settle()
	check(main._world.decor_view.visuals.size() == 1, "confirmed item enters actual yard")
	check(occluder.modulate.a < 0.1, "confirmed selected object remains visible through animal")
	check(store.get_available_keepsakes()[id] == 0, "placed object unavailable from basket")
	main._hide_decor()
	check(occluder.modulate == original_tint, "leaving editor restores normal animal composition")
	check(occluder.position == Vector2(290, 615), "editing never relocates an animal")
	occluder.position = occluder_position
	occluder.z_index = occluder_z
	occluder.modulate = Color.WHITE
	main._hide_basket()
	var moment := PhotoMoment.capture(main._world, {"id": "sheep_pair_near"})
	var keepsakes: Array = moment.items.filter(func(item: Dictionary) -> bool: return item.get("kind") == "prop" and item.get("subject") == "keepsake")
	check(keepsakes.size() == 1, "photo records exactly one confirmed prop")
	check(keepsakes[0].state.find_id == id, "photo retains keepsake identity")
	store._load()
	main._on_decor_changed()
	check(main._world.decor_view.visuals.size() == 1, "actual saved placement reconstructs")
	main._show_basket()
	main._show_decor()
	main._decor_panel.choose_spot("house_edge")
	main._decor_panel.nudge(Vector2i.UP)
	main._decor_panel.commit()
	await settle()
	check(store.get_yard_decor().places.house_edge.dy == -1, "adjustment confirmed")
	for viewport: Vector2i in [Vector2i(390,844), Vector2i(568,320), Vector2i(1280,720), Vector2i(320,568)]:
		root.size = viewport
		for frame in 5: await process_frame
		check(Rect2(Vector2.ZERO,Vector2(viewport)).encloses(main._decor_panel.paper.get_global_rect()), "editor paper fits " + str(viewport))
		check(main._decor_panel.preview_rect().size.x > 100 and main._decor_panel.preview_rect().size.y > 100, "real scene preview has room")
		var capture_dir := OS.get_environment("YOUJIA_DECOR_CAPTURE")
		if not capture_dir.is_empty():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(capture_dir.path_join("decor-%dx%d.png" % [viewport.x, viewport.y]))
	main._decor_panel.remove_button.pressed.emit()
	await settle()
	check(main._world.decor_view.visuals.is_empty(), "remove clears scene after confirmation")
	check(store.get_available_keepsakes()[id] == 1, "remove restores one available object")
	check(moment.items.filter(func(item: Dictionary) -> bool: return item.get("subject") == "keepsake").size() == 1, "old photo remains independent of removal")
	root.get_node("I18n").set_locale("en")
	for status: String in ["idle", "saving", "failed", "unknown"]:
		main._decor_panel.update_view(store.get_yard_decor(), store.get_available_keepsakes(), status, status != "idle")
		for viewport: Vector2i in [Vector2i(320,568), Vector2i(568,320)]:
			root.size = viewport
			for frame in 5: await process_frame
			check(Rect2(Vector2.ZERO,Vector2(viewport)).encloses(main._decor_panel.paper.get_global_rect()), "English status fits " + status + str(viewport))
			check(main._decor_panel.paper.get_global_rect().encloses(main._decor_panel.close_button.get_global_rect()), "escape remains reachable " + status)
	main._on_decor_changed()
	main._hide_decor()
	main._hide_basket()
	await settle()
	main.queue_free()
	for frame in 3: await process_frame
	print("YARD_DECOR_INTEGRATION checks=%d failures=%d" % [checks,failures.size()])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
