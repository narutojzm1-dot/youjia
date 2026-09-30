extends SceneTree

# First approval gate: a motionless, reconstructed painted skeleton in engine.
# Uses the real yard and shows the same assembly near actual size and enlarged.
func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var folder:=OS.get_environment("YOUJIA_CAPTURE_DIR")
	if folder.is_empty():
		push_error("Set YOUJIA_CAPTURE_DIR")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(folder)
	var world=load("res://scripts/game/yard_world.gd").new()
	root.add_child(world)
	world.setup([])
	var player=world.get_player()
	player.position=Vector2(430,525)
	player.tick(0.0,Vector2.ZERO,Vector2(1280,720))
	for id in world.get("_actors").keys():
		world.actor_named(id).visible=false
	var camera:=Camera2D.new()
	camera.position=Vector2(535,455)
	camera.zoom=Vector2(2,2)
	root.add_child(camera)
	camera.make_current()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join("rest-in-yard.png"))
	camera.zoom=Vector2(5,5)
	camera.position=Vector2(430,480)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join("rest-detail.png"))
	root.get_node("AudioDirector").call("release_streams")
	quit(0)
