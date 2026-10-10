extends SceneTree
## Controlled GPU evidence driver, not a claim of ordinary free play.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return
	var main = load("res://scenes/main.tscn").instantiate()
	seed(641)
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	var world = main._world
	var store = root.get_node("SaveStore")
	await store.flush_pending()
	var climate := OS.get_environment("YOUJIA_BALCONY_WEATHER")
	if climate.is_empty(): climate = "sun"
	world.weather = climate
	world._regional_weather.restore({"weather":climate, "remaining":1800.0, "seed":123, "episode":0})
	world._apply_weather_art()
	var out := OS.get_environment("YOUJIA_BALCONY_EVIDENCE")
	DirAccess.make_dir_recursive_absolute(out)
	for kind: String in world.house.balcony.ACTIVITIES:
		var requested := OS.get_environment("YOUJIA_BALCONY_KIND")
		if not requested.is_empty() and requested != kind: continue
		var next_day := 0
		for day: int in range(1, 60):
			if world.house.balcony.plan(day, "sun") == kind:
				next_day = day
				break
		world.holiday_day = next_day - 1
		world._day_elapsed = 400.0
		world.debug_place_player(world.house.APPROACH)
		world.house.begin()
		var captured: Dictionary = {}
		for frame: int in 1500:
			main._process(1.0 / 30.0)
			if world.house.stage == "saving": await store.flush_pending()
			await process_frame
			await RenderingServer.frame_post_draw
			var balcony = world.house.balcony
			if world.house.stage == "balcony" and balcony.stage == "activity":
				var row := int(balcony.seconds / (0.65 if kind == "brush" else 1.35)) % 2
				if not captured.has(row):
					root.get_texture().get_image().save_png(out.path_join(kind + "-%d.png" % row))
					captured[row] = true
			if not world.house.busy(): break
		print("balcony_visual kind=%s day=%d keys=%d done=%s stage=%s player=%s" % [kind, next_day, captured.size(), not world.house.busy(), world.house.stage, world.get_player().position])
		if captured.size() != 2 or world.house.busy():
			quit(1)
			return
	main.queue_free()
	await process_frame
	quit()
