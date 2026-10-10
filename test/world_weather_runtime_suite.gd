extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func settle(store: Node) -> void:
	check(await store.flush_pending(), "native commit acknowledged")
	for i in 3: await process_frame
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return
	var store = root.get_node("SaveStore")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	await settle(store)
	check(not store.get_world_weather().is_empty(), "first weather seed saved before periodic checkpoint")
	main._on_exploration_requested()
	await settle(store)
	check(main._screen == "exploring", "production exploration entered")
	var before: Dictionary = main._world.environment_snapshot()
	var feet: Vector2 = main._world.actor_named("sheep_b").position
	main._process(20.0)
	check(is_equal_approx(main._world._day_elapsed, before.elapsed + 20.0), "production exploring branch advances shared clock once")
	check(is_equal_approx(main._world.environment_snapshot().weather_remaining, before.weather_remaining - 20.0), "production exploring branch consumes same weather episode")
	check(main._world.actor_named("sheep_b").position == feet, "hidden animals stationary")
	var light_before: Color = main._tod_rect.color
	check(light_before == preload("res://scripts/game/world_daylight.gd").tint(main._world.tod_fraction(), main.TOD_COLORS), "exploring refreshes actual shared light from advancing clock")
	main._pause_screen.show()
	main._process(30.0)
	check(is_equal_approx(main._world._day_elapsed, before.elapsed + 20.0), "pause freezes shared travel clock")
	check(main._tod_rect.color == light_before, "pause freezes travel light with clock")
	main._pause_screen.hide()
	main._save_problem_active = true
	main._process(30.0)
	check(is_equal_approx(main._world._day_elapsed, before.elapsed + 20.0), "save problem freezes shared travel clock")
	main._save_problem_active = false
	main._exploration.interrupt()
	await settle(store)
	check(main._screen == "game", "production return completes")
	main._process(0.0)
	check(main._tod_rect.color == light_before, "return retains regional light without resetting time")
	main._save_problem_active = true
	var frozen: float = main._world._day_elapsed
	main._process(30.0)
	check(main._world._day_elapsed == frozen, "save problem freezes yard clock too")
	main._save_problem_active = false
	main._world._save_progress()
	await settle(store)
	var expected: Dictionary = store.get_world_weather()
	var expected_elapsed: float = store.get_holiday_day_elapsed()
	store._load()
	await main._start_holiday(false)
	main.set_process(false)
	var restored: Dictionary = main._world._regional_weather.snapshot()
	check(restored.weather == expected.weather and restored.seed == expected.seed and restored.episode == expected.episode and absf(restored.remaining - expected.remaining) < 0.000001, "fresh yard restores weather sequence and remaining time within JSON precision")
	check(main._world._day_elapsed == expected_elapsed, "fresh yard restores travel clock")
	main.queue_free()
	await process_frame
	root.get_node("AudioDirector").release_streams()
	print("WORLD_WEATHER_RUNTIME checks=%d failures=%d" % [checks, failures.size()])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
