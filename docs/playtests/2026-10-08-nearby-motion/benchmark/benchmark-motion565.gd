extends SceneTree
var target: SubViewport
var painting: Sprite2D
var motion: NearPathMotion

func _initialize() -> void: call_deferred("run")

func sample(reduced: bool) -> Dictionary:
	motion.apply(true, reduced)
	var rows := []
	for frame in 150:
		motion.advance(1.0/60.0, reduced)
		await process_frame
		await RenderingServer.frame_post_draw
		if frame >= 30:
			rows.append({"cpu_ms": RenderingServer.viewport_get_measured_render_time_cpu(target.get_viewport_rid()), "gpu_ms": RenderingServer.viewport_get_measured_render_time_gpu(target.get_viewport_rid()), "draws": RenderingServer.viewport_get_render_info(target.get_viewport_rid(), RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)})
	return {"reduced": reduced, "samples": rows}

func run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	target = SubViewport.new()
	target.world_2d = World2D.new()
	target.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(target)
	RenderingServer.viewport_set_measure_render_time(target.get_viewport_rid(), true)
	painting = Sprite2D.new()
	painting.centered = false
	painting.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	painting.texture = load("res://assets/holiday/exploration/near_path_02.webp")
	target.add_child(painting)
	motion = NearPathMotion.new()
	motion.bind(painting, false)
	var camera := Camera2D.new()
	target.add_child(camera)
	camera.make_current()
	var rows := []
	for css: Vector2i in [Vector2i(390,844),Vector2i(844,390),Vector2i(1280,720)]:
		target.size = css * 2
		var frame: Dictionary = NearPathLayout.frame(NearPathLayout.point("lane",195.0),Vector2(css))
		camera.position = frame.camera
		camera.zoom = Vector2.ONE * float(frame.zoom) * 2.0
		var still: Dictionary = await sample(true)
		var before := target.get_texture().get_image()
		var moving: Dictionary = await sample(false)
		var painted := target.get_texture().get_image()
		var reverse: Dictionary = await sample(true)
		var after := target.get_texture().get_image()
		var prefix := OS.get_environment("YOUJIA_MOTION_BENCH").get_basename() + "-" + str(css.x)
		painted.save_png(prefix + "-moving.png")
		after.save_png(prefix + "-static.png")
		rows.append({"css":css,"dpr":2,"physical":target.size,"actual_paint_pixels":before.get_used_rect().size,"phase_pixels_differ":before.get_data()!=painted.get_data(),"static_pixels_restore":before.get_data()==after.get_data(),"static_before":still,"moving":moving,"static_after":reverse})
	var result := {"source":"2179e80e481797b195529108c197c19323cb87bb","renderer":RenderingServer.get_video_adapter_name(),"method":RenderingServer.get_current_rendering_method(),"scope":"isolated painting only; desktop GPU, not physical mobile or total game FPS","mask_bytes":NearPathMotion.REGIONS.get_image().get_data().size(),"rows":rows}
	var file := FileAccess.open(OS.get_environment("YOUJIA_MOTION_BENCH"),FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t")+"\n")
	print("MOTION_GPU_BENCH_COMPLETE ",result.renderer," mask_bytes=",result.mask_bytes)
	root.get_node("AudioDirector").release_streams()
	quit()
