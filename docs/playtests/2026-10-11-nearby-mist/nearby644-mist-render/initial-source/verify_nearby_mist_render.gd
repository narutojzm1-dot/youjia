extends SceneTree
## Real GPU pixel evidence; controlled environment snapshots, no player-save mutation.
var checks := 0
var failures: Array[String] = []
var canvas: SubViewport
var painting: Sprite2D
var mist: NearPathMist
var output := ""

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)

func picture(reduced: bool, phase: float, state: Dictionary) -> Image:
	mist.apply(true,reduced)
	mist.sync_environment(state,true)
	painting.get_node("FarMist").material.set_shader_parameter("phase",phase)
	await process_frame
	await RenderingServer.frame_post_draw
	return canvas.get_texture().get_image()

func run() -> void:
	output = OS.get_environment("YOUJIA_MIST_CAPTURE")
	if output.is_empty(): push_error("YOUJIA_MIST_CAPTURE required");quit(1);return
	DirAccess.make_dir_recursive_absolute(output)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	canvas = SubViewport.new()
	canvas.size = Vector2i(1672,941)
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	canvas.world_2d = World2D.new()
	root.add_child(canvas)
	painting = Sprite2D.new()
	painting.texture = load(NearPathLayout.ART)
	painting.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	painting.centered = false
	canvas.add_child(painting)
	mist = NearPathMist.new();mist.bind(painting,false)
	var sun := {"weather":"sun","daylight":1.0}
	var a := await picture(false,0.0,sun)
	var b := await picture(false,1.4,sun)
	var reduced := await picture(true,0.0,sun)
	var reduced_later := await picture(true,1.4,sun)
	check(not a.is_empty() and a.get_size() == canvas.size,"full resolution real rendered image exists")
	check(reduced.get_data() == reduced_later.get_data(),"reduced motion is identical over time")
	mist.release()
	await process_frame;await RenderingServer.frame_post_draw
	check(reduced.get_data() == canvas.get_texture().get_image().get_data(),"reduced motion restores exact untouched painting")
	mist = NearPathMist.new();mist.bind(painting,false)
	var mask: Image = NearPathMist.REGIONS.get_image()
	var lake := 0;var ridge := 0;var outside := 0;var painted := 0
	for y in range(941):
		for x in range(1672):
			var coordinate := Vector2i(x,y)-Vector2i(NearPathMist.BOUNDS.position)
			var ink := Color.BLACK
			if Rect2i(Vector2i.ZERO,mask.get_size()).has_point(coordinate):ink=mask.get_pixelv(coordinate)
			if a.get_pixel(x,y) != reduced.get_pixel(x,y):
				painted+=1
				if ink.r == 0.0 and ink.g == 0.0:outside+=1
			if a.get_pixel(x,y) == b.get_pixel(x,y):continue
			if ink.r > 0.0:lake+=1
			elif ink.g > 0.0:ridge+=1
			else:outside+=1
	check(lake>100,"actual lake pixels change between phases")
	check(ridge>100,"actual mountain mist pixels change between phases")
	check(outside==0,"zero touched pixels outside the cropped authored mask")
	check(painted<1672*941*0.025,"mist touches less than 2.5 percent of original painting")
	var states := {}
	for weather: String in ["sun","overcast","rain"]:
		for daylight: float in [1.0,0.0]:
			var state := {"weather":weather,"daylight":daylight}
			var image := await picture(false,0.0,state)
			var name := weather+("-day" if daylight>0.0 else "-night")
			image.save_png(output.path_join(name+".png"))
			states[name]={"strength":mist.strength,"lake_rgb":image.get_pixel(763,432).to_html(),"ridge_rgb":image.get_pixel(648,294).to_html()}
	var lake_before := reduced.get_pixel(763,432)
	var lake_after := a.get_pixel(763,432)
	check(lake_after != lake_before,"cropped shader UV samples the authored lake at its original coordinates")
	a.save_png(output.path_join("phase-0.png"));b.save_png(output.path_join("phase-1.4.png"));reduced.save_png(output.path_join("reduced.png"))
	var result := {"renderer":RenderingServer.get_video_adapter_name(),"method":RenderingServer.get_current_rendering_method(),"checks":checks,"failures":failures,"changed_lake":lake,"changed_ridge":ridge,"painted":painted,"outside_mask":outside,"states":states,"mask_bytes":mask.get_data().size(),"quad_pixels":NearPathMist.BOUNDS.get_area()}
	FileAccess.open(output.path_join("result.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("NEARBY_MIST_RENDER ",JSON.stringify(result))
	root.get_node("AudioDirector").release_streams()
	quit(0 if failures.is_empty() else 1)
