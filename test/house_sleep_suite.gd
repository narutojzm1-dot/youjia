extends SceneTree
const State := preload("res://scripts/game/house_sleep_state.gd")
const Weather := preload("res://scripts/game/world_weather.gd")
class ReceiptStore extends Node:
	signal commit_confirmed(op_id: String, kind: String)
	signal commit_rejected(op_id: String, kind: String, code: String)
	var requests := 0
	func request_house_sleep(_night: Dictionary) -> String:
		requests += 1
		return "sleep-controlled-%d" % requests
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
	var night := {"holiday_day":4,"holiday_day_elapsed":400.0,"plant_state":2,"plant_day_planted":2,"plant_watered_day":3,
		"world_weather":{"weather":"rain","remaining":100.0,"seed":123,"episode":2}}
	var original := night.duplicate(true)
	original.keepsakes = {"pinecone":3}
	var result: Dictionary = State.finish(original,night)
	check(result.holiday_day == 5 and result.holiday_day_elapsed == 0.0,"night advances once to 06:00")
	check(result.plant_state == 3,"watered mature plant blooms")
	check(result.keepsakes == original.keepsakes,"inventory retained")
	check(original.holiday_day == 4,"proposal does not mutate old durable night")
	check(State.finish(result,night) == result,"duplicate night is idempotent")
	var clock := Weather.new()
	clock.restore(night.world_weather)
	clock.advance(200.0)
	check(result.world_weather == clock.snapshot(),"weather advances exact skipped interval")
	for elapsed: float in [0.0,150.0,300.0,600.0,INF,NAN]:
		var invalid := night.duplicate(true)
		invalid.holiday_day_elapsed = elapsed
		check(State.finish(original,invalid) is bool,"non-night/invalid clock rejected")
	var stale := night.duplicate(true)
	stale.holiday_day_elapsed = 390.0
	check(State.finish(original,stale) is bool,"stale same-night clock rejected")
	var dry := night.duplicate(true)
	dry.plant_watered_day = -1
	check(State.finish(original,dry).plant_state == 2,"unwatered plant not invented bloom")
	var store = root.get_node("SaveStore")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	check(await store.flush_pending(),"initial durable state")
	var world = main._world
	_check_window_hours(world)
	check(main._inventory.request("scoop","millet"),"take real held millet before sleep")
	check(await store.flush_pending(),"held millet confirmed before entry")
	check(main._hold_hotbar.is_place_armed(),"real held food arms pointer placement")
	world.holiday_day = 4
	world._day_elapsed = 400.0
	world._plant_state = 2
	world._plant_day_planted = 2
	world._plant_watered_day = 3
	world._regional_weather.restore(night.world_weather)
	world.collected.append("goose_horse_mount")
	world.debug_place_player(world.house.APPROACH)
	check(YardSceneHotspots.resolve(world,"house_door").target == "house_door","door has reachable action")
	world._leading = true
	check(not world.house.available(),"rope blocks entry without dropping animal")
	world._leading = false
	world._fish_state = world.FISH_CASTING
	check(not world.house.available(),"casting blocks entry")
	world._fish_state = world.FISH_IDLE
	var door_screen: Vector2 = root.get_canvas_transform() * Vector2(263,400)
	check(not main._try_hold_place_at(door_screen),"armed held food does not consume house door pointer")
	check(main._inventory.view().held == "millet","house click does not drop held food")
	world.request_pointer_action(Vector2(263,400))
	check(world.house.busy(),"ordinary door action begins sequence")
	var began_at: Vector2 = world.get_player().position
	world.request_pointer_action(Vector2(600,500))
	check(not world._has_walk_goal,"extra click cannot replace entering route")
	var traversed := false
	var saw_open := false
	for i in 1800:
		world.tick(1.0/60.0,Vector2.ZERO)
		traversed = traversed or world.get_player().position.y < 460
		saw_open = saw_open or world.house.door.visible
		if world.house.stage == "saving": break
	check(traversed and began_at.y == 472,"player walks authored porch")
	check(saw_open and not world.get_player().visible,"room shown before sleeping player hidden")
	check(world.holiday_day == 4,"no optimistic morning before receipt")
	check(await store.flush_pending(),"sleep commit reaches native host")
	check(store.get_holiday_day() == 5,"durable morning survives view interruption")
	# A queued pre-sleep progress update cannot regress the confirmed morning.
	store.request_yard_progress(4,400.0,2,2,3,night.world_weather)
	check(await store.flush_pending(),"stale autosave receipt")
	check(store.get_holiday_day() == 5 and store.get_plant_state().state == 3,"stale autosave cannot erase sleep")
	store.request_house_sleep(night)
	check(await store.flush_pending(),"duplicate intent receipt")
	check(store.get_holiday_day() == 5,"repeated old night cannot grant another day")
	for i in 1500:
		world.tick(1.0/60.0,Vector2.ZERO)
		if not world.house.busy(): break
	check(not world.house.busy() and world.get_player().visible,"morning exits door and returns control")
	check(world.get_player().position.distance_to(world.house.APPROACH) < 2.0,"walks back to original lawn approach")
	check(YardGround.allows(world.get_player().position,world.player_ground(),true),"restored normal walk geometry")
	check(world.holiday_day == 5 and world._plant_state == 3,"runtime adopts confirmed plant and day")
	check(main._inventory.view().held == "millet" and world._millet_held,"morning retains actual held millet")
	check(world._regional_weather.snapshot() == store.get_world_weather(),"runtime adopts confirmed weather")
	world._pulse = 100.0
	world.tick(1.0/60.0,Vector2.ZERO)
	check(PhotoMoment.has_event_subject(world.photo_moments.get("plant_first_bloom",{}),"plant_first_bloom"),"sleep bloom earns real scene photo after exit")
	check(await store.flush_pending(),"bloom photo reaches durable album")
	check("plant_first_bloom" in store.get_album(),"sleep bloom unlock survives storage")
	world.photo_moments.erase("plant_first_bloom")
	world._pulse = 100.0
	world.tick(1.0/60.0,Vector2.ZERO)
	check(PhotoMoment.has_event_subject(world.photo_moments.get("plant_first_bloom",{}),"plant_first_bloom"),"restored blooming yard fills missing photo without new growth")
	check(world.collected.count("plant_first_bloom") == 1,"recovered bloom does not duplicate unlock")
	world.house.begin()
	check(not world.house.busy(),"daytime door does not advance another day")
	world.house.lights = 0.8
	var photo := PhotoMoment.capture(world,ExpressionCatalog.find_rule("llama_fed_gentle"))
	check(is_equal_approx(float(photo.house_lights),0.8),"photo records actual pane intensity")
	check(PhotoMoment.sanitize(JSON.parse_string(JSON.stringify(photo))).house_lights == photo.house_lights,"light survives photo serialization")
	photo.erase("house_lights")
	check(not PhotoMoment.sanitize(photo).has("house_lights"),"old photos do not invent warm windows")
	var receipts := ReceiptStore.new()
	root.add_child(receipts)
	var controlled = load("res://scripts/game/house_sleep.gd").new(world,receipts)
	root.add_child(controlled)
	controlled.stage = "saving"
	controlled.night = night
	var op: String = controlled.retry()
	controlled.retry()
	check(receipts.requests == 1,"pending receipt excludes duplicate submission")
	receipts.commit_rejected.emit(op,"house-sleep","disk-full")
	check(controlled.failed and controlled.pending.is_empty() and controlled.stage == "saving","failure cannot start morning animation")
	main._on_save_rejected(op,"house-sleep","disk-full")
	var original_house = world.house
	world.house = controlled
	main._retry_save()
	var retry_id: String = controlled.pending
	check(receipts.requests == 2 and main._save_retry_coverage.has(retry_id),"UI retry binds exact failed receipt coverage")
	main._on_save_confirmed(retry_id,"house-sleep")
	receipts.commit_confirmed.emit(retry_id,"house-sleep")
	check(not main._save_problems.has(op) and controlled.stage == "sleep","confirmed retry clears original error and alone starts dawn")
	world.house = original_house
	controlled.free()
	receipts.free()

	main.queue_free()
	await process_frame
	for failure: String in failures: printerr(failure)
	print("house_sleep_suite checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func _check_window_hours(world) -> void:
	var house = world.house
	var old_elapsed: float = world._day_elapsed
	var old_stage: String = house.stage
	# Exercise the real room facts, including failed/pending saves, rather than
	# treating every busy stage (or an outdoor doze) as inside the room.
	for stage: String in ["", "porch", "open", "in", "close", "saving", "sleep", "balcony", "stairs", "wake", "out"]:
		house.stage = stage
		var inside := stage in ["close", "saving", "sleep", "balcony", "stairs", "wake"]
		check(house.inside_room() == inside, "room occupancy follows passage stage " + stage)
		for hour: float in [0.0, 4.99, 5.0, 6.0, 12.0, 19.99, 20.0, 23.99]:
			world._day_elapsed = fposmod(hour - 6.0,24.0) / 24.0 * 600.0
			var expected := hour >= 20.0 or (hour < 5.0 and not inside)
			check((house.window_light_target() == 1.0) == expected,
				"window rule at %.2f with passage %s" % [hour,stage])
	house.stage = ""
	world._day_elapsed = 400.0 # 22:00, traveller outdoors.
	house.lights = 0.0
	house.tick(1.0)
	check(house.lights > 0.0 and house.lights < 1.0, "panes fade in rather than snap")
	world._day_elapsed = 0.0 # Morning after sleep or natural rollover.
	house.tick(1.0)
	check(house.lights == 0.0, "morning fades the outdoor panes out")
	house.stage = old_stage
	world._day_elapsed = old_elapsed
