extends SceneTree
const View = preload("res://scripts/game/yard_mill_view.gd")
var output := ""
func _initialize() -> void: call_deferred("run")
func run() -> void:
	# Archive reproduction guard only; the original capture hash is in sources.json.
	output = OS.get_environment("YOUJIA_MILL_CAPTURE_DIR")
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
	if output.is_empty() or isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated.trim_suffix("/")+"/"):
		push_error("Set a fresh YOUJIA_MILL_CAPTURE_DIR and isolated APPDATA before capture")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280,720)
	seed(9)
	var world = load("res://scripts/game/yard_world.gd").new()
	world.setup()
	root.add_child(world)
	world.tick(0.0,Vector2.ZERO)
	world.simulation_active = false
	var view = world.mill_view
	var player = world.get_player()
	var radius = player.body_radius * YardGround.depth_at(View.APPROACH.y)
	var route = YardBodies.route(player.position,View.APPROACH,radius,world.physical_obstacles("player"),world.player_ground())
	print("MILL_ROUTE ",route," approachable=",YardBodies.clear_at(View.APPROACH,radius,world.physical_obstacles("player")))
	# Controlled presentation fixture, not a normal-player completion claim.
	player.position = View.APPROACH
	player.facing = -1.0
	player._gait.face = -1.0
	player.tick(0.0,Vector2.ZERO,world.WORLD_SIZE)
	player._sequence_walker.hold_action_frame(&"feed",4)
	for weather in ["sun","overcast"]:
		world.set_weather(weather)
		world._tick_weather_transition(20.0,true)
		view.sync_work(true,0.39,false)
		for i in 3: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output+"/integrated-working-"+weather+".png")
		print("MILL_CAPTURE ",weather," anchor=",view.position," player=",player.position," hand=",player.grass_hand_global_position()," work=",View.WORK_POINT," tint=",view.art.modulate)
	view.sync_work(true,0.79,true)
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/integrated-reduced-overcast.png")
	world.queue_free()
	await process_frame
	quit(0)
