extends SceneTree

# Parameterized archival copy; original capture script SHA is in source-provenance.json.
var work := ""
var output_dir := ""
var mill_path := ""
var font_name := "Microsoft YaHei"
const ANCHOR := Vector2(480, 495)
const PIVOT := Vector2(667.5, 1145)
const CROP_ORIGIN := Vector2(280, 375)

class YardPreview extends Node2D:
	var backdrop: Texture2D
	var mill: Texture2D
	var basket: Texture2D
	var mill_width: float = 90.0
	func _draw() -> void:
		draw_texture_rect(backdrop, Rect2(0,0,1280,720), false)
		var basket_height := 70.0
		var basket_size := basket.get_size() * (basket_height / basket.get_height())
		draw_texture_rect(basket, Rect2(Vector2(335,485) - Vector2(basket_size.x*0.5,basket_size.y), basket_size), false)
		var factor := mill_width / mill.get_width()
		draw_texture_rect(mill, Rect2(ANCHOR - PIVOT * factor, mill.get_size() * factor), false)

class Sheet extends Node2D:
	var font: Font
	var weather_label: String
	var full: SubViewport
	var crops: Array[SubViewport] = []
	func _draw() -> void:
		draw_rect(Rect2(0,0,1280,1090),Color("#f1eadc"))
		draw_string(font,Vector2(16,28),"候选摆位 / 非运行接入  ·  "+weather_label+"  ·  建议比较宽 90 px",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("#46392d"))
		draw_texture(full.get_texture(),Vector2(0,40))
		for i in 3:
			var left := 14.0+float(i)*424.0
			draw_string(font,Vector2(left,790),"原 PNG 宽 %d px · 原生 1:1 裁窗" % [70+20*i],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#46392d"))
			draw_texture(crops[i].get_texture(),Vector2(left,805))
		draw_string(font,Vector2(16,1036),"世界坐标 1280×720；磨盘锚点 (480,495)；源 PNG 未改；GPU 线性 mipmap 缩放",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#46392d"))
		draw_string(font,Vector2(16,1066),"仅底图＋已有背篓对照：未加载角色、导航、互动、存档、天气调色或正式 UI。",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#46392d"))

func _initialize() -> void:
	call_deferred("run")

func read_texture(path: String) -> Texture2D:
	var image := Image.load_from_file(path)
	assert(image != null and not image.is_empty(), "Cannot load source: "+path)
	var result := image.generate_mipmaps()
	assert(result == OK, "Cannot generate memory mipmaps")
	return ImageTexture.create_from_image(image)

func make_view(bg: Texture2D, mill: Texture2D, basket: Texture2D, width: float, crop: bool) -> SubViewport:
	var v := SubViewport.new()
	v.size = Vector2i(400,200) if crop else Vector2i(1280,720)
	v.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(v)
	if crop: v.canvas_transform = Transform2D(0, -CROP_ORIGIN)
	var scene := YardPreview.new()
	scene.backdrop = bg
	scene.mill = mill
	scene.basket = basket
	scene.mill_width = width
	scene.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	v.add_child(scene)
	return v

func run() -> void:
	if not read_arguments():
		quit(2)
		return
	root.size = Vector2i(320,240)
	print("MILLSTONE_GPU rendering=",RenderingServer.get_rendering_device()," adapter=",RenderingServer.get_video_adapter_name())
	var mill := read_texture(mill_path)
	var basket := read_texture(work+"/assets/holiday/objects/yard_back_basket.png")
	var font := SystemFont.new()
	font.font_names = PackedStringArray([font_name])
	for weather: String in ["sunny", "overcast"]:
		var bg_path := work+"/assets/holiday/environment/"+("yard_sunny.png" if weather=="sunny" else "yard_overcast_aligned.png")
		var bg := read_texture(bg_path)
		var views: Array[SubViewport] = []
		var full := make_view(bg,mill,basket,90.0,false)
		views.append(full)
		var crops: Array[SubViewport] = []
		for width in [70.0,90.0,110.0]:
			var v := make_view(bg,mill,basket,width,true)
			crops.append(v)
			views.append(v)
		var sheet_view := SubViewport.new()
		sheet_view.size = Vector2i(1280,1090)
		sheet_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(sheet_view)
		var sheet := Sheet.new()
		sheet.font = font
		sheet.weather_label = "晴天底图" if weather=="sunny" else "阴天底图"
		sheet.full = full
		sheet.crops = crops
		sheet_view.add_child(sheet)
		for i in 5: await process_frame
		sheet.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var filename := output_dir+"/millstone-"+weather+"-gpu.png"
		var result := sheet_view.get_texture().get_image().save_png(filename)
		print("MILLSTONE_GPU_CAPTURE ",filename," result=",result," widths=70,90,110 anchor=480,495 png_unchanged=true")
		if result != OK: quit(2); return
		sheet_view.queue_free()
		for v in views: v.queue_free()
		await process_frame
	print("MILLSTONE_GPU_DONE two diagnostic screenshots; not runtime integration")
	quit(0)


func read_arguments() -> bool:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		if i + 1 >= args.size():
			push_error("Each option needs a value")
			return false
		match args[i]:
			"--repo-root": work = args[i+1].replace("\\", "/").trim_suffix("/")
			"--output-dir": output_dir = args[i+1].replace("\\", "/").trim_suffix("/")
			"--source-png": mill_path = args[i+1].replace("\\", "/")
			"--font-family": font_name = args[i+1]
			_:
				push_error("Unknown preview option: "+args[i])
				return false
		i += 2
	if work.is_empty() or output_dir.is_empty() or not work.is_absolute_path() or not output_dir.is_absolute_path():
		push_error("Usage: --repo-root ABS_CHECKOUT --output-dir ABS_TEMP_OUTPUT [--source-png ABS_PNG] [--font-family NAME]")
		return false
	if output_dir == work or output_dir.begins_with(work+"/"):
		push_error("Diagnostic output must be outside the repository")
		return false
	if mill_path.is_empty():
		mill_path = work.path_join("docs/candidates/millstone_v1/millstone-watercolor-v1.png")
	if not mill_path.is_absolute_path() or not FileAccess.file_exists(mill_path):
		push_error("Source PNG missing or not absolute")
		return false
	for weather: String in ["sunny", "overcast"]:
		if FileAccess.file_exists(output_dir.path_join("millstone-"+weather+"-gpu.png")):
			push_error("Refusing to overwrite an existing capture; choose a fresh output directory")
			return false
	return DirAccess.make_dir_recursive_absolute(output_dir) == OK
