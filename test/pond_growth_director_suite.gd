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
	world.get_player().position = Vector2(440,545)
	period = "lunch"
func begin(seconds := 2.0) -> bool:
	return world.pond_growth.begin("rim_04",Vector2(480,545),{"ap":1,"stones":1,"experience":1,"seconds":seconds},func(): return period)
func approach() -> void:
	for i in 1200:
		world.tick(1.0/30,Vector2.ZERO)
		if world.pond_growth.stage != "walking": return
func capture(label: String) -> void:
	var output := OS.get_environment("YOUJIA_DIRECTOR_CAPTURE")
	if output.is_empty(): return
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
	world.queue_free()
	await process_frame
	await check_real_menus()
	print("POND_GROWTH_DIRECTOR checks=%d failures=%d" % [checks,failures.size()])
	for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)

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
		for phase in ["walking", "working", "saving"]:
			world.pond_growth.cancel()
			world._consume_pending_action()
			store.request_patch("fixture", fixture.duplicate(true))
			check(await store.flush_pending(), "menu fixture " + menu + ":" + phase)
			world.simulation_active = true
			world.input_enabled = true
			world.inventory_busy = false
			world.get_player().position = Vector2(440,545)
			period = "lunch"
			check(begin(2.0), "Main job begins " + menu + ":" + phase)
			if phase != "walking": approach()
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
