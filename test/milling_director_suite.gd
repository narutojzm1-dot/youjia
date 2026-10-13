extends SceneTree
## Actual World paths and SaveStore; isolated setup is not ordinary Web evidence.
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Meals := preload("res://scripts/game/meal_ledger.gd")
const Production := preload("res://scripts/game/growth_production.gd")
const Budget := preload("res://scripts/game/growth_budget.gd")
const Basket := preload("res://scripts/game/physical_basket.gd")
const Schedule := preload("res://scripts/game/growth_schedule.gd")
const STONE := ExplorationRoutes.FIND_STONE
var store: Node
var world: Node2D
var fixture := {}
var period := "lunch"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAILED " + label)

func reset(wheat := 20, stones := 20, tired := false, flour := 0) -> void:
	if is_instance_valid(world):
		world.queue_free()
		await process_frame
	var inventory := Inventory.empty()
	inventory.wheat = wheat
	inventory.flour = flour
	fixture = {"version":5,"holiday_day":1,"holiday_day_elapsed":160.0,
		Inventory.FIELD:inventory,"keepsakes":{STONE:stones} if stones > 0 else {},
		"growth_actions":Budget.empty(),"pond_edging":{"schema":1,"revision":0,"sections":{}},
		"growth_production":Production.empty(),"meal_ledger":Meals.empty(),
		"resident_rest":{"schema":1,"day":1,"cause":"awake" if tired else "sleep"}}
	fixture = Meals.complete(fixture,0,0,1,"lunch",{"wheat":1},tired).candidate
	store.request_patch("isolated-milling-fixture",fixture)
	check(await store.flush_pending(),"fixture persisted")
	world = load("res://scripts/game/yard_world.gd").new()
	world.setup()
	root.add_child(world)
	await process_frame
	world.simulation_active = true
	world.input_enabled = true
	world._day_elapsed = 160.0
	world.get_player().position = Vector2(440,545)
	world.pond_growth.autonomous_enabled = false
	period = "lunch"

func begin(seconds := 2.0) -> bool:
	var recipe := Schedule.MILL_RECIPE.duplicate(true)
	recipe.seconds = seconds
	return world.pond_growth.begin_milling(world.pond_growth.milling_station,recipe,func(): return period)

func reach(wanted: String) -> void:
	for i in 2400:
		if world.pond_growth.stage == wanted or not world.pond_growth.busy(): return
		world.tick(1.0/30,Vector2.ZERO)
	check(false,"bounded route to " + wanted)

func finish_work() -> void:
	for i in 800:
		if world.pond_growth.stage != "working": return
		world.tick(1.0/30,Vector2.ZERO)
	check(false,"bounded production")

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated.trim_suffix("/")+"/"):
		quit(2)
		return
	store = root.get_node("SaveStore")
	await one_draw_and_filters()
	await physical_completion_and_reopen()
	await interruptions_and_stale_plan()
	await fatigue_and_ownership()
	await actual_pause_boundary()
	if is_instance_valid(world): world.queue_free()
	await process_frame
	print("MILLING_DIRECTOR checks=%d failures=%d" % [checks,failures.size()])
	for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)

