extends SceneTree
const Basket := preload("res://scripts/game/physical_basket.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return
	var store = root.get_node("SaveStore")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	var world = main._world
	world.collected.append("goose_horse_mount")
	var player = world.get_player()
	var sprite = world.get_node("PhysicalBasket")
	check(sprite.texture.resource_path == Basket.ART.resource_path and sprite.visible, "production sprite uses installed artwork")
	check(is_equal_approx(sprite.get_rect().size.y * sprite.scale.y, Basket.HEIGHT), "world scale preserves painted proportions")
	check(sprite.z_index == roundi(Basket.ANCHOR.y), "basket sorts at its feet")
	check(YardGround.allows(Basket.APPROACH, world.player_ground(), true), "basket approach is on walkable lawn")
	var hit := Basket.ANCHOR - Vector2(0,30)
	check(YardInteraction.pointer(world,hit).target == YardSceneHotspots.BASKET, "visible object has explicit target")
	player.position = Vector2(250,530)
	world.request_pointer_action(hit)
	check(world._pending_interaction == YardSceneHotspots.BASKET and not main._basket_panel.visible, "distant click walks instead of opening remotely")
	world.tick(0.016, Vector2.RIGHT)
	check(world._pending_interaction.is_empty(), "manual movement cancels approach")
	player.position = Basket.APPROACH
	world.tick(0.016, Vector2.ZERO)
	check(not main._basket_panel.visible, "cancelled click cannot open later")
	player.position = Vector2(250,530)
	world.request_pointer_action(hit)
	for i in 300:
		world.tick(0.016, Vector2.ZERO)
		if main._basket_panel.visible: break
	check(main._basket_panel.visible, "complete production walk opens basket without second tap")
	main._hide_basket()
	await store.flush_pending()
	var before: Dictionary = store.get_yard_inventory().duplicate(true)
	world.request_pointer_action(hit)
	check(main._basket_panel.visible and paused and not world.input_enabled, "actual Main opens the existing panel and pauses world")
	check(store.get_yard_inventory() == before, "opening does not grant or consume inventory")
	check(world._pending_interaction.is_empty() and world._selected_target.is_empty() and not world._has_walk_goal, "opening consumes approach exactly once")
	main._hide_basket()
	check(not main._basket_panel.visible and not paused and world.input_enabled, "closing restores normal control")
	world.request_pointer_action(Vector2(390,520))
	check(world._pending_interaction.is_empty() and world._has_walk_goal, "lawn movement remains available after closing")
	world._consume_pending_action()
	main._inventory.request("scoop", "millet")
	for i in 60:
		await process_frame
		if not main._inventory.busy(): break
	check(store.get_yard_inventory().held == "millet", "fixture holds real durable food")
	player.position = Basket.APPROACH
	check(main._hold_hotbar.is_place_armed(), "real held food arms pointer placement")
	check(not main._try_hold_place_at(root.get_canvas_transform() * hit), "physical basket bypasses armed food placement in Main")
	world.request_pointer_action(hit)
	check(main._basket_panel.visible and store.get_yard_inventory().held == "millet", "held food is preserved while opening physical basket")
	main._hide_basket()
	var snap := PhotoMoment.capture(world, {"id":"llama_fed_gentle"})
	var found := false
	for item: Dictionary in snap.get("items",[]):
		if item.get("subject","") == "basket": found = true
	check(found, "new photos capture the actual basket sprite")
	check(not PhotoMoment.sanitize(snap).is_empty(), "basket photo remains valid inert data")
	var obstacles: Array = world.physical_obstacles("player")
	check(obstacles.any(func(o: Dictionary) -> bool: return o.id == "yard_basket"), "resident routing avoids basket footprint")
	await store.flush_pending()
	await main._show_title()
	await main._start_holiday()
	check(main._world.has_node("PhysicalBasket") and store.get_yard_inventory().held == "millet", "reentry preserves basket and held food without initial grant")
	main.queue_free()
	await process_frame
	for label in failures: printerr(label)
	print("physical_basket_suite: %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
