extends SceneTree
const Memory := preload("res://test/fixtures/exploration_memory_store.gd")
const CLOCK := {"day": 2, "elapsed": 20.0}
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func run() -> void:
	var context := {"nearby": ["cow", "sheep_a"], "rope": ""}
	var joined := 0
	for number in 100:
		var choice := AnimalCompanions.choose(context, str(number))
		check(choice == AnimalCompanions.choose({"nearby": ["sheep_a", "cow"], "rope": ""}, str(number)), "candidate order does not reroll")
		if not choice.is_empty(): joined += 1
	check(joined > 10 and joined < 65, "companions are possible and genuinely optional across fixed seeds")
	check(AnimalCompanions.choose({"nearby": [], "rope": "llama"}, "7") == {"actor_id": "llama", "mode": "rope"}, "rope always takes the existing llama")
	check(AnimalCompanions.choose({"nearby": [], "rope": ""}, "7").is_empty(), "no remote teleport companion")
	check(not AnimalCompanions.valid_choice({"actor_id": "duck_a", "mode": "nearby"}), "ducks remain in their pond")
	check(not AnimalCompanions.valid_choice({"actor_id": "cow", "mode": "rope"}), "food does not leash the cow")
	check(not AnimalCompanions.valid_choice({"actor_id": "cow", "mode": "nearby", "future": true}), "unknown nested fields cannot be silently discarded")
	var session := ExplorationSession.new(ExplorationRoutes.catalog(), 0)
	check(session.begin(ExplorationRoutes.NEAR_PATH, CLOCK, 7, {"nearby": [], "rope": "llama"}).ok, "trip begins with identity")
	var original: Dictionary = session.to_record()
	check(not session.begin(ExplorationRoutes.NEAR_PATH, CLOCK, 8, context).ok and session.to_record() == original, "repeated departure cannot replace trip or partner")
	var restored := ExplorationSession.restore(JSON.parse_string(JSON.stringify(original)), ExplorationRoutes.catalog(), 0)
	check(restored.host_action == ExplorationContract.HOST_REQUEST_RETURN_RESTORED and restored.session.get_view().companion == original.session.companion, "JSON restart safely returns the same identity")
	var old := original.duplicate(true)
	old.session.erase("companion")
	var legacy := ExplorationSession.restore(old, ExplorationRoutes.catalog(), 0)
	check(legacy.session.get_view().companion.is_empty() and not legacy.session.to_record().session.has("companion"), "legacy solo record is not rewritten to invent an animal")
	var bad := original.duplicate(true)
	bad.session.companion["future"] = true
	var quarantined := ExplorationSession.restore(bad, ExplorationRoutes.catalog(), 0)
	check(quarantined.session.is_quarantined() and quarantined.session.to_record() == bad, "unsupported companion record preserved intact")
	for reject in [false, true]:
		var memory := Memory.new()
		var host := ExplorationHost.new(memory)
		host.restore()
		host.begin(CLOCK, 7, {"nearby": [], "rope": "llama"})
		memory.unknown_kind = "exploration"
		memory.pump()
		check(memory.get_exploration_record() == null and host.view().companion.actor_id == "llama", "unknown begin keeps confirmed store and frozen choice")
		host.begin(CLOCK, 99, context)
		check(host.view().companion.actor_id == "llama", "unknown begin cannot reroll")
		memory.resolve_unknown(not reject)
		host.request_return("player")
		memory.pump()
		check(host.can_begin() and memory.get_exploration_record().session == null, "confirmed/rejected departure can return and clean supported partner extension")
		memory.free()
	await runtime()
	print("ANIMAL_COMPANION checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func resident_ids(world) -> Array:
	var ids: Array = world._actors.keys()
	ids.sort()
	return ids

func runtime() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		check(false, "runtime requires an isolated profile")
		return
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	var world = main._world
	var store = root.get_node("SaveStore")
	check(await store.flush_pending(), "initial residents confirmed before departure baseline")
	var original_residents := resident_ids(world)
	check("chicken" in original_residents, "baseline includes the confirmed chick")
	var llama = world.actor_named("llama")
	var original_id: int = llama.get_instance_id()
	for id: String in world._actors: world.actor_named(id).posed = true
	llama.posed = false
	world.debug_place_player(Vector2(300, 560))
	world.debug_place_actor("llama", Vector2(360, 555))
	world._interact_with_target("llama")
	check(world.is_leading(), "actual interaction takes the rope")
	check(YardInteraction.pointer(world, Vector2(180, 660)).target == YardSceneHotspots.PATH_OUT, "explicit exit remains available with rope")
	world.debug_place_player(Vector2(262, 630))
	world.debug_place_actor("llama", Vector2(312, 607))
	check(world.primary_action().target == YardSceneHotspots.PATH_OUT, "at gate action offers going out instead of releasing by accident")
	world.request_primary_action()
	check(main._screen == "exploring" and not world.visible, "ordinary production departure hides the yard")
	var scroll = main._exploration.scroll
	scroll.set_process(false)
	check(scroll.companion != null and scroll.companion.choice.actor_id == "llama", "real near path renders the original stable identity")
	check(scroll.companion.rope.visible and scroll.companion.rope.points.size() == 17, "rope joins real painted endpoints")
	var paused_position: Vector2 = scroll.companion.actor.position
	scroll.set_process(true)
	paused = true
	for i in 3: await process_frame
	check(scroll.companion.actor.position == paused_position, "real paused SceneTree stops companion processing")
	paused = false
	scroll.set_process(false)
	check(await store.flush_pending(), "native departure committed")
	check(store.get_exploration_record().session.companion.actor_id == "llama", "partner is in the actual native trip save")
	var start: Vector2 = scroll.companion.actor.position
	scroll.walk_target = {"arm": "lane", "d": 60.0}
	for frame in 500: scroll.walk(Vector2.ZERO, 0.02)
	check(scroll.companion.actor.position.distance_to(start) > 400.0, "animal actually follows along the full painted lane")
	var nearest: Dictionary = NearPathLayout.nearest(scroll.companion.actor.position)
	check(float(nearest.gap) < 23.0, "follower stays on the lane shoulder rather than crossing stream")
	for frame in 200: scroll.walk(Vector2.ZERO, 0.02)
	var stopped: Vector2 = scroll.companion.actor.position
	for frame in 50: scroll.walk(Vector2.ZERO, 0.02)
	check(scroll.companion.actor.position.distance_to(stopped) < 0.1, "follower settles when player stops")
	root.get_node("TuningStore").set_value("ui.reduced_motion", true, false)
	scroll.walk_target = {"arm": "lane", "d": 300.0}
	for frame in 180: scroll.walk(Vector2.ZERO, 0.02)
	check(scroll.companion.actor._gait._material.get_shader_parameter("amount") == 0.0, "reduced motion follows without gait deformation")
	root.get_node("TuningStore").set_value("ui.reduced_motion", false, false)
	scroll._request_return("player")
	check(await store.flush_pending(), "native return committed")
	check(main._screen == "game" and world.visible and world.actor_named("llama").get_instance_id() == original_id, "return restores same resident, no second animal")
	check(resident_ids(world) == original_residents and llama.position.distance_to(world.get_player().position) < 100.0, "partner returns beside player without spawning")
	check(store.get_exploration_record().session == null, "supported partner session cleaned after return")
	world._interact_with_target(YardSceneHotspots.PATH_OUT)
	check(main._exploration.is_exploring(), "second actual trip can begin")
	main._exploration.interrupt()
	check(await store.flush_pending(), "interrupted trip safely settles")
	check(main._screen == "game" and resident_ids(world) == original_residents and store.get_exploration_record().session == null, "host interrupt cannot lose or duplicate resident")
	world._interact_with_target(YardSceneHotspots.PATH_OUT)
	check(await store.flush_pending(), "active trip saved before abrupt scene removal")
	check(store.get_exploration_record().session.companion.actor_id == "llama", "crash fixture really has a durable companion trip")
	main.queue_free()
	await process_frame
	store._load()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	check(await store.flush_pending(), "fresh native Main restores and settles interrupted trip")
	check(main._screen == "game" and resident_ids(main._world) == original_residents, "restart returns all residents once")
	check(main._world.actor_named("llama").position.distance_to(main._world.get_player().position) < 100.0, "restart places same stable partner beside safe return point")
	check(store.get_exploration_record().session == null, "restart cleanup recognizes and preserves companion contract")
	world = main._world
	for id: String in world._actors: world.actor_named(id).posed = true
	var cow = world.actor_named("cow")
	cow.posed = false
	world.debug_place_actor("cow", world.get_player().position + Vector2(48, -18))
	var nearby: Dictionary = world.companion_context()
	check(nearby.rope == "" and nearby.nearby == ["cow"], "only actual nearby eligible unposed resident enters the draw")
	var seed_value := 0
	while AnimalCompanions.choose(nearby, str(seed_value)).is_empty(): seed_value += 1
	check(main._exploration.try_begin(CLOCK, "sunny", seed_value, nearby), "a nearby cow can join a real production trip without a rope")
	check(main._exploration.scroll.companion.actor.actor_id == "cow" and not main._exploration.scroll.companion.rope.visible, "cow keeps its own painting and has no invented leash")
	check(await store.flush_pending(), "cow choice saved in native trip")
	main._exploration.interrupt()
	check(await store.flush_pending(), "cow trip returns durably")
	check(not world.is_leading() and cow.state != "lead" and cow.position.distance_to(world.get_player().position) < 100.0, "cow returns nearby but does not become a yard follower")
	main.queue_free()
	await process_frame