func one_draw_and_filters() -> void:
	for wanted: String in [STONE,"wheat"]:
		await reset()
		var catalog := {STONE:{"id":"pond_edging","materials":{STONE:1}},"wheat":{"id":"mill_wheat","materials":{"wheat":1}}}
		var reference := RandomNumberGenerator.new()
		var reference_plan := {}
		var chosen_seed := -1
		for candidate_seed in 64:
			reference.seed = candidate_seed
			reference_plan = store.plan_growth_materials(catalog,reference)
			if reference_plan.get("primary") == wanted:
				chosen_seed = candidate_seed
				break
		check(chosen_seed >= 0,"both groups selectable " + wanted)
		world.pond_growth.material_rng.seed = chosen_seed
		check(world.pond_growth.begin_available(func(): return period),"mixed catalog starts " + wanted)
		check(world.pond_growth.proposal == reference_plan,"director uses exact unified planner result " + wanted)
		check(world.pond_growth.material_rng.state == reference.state,"one draw only " + wanted)
		var frozen: Dictionary = world.pond_growth.proposal.duplicate(true)
		var rng_state: int = world.pond_growth.material_rng.state
		reach("taking")
		check(world.pond_growth.stage == "taking" and world.get_player().position.distance_to(Basket.APPROACH) < 16,"real basket before work " + wanted)
		check(world.pond_growth.proposal == frozen and world.pond_growth.material_rng.state == rng_state,"basket checks frozen plan without reroll " + wanted)
		world.pond_growth.cancel()
	for constraint: String in ["last_seed","full","unavailable"]:
		await reset(2 if constraint == "last_seed" else 20,20,false,Inventory.MAX_COUNT if constraint == "full" else 0)
		if constraint == "unavailable": world.pond_growth.milling_station = Vector2(INF,INF)
		check(world.pond_growth.begin_available(func(): return period),"pond remains executable " + constraint)
		check(world.pond_growth.action_id == "pond_edging","unexecutable milling filtered before draw " + constraint)
		world.pond_growth.cancel()
	await reset(2,0)
	var rng_before: int = world.pond_growth.material_rng.state
	check(not world.pond_growth.begin_available(func(): return period),"last seed and no stone start no job")
	check(not world._has_walk_goal and world.pond_growth.material_rng.state == rng_before,"empty executable pool never routes or draws")
	await reset()
	var unfed := fixture.duplicate(true)
	unfed.meal_ledger = Meals.empty()
	store.request_patch("unfed-fixture",unfed)
	check(await store.flush_pending(),"unfed persisted")
	check(not world.pond_growth.begin_available(func(): return period),"unfed never starts either production")
	check(store.get_growth_production().receipts.is_empty() and store.get_yard_inventory().flour == 0,"unfed grants no flour or receipt")

func physical_completion_and_reopen() -> void:
	await reset()
	var before: Dictionary = store.get_yard_inventory()
	check(not world.pond_growth.begin_milling(Vector2(755,615),Schedule.MILL_RECIPE,func(): return period),"cannot mill remotely or on water")
	check(begin(),"physical milling begins")
	check(not world.pond_growth.material.visible and world._walk_goal == Basket.APPROACH,"empty hands travel to basket")
	var frozen: Dictionary = world.pond_growth.proposal.duplicate(true)
	reach("walking")
	check(world.pond_growth.material.visible and world.pond_growth.material.texture is AtlasTexture,"carried wheat uses crop art")
	check(world._walk_goal == world.pond_growth.milling_station,"second route goes to actual mill")
	check(store.get_yard_inventory() == before,"retrieval is presentation only")
	reach("working")
	check(world.pond_growth.stage == "working" and world.get_player().position.distance_to(world.pond_growth.milling_station) < 16,"work only at mill station")
	check(world.get_player()._sequence_walker.animation == &"feed","milling uses standing reaching art instead of pond crouch")
	check(world.mill_view.working,"actual mill receives work presentation")
	check(world.pond_growth.proposal == frozen,"station retains original proposal")
	check(store.get_growth_production().receipts.is_empty(),"approach produces nothing")
	finish_work()
	check(world.pond_growth.stage == "saving" and not world.pond_growth.pending.is_empty(),"one atomic completion queued")
	check(store.get_yard_inventory() == before,"no speculative flour before confirmation")
	var pending: String = world.pond_growth.pending
	world.pond_growth.cancel()
	check(world.pond_growth.pending == pending and not begin(),"accepted completion is retained without replacement")
	check(not world.mill_view.working,"no flour effect while save confirmation is pending")
	check(await store.flush_pending(),"milling durable confirmation")
	var inventory: Dictionary = store.get_yard_inventory()
	check(not world.pond_growth.busy() and inventory.wheat == before.wheat-1 and inventory.flour == 1 and inventory.revision == before.revision+1,"one input/output inventory revision")
	check(store.get_growth_budget(period).available == 2 and store.get_growth_production().receipts[0].experience.cooking == 1,"same AP budget and one cooking XP")
	check(world.pond_growth.begin("rim_04",Vector2(480,545),{"ap":1,"stones":1,"experience":1,"seconds":1.0},func(): return period),"pond follows milling")
	reach("working")
	finish_work()
	check(await store.flush_pending(),"mixed pond completion saved")
	check(store.get_growth_budget(period).available == 1 and store.get_growth_production().revision == 1 and store.get_pond_edging().revision == 1,"mixed work spends single balance with distinct receipts")
	var disk: Dictionary = preload("res://scripts/persistence/save_files.gd").new().read_record(store.SAVE_PATH).get("data",{})
	check(Inventory.read(disk).flour == 1 and Production.read(disk).revision == 1 and Budget.budget(disk,period).available == 1,"atomic output receipts and AP on disk")
	world.queue_free()
	await process_frame
	store._load()
	check(store.get_yard_inventory().flour == 1 and store.get_growth_budget(period).available == 1,"native reopen does not replay milling")
	check(store.get_growth_production().receipts.size() == 1,"native reopen keeps one production receipt")

