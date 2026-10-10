extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	assert(not isolated.is_empty() and OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated))
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	main._world._day_elapsed = 150.0
	main._world.set_weather("rain")
	for id in main._world.shelter.ALL_IDS: main._world.actor_named(id).position = main._world.shelter.BEDS[id]
	for i in 90: main._process(1.0/30.0)
	for id in ["cow", "sheep_a", "sheep_b"]:
		var actor = main._world.actor_named(id)
		actor._blink.wait_left = 0.0
		for i in 8: actor.tick(1.0/60.0, Vector2(1280,720))
	var moment := PhotoMoment.capture(main._world, ExpressionCatalog.find_rule("cow_pet_gentle"))
	var store = root.get_node("SaveStore")
	assert(not store.request_album(PackedStringArray(["cow_pet_gentle"]), {"cow_pet_gentle":moment}).is_empty())
	await store.flush_pending()
	var captured := {}
	for item in moment.items:
		if item.get("subject", "") in main._world.shelter.ALL_IDS:
			captured[item.subject] = {"breath":item.gait.rest_breath_shift,"blink":item.gait.blink_amount}
	for i in 180: main._process(1.0/30.0)
	store._load()
	var restored: Dictionary = store.get_photo_moment("cow_pet_gentle")
	var count := 0
	for item in restored.items:
		if captured.has(item.get("subject", "")):
			assert(absf(float(item.gait.rest_breath_shift) - float(captured[item.subject].breath)) < 0.000000000001)
			assert(absf(float(item.gait.blink_amount) - float(captured[item.subject].blink)) < 0.000000000001)
			count += 1
	assert(count == 5)
	for id in ["cow", "sheep_a", "sheep_b"]: assert(captured[id].blink > 0.99)
	var picture := PhotoMoment.new()
	root.add_child(picture)
	picture.setup(restored)
	for i in 3: await process_frame
	print("RESTING_EYELIDS_DISK five frozen chest offsets and three closed eyelids survive real disk reload and PhotoMoment replay: ",JSON.stringify(captured))
	picture.queue_free()
	main.queue_free()
	await process_frame
	root.get_node("AudioDirector").release_streams()
	quit(0)
