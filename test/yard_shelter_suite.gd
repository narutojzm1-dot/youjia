extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated):
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
	var store = root.get_node("SaveStore")
	await store.flush_pending()
	world._day_elapsed = 150.0
	for id: String in world.shelter.IDS:
		var actor = world.actor_named(id)
		check(world.shelter.inside(actor), id+" starts inside closed pen")
		world.tick(1.0/60.0,Vector2.ZERO)
		check(actor._posture_id == "shelter_rest", id+" uses own lying cel")
	world.debug_place_player(Vector2(830,550))
	world.gate.toggle()
	await store.flush_pending()
	var jumps := 0
	var rail_crossings := 0
	# Browser-sized steps catch premature waypoint skipping at the inner rail.
	for i in 10800:
		var prior: Dictionary = {}
		for id: String in world.shelter.IDS: prior[id] = world.actor_named(id).position
		world._day_elapsed = 150.0
		world.tick(1.0/60.0,Vector2.ZERO)
		for id: String in world.shelter.IDS:
			var actor = world.actor_named(id)
			if actor.position.distance_to(prior[id]) > 5.0: jumps += 1
			if not YardBodies._ground_segment(prior[id],actor.position,preload("res://scripts/game/yard_gate_ground.gd").connected(),true): rail_crossings += 1
		var all_out := true
		for id: String in world.shelter.IDS:
			if not world.shelter.outdoors[id].has_point(world.actor_named(id).position): all_out = false
		if all_out and i > 200: break
	for id: String in world.shelter.IDS:
		print("RELEASE ",id," ",world.actor_named(id).position)
		check(not world.shelter.inside(world.actor_named(id)), id+" walks out through gate")
	check(jumps == 0 and rail_crossings == 0, "release never teleports or crosses rails")
	world.gate.toggle()
	await store.flush_pending()
	check(not world.gate.opened, "manual gate closure outside remains possible")
	world._day_elapsed = 400.0 # 22:00 on the shared clock
	world.tick(1.0/60.0,Vector2.ZERO)
	check(not world.gate.pending.is_empty() and not world.gate.opened, "night return waits for real gate save")
	await store.flush_pending()
	check(world.gate.opened, "evening opens closed gate durably")
	world.gate.toggle()
	check(world.gate.pending.is_empty() and world.gate.opened, "cannot close across the returning queue")
	world.simulation_active = false
	var paused: Vector2 = world.actor_named("cow").position
	world.tick(2.0,Vector2.ZERO)
	check(world.actor_named("cow").position == paused, "pause freezes resident travel")
	world.simulation_active = true
	for i in 14400:
		world._day_elapsed = 400.0
		world.tick(1.0/60.0,Vector2.ZERO)
		if not world.shelter.returning and i > 10: break
	for id: String in world.shelter.IDS:
		var actor = world.actor_named(id)
		print("RETURN ",id," ",actor.position)
		check(world.shelter.at_bed(actor), id+" reaches own bed")
		check(actor._posture_id == "shelter_rest", id+" settles into own rest pose")
		check(not world.ground_food.targets.has(id), id+" has no outside feeding intent overnight")
	check(not world.shelter.returning, "all residents finish returning")
	var moment := PhotoMoment.capture(world,ExpressionCatalog.find_rule("cow_pet_gentle"))
	var restored := PhotoMoment.sanitize(JSON.parse_string(JSON.stringify(moment)))
	check(not restored.is_empty(), "rest cels remain valid in saved photos")
	for id: String in world.shelter.IDS:
		var found := false
		for item: Dictionary in restored.get("items", []):
			if item.get("subject", "") == id and str(item.get("texture", {}).get("path", "")).contains("/characters/shelter/"):
				found = true
		check(found, id+" keeps the actual resting texture after photo JSON round trip")
	world._save_progress()
	await store.flush_pending()
	world.gate.toggle()
	await store.flush_pending()
	check(not store.get_yard_gate_open(), "closed door persists after return")
	store._load()
	await main._start_holiday(false)
	main.set_process(false)
	world = main._world
	for id: String in world.shelter.IDS:
		check(world.shelter.at_bed(world.actor_named(id)), id+" restores to its shelter with saved night and closed gate")
	check(not world.gate.opened, "reload keeps gate closed")
	main.queue_free()
	await process_frame
	root.get_node("AudioDirector").release_streams()
	print("YARD_SHELTER checks=%d failures=%d" % [checks,failures.size()])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
