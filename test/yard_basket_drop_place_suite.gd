extends SceneTree
## #594 (CURSOR-CLOUD): a find dragged from the big basket onto a lit yard spot is placed there
## straight away through YardDecorController, with no separate decor panel in between. While
## the save is pending the basket says so and no second drag starts; a failed save keeps the
## basket open with "check again", which finishes it; nothing is spent on failure. A find's
## paper lists the free spots as buttons, the keyboard / tap way to place it.
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

	# Failed save: nothing placed or spent, the basket stays open with "check again" (#594: there is
	# no separate decor panel to fall back to); checking again finishes this same placement.
	check(main._ui_layer.get_children().filter(func(c: Node) -> bool: return c.get_script() != null and str(c.get_script().resource_path).ends_with("yard_decor_panel.gd")).is_empty(), "no separate decor panel in the game")
	memory.fail_kind_once = "decor"
	drop(panel, "fence_edge")
	await frames()
	check(decor.busy() and decor.state == "saving", "drop submits the placement")
	check(panel.visible, "basket stays open while saving")
	check(panel.status.visible and panel.status.text == "正在把松果摆到篱边……", "basket says it is being set down: " + panel.status.text)
	check(not panel.can_drag("pine_cone") and not panel.begin_drag("pine_cone", Vector2(10, 10)), "no second drag while the save is pending")
	memory.pump()
	await frames()
	check(decor.state == "failed" and decor.view().places.is_empty(), "failed save places nothing")
	check(memory.get_available_keepsakes().get(cone, 0) == 2, "failed save spends nothing")
	check(panel.visible and panel.retry_button.is_visible_in_tree(), "failure keeps the basket open and offers check again")
	check(panel.status.text == "松果还没摆好，还在背篓里；点「再确认一次」再存一次。", "failure note points at check again: " + panel.status.text)
	check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(panel.retry_button.get_global_rect()), "check again is on screen")
	panel.retry_button.pressed.emit()
	await frames()
	check(panel.status.text == "正在把松果摆到篱边……", "checking again says it is being set down again: " + panel.status.text)
	memory.pump()
	await frames()
	check(decor.state == "idle" and decor.view().places.get("fence_edge", {}).get("find_id", "") == cone, "check again finishes the placement")
	check(memory.get_available_keepsakes().get(cone, 0) == 1, "exactly one cone reserved")
	check(panel.status.text == "松果摆在篱边了。在院里点它，就能收回背篓。" and not panel.retry_button.visible, "after check again the note says it is placed: " + panel.status.text)

	# Success in English: placed at once, basket open, note says where and how to take it back.
	root.get_node("I18n").set_locale("en")
	await frames()
	check(panel.visible and Array(panel.legal_spots()) == ["house_edge", "pond_path"], "the filled fence spot no longer lights up")
	drop(panel, "pond_path")
	memory.pump()
	await frames()
	check(decor.view().places.get("pond_path", {}).get("find_id", "") == cone, "drop places the cone on the path")
	check(panel.visible, "success keeps the basket open")
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
	await frames()

	# Failure while the inventory is also saving: the failure note stays through the inventory
	# refresh, and once the global retry lands it the same note turns into "placed".
	memory._data.keepsakes = {cone: 3}
	main._on_decor_changed()
	await frames()
	memory.fail_kind_once = "decor"
	drop(panel, "house_edge")
	main._world._reel_in_fish()
	main._on_inventory_changed()
	check(main._inventory.busy(), "inventory save in flight")
	memory.pump()
	await frames(1)
	check(decor.state == "failed" and panel.visible, "busy inventory keeps the basket up on failure")
	check(panel.status.text == "松果还没摆好，还在背篓里；点「再确认一次」再存一次。", "failure note replaces the saving note: " + panel.status.text)
	check(await store.flush_pending(), "inventory save settles")
	await frames()
	check(panel.status.text.begins_with("松果还没摆好"), "failure note survives the inventory refresh")
	main._retry_save()
	memory.pump()
	await frames()
	check(decor.state == "idle" and decor.view().places.has("house_edge"), "the global retry still lands it")
	check(panel.status.text == "松果摆在屋前了。在院里点它，就能收回背篓。", "the stale failure note becomes placed: " + panel.status.text)

	# Blocked (the controller's DECOR_ rejection): the drop is settled with a "could not" note and
	# no check again, since retrying the same request cannot succeed.
	main._basket_drop = {"find_id": cone, "spot": "house_edge"}
	decor.pending = {"revision": 0, "action": "place", "spot": "house_edge", "details": {}}
	decor.state = "blocked"
	main._on_decor_changed()
	await frames()
	check(panel.status.text == "松果没能摆在那里，还在背篓里。" and not panel.retry_button.visible, "blocked note, no check again: " + panel.status.text)
	check(main._basket_drop.is_empty(), "the drop is settled after a rejection")
	decor.pending.clear()
	decor.state = "idle"
	decor.request("remove", "house_edge")
	memory.pump()
	await frames()

	# Placing from the find's paper (keyboard / tap path): the paper lists the free spots.
	var g = panel.grid
	panel.scroll.ensure_control_visible(g.cells["pine_cone"])
	await frames()
	g.open_menu("pine_cone")
	await frames()
	check(g.spot_row.is_visible_in_tree() and g.spot_buttons["house_edge"].visible and not g.spot_buttons["fence_edge"].visible, "paper offers only the free spots")
	g.spot_buttons["house_edge"].pressed.emit()
	await frames()
	check(decor.busy() and panel.status.text == "正在把松果摆到屋前……", "choosing a spot submits the placement: " + panel.status.text)
	memory.pump()
	await frames()
	check(decor.view().places.get("house_edge", {}).get("find_id", "") == cone and panel.visible, "the paper's spot places it with the basket open")
	decor.request("remove", "house_edge")
	memory.pump()
	await frames()

	# Basket closed while saving: the note is not kept for the next opening.
	decor.request("remove", "fence_edge")
	memory.pump()
	main._hide_basket()
	main._show_basket()
	await frames()
	drop(panel, "fence_edge")
	main._hide_basket()
	memory.pump()
	await frames()
	main._show_basket()
	await frames()
	check(panel.place_note.is_empty(), "a hidden basket keeps no placement note")
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
