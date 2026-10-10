extends SceneTree
const NightSky := preload("res://scripts/game/regional_night_sky.gd")
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
	for minute in 1440:
		var h := float(minute) / 60.0
		var amount := NightSky.night_strength(fraction(h))
		check(is_finite(amount) and amount >= 0.0 and amount <= 1.0, "finite night strength")
		check(absf(amount - NightSky.night_strength(fraction(h + 1.0 / 60.0))) < 0.032, "no midnight/dawn/sunset jump")
		if h >= 5.8 and h <= 20.0: check(amount < 0.0001, "daytime hidden")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	var world = main._world
	world.weather = "sun"
	world._day_elapsed = fraction(1.0) * world.DAY_DURATION_SECONDS
	main._update_tod_tint(world.tod_fraction())
	var sky = main._yard_night_sky
	check(main._night_sky_overlay.visible and sky.amount == 1.0, "clear midnight sky visible")
	check(sky.get_parent() == world and sky.z_index == -1, "sky shares background layer")
	check(sky.get_index() > world._weather_cloud_pairs[3][1].get_index(), "opaque painted cloud bands do not erase the sky layer")
	check(sky.texture == world._backdrop.texture and sky.transform == world._backdrop.transform, "sky uses actual painted mask coordinates")
	var phase: float = sky.material.get_shader_parameter("phase")
	main._pause_screen.show()
	main._process(10.0)
	check(sky.material.get_shader_parameter("phase") == phase, "pause freezes twinkle and world clock")
	main._pause_screen.hide()
	world.weather = "rain"
	main._update_tod_tint(world.tod_fraction(), 1.0 / 60.0)
	check(sky.amount < 1.0 and sky.amount > 0.95, "weather fades instead of flashing")
	for i in 600: main._update_tod_tint(world.tod_fraction(), 1.0 / 60.0)
	check(not main._night_sky_overlay.visible, "rain hides celestial light")
	world.weather = "overcast"
	main._update_tod_tint(world.tod_fraction())
	check(not main._night_sky_overlay.visible, "cloudy night has no stars")
	world.weather = "sun"
	main._update_tod_tint(world.tod_fraction())
	root.get_node("TuningStore").set_value("ui.reduced_motion", true)
	main._update_tod_tint(world.tod_fraction())
	check(sky.material.get_shader_parameter("phase") == 0.0, "reduced motion uses static stars")
	root.get_node("TuningStore").set_value("ui.reduced_motion", false)
	var photo := PhotoMoment.capture(world, ExpressionCatalog.find_rule("cow_pet_gentle"))
	photo = PhotoMoment.sanitize(JSON.parse_string(JSON.stringify(photo)))
	check(photo.get("night_sky", {}) == sky.snapshot(), "photo JSON freezes the actual celestial light")
	check(photo.items.filter(func(item: Dictionary) -> bool: return item.subject.is_empty() and item.kind == "sprite" and item.texture == world._backdrop.texture.resource_path).is_empty(), "photo never captures sky as an opaque background copy")
	var card := PhotoMoment.new()
	root.add_child(card)
	card.setup(photo)
	var replay: Array = card._stage.get_children().filter(func(n: Node) -> bool: return n.get_script() == NightSky)
	check(replay.size() == 1 and replay[0].snapshot() == sky.snapshot(), "album reconstructs frozen sky without a clock")
	if replay.size() == 1:
		check(replay[0].z_index == 0 and replay[0].get_index() < card._shadows.get_index(), "photo sky remains clipped behind all residents")
	card.queue_free()
	for invalid in [{"amount": NAN, "phase": 0}, {"amount": 1, "phase": INF}, {"amount": 2, "phase": 0}, {"amount": 1, "phase": -1}, {}]:
		check(NightSky.sanitize(invalid).is_empty(), "invalid optional sky data rejected")
	var legacy: Dictionary = photo.duplicate(true)
	legacy.erase("night_sky")
	check(not PhotoMoment.sanitize(legacy).is_empty(), "legacy photographs remain valid")
	main._on_exploration_requested()
	await root.get_node("SaveStore").flush_pending()
	main._update_tod_tint(world.tod_fraction())
	var path_sky = main._path_night_sky
	check(main._screen == "exploring" and is_instance_valid(path_sky), "nearby receives shared night sky")
	if is_instance_valid(path_sky):
		check(path_sky.amount == 1.0 and path_sky.material.get_shader_parameter("phase") == phase, "travel keeps one solar phase")
		check(path_sky.get_index() == main._exploration.scroll.painting.get_index() + 1, "nearby sky stays behind items")
		check(path_sky.material.get_shader_parameter("sky_bounds") != sky.material.get_shader_parameter("sky_bounds"), "nearby uses its own authored horizon")
	main._exploration.interrupt()
	await root.get_node("SaveStore").flush_pending()
	main._update_tod_tint(world.tod_fraction())
	check(main._yard_night_sky == sky, "return reuses original layer")
	world._save_progress()
	await root.get_node("SaveStore").flush_pending()
	root.get_node("SaveStore")._load()
	await main._start_holiday(false)
	main.set_process(false)
	main._update_tod_tint(main._world.tod_fraction())
	check(main._yard_night_sky.get_parent() == main._world, "reload never reuses a queued old-world layer")
	check(main._yard_night_sky.amount == 1.0 and main._night_sky_overlay.visible, "real save reload recovers clear midnight light")
	main.queue_free()
	await process_frame
	root.get_node("AudioDirector").release_streams()
	print("REGIONAL_NIGHT_SKY checks=%d failures=%d" % [checks, failures.size()])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
