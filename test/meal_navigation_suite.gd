extends SceneTree
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Basket := preload("res://scripts/game/physical_basket.gd")
var checks := 0
var failures: Array[String] = []
var world: Node2D
var store: Node

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func reset(elapsed := 325.0) -> void:
	if is_instance_valid(world): world.free()
	await store.flush_pending()
	var inv := Inventory.empty()
	inv.fish = {"medium": 1}
	store.request_patch("meal-navigation-fixture", {"holiday_day": 4, "holiday_day_elapsed": elapsed,
		"resident_rest": {"schema": 1, "day": 4, "cause": "awake"},
		"meal_ledger": {"schema": 1, "revision": 0, "receipts": []}, Inventory.FIELD: inv})
	check(await store.flush_pending(), "isolated meal fixture committed")
	world = load("res://scripts/game/yard_world.gd").new()
	world.setup([], {}, 4, elapsed)
	root.add_child(world)
	await process_frame
	world.simulation_active = true
	world.input_enabled = true
	world.pond_growth.autonomous_enabled = false
	world.get_player().position = Vector2(520, 490)
	# Keep a repeatable collision fixture, using the ordinary residents and their
	# body footprints. No test bypass changes the player's route or position.
	for actor in world._actors.values(): actor.set_meta("pond_story", true)

func block_basket() -> void:
	# Sampled from an unmodified resident moving inside its normal home during
	# the native reproduction. The exact center is blocked, but its edge is not.
	world.actor_named("sheep_a").position = Vector2(310.2198, 512.9765)
	world.actor_named("sheep_b").position = Vector2(391.9069, 483.5826)

func untouched() -> bool:
	return store.get_yard_inventory().fish.get("medium", 0) == 1 and store.get_meal_ledger().receipts.is_empty()

func walk_until_take() -> void:
	var collision_free := true
	for frame in 600:
		world.tick(1.0 / 30.0, Vector2.ZERO)
		var player = world.get_player()
		collision_free = collision_free and YardBodies.clear_at(player.position,
			player.body_radius * YardGround.depth_at(player.position.y), world.physical_obstacles("player"))
		if world.house.busy(): break
	check(collision_free, "meal approach respects every resident footprint")

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated.trim_suffix("/") + "/"):
		quit(2)
		return
	store = root.get_node("SaveStore")
	await reset()
	check(world.actor_named("sheep_a").position == Vector2(309, 508.5), "ordinary sheep home starts beside basket")
	block_basket()
	var start: Vector2 = world.get_player().position
	var radius: Vector2 = world.get_player().body_radius * YardGround.depth_at(start.y)
	check(YardBodies.route(start, Basket.APPROACH, radius, world.physical_obstacles("player"), world.player_ground()).is_empty(), "normal resident can block the exact basket destination")
	check(not YardBodies.route(start, Basket.APPROACH + Vector2(4, 0), radius, world.physical_obstacles("player"), world.player_ground()).is_empty(), "a nearby point inside existing interaction reach is accessible")
	world.house.consider_meal(8.1, Vector2.ZERO)
	check(world._pending_interaction == "meal_basket" and world._walk_goal == Basket.APPROACH, "meal retains physical basket interaction center")
	check(not world._walk_path.is_empty() and world.get_player().position == start, "occupied basket starts a real route without teleport")
	walk_until_take()
	check(world.house.stage == "take" and world.get_player().position.distance_to(Basket.APPROACH) < 18.0, "normal walk reaches a valid physical basket pickup")
	check(untouched(), "approach and pickup do not debit ingredients or grant a meal")

	# Blocking a route after it starts must use the same fallback during repath.
	await reset()
	world.house.consider_meal(8.1, Vector2.ZERO)
	block_basket()
	world._body_repath = 0.0
	walk_until_take()
	check(world.house.stage == "take", "resident entering the destination cannot strand an existing meal route")
	check(untouched(), "dynamic reroute keeps transaction uncommitted")

	await reset(374.9)
	block_basket()
	world.house.consider_meal(8.1, Vector2.ZERO)
	world._day_elapsed = 375.1
	world.tick(0.01, Vector2.ZERO)
	check(world._pending_interaction.is_empty() and not world._has_walk_goal and not world.house.owns_actor(), "meal cutoff releases first-leg meal navigation immediately")
	check(world.primary_action().label != "action.house_cooking" and untouched(), "expired first leg clears cooking label without changing food")

	await reset()
	block_basket()
	world.house.consider_meal(8.1, Vector2.ZERO)
	world.holiday_day = 5
	world.house.consider_meal(0.1, Vector2.ZERO)
	check(world._pending_interaction.is_empty() and not world.house.owns_actor() and untouched(), "same meal window on a different day cannot retain yesterday's fetch")

	await reset()
	block_basket()
	world.house.consider_meal(8.1, Vector2.ZERO)
	world._has_walk_goal = false
	world.house.consider_meal(0.1, Vector2.ZERO)
	check(world._pending_interaction.is_empty() and not world.house.owns_actor(), "lost navigation goal cannot keep a phantom cooking action")

	await reset()
	block_basket()
	world.house.consider_meal(8.1, Vector2.ZERO)
	world._request_action("", Vector2(520, 545))
	world.house.consider_meal(0.1, Vector2.ZERO)
	check(world._has_walk_goal and world._walk_goal == Vector2(520, 545) and not world.house.owns_actor(), "replaced meal intent preserves the player's unrelated destination")

	# A fully occupied reach has no legal pickup. Wait briefly, then release
	# ownership/cool down; never overlap a resident or collect remotely.
	await reset()
	world.actor_named("cow").position = Basket.APPROACH
	world.house.consider_meal(8.1, Vector2.ZERO)
	check(world._walk_path.is_empty(), "completely occupied basket has no fabricated path")
	start = world.get_player().position
	for frame in 360: world.tick(1.0 / 30.0, Vector2.ZERO)
	check(not world.house.owns_actor() and not world._has_walk_goal, "stationary blocked meal route releases actor within twelve seconds")
	check(world.get_player().position.distance_to(start) < 0.01 and untouched(), "blocked timeout never teleports, consumes, or grants")
	world.house.consider_meal(8.1, Vector2.ZERO)
	check(not world.house.owns_actor(), "failed navigation observes its cooldown")
	world.actor_named("cow").position = Vector2(466, 489)
	world.house.consider_meal(30.0, Vector2.ZERO)
	check(world._pending_interaction == "meal_basket" and not world._walk_path.is_empty(), "later clear route can start a fresh valid meal")

	world.free()
	await process_frame
	for failure in failures: push_error(failure)
	print("MEAL_NAVIGATION checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
