extends SceneTree
func _initialize() -> void:
	call_deferred("_bake")
func _bake() -> void:
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(384,448)
	viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var actor:=ResidentWalker.new()
	viewport.add_child(actor)
	actor.position=Vector2(192,420)
	actor.scale=Vector2(4,4)
	actor.z_index=10
	await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://assets/holiday/characters/resident_walk_authored_v1/idle.png")
	root.get_node("AudioDirector").call("release_streams")
	quit(0)
