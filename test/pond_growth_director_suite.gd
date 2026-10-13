extends SceneTree
const Meals := preload("res://scripts/game/meal_ledger.gd")
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const STONE := ExplorationRoutes.FIND_STONE
var checks := 0
var failures: Array[String] = []
var period := "lunch"
var store: Node
var world: Node2D
var fixture := {}
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAILED "+label)
func reset(tired := false) -> void:
	if is_instance_valid(world):
		world.queue_free()
		await process_frame
	var inv := Inventory.empty()
	inv.wheat = 20
	fixture = {"version":5,"holiday_day":1,"keepsakes":{STONE:20},Inventory.FIELD:inv,
		"growth_actions":{"schema":1,"revision":0,"actions":{}},"pond_edging":{"schema":1,"revision":0,"sections":{}},
		"resident_rest":{"schema":1,"day":1,"cause":"awake" if tired else "sleep"}}
	fixture = Meals.complete(fixture,0,0,1,"lunch",{"wheat":1},tired).candidate
	# Explicit isolated recipe costs; never initialize a user's inventory.
	store.request_patch("fixture",fixture)
	check(await store.flush_pending(),"fixture persisted")
	world = load("res://scripts/game/yard_world.gd").new()
	world.setup()
	root.add_child(world)
	await process_frame
	world.simulation_active = true
	world.input_enabled = true
	world.pond_growth.autonomous_enabled = false
	world.get_player().position = Vector2(440,545)
	period = "lunch"
func begin(seconds := 2.0) -> bool:
	return world.pond_growth.begin("rim_04",Vector2(480,545),{"ap":1,"stones":1,"experience":1,"seconds":seconds},func(): return period)
func approach() -> void:
	for i in 1200:
		world.tick(1.0/30,Vector2.ZERO)
		if world.pond_growth.stage not in ["fetching","taking","walking"]: return
func reach_stage(wanted: String) -> void:
	for i in 2400:
		if world.pond_growth.stage == wanted or not world.pond_growth.busy(): return
		world.tick(1.0/30,Vector2.ZERO)
