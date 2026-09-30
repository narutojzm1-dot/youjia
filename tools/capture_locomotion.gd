extends SceneTree

# Deterministic real-renderer recording: run with --fixed-fps 30 and an output
# folder in YOUJIA_CAPTURE_DIR. Each PNG is captured after the rendered frame.
var _frame := 0
var _world: Variant
var _folder := ""

func _initialize() -> void:
	call_deferred("_record")

func _record() -> void:
	_folder = OS.get_environment("YOUJIA_CAPTURE_DIR")
	if _folder.is_empty():
		push_error("Set YOUJIA_CAPTURE_DIR to a writable evidence folder")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_folder)
	var source_hashes := {}
	for path: String in ["res://scripts/entities/native_walker.gd", "res://scenes/native_walker.tscn", "res://scripts/entities/vacationer.gd", "res://scripts/entities/felt_actor.gd", "res://scripts/entities/grounded_gait.gd", "res://scripts/entities/planted_gait.gd", "res://scripts/entities/layered_hero.gd", "res://scripts/entities/layered_llama.gd", "res://scripts/game/yard_world.gd", "res://tools/capture_locomotion.gd"]:
		if FileAccess.file_exists(path):
			source_hashes[path] = FileAccess.get_sha256(path)
	var manifest := FileAccess.open(_folder.path_join("manifest.json"), FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"engine": Engine.get_version_info(), "source_sha256": source_hashes, "frames": 150, "fps": 30}, "  "))
	manifest.close()
	print("[locomotion-capture] source_sha256: " + JSON.stringify(source_hashes))
	seed(42)
	_world = load("res://scripts/game/yard_world.gd").new()
	root.add_child(_world)
	_world.setup([])
	# Keep the same deterministic route and expression for before/after.
	_world.debug_place_player(Vector2(340, 505))
	_world.actor_named("cow").position = Vector2(455, 480)
	_world.actor_named("cow").set("_target", Vector2(605, 480))
	_world.actor_named("llama").position = Vector2(610, 485)
	_world.actor_named("llama").set("_target", Vector2(780, 490))
	_world.actor_named("goose").position = Vector2(800, 505)
	_world.actor_named("goose").set("_target", Vector2(700, 505))
	# Avoid camera and UI transitions: capture the actual yard simulation.
	for frame: int in 150:
		var move := Vector2.RIGHT if frame < 72 else Vector2.ZERO
		if frame >= 96:
			move = Vector2.LEFT
		_world.tick(1.0 / 30.0, move)
		await process_frame
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		var result := picture.save_png(_folder.path_join("%04d.png" % frame))
		if result != OK:
			push_error("Frame save failed: " + error_string(result))
			quit(1)
			return
	print("[locomotion-capture] 150 rendered frames: " + _folder)
	root.get_node("AudioDirector").call("release_streams")
	quit(0)
