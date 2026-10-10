extends SceneTree
# Controlled initial rain/bed fixture, then continuous ordinary Main processing.
var frames := 0
var main: Node
var folder := ""
func _initialize() -> void: call_deferred("run")
func run() -> void:
	folder = OS.get_environment("YOUJIA_CAPTURE_DIR")
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if folder.is_empty() or isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated): quit(2); return
	DirAccess.make_dir_recursive_absolute(folder)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	main._world._day_elapsed = 150.0
	main._world.collected.append("goose_horse_mount")
	main._world.set_weather("rain")
	for id in main._world.shelter.ALL_IDS: main._world.actor_named(id).position = main._world.shelter.BEDS[id]
	var goose = main._world.actor_named("goose")
	goose.state = "rest"
	goose._idle_time = 120.0
	goose._velocity = Vector2.ZERO
	goose._gait.weight = 0.0
	goose.set_expression("idle")
	for i in 90: main._process(1.0/30.0)
	for frame in 540:
		if frame == 300:
			root.get_node("TuningStore").set_value("ui.reduced_motion", true, false)
		if frame == 360:
			root.get_node("TuningStore").set_value("ui.reduced_motion", false, false)
		if frame == 420:
			main._world.set_weather("sun")
			main._world._day_elapsed = 150.0
		main._process(1.0/30.0)
		await process_frame
		if frame in [120,300,419,539] or main._world.actor_named("sheep_a")._blink.amount > 0.99 or main._world.actor_named("sheep_b")._blink.amount > 0.99:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder.path_join("yard-%03d.png" % frame))
		if frame % 60 == 0:
			var states := {}
			for id in main._world.shelter.ALL_IDS + ["goose"]:
				var a = main._world.actor_named(id)
				states[id] = {"cel":a._posture_id,"state":a.state,"breath":a._gait._material.get_shader_parameter("rest_breath_shift"),"blink":0.0 if a._blink == null else a._blink.amount,"position":[a.position.x,a.position.y]}
			print("RESTING_EYELIDS_FRAME ",frame," ",JSON.stringify(states))
	main.queue_free()
	await process_frame
	root.get_node("AudioDirector").release_streams()
	print("RESTING_EYELIDS_CONTINUOUS completed")
	quit(0)