func capture(label: String) -> void:
	var output := OS.get_environment("YOUJIA_DIRECTOR_CAPTURE")
	if output.is_empty(): return
	# CPUParticles use real render time, unlike the accelerated world fixture.
	if label == "integrated-dinner": await create_timer(3.0).timeout
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_jpg(output+"/"+label+".jpg",0.85) == OK,"capture "+label)
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated.trim_suffix("/")+"/"):
		quit(2)
		return
	root.size = Vector2i(1280,720)
	store = root.get_node("SaveStore")
	await reset()
	check(not world.pond_growth.busy(),"ordinary setup does not auto-start")
	check(not world.pond_growth.begin("rim_04",Vector2(440,450),{"ap":1,"stones":1,"experience":1,"seconds":2.0},func(): return period),"distant station cannot produce remote stones")
	check(not world.pond_growth.begin("rim_04",Vector2(755,615),{"ap":1,"stones":1,"experience":1,"seconds":2.0},func(): return period),"pond water is not a work station")
	check(begin(),"eligible explicit job starts")
	check(not begin(),"no overlapping job")
	check(world.pond_growth.stage == "fetching" and world._walk_goal == Vector2(335,522),"first route leads to real basket")
	check(not world.pond_growth.material.visible,"no material before basket arrival")
	reach_stage("taking")
	check(world.get_player().position.distance_to(Vector2(335,522)) < 16,"pickup occurs at physical basket")
	check(store.get_growth_budget("lunch").available == 3 and int(store.get_keepsakes()[STONE]) == 20,"fetching does not debit AP or materials")
	reach_stage("walking")
	check(world.pond_growth.material.visible and world._walk_goal == Vector2(480,545),"visible material carried on second route")
	await capture("transport")
	approach()
	check(world.pond_growth.stage == "working","real world path arrives at station")
	for i in 10: world.tick(1.0/30,Vector2.ZERO)
	await capture("working")
	check(world.get_player().position.distance_to(Vector2(480,545)) < 16,"no remote construction")
	check(store.get_pond_edging().sections.is_empty(),"approach does not create result")
	for i in 20: world.tick(1.0/30,Vector2.ZERO)
	check(world.pond_growth.stage == "working","unfinished work retains inventory")
	for i in 31: world.tick(1.0/30,Vector2.ZERO)
	check(world.pond_growth.stage == "saving","finished work queues exactly one transaction")
	check(world.pond_edging_view.visuals.is_empty(),"no speculative stones")
	var accepted: String = world.pond_growth.pending
	world.pond_growth.cancel()
	check(world.pond_growth.pending == accepted and world.pond_growth.stage == "saving","accepted operation cannot be forgotten or resubmitted")
	check(await store.flush_pending(),"native completion confirmed")
	check(not world.pond_growth.busy() and world.pond_edging_view.visuals.has("rim_04"),"confirmation ends job and projects stones")
	check(store.get_growth_budget("lunch").available == 2,"one AP spent")
	check(store.get_pond_edging().sections.get("rim_04",{}).get("experience",0) == 1,"one XP awarded")
	check(not begin(),"completed section cannot repeat")
	await capture("confirmed")
	await reset(true)
	check(begin(),"fatigued lunch job starts")
	approach()
	check(world.pond_growth.stage == "working","fatigue does not block walking")
	for i in 61: world.tick(1.0/30,Vector2.ZERO)
	check(world.pond_growth.stage == "working","fatigued work takes twice as long")
	for i in 61: world.tick(1.0/30,Vector2.ZERO)
	check(world.pond_growth.stage == "saving","fatigued work eventually submits")
	check(await store.flush_pending(),"fatigued native completion")
	check(store.get_growth_budget("lunch").available == 0,"fatigued one AP spent once")
	check(store.get_pond_edging().sections.get("rim_04",{}).get("experience",0) == 1,"fatigue does not halve result XP")
	await reset()
	check(begin(),"interruptible approach begins")
	world.request_pointer_action(Vector2(420,545))
	check(not world.pond_growth.busy(),"pointer takes control immediately")
	check(store.get_pond_edging().sections.is_empty(),"cancel before submission creates nothing")
	world._consume_pending_action()
	check(begin(),"new job after cancellation")
	approach()
	world.tick(1.0/30,Vector2.RIGHT)
	check(not world.pond_growth.busy(),"manual movement cancels working")
	check(store.get_growth_budget("lunch").available == 3,"interruption does not spend AP")
	check(begin(),"period-change test begins")
	period = "dinner"
	world.tick(1.0/30,Vector2.ZERO)
	check(not world.pond_growth.busy(),"live period change cancels old plan")
	period = "lunch"
	check(begin(),"stale inventory test begins")
	approach()
	var changed: Dictionary = fixture.duplicate(true)
	changed.keepsakes[STONE] = 19
	store.request_patch("fixture",changed)
	check(await store.flush_pending(),"other inventory action confirmed")
	for i in 61: world.tick(1.0/30,Vector2.ZERO)
	await store.flush_pending()
	check(not world.pond_growth.busy(),"rejected stale plan releases actor")
	check(store.get_pond_edging().sections.is_empty(),"stale plan has no result")
	check(store.get_growth_budget("lunch").available == 3,"stale plan has no partial AP charge")
	await reset()
	check(begin(30.0),"long work begins")
	approach()
	for i in 240: world.tick(1.0/30,Vector2.ZERO)
	check(world.pond_growth.stage == "working" and not world._quiet_sky_active and not world.get_player().idle_rest.active(),"work does not trigger idle rest or sky camera")
	world.inventory_busy = true
	world.tick(1.0/30,Vector2.ZERO)
	check(not world.pond_growth.busy(),"inventory takes control without finishing work")
	check(store.get_growth_budget("lunch").available == 3,"menu interruption has no charge")
	for interrupted in ["fetching","taking","walking"]:
		await reset()
		check(begin(),"retrieval cancellation starts " + interrupted)
		reach_stage(interrupted)
		check(world.pond_growth.stage == interrupted,"retrieval phase reached " + interrupted)
		world.request_pointer_action(Vector2(440,545))
		check(not world.pond_growth.busy() and not world.pond_growth.material.visible,"player takeover clears carried presentation " + interrupted)
		check(int(store.get_keepsakes()[STONE]) == 20 and store.get_growth_budget("lunch").available == 3,"retrieval cancellation preserves stock and AP " + interrupted)
	await reset()
	check(begin(),"basket revalidation begins")
	var unavailable: Dictionary = fixture.duplicate(true)
	unavailable.keepsakes[STONE] = 19
	store.request_patch("fixture",unavailable)
	check(await store.flush_pending(),"inventory changes before basket arrival")
	reach_stage("taking")
	check(not world.pond_growth.busy() and not world.pond_growth.material.visible,"stale material plan cancels before pickup")
	check(store.get_pond_edging().sections.is_empty() and store.get_growth_budget("lunch").available == 3,"stale retrieval has no world or AP result")
	await check_work_poses()
	await check_autonomous_work()
	await check_meal_reservation()
	world.queue_free()
	await process_frame
	await check_real_menus()
	await check_growth_feedback()
	print("POND_GROWTH_DIRECTOR checks=%d failures=%d" % [checks,failures.size()])
	for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)

