extends SceneTree

# Four manually authored silhouette keys. No procedural walk or IK is sampled.
const KEYS := [
	{"name":"1 Contact", "pelvis":-46.82,"legs":[Vector3(0.20,0.18,0.10),Vector3(-0.24,0.10,-0.12)]},
	{"name":"2 Load", "pelvis":-46.38,"legs":[Vector3(0.25,0.40,0.15),Vector3(-0.28,0.40,0.0)]},
	{"name":"3 Passing", "pelvis":-47.17,"legs":[Vector3(-0.12,0.65,0.03),Vector3(0.04,0.08,0.0)]},
	{"name":"4 Push off", "pelvis":-48.29,"legs":[Vector3(-0.30,0.40,-0.10),Vector3(0.18,0.08,0.22)]},
]

var _actors: Array[ResidentWalker]=[]

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var folder:=OS.get_environment("YOUJIA_CAPTURE_DIR")
	if folder.is_empty():
		quit(1)
		return
	var background:=ColorRect.new()
	background.color=Color("eee9df")
	background.size=Vector2(1280,720)
	root.add_child(background)
	for index: int in 4:
		var actor:=ResidentWalker.new()
		root.add_child(actor)
		_actors.append(actor)
		actor.position=Vector2(150+index*295,560)
		actor.z_index=10
		actor.scale=Vector2(3.4,3.4)
		actor.pelvis.position.y=KEYS[index].pelvis
		for side: int in 2:
			var pose: Vector3=KEYS[index].legs[side]
			actor.thighs[side].rotation=pose.x
			actor.shins[side].rotation=pose.y
			actor.feet[side].rotation=pose.z-pose.x-pose.y
			actor.shoulders[side].rotation=(0.04 if side==0 else -0.04)*cos(index*PI*0.5)
			actor.elbows[side].rotation=-0.05
		var label:=Label.new()
		label.text=KEYS[index].name
		label.position=Vector2(65+index*295,125)
		label.add_theme_color_override("font_color",Color("334953"))
		label.add_theme_font_size_override("font_size",22)
		root.add_child(label)
		var line:=Line2D.new()
		line.points=PackedVector2Array([Vector2(55+index*295,560),Vector2(245+index*295,560)])
		line.default_color=Color("b5ad9d")
		line.width=1.0
		root.add_child(line)
	DirAccess.make_dir_recursive_absolute(folder)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join("authored-four-poses.png"))
	for child in root.get_children():
		if child is Label or child is Line2D:
			child.visible=false
	var caption:=Label.new()
	caption.position=Vector2(250,80)
	caption.add_theme_color_override("font_color",Color("334953"))
	caption.add_theme_font_size_override("font_size",24)
	root.add_child(caption)
	for index: int in 4:
		for side: int in 4:
			_actors[side].visible=side==index
		_actors[index].position=Vector2(590,560)
		_actors[index].scale=Vector2(4,4)
		caption.text="Four authored keys - half-cycle only | "+KEYS[index].name
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder.path_join("key%d.png"%index))
	root.get_node("AudioDirector").call("release_streams")
	quit(0)
