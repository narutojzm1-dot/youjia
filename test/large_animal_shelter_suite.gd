extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func simulate(world: Node, seconds: float, clock := 150.0) -> void:
	for i in roundi(seconds * 60):
		world._day_elapsed = clock
		world._regional_weather.state.remaining = 9999.0
		world.tick(1.0 / 60.0, Vector2.ZERO)
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return
	seed(565)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	var world = main._world
	world.collected.append("goose_horse_mount")
	world.debug_place_player(Vector2(390,550))
	var store = root.get_node("SaveStore")
	await store.flush_pending()
	world._day_elapsed = 150.0
	for id in ["horse", "llama"]:
		check(not world.shelter.inside(world.actor_named(id)), id+" starts outdoors despite closed resident gate")
	world._leading = true
	world.set_weather("rain")
	await store.flush_pending()
	simulate(world, 0.2)
	await store.flush_pending()
	check(world.gate.opened, "rain opens gate through durable transaction")
	check(not world.actor_named("llama").has_meta("shelter_controlled"), "rope owns llama during rain")
	check(world.actor_named("llama").state == "lead", "shelter does not cancel lead")
	world._leading = false
	var h = world.actor_named("horse")
	print("ROUTE_DEBUG ",YardGround.allows(world.shelter.BEDS.horse,YardGateGround.connected(),true)," ",YardBodies.clear_at(world.shelter.BEDS.horse,h.body_radius*YardGround.depth_at(h.position.y),world.physical_obstacles("horse"))," ",YardBodies.route(h.position,world.shelter.BEDS.horse,h.body_radius*YardGround.depth_at(h.position.y),world.physical_obstacles("horse"),YardGateGround.connected(),true))
	var jump := false
	var rail := false
	for i in 24000:
		var positions := {}
		for id in world.shelter.ALL_IDS: positions[id] = world.actor_named(id).position
		simulate(world,1.0/60.0)
		for id in world.shelter.ALL_IDS:
			var actor = world.actor_named(id)
			jump = jump or actor.position.distance_to(positions[id]) > 5.0
			rail = rail or not YardBodies._ground_segment(positions[id],actor.position,YardGateGround.connected(),true)
		if i > 10 and not world.shelter.returning: break
	check(not jump and not rail, "five animals walk continuously through real gate")
	for id in world.shelter.ALL_IDS:
		var actor = world.actor_named(id)
		print("RAIN_BED ",id," ",actor.position)
		print("STATE ", world.weather, " active=",world.shelter.active," cel=",actor._posture_id," controlled=",actor.has_meta("shelter_controlled"))
		check(world.shelter.at_bed(actor), id+" reaches distinct rain bed")
		check(actor._posture_id == "shelter_rest", id+" uses lying painting")
	var photo := PhotoMoment.sanitize(JSON.parse_string(JSON.stringify(PhotoMoment.capture(world,ExpressionCatalog.find_rule("cow_pet_gentle")))))
	for id in ["horse", "llama"]:
		var found := false
		for item in photo.get("items",[]):
			if item.get("subject", "") == id and str(item.get("texture",{}).get("path", "")).ends_with(id+"-rest.png"): found = true
		check(found, id+" photo retains actual lying cel")
	world._save_progress()
	await store.flush_pending()
	store._load()
	await main._start_holiday(false)
	main.set_process(false)
	world = main._world
	for id in ["horse","llama"]: check(world.shelter.at_bed(world.actor_named(id)), id+" reopens safely in rain bed")
	world.set_weather("sun")
	await store.flush_pending()
	world.debug_place_player(Vector2(390,550))
	simulate(world,300)
	for id in ["horse","llama"]:
		print("SUN_RETURN ",id," ",world.actor_named(id).position," active=",world.shelter.active," ",world.shelter.paths)
		check(not world.shelter.inside(world.actor_named(id)), id+" walks outside after rain")
	simulate(world,240,400.0)
	for id in world.shelter.ALL_IDS: print('NIGHT_ALL ',id,' ',world.actor_named(id).position,' paths=',world.shelter.paths)
	for id in ["horse","llama"]:
		var actor = world.actor_named(id)
		print("NIGHT ",id," ",actor.position," active=",world.shelter.active)
		check(actor.position.distance_to(world.shelter.HOME_REST[id]) < 4.0, id+" returns to own outdoor night area")
		check(actor._posture_id == "shelter_rest", id+" rests at night without crowding cow pen")
	world._leading = true
	simulate(world,1.0,400.0)
	check(not world.actor_named("llama").has_meta("shelter_rest"), "taking rope wakes resting llama")
	main.queue_free()
	await process_frame
	root.get_node("AudioDirector").release_streams()
	print("LARGE_ANIMAL_SHELTER checks=%d failures=%d" % [checks,failures.size()])
	for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
