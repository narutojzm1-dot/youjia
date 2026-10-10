extends SceneTree
var main
var elapsed := 0.0
var keys: Array[String] = []
var output := "C:/Users/Zengm/AppData/Local/Temp/youjia-idle639-gpu"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await main._start_holiday()
	main.set_process(false)
	main._world.get_player().position = Vector2(300,580)
	# Controlled fixture: move nearby actors to their own far activity areas.
	for actor in main._world._actors.values(): actor.position = Vector2(900,490)
	main._world._goose_mount_wait = 0.0
	main._world._goose_mount_phase = -1
	for frame: int in 4350:
		main._world.tick(1.0/30.0,Vector2.RIGHT if frame >= 4230 and frame < 4260 else Vector2.ZERO)
		await process_frame
		var rest = main._world.get_player().idle_rest
		var key: String = rest.stage + "-" + str(rest.cel)
		if rest.active() and not key in keys:
			keys.append(key)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output + "/" + key + ".png")
	print("IDLE639 GPU stages=" + str(keys))
	quit(0 if "nap-6" in keys and "rise-7" in keys else 1)
