extends SceneTree
## Art calibration only. No resident state, feeding or relationship gameplay.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var output := OS.get_environment("YOUJIA_CAPTURE_DIR")
	if output.is_empty(): quit(2); return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	var world: Node2D = load("res://scripts/game/yard_world.gd").new()
	root.add_child(world)
	world.setup()
	world.debug_place_player(Vector2(455, 610))
	world.tick(0.0, Vector2.ZERO)
	var camera := Camera2D.new()
	world.add_child(camera)
	camera.position = Vector2(640, 360)
	camera.make_current()
	var path := ProjectSettings.globalize_path("res://art/candidates/pond-stories-2026-10-07/")
	for spec: Dictionary in [
		{"file": "beibei-search-v1.png", "anchor": Vector2(700, 1090), "scale": 72.0 / 1089.0, "point": Vector2(560, 580)},
		{"file": "turtle-v2.png", "anchor": Vector2(710, 800), "scale": 90.0 / 1307.0, "point": Vector2(600, 650)},
		{"file": "hen-v1.png", "anchor": Vector2(650, 1195), "scale": 56.0 / 1160.0, "point": Vector2(515, 635)},
		{"file": "chick-v1.png", "anchor": Vector2(680, 1100), "scale": 25.0 / 989.0, "point": Vector2(476, 645)},
	]:
		var sprite := Sprite2D.new()
		var pixels := Image.load_from_file(path + spec.file)
		sprite.texture = ImageTexture.create_from_image(pixels)
		sprite.centered = false
		sprite.offset = -spec.anchor
		sprite.position = spec.point
		sprite.scale = Vector2.ONE * spec.scale
		sprite.z_index = roundi(sprite.position.y)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		world.add_child(sprite)
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var label := Label.new()
	label.text = "F 原画候选 · 比例检查（无玩法接入）"
	label.position = Vector2(20, 20)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("503d2a"))
	layer.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg(output + "/pond-candidates-1280.jpeg", 0.9)
	print("POND_CANDIDATE_CAPTURE complete")
	quit()
