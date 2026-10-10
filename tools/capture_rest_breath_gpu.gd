extends SceneTree
const Breath := preload("res://scripts/entities/painted_rest_breath.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var folder := OS.get_environment("YOUJIA_CAPTURE_DIR")
	if folder.is_empty(): quit(2); return
	DirAccess.make_dir_recursive_absolute(folder)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(384,384)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var sprite := Sprite2D.new()
	sprite.position = Vector2(192,192)
	sprite.scale = Vector2(0.3,0.3)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	viewport.add_child(sprite)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/felt_walk.gdshader")
	sprite.material = mat
	var results: Array = []
	for path: String in Breath.REGIONS:
		sprite.texture = load(path)
		Breath.configure(mat, path)
		mat.set_shader_parameter("rest_breath_shift", 0.0)
		for i in 3: await process_frame
		await RenderingServer.frame_post_draw
		var baseline := viewport.get_texture().get_image()
		mat.set_shader_parameter("rest_breath_shift", Breath.MAX_SHIFT)
		for i in 3: await process_frame
		await RenderingServer.frame_post_draw
		var peak := viewport.get_texture().get_image()
		var region: Vector4 = Breath.REGIONS[path]
		var changed := 0
		var outside := 0
		for y in 384:
			for x in 384:
				if baseline.get_pixel(x,y).is_equal_approx(peak.get_pixel(x,y)): continue
				changed += 1
				var uv := (Vector2(x,y)+Vector2(0.5,0.5))/384.0
				if not Rect2(region.x,region.y,region.z,region.w).grow(0.5/384.0).has_point(uv): outside += 1
		if changed == 0 or outside > 0: failures += 1
		var label := path.get_file().get_basename()
		baseline.save_png(folder.path_join(label+"-baseline.png"))
		peak.save_png(folder.path_join(label+"-peak.png"))
		var record := {"animal":label,"changed_pixels":changed,"outside_chest_pixels":outside}
		results.append(record)
		print("REST_BREATH_GPU ",JSON.stringify(record))
	var file := FileAccess.open(folder.path_join("gpu-results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t"))
	file.close()
	viewport.queue_free()
	await process_frame
	print("REST_BREATH_GPU failures=", failures)
	quit(1 if failures else 0)
