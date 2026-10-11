extends SceneTree
## Controlled GPU compositions only; ordinary natural-night evidence is separate.
var checks := 0
var failures: Array[String] = []
var canvas: SubViewport
var painting: Sprite2D
var light: NearPathWindowLight
var tint: ColorRect
var output := ""
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)
func picture(night: bool, enabled: bool, reduced: bool = false) -> Image:
	tint.color = Color(0.26,0.34,0.55,1.0) if night else Color.WHITE
	light.apply(enabled,reduced)
	light.sync_environment({"day_fraction":0.625 if night else 0.25},true)
	await process_frame;await RenderingServer.frame_post_draw
	return canvas.get_texture().get_image()
func run() -> void:
	output = OS.get_environment("YOUJIA_MIST_CAPTURE")
	if output.is_empty(): push_error("capture directory required");quit(1);return
	DirAccess.make_dir_recursive_absolute(output)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	canvas = SubViewport.new();canvas.world_2d=World2D.new()
	canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(canvas)
	painting=Sprite2D.new();painting.centered=false;painting.texture=load(NearPathLayout.ART)
	painting.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;canvas.add_child(painting)
	var overlay:=CanvasLayer.new();overlay.layer=5;overlay.custom_viewport=canvas;canvas.add_child(overlay)
	tint=ColorRect.new();var multiply:=ShaderMaterial.new();var shader:=Shader.new()
	shader.code="shader_type canvas_item; render_mode blend_mul, unshaded;"
	multiply.shader=shader;tint.material=multiply;overlay.add_child(tint)
	light=NearPathWindowLight.new();light.bind(painting,false)
	var mask:Image=NearPathWindowLight.MASK.get_image()
	var rows:=[]
	for size:Vector2i in [Vector2i(1672,941),Vector2i(1280,720),Vector2i(390,844)]:
		canvas.size=size;tint.size=Vector2(size)
		var view:=NearPathLayout.frame(NearPathLayout.point("lane",663),Vector2(size))
		var zoom:float=view["zoom"]
		var camera:Vector2=view["camera"]
		canvas.canvas_transform=Transform2D(Vector2(zoom,0),Vector2(0,zoom),Vector2(size)*0.5-camera*zoom)
		var before:=await picture(true,false)
		var after:=await picture(true,true)
		var reduced:=await picture(true,true,true)
		check(after.get_data()==reduced.get_data(),"static reduced night remains identical "+str(size))
		var changed:=0;var leaked:=0
		for y in range(size.y):
			for x in range(size.x):
				if before.get_pixel(x,y)==after.get_pixel(x,y):continue
				changed+=1
				var at:Vector2=canvas.canvas_transform.affine_inverse()*Vector2(x+0.5,y+0.5)-NearPathWindowLight.BOUNDS.position-Vector2(0.5,0.5)
				var permitted:=false
				for oy in range(2):
					for ox in range(2):
						var pos:=Vector2i(floori(at.x)+ox,floori(at.y)+oy)
						if Rect2i(Vector2i.ZERO,mask.get_size()).has_point(pos) and mask.get_pixelv(pos).r>0.0:permitted=true
				if not permitted:leaked+=1
		check(changed>10,"actual glass is illuminated "+str(size))
		check(leaked==0,"zero changed pixels beyond bilinear pane support "+str(size))
		var pane:=Vector2i(canvas.canvas_transform*Vector2(1412,322))
		var frame:=Vector2i(canvas.canvas_transform*Vector2(1417,330))
		var a:=before.get_pixelv(pane);var b:=after.get_pixelv(pane)
		check(b.r>a.r+0.1 and b.r>b.b,"warm panes are visible above shared night tint "+str(size))
		check(before.get_pixelv(frame)==after.get_pixelv(frame),"painted vertical frame remains unchanged "+str(size))
		var day:=await picture(false,true)
		var raw:=await picture(false,false)
		check(day.get_data()==raw.get_data(),"daylight is the exact original painting "+str(size))
		var label:=str(size.x)+"x"+str(size.y)
		before.save_png(output.path_join(label+"-before.png"));after.save_png(output.path_join(label+"-night.png"));day.save_png(output.path_join(label+"-day.png"))
		rows.append({"size":[size.x,size.y],"zoom":zoom,"camera":[camera.x,camera.y],"changed":changed,"outside_mask":leaked,"pane_before":a.to_html(),"pane_after":b.to_html()})
	var result:Dictionary={"renderer":RenderingServer.get_video_adapter_name(),"checks":checks,"failures":failures,"views":rows,"mask_bytes":mask.get_data().size(),"quad_pixels":NearPathWindowLight.BOUNDS.get_area()}
	FileAccess.open(output.path_join("result.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t")+"\n")
	print("NEARBY_WINDOW_LIGHT_RENDER ",JSON.stringify(result))
	root.get_node("AudioDirector").release_streams();quit(0 if failures.is_empty() else 1)
