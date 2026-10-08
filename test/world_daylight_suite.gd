extends SceneTree
const Daylight := preload("res://scripts/game/world_daylight.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func fraction(h: float) -> float: return fposmod(h - 6.0, 24.0) / 24.0
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	var world = main._world
	world.weather = "sun"
	for h in 24:
		var t := fraction(float(h))
		world._day_elapsed = t * world.DAY_DURATION_SECONDS
		var view: Dictionary = world.environment_snapshot()
		check(is_equal_approx(view.hour, float(h)), "shared hour %d" % h)
		var expected := "night" if h < 5 or h >= 20 else ("dawn" if h < 7 else ("morning" if h < 11 else ("noon" if h < 14 else ("afternoon" if h < 18 else "evening"))))
		check(view.phase == expected and main._tod_phase_name(t) == expected, "shared phase %d" % h)
		check(world._wants_night_clouds() == (expected == "night"), "cloud night %d" % h)
		check(world._wants_sunset_clouds() == (expected == "evening"), "cloud sunset %d" % h)
		check(world._wants_morning_clouds() == (expected in ["dawn", "morning"]), "cloud dawn %d" % h)
		main._update_tod_tint(t)
		var light: Color = main._tod_rect.color
		if h >= 20 or h < 5:
			check(light.b > light.r and light.a >= 0.3, "actual night is cool and dim %d" % h)
			# scene_tint multiplies by mix(white, tint, alpha), not tint alone.
			var night_gain := Color.WHITE.lerp(Color(light.r, light.g, light.b), light.a)
			check(night_gain.g < 0.55 and night_gain.b > 0.5, "night visibly dims paint while keeping blue detail %d" % h)
		if h >= 11 and h <= 14: check(is_zero_approx(light.a), "midday remains clear %d" % h)
		check(view.daylight >= 0.0 and view.daylight <= 1.0, "solar strength bounded")
	# Both midnight and the saved day's 06:00 rollover must have no color jump.
	for h in [0.0, 5.0, 6.0, 7.0, 8.0, 11.0, 14.0, 17.0, 18.0, 19.0, 20.0]:
		var a := Daylight.tint(fraction(h - 0.0001), main.TOD_COLORS)
		var b := Daylight.tint(fraction(h + 0.0001), main.TOD_COLORS)
		check(absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)+absf(a.a-b.a) < 0.001, "continuous light across %s" % h)
	check(is_equal_approx(Daylight.daylight(fraction(12)), 1.0), "sun highest at noon")
	check(is_zero_approx(Daylight.daylight(fraction(0))), "no sun at midnight")
	check(Daylight.hour(NAN) == 6.0, "invalid input remains finite")
	world.weather = "overcast"
	check(not world._wants_sunset_clouds() and not world._wants_night_clouds(), "overcast retains its own cloud artwork")
	main.queue_free()
	await process_frame
	root.get_node("AudioDirector").release_streams()
	print("WORLD_DAYLIGHT checks=%d failures=%d" % [checks, failures.size()])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
