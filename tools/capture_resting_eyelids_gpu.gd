extends SceneTree
const Blink := preload("res://scripts/entities/painted_blink.gd")
var failures := 0
var viewport: SubViewport
func _initialize() -> void: call_deferred("run")
func pixels() -> Image:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()
func run() -> void:
	var folder := OS.get_environment("YOUJIA_CAPTURE_DIR")
	if folder.is_empty(): quit(2); return
	DirAccess.make_dir_recursive_absolute(folder)
	viewport = SubViewport.new()
	viewport.size = Vector2i(384,384)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var sprite := Sprite2D.new()
	sprite.position = Vector2(192,192)
	sprite.scale = Vector2(0.3,0.3)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	viewport.add_child(sprite)
	var results := []
	for profile in ["sheep_a_rest", "sheep_b_rest"]:
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://shaders/felt_walk.gdshader")
		sprite.material = mat
		var b := Blink.new()
		b.bind(mat, profile)
		sprite.texture = load(b.source_path)
		var baseline: Image = await pixels()
		mat.set_shader_parameter("blink_amount",1.0)
		var peak: Image = await pixels()
		var changed := 0
		var outside := 0
		var alpha_changed := 0
		var ra: Vector4 = mat.get_shader_parameter("blink_eye_a")
		var rb: Vector4 = mat.get_shader_parameter("blink_eye_b")
		for y in 384:
			for x in 384:
				var before := baseline.get_pixel(x,y)
				var after := peak.get_pixel(x,y)
				if before.a != after.a: alpha_changed += 1
				if before.is_equal_approx(after): continue
				changed += 1
				var extent := Vector2(sprite.texture.get_size()) * sprite.scale
				var uv := (Vector2(x,y)+Vector2(0.5,0.5)-sprite.position+extent*0.5)/extent
				if not Rect2(ra.x,ra.y,ra.z,ra.w).grow(0.5/384.0).has_point(uv) and not Rect2(rb.x,rb.y,rb.z,rb.w).grow(0.5/384.0).has_point(uv):
					outside += 1
					if outside <= 5: print("OUTSIDE ",Vector2i(x,y)," ",before," -> ",after," uv=",uv," regions=",ra," ",rb)
		sprite.material = PhotoMoment._load_gait(PhotoMoment._sanitize_gait({"blink_amount":1.0}), b.source_path)
		var replay: Image = await pixels()
		var replay_diff := 0
		for y in 384:
			for x in 384:
				if not peak.get_pixel(x,y).is_equal_approx(replay.get_pixel(x,y)): replay_diff += 1
		if changed == 0 or outside > 0 or alpha_changed > 0 or replay_diff > 0: failures += 1
		baseline.save_png(folder.path_join(profile+"-open.png"))
		peak.save_png(folder.path_join(profile+"-closed.png"))
		var result := {"profile":profile,"changed_pixels":changed,"outside_eyes":outside,"alpha_changed":alpha_changed,"frozen_photo_diff":replay_diff}
		print("RESTING_EYELIDS_GPU ",JSON.stringify(result))
		results.append(result)
	var file := FileAccess.open(folder.path_join("eyelids-gpu-results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t"))
	file.close()
	print("RESTING_EYELIDS_GPU failures=",failures)
	quit(1 if failures else 0)
