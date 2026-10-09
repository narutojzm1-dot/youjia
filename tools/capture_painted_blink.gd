extends SceneTree
## Explicit offline GPU art check, never shipped as a player/debug endpoint.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var output := OS.get_environment("YOUJIA_CAPTURE_DIR")
	if output.is_empty():
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640, 640)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var sprite := Sprite2D.new()
	var species := OS.get_environment("YOUJIA_BLINK_SPECIES")
	if species not in ["horse", "sheep_a", "sheep_b", "llama"]: species = "cow"
	var blink := preload("res://scripts/entities/painted_blink.gd").new()
	sprite.position = Vector2(320, 320)
	sprite.scale = Vector2(0.5, 0.5)
	viewport.add_child(sprite)
	var gait := GroundedGait.new()
	gait.setup(sprite, 0.70)
	blink.bind(gait._material, species)
	sprite.texture = load(blink.source_path)
	var frames: Array[Image] = []
	for value: float in [0.0, 0.5, 1.0]:
		gait._material.set_shader_parameter("blink_amount", value)
		await process_frame
		await RenderingServer.frame_post_draw
		var frame := viewport.get_texture().get_image()
		frame.save_png(output.path_join("%s-eye-%d.png" % [species, roundi(value * 100.0)]))
		frames.append(frame)
	var changed := 0
	var outside := 0
	var alpha_changed := 0
	var image_rect := sprite.get_rect()
	var inverse := sprite.get_global_transform().affine_inverse()
	for y in 640:
		for x in 640:
			var a := frames[0].get_pixel(x, y)
			var b := frames[2].get_pixel(x, y)
			if a.a != b.a: alpha_changed += 1
			if a != b:
				changed += 1
				var local := inverse * (Vector2(x, y) + Vector2(0.5, 0.5))
				var uv := (local - image_rect.position) / image_rect.size * 1280.0
				var eye_a := Rect2(Vector2(blink.eye_a.x, blink.eye_a.y), Vector2(blink.eye_a.z, blink.eye_a.w)).grow(2.0)
				var eye_b := Rect2(Vector2(blink.eye_b.x, blink.eye_b.y), Vector2(blink.eye_b.z, blink.eye_b.w)).grow(2.0)
				if not eye_a.has_point(uv) and not eye_b.has_point(uv): outside += 1
	print("BLINK_GPU changed=%d outside=%d alpha_changed=%d" % [changed, outside, alpha_changed])
	viewport.queue_free()
	await process_frame
	quit(0 if changed > 100 and outside == 0 and alpha_changed == 0 else 1)
