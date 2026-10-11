extends SceneTree
const Schedule := preload("res://scripts/game/meal_schedule.gd")
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
var failures: Array[String] = []
var checks := 0
var main: Node
var world: Node2D
var store: Node
var captured := {}
var seen_stages := {}

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func step_until(target: String, frames: int = 2400) -> bool:
	for i in frames:
		world.tick(1.0 / 30.0, Vector2.ZERO)
		await process_frame
		if not world.house.pending.is_empty(): await store.flush_pending()
		var stage: String = world.house.stage
		seen_stages[stage] = true
		var folder := OS.get_environment("YOUJIA_COOK_CAPTURE")
		if not folder.is_empty() and stage in ["cook", "balcony", "out"] and not captured.has(stage):
			if (stage == "cook" and world.house.seconds > 3.0) or (stage == "balcony" and world.house.balcony.stage == "activity" and world.house.balcony.seconds > 1.0) or (stage == "out" and world.house.seconds > 1.0):
				main._process(0.0)
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_jpg(folder.path_join(stage + ".jpg"), 0.8)
				captured[stage] = true
		if stage == target: return true
	return false

func brush_seed(wanted: bool) -> int:
	var rng := RandomNumberGenerator.new()
	for seed_value in 100:
		rng.seed = seed_value
		if (rng.randf() < 0.8) == wanted: return seed_value
	return -1

