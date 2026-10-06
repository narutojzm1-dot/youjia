extends SceneTree

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func run() -> void:
	var tuning := root.get_node("TuningStore")
	tuning.reset_defaults()
	var world = load("res://scripts/game/yard_world.gd").new()
	root.add_child(world)
	world.setup()
	world._weather_timer = 10000.0
	check(ResourceLoader.exists("res://assets/holiday/environment/yard_overcast.png"), "legacy photo background remains loadable")
	check(world.OVERCAST.resource_path.ends_with("yard_overcast_aligned.png"), "new art has persistent distinct path")
	var scale_before: Vector2 = world._backdrop.scale
	world.set_weather("overcast")
	check(is_zero_approx(world._weather_mix), "changing target does not jump")
	world.tick(1.5, Vector2.ZERO)
	check(is_equal_approx(world._weather_mix, 0.5), "halfway weather uses actual half alpha")
	check(world._backdrop.modulate.a == 1.0 and world._weather_backdrop_blend.modulate.a == 0.5, "photo base opaque and overlay records actual mix")
	world.set_weather("sun")
	check(is_equal_approx(world._weather_mix, 0.5), "midpoint reversal continuous")
	world.tick(0.6, Vector2.ZERO)
	check(is_equal_approx(world._weather_mix, 0.3), "reverse moves toward sunny")
	world.set_weather("overcast")
	check(is_equal_approx(world._weather_mix, 0.3), "second reversal continuous")
	world.simulation_active = false
	var scroll: float = world._cloud_scroll
	world.tick(2.0, Vector2.ZERO)
	check(is_equal_approx(world._weather_mix, 0.3) and world._cloud_scroll == scroll, "paused weather and cloud movement freeze")
	tuning.set_value("ui.reduced_motion", true)
	check(world._weather_mix == 1.0, "reduced motion settles immediately even while paused")
	world.set_weather("sun")
	check(world._weather_mix == 0.0, "reduced reverse settles immediately")
	check(world._backdrop.scale == scale_before and world._backdrop.position == Vector2.ZERO, "world backdrop bounds unchanged")
	for phase: float in [0.18, 0.4, 0.8, 0.92]:
		world._day_elapsed = phase * world.DAY_DURATION_SECONDS
		world._apply_weather_art()
		check(world._weather_cloud_pair()[0].texture == world._cloud_texture_for_now(), "TOD uses correct cloud resource")
		check(world._weather_cloud_pair()[0].modulate.a == 1.0, "reduced TOD settles cloud weight")
	check(world._cloud_tint.r < 1.0, "night clouds dim")
	tuning.set_value("environment.filter.enabled", false)
	check(world._backdrop.modulate == Color.WHITE and world._cloud_tint == Color.WHITE, "filter disabled clears all tint")
	tuning.set_value("ui.reduced_motion", false)
	world.simulation_active = false
	var paused_mix: float = world._weather_mix
	var paused_weights: Array = world._weather_cloud_weights.duplicate()
	tuning.set_value("environment.filter.enabled", true)
	check(world._cloud_tint.r < 1.0, "paused filter enable restores night tint immediately")
	var previous_tint: Color = world._cloud_tint
	tuning.set_value("environment.filter.intensity", 0.8)
	check(world._cloud_tint != previous_tint, "paused filter strength updates cloud tint immediately")
	check(world._weather_mix == paused_mix and world._weather_cloud_weights == paused_weights, "filter changes preserve transition weights")
	world.simulation_active = true
	world._day_elapsed = 0.4 * world.DAY_DURATION_SECONDS
	world._apply_weather_art()
	var weights: Array = world._weather_cloud_weights.duplicate()
	world._day_elapsed = 0.8 * world.DAY_DURATION_SECONDS
	world._apply_weather_art()
	check(world._weather_cloud_weights == weights, "TOD change does not snap cloud weights")
	world.tick(1.5, Vector2.ZERO)
	check(world._weather_cloud_weights[2] > 0.0 and world._weather_cloud_weights[2] < 1.0, "sunset cloud crossfade advances")
	# All looping cloud art must remain on the painted world, including the wrap.
	for scroll_at: float in [0.0, 0.25, 320.0, 1279.75]:
		world._cloud_scroll = scroll_at
		world._layout_cloud_bands()
		for pair: Array in world._weather_cloud_pairs:
			var covered := 0.0
			for band: Sprite2D in pair:
				var bounds: Rect2 = band.transform * band.get_rect()
				check(bounds.position.x >= -0.001 and bounds.end.x <= world.WORLD_SIZE.x + 0.001, "visible cloud stays inside painted horizontal bounds at %s" % scroll_at)
				covered += bounds.size.x
			check(is_equal_approx(covered, world.WORLD_SIZE.x), "cloud pair covers full sky without gap or double width at %s" % scroll_at)
	world.free()
	tuning.reset_defaults()
	if failures.is_empty(): print("Weather transition suite passed: %d checks" % checks)
	else:
		for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
