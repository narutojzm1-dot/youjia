extends SceneTree
var checks := 0
var failures: Array[String] = []
var main
var store
var world

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: ", label)

func settle() -> void:
	check(await store.flush_pending(), "native commit confirmed")
	for i in 3: await process_frame

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return
	store = root.get_node("SaveStore")
	var scenario_seed := int(OS.get_environment("YOUJIA_FOOD_TEST_SEED"))
	seed(scenario_seed)
	print("FOOD_SCENARIO_SEED ", scenario_seed)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	world = main._world
	var player = world.get_player()
	player.position = world._grass_point()
	world._interact_with_target("grass")
	check(not player.carrying_grass and main._inventory.busy(), "grass waits for durable harvest")
	await settle()
	check(player.carrying_grass and world._fish_carry_type == "", "grass has one correct hand visual")
	check(world.primary_action().target == "drop_food", "carrying changes action button to drop")
	check(YardInteraction.pointer(world, Vector2(180, 660)).target == YardSceneHotspots.PATH_OUT, "carried food does not disable the explicit exit path")
	player.position = Vector2(430, 535)
	world.request_primary_action()
	check(player.carrying_grass and world.ground_food.items.is_empty(), "no optimistic drop")
	await settle()
	check(not player.carrying_grass and world.ground_food.items.size() == 1, "confirmed grass becomes visible ground object")
	var item: Dictionary = world.ground_food.items[0]
	var location := Vector2(item.x, item.y)
	check(YardGround.allows(location, YardGround.lawn(), true), "drop is legal ground")
	check(world.ground_food.sprites.has(int(item.id)), "ground object rendered by stable ID")
	store._load()
	main._on_inventory_changed()
	check(world.ground_food.items.size() == 1 and store.get_yard_inventory().held == "", "native reopen keeps dropped grass once")
	world.request_pointer_action(location)
	await settle()
	check(player.carrying_grass and world.ground_food.items.is_empty(), "ordinary ground target can pick uneaten grass back up")
	main._show_basket()
	main._basket_panel.return_button.pressed.emit()
	await settle()
	check(main._inventory.view().grass == 1 and not player.carrying_grass, "grass returns to basket")
	main._basket_panel.fish_buttons.grass.pressed.emit()
	await settle()
	main._hide_basket()
	check(main._inventory.view().grass == 0 and player.carrying_grass, "grass can be taken back out")
	# Controlled positions exercise real routing and native consumption, not a fake host.
	for id: String in world._actors:
		world.actor_named(id).posed = true
	var cow = world.actor_named("cow")
	cow.posed = false
	cow.position = Vector2(460, 500)
	cow.state = "rest"
	cow._idle_time = 100.0
	player.position = Vector2(310, 545)
	world.request_primary_action()
	await settle()
	var lure: Dictionary = world.ground_food.items[0]
	var lure_point := Vector2(lure.x, lure.y)
	player.position = Vector2(210, 595)
	var before: Vector2 = cow.position
	var saw_cow_bite := false
	var mouth_contact := false
	for frame in 1600:
		world.tick(0.05, Vector2.ZERO)
		if cow._posture_id == "graze":
			saw_cow_bite = true
			var mouth: Vector2 = cow._sprite.to_global(Vector2(223, 965) - Vector2(750, 990))
			mouth_contact = mouth_contact or mouth.distance_to(world.to_global(lure_point)) < 8.0
		if main._inventory.busy(): await settle()
		if world.ground_food.items.is_empty(): break
	check(world.ground_food.items.is_empty(), "cow walks to and consumes the ground lure")
	check(saw_cow_bite and mouth_contact, "cow's complete grazing cel puts its mouth at the ground food")
	check(cow.position.distance_to(before) > 50.0, "cow reaches food outside daily wander rectangle")
	check(cow.state != "lead" and not world.is_leading(), "eating grass does not make cow follow the player")
	check(main._inventory.view().held == "" and main._inventory.view().grass == 0, "grass conserved through harvest basket drop and consumption")
	store._load()
	check(store.get_yard_inventory().ground.is_empty(), "consumed food does not resurrect from native save")
	# A lure changes where an animal visits, not its permanent home. Observe the
	# same cow after the real durable consumption above, without relocating it.
	var return_continuous := true
	var return_on_ground := true
	for frame in 1200:
		var previous: Vector2 = cow.position
		world.tick(0.05, Vector2.ZERO)
		return_continuous = return_continuous and cow.position.distance_to(previous) <= cow.speed * 1.18 * 0.05 + 0.02
		return_on_ground = return_on_ground and cow._stands_on(cow.position)
		if cow.wander_rect.has_point(cow.position): break
	check(cow.wander_rect.has_point(cow.position), "cow naturally returns to its daily area after eating a distant lure")
	check(return_continuous and return_on_ground, "homeward walk stays on ground without teleporting")
	check(cow.state != "lead" and not world.is_leading(), "homeward walk never turns feeding into player-following")
	# Two sheep compete for one physical grass bundle. The second never double-eats.
	for id: String in world._actors: world.actor_named(id).posed = true
	for id: String in ["sheep_a", "sheep_b"]:
		var sheep = world.actor_named(id)
		sheep.posed = false
		sheep.position = Vector2(460, 478 if id == "sheep_a" else 532)
		sheep.state = "rest"
		sheep._idle_time = 100.0
	player.position = world._grass_point()
	world._interact_with_target("grass")
	await settle()
	player.position = Vector2(480, 500)
	world.request_primary_action()
	await settle()
	player.position = Vector2(240, 590)
	var shared_food := Vector2(world.ground_food.items[0].x, world.ground_food.items[0].y)
	var revision := int(main._inventory.view().revision)
	world.simulation_active = false
	var positions := [world.actor_named("sheep_a").position, world.actor_named("sheep_b").position]
	world.tick(20.0, Vector2.ZERO)
	check(world.ground_food.items.size() == 1 and world.actor_named("sheep_a").position == positions[0], "paused simulation leaves food and competitors untouched")
	world.simulation_active = true
	for frame in 1000:
		world.tick(0.05, Vector2.ZERO)
		if main._inventory.busy(): await settle()
		if world.ground_food.items.is_empty(): break
	check(world.ground_food.items.is_empty(), "one of two sheep reaches and eats the shared grass")
	if not world.ground_food.items.is_empty():
		print("FOOD_FAILURE_TRACE ", {"items": world.ground_food.items, "targets": world.ground_food.targets, "waiting": world.ground_food.waiting, "busy": world.inventory_busy, "input": world.input_enabled, "inventory": main._inventory.view(), "sheep_a": [world.actor_named("sheep_a").position, world.actor_named("sheep_a").state], "sheep_b": [world.actor_named("sheep_b").position, world.actor_named("sheep_b").state]})
	check(int(main._inventory.view().revision) == revision + 1, "two real competitors produce exactly one durable consumption")
	var winners := 0
	for id: String in ["sheep_a", "sheep_b"]:
		if float(world.ground_food.cooldowns.get(id, 0.0)) > 0.0:
			winners += 1
			check(world.actor_named(id).position.distance_to(shared_food) < 18.0, "winner physically reaches the food without expanded eating range")
	check(winners == 1, "only the successful consumer receives a feeding cooldown")
	# A basket fish becomes a real bank object; goose consumes it after walking.
	for id: String in world._actors: world.actor_named(id).posed = true
	var goose = world.actor_named("goose")
	goose.posed = false
	goose.position = Vector2(800, 500)
	goose.state = "rest"
	goose._idle_time = 100.0
	main._on_fish_caught("small")
	await settle()
	main._inventory.request("withdraw", "small")
	await settle()
	player.position = Vector2(730, 515)
	world.request_primary_action()
	await settle()
	check(world.ground_food.items.size() == 1 and world._fish_carry_type == "", "basket fish transfers to ground")
	player.position = Vector2(650, 465)
	for frame in 1000:
		world.tick(0.05, Vector2.ZERO)
		if main._inventory.busy(): await settle()
		if world.ground_food.items.is_empty(): break
	check(world.ground_food.items.is_empty() and float(world.ground_food.cooldowns.get("goose", 0.0)) > 0.0, "goose walks over and consumes bank fish")
	store._load()
	check(store.get_yard_inventory().ground.is_empty() and store.get_yard_inventory().fish.is_empty(), "fish consumption persists without duplicate hand or basket count")
	# A cluster at the actual exit path draws the cow from across the yard.
	for id: String in world._actors: world.actor_named(id).posed = true
	cow.posed = false
	cow.position = Vector2(480, 480)
	cow.state = "rest"
	cow._idle_time = 100.0
	world.ground_food.cooldowns.erase("cow")
	var drops := [Vector2(210,572), Vector2(250,584), Vector2(255,610), Vector2(190,595)]
	for index in drops.size():
		player.position = world._grass_point()
		world._interact_with_target("grass")
		await settle()
		player.position = drops[index]
		player.facing = 1.0
		world.request_primary_action()
		await settle()
		if index == 0:
			world.ground_food.tick(0.01)
			check(cow.state != "food", "one distant bundle does not call the cow across the yard")
	check(world.ground_food.items.size() == 4, "four distinct exit-path bundles remain on the ground")
	player.position = Vector2(370, 550)
	var gate_bite := false
	for frame in 2200:
		world.tick(0.05, Vector2.ZERO)
		if cow._posture_id == "graze":
			var mouth: Vector2 = world.to_local(cow._sprite.to_global(Vector2(223, 965) - Vector2(750, 990)))
			gate_bite = gate_bite or (mouth.x < 310.0 and mouth.y > 565.0)
		if main._inventory.busy(): await settle()
		if world.ground_food.items.size() < 4: break
	check(world.ground_food.items.size() == 3 and gate_bite, "a cluster draws the cow along a valid route to eat at the exit path")
	check(cow.state != "lead", "cluster attraction never turns into player following")
	# A duck reaches only a fish on its bank; its feet never leave the water ellipse.
	for id: String in world._actors: world.actor_named(id).posed = true
	var duck = world.actor_named("duck_a")
	duck.posed = false
	duck.position = duck.ellipse_center
	duck.state = "rest"
	duck._idle_time = 100.0
	main._on_fish_caught("small")
	await settle()
	main._inventory.request("withdraw", "small")
	await settle()
	player.position = Vector2(675, 527)
	player.facing = 1.0
	world.request_primary_action()
	await settle()
	var fish_id := -1
	for dropped: Dictionary in world.ground_food.items:
		if dropped.kind == "small": fish_id = int(dropped.id)
	check(fish_id > 0, "bank drop creates a physical fish for the duck")
	player.position = Vector2(630, 470)
	var stayed_in_water := true
	for frame in 1000:
		world.tick(0.05, Vector2.ZERO)
		stayed_in_water = stayed_in_water and YardGround.in_ellipse(duck.position, duck.ellipse_center, duck.ellipse_radius)
		if main._inventory.busy(): await settle()
		if world.ground_food.find_item(fish_id).is_empty(): break
	check(stayed_in_water and world.ground_food.find_item(fish_id).is_empty(), "duck consumes reachable bank fish without teleporting onto land")
	# Rope following remains the stronger intent even beside a food cluster.
	var llama = world.actor_named("llama")
	llama.posed = false
	llama.position = Vector2(285, 578)
	world._leading = true
	player.leading = true
	llama.begin_lead(player)
	var remaining: int = world.ground_food.items.size()
	for frame in 100: world.tick(0.05, Vector2.ZERO)
	check(llama.state == "lead" and world.ground_food.items.size() == remaining, "led llama is not hijacked by nearby ground food")
	root.get_node("AudioDirector").release_streams()
	print("YARD_GROUND_FOOD_RUNTIME checks=%d failures=%d" % [checks, failures.size()])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
