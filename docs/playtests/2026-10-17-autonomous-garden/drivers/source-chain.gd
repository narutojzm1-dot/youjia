extends SceneTree
const SEEDS := ExplorationRoutes.FIND_FLOWER_SEEDS
var checks := 0
func check(value: bool) -> void:
	assert(value)
	checks += 1
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var prefix := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
	assert(not prefix.is_empty() and OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(prefix+"/"))
	var store := root.get_node("SaveStore")
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("GARDEN_FIXTURE")))
	d.keepsakes = {}
	store.request_patch("controlled-empty-source",d)
	check(await store.flush_pending())
	var trip: ExplorationSession
	var used_seed := -1
	for seed in 80:
		trip = ExplorationSession.new(ExplorationRoutes.catalog(),0)
		check(trip.begin(ExplorationRoutes.NEAR_PATH,{"day":1,"elapsed":160.0},str(seed)).ok)
		check(trip.visit("slope").ok)
		if trip.get_view().get("offer") == SEEDS:
			used_seed = seed
			break
	check(used_seed >= 0)
	check(trip.take(SEEDS).ok)
	check(trip.request_return("player").ok)
	var proposal: Dictionary = trip.get_proposal()
	var serial: int = trip.to_record().session.trip_serial
	var receipt := {}
	var op: String = store.request_exploration_trip(trip.to_record(),serial,PackedStringArray([SEEDS]),receipt)
	check(not op.is_empty() and store.get_keepsakes().is_empty())
	check(await store.flush_pending())
	check(receipt.granted and store.get_keepsakes()[SEEDS] == 1 and store.get_exploration_committed_serial() == serial)
	store._load()
	check(store.get_keepsakes()[SEEDS] == 1)
	var again := {}
	store.request_exploration_trip(trip.to_record(),serial,PackedStringArray([SEEDS]),again)
	check(await store.flush_pending() and not again.granted and store.get_keepsakes()[SEEDS] == 1)
	check(trip.commit_succeeded(proposal.trip_id).ok)
	store.request_exploration_record(trip.to_record())
	check(await store.flush_pending())
	var world = load("res://scripts/game/yard_world.gd").new()
	world.setup()
	root.add_child(world)
	await process_frame
	world._day_elapsed = 160.0
	world.simulation_active = true
	world.input_enabled = true
	world.get_player().position = Vector2(440,545)
	world.pond_growth.autonomous_enabled = false
	check(world.pond_growth.begin_available(func(): return "lunch") and world.pond_growth.action_id == "plant_flowers")
	for i in 4200:
		world.tick(1.0/30,Vector2.ZERO)
		await process_frame
		if store.get_yard_garden().get("revision",0) == 1: break
	check(store.get_yard_garden().get("revision",0) == 1)
	check(store.get_keepsakes().get(SEEDS,0) == 0 and store.get_growth_budget("lunch").available == 2)
	var photo := PhotoMoment.capture(world,{"id":"fish_first_catch"})
	check(not photo.is_empty())
	FileAccess.open(OS.get_environment("GARDEN_PHOTO"),FileAccess.WRITE).store_string(JSON.stringify(photo))
	world.garden_view.sync_day(4)
	FileAccess.open(OS.get_environment("GARDEN_BLOOM_PHOTO"),FileAccess.WRITE).store_string(JSON.stringify(PhotoMoment.capture(world,{"id":"fish_first_catch"})))
	store._load()
	check(store.get_yard_garden().get("revision",0) == 1 and store.get_keepsakes().get(SEEDS,0) == 0)
	world.queue_free()
	await process_frame
	print("GARDEN_SOURCE_CHAIN checks=%d seed=%d actual native FIFO return+plant+reopen" % [checks,used_seed])
	quit()
