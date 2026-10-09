extends SceneTree
## #594 (CURSOR-CLOUD): a find dragged from the big basket onto a lit yard spot is placed there
## straight away through YardDecorController, with no separate decor panel in between. While
## the save is pending the basket says so and no second drag starts; a failed save falls back
## to the decor panel at that spot, whose "check again" finishes it; nothing is spent on failure.
## The decor controller runs on the in-memory store so a failure can be forced.
const Controller := preload("res://scripts/inventory/yard_decor_controller.gd")
const MemoryStore := preload("res://test/fixtures/exploration_memory_store.gd")
var checks := 0
var failures: Array[String] = []
var main

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func frames(n: int = 3) -> void:
	for frame in n: await process_frame

func drop(panel, spot: String) -> void:
	var start: Vector2 = panel.grid.cells["pine_cone"].get_global_rect().get_center()
	check(panel.begin_drag("pine_cone", start), "cone drag starts for %s" % spot)
	panel.drag_to(panel.spot_screen_position(spot))
	check(panel.end_drag(panel.spot_screen_position(spot)) == spot, "cone dropped on %s" % spot)

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		push_error("Basket drop placing requires an isolated player profile")
		quit(2)
		return
	var store = root.get_node("SaveStore")
	root.size = Vector2i(1280, 720)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	await main._start_holiday()
	var cone: String = ExplorationRoutes.FIND_PINE_CONE
	store.request_exploration_trip(null, 1, PackedStringArray([cone, cone]), {})
	check(await store.flush_pending(), "two cones in the basket")
	var memory := MemoryStore.new()
	memory._data.keepsakes = {cone: 2}
	main._decor.changed.disconnect(main._on_decor_changed)
	var decor := Controller.new(memory)
	decor.changed.connect(main._on_decor_changed)
	main._decor = decor
	main._on_decor_changed()
	main._show_basket()
	await frames()
	var panel = main._basket_panel

	# Failed save: nothing placed or spent, the decor panel opens at that spot with "check again".
	memory.fail_kind_once = "decor"
	drop(panel, "fence_edge")
	await frames()
	check(decor.busy() and decor.state == "saving", "drop submits the placement")
	check(panel.visible and not main._decor_panel.visible, "basket stays open while saving")
	check(panel.status.visible and panel.status.text == "正在把松果摆到篱边……", "basket says it is being set down: " + panel.status.text)
	check(not panel.can_drag("pine_cone") and not panel.begin_drag("pine_cone", Vector2(10, 10)), "no second drag while the save is pending")
	memory.pump()
	await frames()
	check(decor.state == "failed" and decor.view().places.is_empty(), "failed save places nothing")
	check(memory.get_available_keepsakes().get(cone, 0) == 2, "failed save spends nothing")
	check(main._decor_panel.visible and not panel.visible, "failure falls back to the decor panel")
	check(main._decor_panel.selected == "fence_edge" and main._decor_panel.retry_button.visible, "decor panel at the dropped spot offers check again: %s retry=%s state=%s" % [main._decor_panel.selected, main._decor_panel.retry_button.visible, main._decor_panel.state])
	main._decor_panel.retry_button.pressed.emit()
	memory.pump()
	await frames()
	check(decor.state == "idle" and decor.view().places.get("fence_edge", {}).get("find_id", "") == cone, "check again finishes the placement")
	check(memory.get_available_keepsakes().get(cone, 0) == 1, "exactly one cone reserved")
	main._hide_decor()
	await frames()

	# Success in English: placed at once, basket open, note says where and how to take it back.
	root.get_node("I18n").set_locale("en")
	await frames()
	check(panel.visible and Array(panel.legal_spots()) == ["house_edge", "pond_path"], "the filled fence spot no longer lights up")
	drop(panel, "pond_path")
	memory.pump()
	await frames()
	check(decor.view().places.get("pond_path", {}).get("find_id", "") == cone, "drop places the cone on the path")
	check(panel.visible and not main._decor_panel.visible, "success keeps the basket open")
	check(panel.status.visible and panel.status.text == "The pine cone is on the pond path now. Tap it in the yard to put it back.", "English note: " + panel.status.text)
	main._on_inventory_changed()
	await frames()
	check(panel.status.text.begins_with("The pine cone is on the pond path"), "the note survives a basket refresh")
	main._hide_basket()
	await frames()
	main._show_basket()
	await frames()
	check(panel.place_note.is_empty() and panel.status.text != "The pine cone is on the pond path now. Tap it in the yard to put it back.", "closing the basket clears the note")
	root.get_node("I18n").set_locale("zh-CN")
	main._hide_basket()
	root.get_node("AudioDirector").release_streams()
	decor.changed.disconnect(main._on_decor_changed)
	main.queue_free()
	await frames()
	memory.free()
	if failures.is_empty():
		print("YARD_BASKET_DROP_PLACE checks=%d failures=0" % checks)
	else:
		for f: String in failures: print("FAIL ", f)
		print("YARD_BASKET_DROP_PLACE checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
