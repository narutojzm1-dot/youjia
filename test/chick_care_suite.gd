extends SceneTree
const Care := preload("res://scripts/game/chick_care.gd")
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Residents := preload("res://scripts/game/world_residents.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(why)
func fixture(kind: String = "wheat") -> Dictionary:
	var data := Residents.transition({"holiday_day": 1, "holiday_day_elapsed": 0.0, "untouched": {"old": 4}}, 0, "settle_chick").candidate as Dictionary
	data.yard_inventory = Inventory.empty()
	data.yard_inventory.ground = [{"id": 1, "kind": kind, "x": 500.0, "y": 500.0}]
	data.yard_inventory.next_food_id = 2
	return data
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated): quit(2); return
	check(Care.read({}).bonus_seconds == 0, "old save starts with no invented feeding")
	for bad: Variant in [null, {}, {"schema": 2, "bonus_seconds": 0}, {"schema": 1, "bonus_seconds": -300}, {"schema": 1, "bonus_seconds": 301}, {"schema": 1, "bonus_seconds": 1500}, {"schema": 1, "bonus_seconds": 0, "future": 4}]:
		check(Care.read({Care.FIELD: bad}).is_empty(), "unsupported care never silently reset")
	for kind: String in ["millet", "wheat", "corn"]:
		var source := fixture(kind)
		var old := source.duplicate(true)
		var fed := Inventory.transition(source, 0, "eat", kind, {"id": 1}, "chicken").candidate as Dictionary
		check(source == old, "source remains unchanged " + kind)
		check(fed.yard_inventory.ground.is_empty() and Care.read(fed).bonus_seconds == 300, "one consume candidate contains food removal and credit " + kind)
		check(fed.untouched == source.untouched and fed.world_residents == source.world_residents, "other owners unchanged " + kind)
		check(Inventory.transition(fed, 0, "eat", kind, {"id": 1}, "chicken").error == "BASKET_CHANGED", "retry cannot grant second credit " + kind)
		check(Inventory.transition(fed, 1, "eat", kind, {"id": 1}, "chicken").error == "BASKET_EMPTY", "another consumer cannot reuse removed food " + kind)
		check(Care.read(JSON.parse_string(JSON.stringify(fed))).bonus_seconds == 300, "JSON reopen keeps credit " + kind)
	var source := fixture()
	for consumer: String in ["", "cow", "chick-fake"]:
		check(not Inventory.transition(source, 0, "eat", "wheat", {"id": 1}, consumer).candidate.has(Care.FIELD), "other consumer no chick credit")
	check(not Inventory.transition(source, 0, "pickup", "wheat", {"id": 1}, "chicken").candidate.has(Care.FIELD), "pickup does not count as feeding")
	var corrupt := source.duplicate(true)
	corrupt[Care.FIELD] = {"schema": 2, "bonus_seconds": 0}
	check(Inventory.transition(corrupt, 0, "eat", "wheat", {"id": 1}, "chicken").error == "BASKET_CHICK_CARE_UNSUPPORTED", "invalid care rejects entire consume")
	check(corrupt.yard_inventory.ground.size() == 1, "rejected consume keeps food")
	var future := fixture()
	future.world_residents.schema = 4
	check(Inventory.transition(future, 0, "eat", "wheat", {"id": 1}, "chicken").error == "BASKET_CHICK_CARE_UNSUPPORTED", "future resident blocks atomic feeding without resetting data")
	for i in 8:
		source = Care.credit(source, "eat", "wheat", "chicken").candidate
	check(Care.read(source).bonus_seconds == 1200, "feeding bonus capped at two days")
	check(Care.age(source, 0.0, 599.9) < Care.GROW_SECONDS, "feeding cannot replace first natural day")
	check(Care.age(source, 0.0, 600.0) == Care.GROW_SECONDS, "four portions allow growth after one natural day")
	source.holiday_day = 2
	check(Residents.transition(source, 1, "grow_chicken").candidate.world_residents.chicken.stage == "hen", "authoritative growth uses saved food credit")
	var natural := fixture()
	check(Care.age(natural, 0.0, 1799.9) < Care.GROW_SECONDS and Care.age(natural, 0.0, 1800.0) == Care.GROW_SECONDS, "without feeding same three-day growth")
	natural.holiday_day = 4
	var hen := Residents.transition(natural, 1, "grow_chicken").candidate as Dictionary
	check(not Care.credit(hen, "eat", "corn", "chicken").candidate.has(Care.FIELD), "adult does not gain redundant care")
	check(Care.age({}, 20.0, 10.0) == -1.0, "clock rollback not positive growth")

	var Memory := preload("res://test/fixtures/exploration_memory_store.gd")
	var memory := Memory.new()
	memory._data = fixture()
	memory.fail_kind_once = "inventory"
	memory.request_inventory_action(0, "eat", "wheat", {"id": 1}, "chicken")
	memory.pump()
	check(memory.get_yard_inventory().ground.size() == 1 and memory.get_chick_growth().bonus_seconds == 0, "failed write exposes neither effect")
	memory.request_inventory_action(0, "eat", "wheat", {"id": 1}, "chicken")
	memory.pump()
	check(memory.get_yard_inventory().ground.is_empty() and memory.get_chick_growth().bonus_seconds == 300, "failed consume retries both once")
	memory.free()
	for landed: bool in [false, true]:
		var uncertain := Memory.new()
		uncertain._data = fixture()
		uncertain.unknown_kind = "inventory"
		uncertain.request_inventory_action(0, "eat", "wheat", {"id": 1}, "chicken")
		uncertain.pump()
		check(uncertain.get_yard_inventory().ground.size() == 1 and uncertain.get_chick_growth().bonus_seconds == 0, "unknown consume exposes neither effect")
		uncertain.resolve_unknown(landed)
		check(uncertain.get_yard_inventory().ground.size() == (0 if landed else 1) and uncertain.get_chick_growth().bonus_seconds == (300 if landed else 0), "unknown outcome resolves both effects together")
		uncertain.free()
	var store = root.get_node("SaveStore")
	check(await store.flush_pending(), "native store initialized")
	store.request_patch("chick-care-fixture", fixture())
	check(await store.flush_pending(), "fixture persisted in isolated production store")
	var operation: String = store.request_inventory_action(0, "eat", "wheat", {"id": 1}, "chicken")
	check(not operation.is_empty(), "production consume accepted")
	check(store.get_yard_inventory().ground.size() == 1 and store.get_chick_growth().bonus_seconds == 0, "before confirmation both effects hidden")
	check(await store.flush_pending(), "production consume commits")
	check(store.get_yard_inventory().ground.is_empty() and store.get_chick_growth().bonus_seconds == 300, "one native commit exposes both effects")
	store._load()
	check(store.get_yard_inventory().ground.is_empty() and store.get_chick_growth().bonus_seconds == 300, "native disk reopen preserves food and credit together")

	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	check(await store.flush_pending(), "scene startup saved")
	for i in 4: await process_frame
	var world = main._world
	var chick = world.actor_named("chicken")
	check(chick != null, "confirmed chick in real yard")
	chick.posed = false
	chick._routine_step = 0
	chick._start_rest()
	check(chick._posture_id == "peck" and store.get_chick_growth().bonus_seconds == 300, "natural peck uses painting without another feeding credit")
	world.get_player().position = chick.position + Vector2(-30, 5)
	var picked: Dictionary = YardInteraction.pointer(world, chick.visual_hit_rect().get_center())
	check(picked.target == "chick_care:chicken", "pointer selects actual visible chick")
	check(world.action_target_key(picked) == "target.chick", "HUD uses translated chick identity instead of a raw key")
	world._request_action(picked.target, picked.point)
	check(main._chick_panel.visible and paused and not world.input_enabled, "click arrival opens growth panel and freezes yard")
	check(main._chick_panel.progress.value > 16.0 and main._chick_panel.progress.value < 18.0, "panel includes confirmed half-day feeding credit")
	for locale: String in ["zh-CN", "en"]:
		root.get_node("I18n").set_locale(locale)
		for viewport: Vector2i in [Vector2i(1280,720), Vector2i(390,844), Vector2i(568,320)]:
			root.size = viewport
			main._chick_panel.refresh()
			for i in 4: await process_frame
			check(Rect2(Vector2.ZERO, Vector2(viewport)).encloses(main._chick_panel.paper.get_global_rect()), "growth panel fits viewport and locale")
			main._chick_panel.scroll.scroll_vertical = 10000
			for i in 3: await process_frame
			check(main._chick_panel.scroll.get_global_rect().encloses(main._chick_panel.close_button.get_global_rect()), "scroll reaches back button")
	root.get_node("I18n").set_locale("zh-CN")
	root.size = Vector2i(1280,720)
	main._chick_panel.scroll.scroll_vertical = 0
	main._chick_panel.refresh()
	for i in 4: await process_frame
	var output := OS.get_environment("YOUJIA_CAPTURE_DIR")
	if not output.is_empty() and DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(output)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("growth-panel.png"))
	var escape := InputEventAction.new()
	escape.action = "pause"
	escape.pressed = true
	main._input(escape)
	check(not main._chick_panel.visible and not paused and world.input_enabled, "Escape closes and restores walking")
	main.queue_free()
	await process_frame
	print("CHICK_CARE checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
