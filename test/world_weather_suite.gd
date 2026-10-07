extends SceneTree
const Weather := preload("res://scripts/game/world_weather.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return
	var climate = Weather.new()
	climate.restore({"weather":"sun", "remaining":300.0, "seed":565, "episode":0})
	climate.advance(299.0)
	check(climate.state.weather == "sun" and climate.state.remaining == 1.0, "no premature weather change")
	var restored = Weather.new()
	restored.restore(JSON.parse_string(JSON.stringify(climate.snapshot())))
	var same := 0
	var changed := 0
	for i in 80:
		var before: String = climate.state.weather
		var duration: float = climate.state.remaining
		climate.advance(duration)
		restored.advance(duration)
		check(climate.snapshot() == restored.snapshot(), "reopened weather follows same random sequence")
		check(climate.state.remaining >= 300 and climate.state.remaining <= 1800, "half-day to three-day episodes")
		if before == climate.state.weather: same += 1
		else: changed += 1
	check(same > 0 and changed > 0, "random choices include staying and changing, not fixed alternation")
	var stable: Dictionary = climate.snapshot()
	climate.advance(NAN)
	climate.advance(-5)
	check(climate.snapshot() == stable, "invalid delta cannot corrupt weather")
	check(Weather.sanitize({"weather":"sun", "remaining":INF,"seed":1,"episode":0}).is_empty(), "invalid stored duration rejected")
	for key: String in ["remaining", "seed", "episode"]:
		for invalid: Variant in [null, [], {}, true, "5", NAN, INF]:
			var bad: Dictionary = stable.duplicate(true)
			bad[key] = invalid
			check(Weather.sanitize(bad).is_empty(), "malformed weather field rejected without coercion: " + key)
	for key: String in ["seed", "episode"]:
		var bad: Dictionary = stable.duplicate(true)
		bad[key] = 1.5
		check(Weather.sanitize(bad).is_empty(), "fractional sequence field rejected")
	var store = root.get_node("SaveStore")
	check(await store.flush_pending(), "native store initialized")
	store.request_yard_progress(7, 123.5, 0, 0, -1, stable)
	check(await store.flush_pending(), "weather and clock committed together")
	store._load()
	check(store.get_world_weather() == stable and store.get_holiday_day() == 7 and store.get_holiday_day_elapsed() == 123.5, "native reload restores weather and clock")
	store.request_yard_progress(7, 124, 0, 0, -1)
	check(await store.flush_pending(), "legacy yard caller still commits")
	check(store.get_world_weather() == stable, "legacy caller does not erase climate")
	var world = load("res://scripts/game/yard_world.gd").new()
	root.add_child(world)
	world.setup([], {}, 7, 590, {}, false, {}, {"weather":"overcast", "remaining":1000.0,"seed":565,"episode":0})
	var animal_position: Vector2 = world.actor_named("sheep_b").position
	world.advance_world_time(20)
	check(world.holiday_day == 8 and world._day_elapsed == 10, "shared clock crosses day while away")
	check(world.weather == "overcast" and world.environment_snapshot().weather_remaining == 980, "away clock consumes same weather episode")
	check(world.actor_named("sheep_b").position == animal_position, "away clock does not move hidden residents")
	var snapshot: Dictionary = world.environment_snapshot()
	snapshot.weather = "fake"
	check(world.weather == "overcast", "snapshot cannot mutate world")
	world._save_progress()
	check(await store.flush_pending(), "away progress durable")
	store._load()
	check(store.get_world_weather().remaining == 980 and store.get_holiday_day() == 8, "away clock and weather reload together")
	world.free()
	root.get_node("AudioDirector").release_streams()
	print("WORLD_WEATHER checks=%d failures=%d" % [checks, failures.size()])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
