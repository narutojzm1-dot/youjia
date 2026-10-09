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
	sprite.texture = load("res://assets/holiday/characters/cast_v2/cow_chew.png")
	sprite.position = Vector2(320, 320)
	sprite.scale = Vector2(0.5, 0.5)
	viewport.add_child(sprite)
	var gait := GroundedGait.new()
	gait.setup(sprite, 0.70)
	var blink := preload("res://scripts/entities/painted_blink.gd").new()
	blink.bind(gait._material)
	var frames: Array[Image] = []
	for value: float in [0.0, 0.5, 1.0]:
		gait._material.set_shader_parameter("blink_amount", value)
		await process_frame
		await RenderingServer.frame_post_draw
		var frame := viewport.get_texture().get_image()
		frame.save_png(output.path_join("cow-eye-%d.png" % roundi(value * 100.0)))
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
				if not Rect2(163,388,69,62).has_point(uv) and not Rect2(288,410,117,74).has_point(uv): outside += 1
	print("BLINK_GPU changed=%d outside=%d alpha_changed=%d" % [changed, outside, alpha_changed])
	viewport.queue_free()
	await process_frame
	quit(0 if changed > 100 and outside == 0 and alpha_changed == 0 else 1)