func check_work_poses() -> void:
	var normal_frame := -1
	for tired in [false, true]:
		await reset(tired)
		check(begin(12.0), "production pose begins tired=" + str(tired))
		approach()
		var player = world.get_player()
		var foot: Vector2 = player.position
		for i in (180 if tired else 90): world.tick(1.0/30, Vector2.ZERO)
		check(world.pond_growth.stage == "working", "pose follows unfinished production")
		check(player._sequence_walker.frame in [3,4] and player._sequence_walker.held_action_frame >= 0, "settling holds authored crouch beyond one-shot duration")
		check(player.position.distance_to(foot) < 0.01, "production keeps feet planted")
		check(world.pond_growth.material.global_position.distance_to(player.global_position) < 22, "uncommitted material rests beside feet")
		check(store.get_pond_edging().sections.is_empty() and int(store.get_keepsakes()[STONE]) == 20, "grounded presentation is not a saved/debited stone")
		if tired:
			check(player._sequence_walker.frame == normal_frame, "fatigue doubles production pose duration without extra cycles")
		else:
			normal_frame = player._sequence_walker.frame
			await capture("settling-stone")
		world.pond_growth.cancel()
		check(player._sequence_walker.held_action_frame == -1 and not world.pond_growth.material.visible, "cancel clears held pose and temporary stone immediately")
		player._play_grass_action(&"feed")
		player.tick(0.7, Vector2.ZERO, world.WORLD_SIZE)
		check(player._sequence_walker.action_kind.is_empty(), "ordinary feeding still completes as a one-shot")
	await reset()
	check(begin(12.0), "reduced motion production begins")
	approach()
	root.get_node("TuningStore").set_value("ui.reduced_motion", true, false)
	for i in 90: world.tick(1.0/30,Vector2.ZERO)
	check(world.get_player()._sequence_walker.held_action_frame == -1, "reduced motion disables production pose changes")
	check(world.pond_growth.stage == "working" and world.pond_growth.material.visible, "reduced motion keeps production and material readable")
	root.get_node("TuningStore").set_value("ui.reduced_motion", false, false)
	for i in 240: world.tick(1.0/30,Vector2.ZERO)
	check(world.get_player()._sequence_walker.frame >= 6, "production rises near completion")
	await capture("rising-after-stone")
	for i in 40: world.tick(1.0/30,Vector2.ZERO)
	check(world.get_player()._sequence_walker.held_action_frame == -1 and not world.pond_growth.material.visible, "submission releases pose and hides temporary material")
	check(await store.flush_pending(), "pose completion persists once")

