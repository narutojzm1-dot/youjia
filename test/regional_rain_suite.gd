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
	var store = root.get_node("SaveStore")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	var world = main._world
	world.collected.append("goose_horse_mount")
	await store.flush_pending()
	world._day_elapsed = 150.0
	world.debug_place_player(Vector2(300,545))
	world.gate.toggle()
	await store.flush_pending()
	for i in 10800:
		world._day_elapsed = 150.0
		world.tick(1.0/60.0,Vector2.ZERO)
		var all_out := true
		for id: String in world.shelter.IDS:
			if not world.shelter.outdoors[id].has_point(world.actor_named(id).position): all_out = false
		if all_out and i > 200: break
	for id: String in world.shelter.IDS: check(not world.shelter.inside(world.actor_named(id)),id+" outside before daytime rain")
	world.gate.toggle()
	await store.flush_pending()
	check(not world.gate.opened,"close before rain")
	world.set_weather("rain")
	await store.flush_pending()
	world.tick(1.0/60.0,Vector2.ZERO)
	check(not world.gate.pending.is_empty(),"rain initiates durable gate opening in daylight")
	await store.flush_pending()
	check(world.gate.opened,"rain gate receipt confirmed")
	for i in 14400:
		world._day_elapsed = 150.0
		world.tick(1.0/60.0,Vector2.ZERO)
		if not world.shelter.returning and i > 200: break
	for id: String in world.shelter.IDS:
		check(world.shelter.at_bed(world.actor_named(id)),id+" returns in daylight rain")
	check(world.rain.amount == 1.0 and world._weather_mix == 1.0,"rain shows overcast base and full rain")
	var moment := PhotoMoment.capture(world,ExpressionCatalog.find_rule("cow_pet_gentle"))
	var photo := PhotoMoment.sanitize(JSON.parse_string(JSON.stringify(moment)))
	check(photo.get("weather","") == "rain" and photo.get("rain",{}).get("amount",0.0) == 1.0,"photo JSON retains actual rain")
	var card := PhotoMoment.new()
	root.add_child(card)
	card.setup(photo)
	var recorded: Node = card._stage.get_children().filter(func(n: Node) -> bool: return n.get_script() == load("res://scripts/game/regional_rain.gd"))[0]
	check(recorded.snapshot() == photo.rain,"photo replays the captured rain phase, not current weather")
	check(recorded.layers[0].get_index() < card._shadows.get_index(),"photo pond rings remain below animal shadows and birds")
	check(recorded.layers[0].z_index == 0 and recorded.layers[1].z_index == 0,"photo rain cannot escape album draw order")
	card.queue_free()
	var clock: float = world.rain.clock
	world.simulation_active = false
	world.tick(20.0,Vector2.ZERO)
	check(world.rain.clock == clock,"pause freezes rain and pond ripples")
	root.get_node("TuningStore").set_value("ui.reduced_motion",true)
	check(world.rain.reduced,"reduced motion takes effect while paused")
	world.simulation_active = true
	world.tick(0.1,Vector2.ZERO)
	check(world.rain.clock == clock,"reduced motion does not animate rain")
	root.get_node("TuningStore").set_value("ui.reduced_motion",false)
	world._save_progress()
	await store.flush_pending()
	store._load()
	await main._start_holiday(false)
	main.set_process(false)
	world = main._world
	check(world.weather == "rain" and world.rain.amount == 1.0,"rain survives real save reload")
	for id: String in world.shelter.IDS: check(world.shelter.at_bed(world.actor_named(id)),id+" stays sheltered on rainy reload even with open gate")
	main._on_exploration_requested()
	await store.flush_pending()
	check(main._screen == "exploring","rain permits exploration")
	check(is_instance_valid(main._path_rain) and main._path_rain.amount == 1.0,"near path receives same rain")
	check(not main._path_rain.pond,"yard pond mask never leaks into near path")
	var remaining: float = world.environment_snapshot().weather_remaining
	main._process(1.0)
	check(is_equal_approx(world.environment_snapshot().weather_remaining,remaining-1.0),"travel consumes one regional weather clock")
	var travel_clock: float = main._path_rain.clock
	main._pause_screen.show()
	main._process(10.0)
	check(main._path_rain.clock == travel_clock,"travel pause freezes rain")
	main._pause_screen.hide()
	main._exploration.interrupt()
	await store.flush_pending()
	check(main._screen == "game" and world.weather == "rain","return keeps same rain episode")
	world.set_weather("sun")
	await store.flush_pending()
	world.collected.append("goose_horse_mount")
	for i in 10800:
		world._day_elapsed = 150.0
		world.tick(1.0/60.0,Vector2.ZERO)
		var all_out := true
		for id: String in world.shelter.IDS:
			if not world.shelter.outdoors[id].has_point(world.actor_named(id).position): all_out = false
		if all_out and i > 200: break
	for id: String in world.shelter.IDS: check(not world.shelter.inside(world.actor_named(id)),id+" returns outdoors after rain stops")
	check(world.rain.amount == 0.0,"rain fades out")
	var valid: Dictionary = world._regional_weather.snapshot()
	world.set_weather("invalid")
	check(world._regional_weather.snapshot() == valid and world.weather == "sun","invalid selection cannot desync public weather")
	world.toggle_weather()
	check(world.weather == "overcast","weather button sun to overcast")
	world.toggle_weather()
	check(world.weather == "rain","weather button overcast to rain")
	world.toggle_weather()
	check(world.weather == "sun","weather button rain to sun")
	await store.flush_pending()
	main.queue_free()
	await process_frame
	root.get_node("AudioDirector").release_streams()
	print("REGIONAL_RAIN checks=%d failures=%d" % [checks,failures.size()])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
