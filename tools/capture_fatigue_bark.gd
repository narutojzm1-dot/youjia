extends SceneTree
## Native render. Default uses an explicit clock fixture; NATURAL_NIGHT waits
## for the unchanged production clock with no time/inventory/save injection.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	var output := OS.get_environment("YOUJIA_FATIGUE_CAPTURE")
	var natural := OS.get_environment("YOUJIA_FATIGUE_NATURAL_NIGHT") == "1"
	if isolated.is_empty() or output.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	var store = root.get_node("SaveStore")
	await store.flush_pending()
	# Move only the clock fixture to just before a natural morning. Production
	# World + SaveStore must confirm the transition; never call show_bark here.
	if not natural:
		main._world._day_elapsed = 599.9
		main._world.advance_world_time(0.2)
		await store.flush_pending()
	print("FATIGUE_RENDER_START natural=%s day=%s elapsed=%s cause=%s" % [natural, store.get_holiday_day(), main._world._day_elapsed, store.get_rest_context().cause])
	var started := Time.get_ticks_msec()
	var night_saved := false
	while Time.get_ticks_msec() - started < (660000 if natural else 30000):
		await process_frame
		if natural and not night_saved and main._world._day_elapsed >= 450.0:
			night_saved = true
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output + ".midnight.png")
			print("NATURAL_MIDNIGHT day=%s elapsed=%s cause=%s" % [store.get_holiday_day(), main._world._day_elapsed, store.get_rest_context().cause])
		if main._resident_bubble.is_showing() and main._resident_bubble._label.text == root.get_node("I18n").t("bark.fatigue_sleepy"):
			await RenderingServer.frame_post_draw
			var error := root.get_texture().get_image().save_png(output)
			print("FATIGUE_RENDER day=%s cause=%s elapsed_ms=%s error=%s" % [store.get_holiday_day(), store.get_rest_context().cause, Time.get_ticks_msec() - started, error])
			main.queue_free()
			await process_frame
			quit(0 if error == OK else 1)
			return
	push_error("Fatigue did not trigger in the production Main loop")
	quit(1)