func check_growth_feedback() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	await main._start_holiday()
	world = main._world
	world.pond_growth.autonomous_enabled = false
	var confirmed_snapshot := {}
	for scenario in ["confirmed", "blocked", "rejected"]:
		store.request_patch("feedback-fixture", fixture.duplicate(true))
		check(await store.flush_pending(), "feedback fixture " + scenario)
		main._growth_bark_revision = int(store.get_pond_edging().get("revision", -1))
		main._resident_barks.reset()
		main._resident_bubble.dismiss()
		main._bark_clock = 100.0
		world.get_player().position = Vector2(480,545)
		# Apply normal frame transforms before taking a visual baseline.
		main._process(0.0)
		var budget: Dictionary = store.get_growth_budget("lunch")
		var materials: Dictionary = store.plan_growth_materials({STONE:{"id":"pond_edging","materials":{STONE:1}}},RandomNumberGenerator.new())
		if scenario == "blocked": main._toggle_pause()
		if scenario == "rejected": budget.day = 99
		var id: String = store.request_pond_growth(budget,"rim_04",materials,1,1,1)
		check(not main._resident_bubble.is_showing(), "no feedback before confirmation " + scenario)
		await store.flush_pending()
		if scenario == "confirmed":
			confirmed_snapshot = preload("res://scripts/persistence/save_files.gd").new().read_record(store.SAVE_PATH).get("data", {})
			check(not id.is_empty() and main._resident_bubble.is_showing(), "actual durable growth produces a bark")
			check(main._resident_bubble._label.text == root.get_node("I18n").t("bark.growth_completed"), "growth text resolves")
			main._process(0.0)
			await capture("growth-feedback")
			main._resident_bubble.dismiss()
			main._bark_clock = 200.0
			main._on_save_confirmed(id,"growth")
			check(not main._resident_bubble.is_showing(), "duplicate acknowledgement never replays after cooldown")
		else:
			check(not main._resident_bubble.is_showing(), "blocked or rejected growth has no cheer " + scenario)
		if scenario == "blocked":
			main._toggle_pause()
			main._tick_resident_barks(0.0)
			check(not main._resident_bubble.is_showing(), "closing menu does not replay suppressed completion")
	main.queue_free()
	await process_frame
	# The rejection scenario is independent; reopen an actual successful record.
	check(not confirmed_snapshot.get("pond_edging", {}).get("sections", {}).is_empty(), "reopen fixture includes persisted growth")
	store.request_patch("feedback-reopen", confirmed_snapshot)
	check(await store.flush_pending(), "restore confirmed record before reopening")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	await main._start_holiday()
	check(not main._resident_bubble.is_showing(), "reopening does not replay old growth feedback")
	main.queue_free()
	await process_frame

# Main deliberately stops World.tick while these menus own input. Exercise the
# actual open/close methods without manually ticking the blocked World.
func check_real_menus() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	await main._start_holiday()
	world = main._world
	for menu in ["basket", "album", "pause"]:
		for phase in ["fetching", "taking", "walking", "working", "saving"]:
			world.pond_growth.cancel()
			world._consume_pending_action()
			store.request_patch("fixture", fixture.duplicate(true))
			check(await store.flush_pending(), "menu fixture " + menu + ":" + phase)
			world.simulation_active = true
			world.input_enabled = true
			world.inventory_busy = false
			world.cancel_scene_feedback()
			world._consume_pending_action()
			# Each menu case is an independent same-day fixture. Long paths from
			# prior cases must not roll the actual world clock into a different day.
			world.holiday_day = 1
			world._day_elapsed = world.DAY_DURATION_SECONDS * 0.4
			world.get_player().position = Vector2(440,545)
			period = "lunch"
			var started := begin(2.0)
			if not started:
				print("START_CONTEXT ", menu, ":", phase, " avail=",world.pond_growth.available()," busy=",world.pond_growth.stage," walk=",world._has_walk_goal," budget=",store.get_growth_budget(period)," rest=",store.get_rest_context()," sections=",store.get_pond_edging())
			check(started, "Main job begins " + menu + ":" + phase)
			if phase == "saving": approach()
			else: reach_stage(phase)
			if phase == "saving":
				for i in 61: world.tick(1.0/30,Vector2.ZERO)
			check(world.pond_growth.stage == phase, "Main stage before menu " + menu + ":" + phase)
			var accepted: String = world.pond_growth.pending
			match menu:
				"basket": main._show_basket()
				"album": main._show_album()
				"pause": main._toggle_pause()
			if phase == "saving":
				check(not accepted.is_empty() and world.pond_growth.pending == accepted and world.pond_growth.stage == "saving", "menu retains accepted write " + menu)
			else:
				check(not world.pond_growth.busy() and world.pond_growth.pending.is_empty(), "menu cancels before any World tick " + menu + ":" + phase)
			match menu:
				"basket": main._hide_basket()
				"album": main._hide_album()
				"pause": main._toggle_pause()
			check(await store.flush_pending(), "menu resolves outstanding writes " + menu + ":" + phase)
			for i in 120: main._process(1.0/30)
			check(await store.flush_pending(), "no late write " + menu + ":" + phase)
			var spent: int = 1 if phase == "saving" else 0
			check(store.get_growth_budget("lunch").available == 3 - spent, "AP unchanged or charged once " + menu + ":" + phase)
			check(store.get_pond_edging().sections.size() == spent, "no resumed duplicate world result " + menu + ":" + phase)
			check(int(store.get_keepsakes().get(STONE,0)) == 20 - spent, "materials unchanged or charged once " + menu + ":" + phase)
	main.queue_free()
	await process_frame

