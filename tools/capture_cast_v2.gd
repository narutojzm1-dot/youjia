extends SceneTree

# Actual yard rendering with the accepted hero and complete approved cast.
# Teasing and goose annoyance go through the normal condition evaluator.
func _initialize() -> void:
	call_deferred("_record")

func _record() -> void:
	var folder:=OS.get_environment("YOUJIA_CAPTURE_DIR")
	if folder.is_empty():
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(folder)
	seed(42)
	var world=load("res://scripts/game/yard_world.gd").new()
	root.add_child(world)
	world.setup([])
	world._pose_cast()
	world.debug_place_player(Vector2(760,535))
	world.get_player().tick(0.0,Vector2.ZERO,Vector2(1280,720))
	var timeline: Array=[]
	var frame_count:=1 if OS.get_environment("YOUJIA_CAST_STATIC")=="1" else 240
	for index: int in frame_count:
		if index==45:
			world._evaluate_expressions()
		if index==135:
			world.set_weather("overcast")
			var llama: Variant=world.actor_named("llama")
			var goose: Variant=world.actor_named("goose")
			goose.set_pose(llama.position+Vector2(72,20),goose._base_scale,-1.0)
			goose.current_zone="pasture"
			world._evaluate_expressions()
		world.tick(1.0/30,Vector2.ZERO)
		if index%30==0:
			timeline.append({"frame":index,"llama_expression":world.actor_named("llama").current_expression,"photos":world.collected_count(),"last_photo":world.last_photo})
		await process_frame
		await RenderingServer.frame_post_draw
		var picture:=root.get_texture().get_image()
		picture.save_png(folder.path_join("%04d.png"%index))
		if index==0:
			picture.save_png(folder.path_join("full-scene.png"))
	var hashes: Dictionary={}
	for path: String in ["res://scripts/game/cast_art.gd","res://scripts/game/yard_world.gd","res://scripts/entities/felt_actor.gd","res://scripts/game/expression_catalog.gd","res://assets/holiday/characters/cast_v2/manifest.json","res://tools/capture_cast_v2.gd"]:
		hashes[path]=FileAccess.get_sha256(path)
	var manifest:=FileAccess.open(folder.path_join("manifest.json"),FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"frames":frame_count,"fps":30,"source_sha256":hashes,"interaction_timeline":timeline},"  "))
	print("[cast-v2-capture] "+JSON.stringify(timeline))
	root.get_node("AudioDirector").call("release_streams")
	quit(0)
