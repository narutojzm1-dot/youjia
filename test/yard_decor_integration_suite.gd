extends SceneTree
## Yard decor in the real game after #594: there is no separate decor panel. From the big
## basket a find is placed on a free fixed spot (here through its paper's spot button; the
## drag is covered by yard_basket_drag_suite), the placement is durable, shows in the yard and
## in photos, survives a reload, and tapping it in the yard puts it back in the basket.
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
	var no_panel := true
	for child: Node in main._ui_layer.get_children():
		var script: Script = child.get_script()
		if script != null and script.resource_path.ends_with("yard_decor_panel.gd"): no_panel = false
	check(no_panel and not ResourceLoader.exists("res://scripts/ui/yard_decor_panel.gd"), "no separate decor panel exists")
	main._show_basket()
	var panel = main._basket_panel
	var grid = panel.grid
	check(panel.visible and paused and not main._world.input_enabled, "basket pauses the world")
	for frame in 3: await process_frame
	panel.scroll.ensure_control_visible(grid.cells["pine_cone"])
	grid.open_menu("pine_cone")
	for frame in 3: await process_frame
	check(grid.spot_row.is_visible_in_tree() and grid.spot_buttons["house_edge"].visible, "find paper offers the house spot")
	grid.spot_buttons["house_edge"].pressed.emit()
	check(main._decor.busy(), "placing waits for durable commit")
	check(store.get_yard_decor().places.is_empty(), "nothing is shown as placed before the save confirms")
	await settle()
	check(store.get_yard_decor().places.get("house_edge", {}).get("find_id", "") == id, "confirmed placement saved at the house")
	var entry: Dictionary = store.get_yard_decor().places.house_edge
	check(int(entry.dx) == 0 and int(entry.dy) == 0, "placed without a nudge")
	check(main._world.decor_view.visuals.size() == 1, "confirmed item enters actual yard")
	check(store.get_available_keepsakes()[id] == 0, "placed object unavailable from basket")
	check(panel.visible and grid.cells["pine_cone"].disabled, "basket stays open and the cone cell is empty")
	main._hide_basket()
	var moment := PhotoMoment.capture(main._world, {"id": "sheep_pair_near"})
	var keepsakes: Array = moment.items.filter(func(item: Dictionary) -> bool: return item.get("kind") == "prop" and item.get("subject") == "keepsake")
	check(keepsakes.size() == 1, "photo records exactly one confirmed prop")
	check(keepsakes[0].state.find_id == id, "photo retains keepsake identity")
	store._load()
	main._on_decor_changed()
	check(main._world.decor_view.visuals.size() == 1, "actual saved placement reconstructs")
	# Move the find to pond_path so the portrait basket paper does not cover it
	# (house_edge sits under the paper on 390×844; fence/pond stay in the right margin).
	main._on_decor_recall("house_edge")
	await settle()
	check(main._decor.request("place", "pond_path", {"find_id": id, "dx": 0, "dy": 0}), "re-place on pond path for uncovered tap")
	await settle()
	# #598 / #594: while the basket is still open (place note says tap the yard find),
	# a press outside the paper on the placed prop must recall — not only a closed-yard walk-up.
	main._show_basket()
	for frame in 3: await process_frame
	check(main._basket_panel.visible and not main._world.input_enabled, "basket open again before recall tap")
	var placed_at: Vector2 = main._world.decor_view.placed("pond_path").point
	var screen_at: Vector2 = main._world.decor_view.get_global_transform_with_canvas() * placed_at
	check(not main._basket_panel.panel.get_global_rect().has_point(screen_at), "pond path find is outside the basket paper")
	var press := InputEventMouseButton.new()
	press.pressed = true
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = screen_at
	panel.show_place_note(id, "pond_path", "placed")
	check(main._basket_ground_recall(press), "basket-open ground recall accepts the yard tap")
	check(main._decor.busy(), "putting it back waits for durable commit")
	await settle()
	check(main._world.decor_view.visuals.is_empty(), "recall clears scene after confirmation")
	check(store.get_available_keepsakes()[id] == 1, "recall restores one available object")
	check(panel.place_note.is_empty() and not panel.status.text.contains("摆在"), "recalled find does not retain the old placement instruction")
	main._hide_basket()
	check(moment.items.filter(func(item: Dictionary) -> bool: return item.get("subject") == "keepsake").size() == 1, "old photo remains independent of removal")
	# The basket's status line with every placement note stays on screen in English.
	root.get_node("I18n").set_locale("en")
	main._show_basket()
	for stage: String in ["saving", "placed", "failed", "blocked"]:
		for viewport: Vector2i in [Vector2i(320,568), Vector2i(568,320), Vector2i(390,844)]:
			root.size = viewport
			for frame in 5: await process_frame
			panel.show_place_note(id, "pond_path", stage)
			for frame in 3: await process_frame
			var view := Rect2(Vector2.ZERO, Vector2(viewport))
			check(view.encloses(panel.panel.get_global_rect()), "English %s note keeps the basket on screen %s" % [stage, viewport])
			check(view.encloses(panel.status.get_global_rect()) and view.encloses(panel.close_button.get_global_rect()), "English %s note and the close button stay reachable %s" % [stage, viewport])
	main._hide_basket()
	root.get_node("I18n").set_locale("zh-CN")
	await settle()
	root.get_node("AudioDirector").release_streams()
	main.queue_free()
	for frame in 3: await process_frame
	print("YARD_DECOR_INTEGRATION checks=%d failures=%d" % [checks,failures.size()])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