# Integrate the actual house director with construction, including route-only
# reservations before either director enters a visible animation stage.
func check_meal_reservation() -> void:
	await reset()
	var food: Dictionary = fixture.duplicate(true)
	food[Inventory.FIELD].millet = 3
	food.holiday_day_elapsed = 320.0
	store.request_patch("meal-construction-fixture", food)
	check(await store.flush_pending(), "dinner fixture persisted")
	world._day_elapsed = 320.0
	period = "dinner"
	check(begin(30.0), "lunch carry starts dinner construction")
	approach()
	check(world.pond_growth.stage == "working", "meal overlap test reaches production")
	check(not world.house.available(), "construction reserves actor against house activity")
	world.house.consider_meal(8.1, Vector2.ZERO)
	check(world._pending_interaction != "meal_basket", "idle meal does not steal construction actor")
	world.house.cancel_preparation()
	world.pond_growth.cancel()
	world.house.meal_cooldown = 0.0
	world.house.consider_meal(8.1, Vector2.ZERO)
	check(world._pending_interaction == "meal_basket", "released actor starts dinner retrieval")
	check(not world.pond_growth.available(), "meal basket route reserves actor before house animation")
	for i in 2400:
		world.tick(1.0 / 30.0, Vector2.ZERO)
		if not world.house.cooking_plan.is_empty():
			check(not world.pond_growth.available(), "selected ingredients reserve actor through house route")
			break
	world.house.meal_rng.seed = 1
	var cooking_captured := false
	for i in 3600:
		world.tick(1.0 / 30.0, Vector2.ZERO)
		if world.house.stage == "cook" and world.house.seconds > 3.0 and not cooking_captured:
			await capture("integrated-dinner")
			cooking_captured = true
		if not world.house.pending.is_empty(): await store.flush_pending()
		if not world.house.busy() and world.house.cooking_plan.is_empty(): break
	check(store.get_meal_ledger().receipts.size() == 2, "real dinner commits one additional receipt")
	check(store.get_yard_inventory().millet == 2, "real dinner consumes exactly one ingredient")
	check(store.get_growth_budget("dinner").available == 3, "real dinner grants two AP plus one carried AP")
	world._consume_pending_action()
	check(begin(), "construction resumes after real dinner")
	approach()
	for i in 61: world.tick(1.0 / 30.0, Vector2.ZERO)
	check(await store.flush_pending(), "post-dinner construction saved")
	check(store.get_growth_budget("dinner").available == 2, "post-dinner construction spends one AP")
	var disk: Dictionary = preload("res://scripts/persistence/save_files.gd").new().read_record(store.SAVE_PATH).get("data", {})
	check(Meals.read(disk).receipts.size() == 2, "meal receipts survive disk read")
	check(preload("res://scripts/game/growth_budget.gd").budget(disk, "dinner").get("available", -1) == 2, "AP survives disk read")
	check(disk.get("keepsakes", {}).get(STONE, -1) == 19, "material spent exactly once on disk")
	check(disk.get("pond_edging", {}).get("sections", {}).get("rim_04", {}).get("experience", 0) == 1, "world result and experience survive disk read")
	world.queue_free()
	await process_frame
	store._load()
	world = load("res://scripts/game/yard_world.gd").new()
	world.setup()
	root.add_child(world)
	await process_frame
	check(store.get_meal_ledger().receipts.size() == 2 and store.get_yard_inventory().millet == 2, "fresh native load restores meal and inventory")
	check(store.get_growth_budget("dinner").available == 2, "fresh native load preserves AP without regrant")
	check(world.pond_edging_view.visuals.has("rim_04") and not world.pond_growth.busy(), "reopened world projects confirmed stones without restarting work")
	world.simulation_active = true
	world.tick(0.0, Vector2.ZERO)
	await capture("integrated-reopened")

