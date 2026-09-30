extends SceneTree

# A controlled enlarged hero/llama motion comparison, using the actual yard art.
# Run with --fixed-fps 30 and YOUJIA_CAPTURE_DIR set to a fresh output directory.
# Six seconds: right / stop / left / settle. Other cast members are hidden.
var _world: Variant


func _initialize() -> void:
	call_deferred("_record")


func _record() -> void:
	var folder := OS.get_environment("YOUJIA_CAPTURE_DIR")
	if folder.is_empty():
		push_error("Set YOUJIA_CAPTURE_DIR to a writable evidence folder")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(folder)
	var source_hashes := {}
	for path: String in ["res://scripts/entities/sequence_resident.gd", "res://assets/holiday/characters/resident_walk_authored_v1/idle.png", "res://scripts/entities/resident_walker.gd", "res://assets/holiday/characters/approved_resident_upper_v1.png", "res://scripts/entities/painted_walker.gd", "res://assets/holiday/characters/approved_traveler_upper_v1.png", "res://assets/holiday/characters/approved_traveler_pants_v1.png", "res://scripts/entities/native_walker.gd", "res://scenes/native_walker.tscn", "res://scripts/entities/vacationer.gd", "res://scripts/entities/felt_actor.gd", "res://scripts/entities/grounded_gait.gd", "res://scripts/entities/planted_gait.gd", "res://scripts/entities/layered_hero.gd", "res://scripts/entities/layered_llama.gd", "res://assets/holiday/characters/llama_legs_atlas_v1.png", "res://assets/holiday/characters/player_rig_atlas_v1.png", "res://tools/capture_planted_gait.gd"]:
		if FileAccess.file_exists(path):
			source_hashes[path] = FileAccess.get_sha256(path)
	var manifest := FileAccess.open(folder.path_join("manifest.json"), FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"engine": Engine.get_version_info(), "source_sha256": source_hashes, "frames": 180, "fps": 30, "camera_zoom": 2.0, "sequence": "right 1.5s, stop 1s, left 1.5s, settle 2s"}, "  "))
	manifest.close()
	print("[planted-gait-capture] source_sha256: " + JSON.stringify(source_hashes))
	seed(42)
	_world = load("res://scripts/game/yard_world.gd").new()
	root.add_child(_world)
	_world.setup([])
	var player: Variant = _world.get_player()
	var llama: Variant = _world.actor_named("llama")
	if OS.get_environment("YOUJIA_EXPERIMENTAL_LLAMA")=="1" and llama.has_method("enable_experimental_planted_gait"):
		llama.enable_experimental_planted_gait()
	player.position = Vector2(350, 505)
	llama.position = Vector2(650, 505)
	llama.set("_target", Vector2(850, 505))
	llama.state = "wander"
	for id: String in _world.get("_actors").keys():
		if id != "llama":
			_world.actor_named(id).queue_free()
			_world.get("_actors").erase(id)
	# Same camera, original textures and lighting for both revisions.
	var camera := Camera2D.new()
	camera.position = Vector2(535, 455)
	camera.zoom = Vector2(2.0, 2.0)
	root.add_child(camera)
	camera.make_current()
	for frame: int in 180:
		var move := Vector2.ZERO
		if frame < 45:
			move = Vector2.RIGHT
		elif frame >= 75 and frame < 120:
			move = Vector2.LEFT
		if frame == 45 or frame == 120:
			llama.state = "graze"
			llama.set("_idle_time", 20.0)
		elif frame == 75:
			llama.state = "wander"
			llama.set("_target", Vector2(450, 505))
		player.tick(1.0 / 30.0, move, Vector2(1280, 720))
		llama.tick(1.0 / 30.0, Vector2(1280, 720))
		_world.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		var result := picture.save_png(folder.path_join("%04d.png" % frame))
		if result != OK:
			push_error("Frame save failed: " + error_string(result))
			quit(1)
			return
	print("[planted-gait-capture] 180 rendered frames: " + folder)
	root.get_node("AudioDirector").call("release_streams")
	quit(0)
