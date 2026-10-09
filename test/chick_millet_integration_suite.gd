extends SceneTree
var checks := 0
var failures := 0
var main
var world
var store
var output := ""
func _initialize() -> void: call_deferred("run")
func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(why)
func settle() -> void:
	check(await store.flush_pending(), "production save commits")
	for i in 4: await process_frame
	check(await store.flush_pending(), "deferred resident transition commits")
func capture(label: String) -> void:
	if output.is_empty() or DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg(output.path_join(label + ".jpeg"), 0.9)
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated): quit(2); return
	output = OS.get_environment("YOUJIA_CAPTURE_DIR")
	if not output.is_empty(): DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	store = root.get_node("SaveStore")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	world = main._world
	await settle()
	check(store.get_world_residents().chicken.stage == "chick" and world.actor_named("chicken") != null, "new yard introduces one confirmed chick")
	var birth: Dictionary = store.get_world_residents().chicken.settled_clock.duplicate(true)
	main._show_basket()
	check(not main._basket_panel.scoop_button.visible, "infinite tin retired; legacy millet remains compatible")
	main._basket_panel.scoop_button.pressed.emit()
	check(main._inventory.busy() and not world._millet_held, "no optimistic grain grant")
	await settle()
	check(world._millet_held and world._fish_carry_type == "" and not world.get_player().carrying_grass, "millet is neither grass nor fish")
	check(main._basket_panel.scoop_button.disabled, "cannot scoop twice into occupied hand")
	main._basket_panel.return_button.pressed.emit()
	await settle()
	check(store.get_yard_inventory().millet == 1 and not world._millet_held, "one handful in basket")
	main._basket_panel.fish_buttons.millet.pressed.emit()
	await settle()
	main._hide_basket()
	check(store.get_yard_inventory().millet == 0 and world.ground_food.held() == "millet", "withdraw conserves grain")
	check(world.primary_action().target == "drop_food", "normal action offers dropping millet")
	for id: String in world._actors: world.actor_named(id).posed = true
	var chick: Node2D = world.actor_named("chicken")
	chick.posed = false
	chick.position = Vector2(510, 500)
	chick.state = "rest"
	chick._idle_time = 100.0
	world.get_player().position = Vector2(435, 530)
	world.get_player().facing = 1.0
	world.request_primary_action()
	await settle()
	check(not world._millet_held and world.ground_food.items.size() == 1, "millet becomes one ground portion")
	var item: Dictionary = world.ground_food.items[0]
	check(world.ground_food.sprites[int(item.id)].texture.resource_path.ends_with("millet.png"), "ground uses actual millet painting")
	check(world.ground_food._accepts(chick, item) and not world.ground_food._accepts(world.actor_named("cow"), item), "chick eats grain; cow does not take it as grass")
	world.get_player().position = Vector2(330, 510)
	await capture("chick-and-millet")
	var peck_seen := false
	for frame in 800:
		world.tick(0.05, Vector2.ZERO)
		if chick._posture_id == "peck" and not peck_seen:
			peck_seen = true
			await capture("chick-peck")
		if main._inventory.busy(): await settle()
		if world.ground_food.items.is_empty(): break
	check(peck_seen, "chick uses full peck cel before eating")
	check(world.ground_food.items.is_empty() and float(world.ground_food.cooldowns.get("chicken", 0.0)) > 0.0, "real chick routes to grain and consumes once")
	store._load()
	check(store.get_yard_inventory().ground.is_empty(), "consumed grain stays gone after native reload")
	# A controlled clock boundary tests growth, not ordinary elapsed play.
	store.request_patch("growth-fixture", {"holiday_day": int(birth.day) + 3, "holiday_day_elapsed": float(birth.elapsed)})
	await settle()
	await settle()
	check(store.get_world_residents().chicken.stage == "hen" and world.actor_named("chicken").get_meta("resident_stage") == "hen", "same resident grows using confirmed clock")
	check(world.actor_named("chicken")._sprite.texture.resource_path.ends_with("/hen.png"), "grown bird uses distinct adult painting")
	await capture("grown-hen")
	store._load()
	main._on_residents_changed()
	check(store.get_world_residents().chicken.settled_clock == birth, "growth and reload keep birth clock")
	main._show_basket()
	for locale: String in ["zh-CN", "en"]:
		root.get_node("I18n").set_locale(locale)
		for viewport: Vector2i in [Vector2i(390, 844), Vector2i(568, 320)]:
			root.size = viewport
			main._on_inventory_changed()
			for i in 3: await process_frame
			main._basket_panel.scroll.scroll_vertical = 10000
			for i in 3: await process_frame
			var button: Button = main._basket_panel.scoop_button
			check(button.size.x <= viewport.x - 24 and button.size.y >= 44, "grain source fits narrow panel")
			await capture("basket-%s-%d" % [locale, viewport.x])
	print("CHICK_MILLET_INTEGRATION checks=%d failures=%d" % [checks, failures])
	main.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