func check_autonomous_work(test_seed := 0) -> void:
	var schedule = preload("res://scripts/game/growth_schedule.gd")
	for entry in [[0.0,"breakfast"],[0.24,"breakfast"],[0.25,"lunch"],[0.49,"lunch"],[0.5,"dinner"],[0.99,"dinner"],[1.0,""]]:
		check(schedule.period(entry[0]) == entry[1], "live AP period boundary")
	seed(test_seed)
	await reset()
	world._day_elapsed = 160.0
	world.pond_growth.autonomous_enabled = true
	world.pond_growth.consider(1000.0, Vector2.ZERO)
	check(not world.pond_growth.busy(), "large delta cannot catch up offline work")
	for i in 300: world.tick(1.0/30, Vector2.ZERO)
	check(not world.pond_growth.busy(), "short idle does not seize actor")
	world.tick(1.0/30, Vector2.RIGHT)
	for i in 60: world.tick(1.0/30, Vector2.ZERO)
	check(not world.pond_growth.busy(), "movement resets idle grace")
	for i in 360:
		world.tick(1.0/30, Vector2.ZERO)
		if world.pond_growth.busy(): break
	check(world.pond_growth.stage == "fetching" and world.pond_growth.section == "rim_04", "ordinary world automatically chooses first accessible unfinished bank")
	world.pond_growth.autonomous_enabled = false
	approach()
	check(world.pond_growth.stage == "working", "autonomous actor really reaches the bank")
	world._goose_mount_wait = 3.49
	world._tick_goose_mount_encounter(1.0/30, Vector2.ZERO)
	check(world._goose_mount_phase < 0 and world._goose_mount_wait == 0.0, "ambient encounter cannot steal production actor")
	await capture("autonomous-working")
	for i in 361: world.tick(1.0/30, Vector2.ZERO)
	print("AUTO_BEFORE_SAVE ",world.pond_growth.stage," work=",world.pond_growth.work," pos=",world.get_player().position," target=",world.pond_growth.target," elapsed=",world._day_elapsed," pending=",world._pending_interaction," house=",world.house.stage)
	check(await store.flush_pending(), "autonomous completion durably confirmed")
	print("AUTO_AFTER_SAVE ",store.get_growth_budget("lunch")," sections=",store.get_pond_edging())
	check(store.get_growth_budget("lunch").available == 2 and int(store.get_keepsakes()[STONE]) == 19, "autonomous action charges one AP and one stone")
	check(world.pond_edging_view.visuals.has("rim_04"), "autonomous confirmed world effect visible")
	world.pond_growth.autonomous_enabled = true
	var encounter_seen := false
	var save_seen := false
	var started_at := -1
	# The 12-second grace counts free idle time. A legitimate goose/horse
	# encounter between jobs may reserve the actor, finish, then restart grace.
	for i in 1200:
		world.tick(1.0/30, Vector2.ZERO)
		encounter_seen = encounter_seen or world._goose_mount_phase >= 0
		save_seen = save_seen or not store.is_save_idle()
		# Real play yields between ticks. Let incidental world saves settle;
		# a tight accelerated loop otherwise starves their async callbacks.
		await process_frame
		if world.pond_growth.busy():
			started_at = i
			break
	check(started_at <= 361 or encounter_seen or save_seen, "only observed actor/save ownership may extend next-job grace")
	check(not encounter_seen or "goose_horse_mount" in world.collected, "idle encounter finishes before production reclaims actor")
	print("NEXT_WORK_TIMING seed=",test_seed," tick=",started_at," encounter_seen=",encounter_seen," save_seen=",save_seen)
	if world.pond_growth.section != "rim_05":
		print("NEXT_WORK_CONTEXT stage=",world.pond_growth.stage," idle=",world.pond_growth.idle_seconds," available=",world.pond_growth.available()," goose=",world._goose_mount_phase," walk=",world._has_walk_goal," house=",world.house.stage," pending=",world._pending_interaction," save_idle=",store.is_save_idle())
	check(world.pond_growth.busy() and world.pond_growth.section == "rim_05", "next autonomous job skips completed bank")
	world.cancel_scene_feedback()
	check(not world.pond_growth.busy() and world.pond_growth.idle_seconds == 0.0, "menu takeover cancels and resets grace")
	world.pond_growth.autonomous_enabled = false
	await reset()
	var empty_ap: Dictionary = fixture.duplicate(true)
	empty_ap.meal_ledger = {"schema":1,"revision":0,"receipts":[]}
	store.request_patch("unfed-fixture", empty_ap)
	check(await store.flush_pending(), "unfed fixture persisted")
	world._day_elapsed = 160.0
	world.pond_growth.autonomous_enabled = true
	for i in 400: world.tick(1.0/30, Vector2.ZERO)
	check(not world.pond_growth.busy() and store.get_pond_edging().sections.is_empty(), "no food receipt means no autonomous world impact")
	world.pond_growth.autonomous_enabled = false