func interruptions_and_stale_plan() -> void:
	for phase: String in ["fetching","taking","walking","working"]:
		await reset()
		check(begin(),"interruptible milling " + phase)
		reach(phase)
		check(world.pond_growth.stage == phase,"actual phase before takeover " + phase)
		world.request_pointer_action(Vector2(420,545))
		check(not world.pond_growth.busy() and not world.pond_growth.material.visible,"pointer cancels milling " + phase)
		check(store.get_growth_production().receipts.is_empty() and store.get_yard_inventory().wheat == 19 and store.get_growth_budget(period).available == 3,"takeover creates no partial result " + phase)
	for phase: String in ["fetching","walking","working"]:
		await reset()
		check(begin(),"stale milling starts " + phase)
		reach(phase)
		var changed := fixture.duplicate(true)
		changed[Inventory.FIELD].wheat -= 1
		changed[Inventory.FIELD].revision += 1
		store.request_patch("stock-race",changed)
		check(await store.flush_pending(),"concurrent stock change " + phase)
		if phase == "working": finish_work()
		else: reach("working" if phase == "walking" else "taking")
		await store.flush_pending()
		check(not world.pond_growth.busy() and store.get_yard_inventory().flour == 0 and store.get_growth_budget(period).available == 3,"stale plan never reselects or partly commits " + phase)
	await reset()
	check(begin(),"period interruption starts")
	period = "dinner"
	world.tick(1.0/30,Vector2.ZERO)
	check(not world.pond_growth.busy() and store.get_yard_inventory().flour == 0,"period change drops unaccepted work")

func fatigue_and_ownership() -> void:
	await reset(20,20,true)
	check(begin(),"tired milling starts")
	reach("taking")
	for i in 25: world.tick(1.0/30,Vector2.ZERO)
	check(world.pond_growth.stage == "walking","tired retrieval remains 0.8 seconds")
	reach("working")
	for i in 61: world.tick(1.0/30,Vector2.ZERO)
	check(world.pond_growth.stage == "working","tired production takes twice normal time")
	finish_work()
	check(await store.flush_pending(),"tired completion saved")
	check(store.get_yard_inventory().flour == 1 and store.get_growth_budget(period).available == 0 and store.get_growth_production().receipts[0].experience.cooking == 1,"fatigue halves speed only not output or XP")
	await reset()
	check(begin(30.0),"milling actor ownership begins")
	check(not world.house.available(),"milling retrieval owns actor against house")
	reach("working")
	world.inventory_busy = true
	world.tick(1.0/30,Vector2.ZERO)
	check(not world.pond_growth.busy() and store.get_yard_inventory().flour == 0,"menu ownership cancels milling")
	world.inventory_busy = false
	world._pending_interaction = "meal_basket"
	check(not begin(),"meal route-only reservation blocks milling")

func actual_pause_boundary() -> void:
	for phase: String in ["fetching","taking","walking","working","saving"]:
		await reset()
		world.queue_free()
		await process_frame
		var main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		await process_frame
		main.set_process(false)
		await main._start_holiday()
		world = main._world
		world.pond_growth.autonomous_enabled = false
		world.get_player().position = Vector2(440,545)
		check(begin(),"real Main milling before pause " + phase)
		if phase == "saving":
			reach("working")
			finish_work()
		else: reach(phase)
		check(world.pond_growth.stage == phase,"actual Main reaches phase " + phase)
		var accepted: String = world.pond_growth.pending
		main._toggle_pause()
		check(not world.pond_growth.material.visible and not world.mill_view.working,"pause synchronously clears flour and carry " + phase)
		if phase == "saving":
			check(world.pond_growth.pending == accepted and not accepted.is_empty(),"pause retains accepted operation identity")
		else: check(not world.pond_growth.busy(),"pause cancels unaccepted milling " + phase)
		main._toggle_pause()
		check(await store.flush_pending(),"paused completion resolved " + phase)
		var produced := 1 if phase == "saving" else 0
		check(store.get_yard_inventory().flour == produced and store.get_growth_production().revision == produced,"pause only preserves accepted output " + phase)
		main.queue_free()
		await process_frame
