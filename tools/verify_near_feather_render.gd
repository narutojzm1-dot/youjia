extends SceneTree
## Controlled same-composition paint comparison, separate from ordinary-input Web evidence.
var canvas: SubViewport
var ground: Node2D
var modern := false
var anchor := Vector2(1240,668)
var output := ""

func _initialize() -> void:call_deferred("run")

func draw_find() -> void:
	var size := 1.6 * NearPathLayout.depth(anchor.y)
	if modern:NearGroundFindArt.draw(ground,"formal.find.feather",anchor,size)
	else:KeepsakeArt.draw(ground,"formal.find.feather",anchor,size,true)

func image(updated: bool) -> Image:
	modern=updated;ground.queue_redraw()
	await process_frame;await RenderingServer.frame_post_draw
	return canvas.get_texture().get_image()

func run() -> void:
	output=OS.get_environment("YOUJIA_MIST_CAPTURE")
	if output.is_empty():push_error("capture directory required");quit(1);return
	DirAccess.make_dir_recursive_absolute(output)
	canvas=SubViewport.new();canvas.size=Vector2i(1672,941)
	canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	canvas.world_2d=World2D.new();root.add_child(canvas)
	var painting:=Sprite2D.new();painting.centered=false;painting.texture=load(NearPathLayout.ART);canvas.add_child(painting)
	ground=Node2D.new();canvas.add_child(ground);ground.draw.connect(draw_find)
	var walker:=SequenceResident.new();canvas.add_child(walker)
	var spot:=NearPathLayout.point("lane",590.0)
	walker.position=spot;walker.advance(0.0,Vector2.ZERO,NearPathLayout.depth(spot.y),-1.0,true)
	var before:=await image(false)
	var after:=await image(true)
	before.save_png(output.path_join("before.png"));after.save_png(output.path_join("after.png"))
	var ratio:=NearGroundFindArt.reveal_scale("formal.find.feather")
	var unchanged:=NearGroundFindArt.reveal_scale("formal.find.pine_cone") == 1.0
	var size:=1.6*NearPathLayout.depth(anchor.y)*KeepsakeArt.TEXTURE_SPAN
	var old_visible:=size*NearGroundFindArt.visible_span(KeepsakeArt.texture("formal.find.feather"))
	var new_visible:=size*NearGroundFindArt.FEATHER_SCALE*NearGroundFindArt.visible_span(NearGroundFindArt.FEATHER)
	var actual_start:=size*ratio*NearGroundFindArt.visible_span(KeepsakeArt.texture("formal.find.feather"))
	var ok:=ratio>0.57 and ratio<0.60 and unchanged and is_equal_approx(new_visible,actual_start) and before.get_data()!=after.get_data()
	var metrics:={"renderer":RenderingServer.get_video_adapter_name(),"ratio":ratio,"old_visible_pixels":old_visible,"new_visible_pixels":new_visible,"reveal_start_visible_pixels":actual_start,"other_find_scale_unchanged":unchanged,"pass":ok}
	FileAccess.open(output.path_join("result.json"),FileAccess.WRITE).store_string(JSON.stringify(metrics,"\t")+"\n")
	print("NEAR_FEATHER_RENDER ",JSON.stringify(metrics))
	root.get_node("AudioDirector").release_streams();quit(0 if ok else 1)
