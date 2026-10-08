extends SceneTree
## Run with a real renderer, not the headless dummy renderer. No save mutation.
var checks := 0
var failures: Array[String] = []
var canvas: SubViewport
var painting: Sprite2D
var motion: NearPathMotion
var output := ""

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)

func picture(reduced: bool, phase: float) -> Image:
	motion.apply(true, reduced)
	if not reduced: painting.material.set_shader_parameter("phase", phase)
	await process_frame
	await RenderingServer.frame_post_draw
	return canvas.get_texture().get_image()

func run() -> void:
	output = OS.get_environment("YOUJIA_MOTION_CAPTURE")
	if output.is_empty(): push_error("YOUJIA_MOTION_CAPTURE output directory required"); quit(1); return
	DirAccess.make_dir_recursive_absolute(output)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	canvas = SubViewport.new()
	canvas.size = Vector2i(1672, 941)
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	canvas.world_2d = World2D.new()
	root.add_child(canvas)
	painting = Sprite2D.new()
	painting.texture = load("res://assets/holiday/exploration/near_path_02.webp")
	painting.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	painting.centered = false
	canvas.add_child(painting)
	motion = NearPathMotion.new()
	motion.bind(painting, false)
	var a := await picture(false, 0.0)
	var b := await picture(false, 1.4)
	var still_a := await picture(true, 0.0)
	var still_b := await picture(true, 2.1)
	check(not a.is_empty() and a.get_size() == canvas.size, "real full-resolution capture exists")
	check(a.get_data() != b.get_data(), "ordinary phase changes actual pixels")
	check(still_a.get_data() == still_b.get_data(), "reduced motion is pixel-identical over time")
	painting.material = null
	await process_frame
	await RenderingServer.frame_post_draw
	check(still_a.get_data() == canvas.get_texture().get_image().get_data(), "reduced motion equals untouched painting")
	var mask: Image = NearPathMotion.REGIONS.get_image()
	var changed_water := 0
	var changed_foliage := 0
	var leaked := 0
	var changed := 0
	for y in range(941):
		for x in range(1672):
			if a.get_pixel(x,y) == b.get_pixel(x,y): continue
			changed += 1
			var zone := mask.get_pixel(x,y)
			if zone.r > 0.0: changed_water += 1
			elif zone.g > 0.0: changed_foliage += 1
			else: leaked += 1
	check(changed_water > 100, "creek interiors visibly animate")
	check(changed_foliage > 100, "leaf/grass interiors visibly animate")
	check(leaked == 0, "zero changed pixels outside authored mask")
	check(changed < 1672 * 941 * 0.03, "motion stays below three percent of painting")
	a.save_png(output.path_join("phase-0.png"))
	b.save_png(output.path_join("phase-1.4.png"))
	still_a.save_png(output.path_join("reduced.png"))
	var metrics := {"renderer": RenderingServer.get_video_adapter_name(), "method": RenderingServer.get_current_rendering_method(), "checks": checks, "failures": failures, "changed_water": changed_water, "changed_foliage": changed_foliage, "changed_total": changed, "outside_mask": leaked}
	var file := FileAccess.open(output.path_join("result.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics, "\t") + "\n")
	print("NEARBY_MOTION_RENDER ", JSON.stringify(metrics))
	root.get_node("AudioDirector").release_streams()
	quit(0 if failures.is_empty() else 1)