func fixture(elapsed: float, millet: int = 3) -> void:
	var inv := Inventory.empty()
	inv.millet = millet
	store.request_patch("cooking-fixture", {"holiday_day": 2, "holiday_day_elapsed": elapsed,
		"resident_rest": {"schema": 1, "day": 2, "cause": "awake"},
		"meal_ledger": {"schema": 1, "revision": 0, "receipts": []}, Inventory.FIELD: inv})
	check(await store.flush_pending(), "fixture durably written")
	world.holiday_day = 2
	world._day_elapsed = elapsed
	world.house.meal_idle = 0.0
	world.house.meal_cooldown = 0.0
	world.debug_place_player(Vector2(380, 520))

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated.trim_suffix("/") + "/"):
		quit(2)
		return
	for hours: Array in [[7.0,"breakfast"],[10.0,""],[12.0,"lunch"],[15.0,""],[18.0,"dinner"],[21.0,""]]:
		check(Schedule.meal_at((hours[0] - 6.0) / 24.0) == hours[1], "meal window boundary")
	check(not Schedule.RECIPES.has("wheat") and not Schedule.RECIPES.has("odd"), "no unmilled wheat or unusual fish recipes")
	store = root.get_node("SaveStore")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	world = main._world
	check(world.house.smoke == null, "unused house allocates no cooking particles")
	await fixture(50.0)
	world.house.consider_meal(10.0, Vector2.RIGHT)
	check(not world._has_walk_goal and not world.house.busy(), "manual movement prevents auto meal")
	world.input_enabled = false
	world.house.consider_meal(10.0, Vector2.ZERO)
	check(not world._has_walk_goal, "modal input block prevents auto meal")
	world.input_enabled = true
	world.house.consider_meal(8.1, Vector2.ZERO)
	check(world._has_walk_goal and world._pending_interaction == "house_meal", "idle meal uses production walking route")
	check(world.get_player().position.distance_to(Vector2(380,520)) < 1.0, "meal request never teleports")
	check(await step_until("cook"), "walk, open, enter, close reaches cooking")
	check(not world.get_player().visible and world.house.smoke.is_cooking(), "indoor cook hides one actor and emits smoke")
	check(store.get_meal_ledger().receipts.is_empty() and store.get_yard_inventory().millet == 3, "unconfirmed cooking does not debit or grant")
	world.house.meal_rng.seed = brush_seed(true)
	check(await step_until(""), "confirmed cooking and optional balcony returns to yard")
	check(world.get_player().visible and world.get_player().modulate.a == 1.0, "traveller restored after cooking")
	check(seen_stages.has("balcony") and world.house.balcony.activity == "brush", "80-percent branch uses brushing, not morning activity rotation")
	check(store.get_holiday_day() == 2 and world.holiday_day == 2, "meal never advances to tomorrow")
	check(store.get_meal_ledger().receipts.size() == 1 and store.get_meal_ledger().receipts[0].earned == 0, "fatigued breakfast completes once with zero grant")
	check(store.get_yard_inventory().millet == 2, "exactly one ingredient consumed")
	check(not world.house.smoke.is_cooking(), "smoke stops after meal")
	store._load()
	check(store.get_meal_ledger().receipts.size() == 1 and store.get_yard_inventory().millet == 2, "native reopen preserves receipt and stock")
	world.house.meal_cooldown = 0.0
	world.house.consider_meal(9.0, Vector2.ZERO)
	check(not world._has_walk_goal and not world.house.busy(), "same breakfast cannot auto repeat after reload")
	if not OS.get_environment("YOUJIA_COOK_CAPTURE").is_empty():
		main.queue_free()
		await process_frame
		print("HOUSE_COOKING_CAPTURE failures=%d" % failures.size())
		quit(0 if failures.is_empty() else 1)
		return
	await fixture(325.0)
	world.debug_place_player(world.house.APPROACH)
	world.house.begin()
	check(await step_until("cook"), "dinner starts")
	seen_stages.clear()
	world.house.meal_rng.seed = brush_seed(false)
	check(await step_until(""), "20-percent direct exit branch completes")
	check(not seen_stages.has("balcony") and store.get_meal_ledger().receipts[0].earned == 1, "direct exit omits brushing without losing fatigue-adjusted dinner")
	await fixture(175.0)
	world.debug_place_player(world.house.APPROACH)
	world.house.begin()
	check(await step_until("cook"), "lunch cooking starts")
	world.house.skip_balcony()
	check(await step_until(""), "player interrupts uncommitted meal and exits")
	check(store.get_yard_inventory().millet == 3 and store.get_meal_ledger().receipts.is_empty(), "interrupted meal keeps all food and grants nothing")
	await fixture(175.0)
	world.debug_place_player(world.house.APPROACH)
	world.house.begin()
	check(await step_until("cook"), "concurrent stock scenario enters cooking")
	var changed: Dictionary = store.get_yard_inventory()
	changed.revision += 1
	changed.millet = 2
	store.request_patch("concurrent-stock", {Inventory.FIELD:changed})
	check(await store.flush_pending(), "concurrent inventory change lands")
	check(await step_until(""), "stale plan rejects and restores actor")
	check(store.get_yard_inventory().millet == 2 and store.get_meal_ledger().receipts.is_empty(), "rejected meal neither rerolls nor double consumes")
	check(not main._save_problem_active and not world.house.failed, "stale inventory is a domain refusal, not a save modal that traps the hidden actor")
	# A real autonomous approach crosses the dinner deadline before arrival.
	await fixture(374.9)
	world.house.consider_meal(8.1, Vector2.ZERO)
	check(world._pending_interaction == "house_meal", "late dinner queues only a meal intent")
	check(world.primary_action().target == "house_meal", "HUD preserves queued meal intent")
	for frame in 1800:
		world.tick(1.0 / 30.0, Vector2.ZERO)
		await process_frame
		if not world._has_walk_goal and world._pending_interaction.is_empty(): break
	check(world.get_player().position.distance_to(world.house.APPROACH) < 20.0, "late meal actually reaches house along walking route")
	check(world._day_elapsed >= 375.0 and not world.house.busy(), "expired dinner stays outside instead of starting sleep")
	check(await store.flush_pending(), "late arrival pending saves settle")
	check(store.get_holiday_day() == 2 and world.holiday_day == 2 and store.get_rest_context().cause == "awake", "autonomous late arrival does not advance day or grant sleep")
	check(store.get_meal_ledger().receipts.is_empty() and store.get_yard_inventory().millet == 3, "expired meal changes neither receipt nor ingredients")
	world._interact_with_target("house_door")
	check(world.house.busy() and world.house.cooking_plan.is_empty(), "explicit player door action still starts nighttime sleep")
	check(await step_until(""), "explicit sleep completes normally")
	check(store.get_holiday_day() == 3 and world.holiday_day == 3, "only explicit sleep advances to next morning")
	main.queue_free()
	await process_frame
	for failure in failures: push_error(failure)
	print("HOUSE_COOKING checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
