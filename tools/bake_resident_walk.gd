extends SceneTree

# Authored full-body pose bake, not procedural gait sampling. Eight genuine
# keys exchange support/swing legs; one rigid in-between per interval.
const KEYS := [
	{"y":-46.82,"legs":[Vector3(0.20,0.18,0.10),Vector3(-0.24,0.10,-0.12)]},
	{"y":-46.38,"legs":[Vector3(0.25,0.40,0.15),Vector3(-0.28,0.40,0.0)]},
	{"y":-47.17,"legs":[Vector3(-0.12,0.65,0.03),Vector3(0.04,0.08,0.0)]},
	{"y":-48.29,"legs":[Vector3(-0.30,0.40,-0.10),Vector3(0.18,0.08,0.22)]},
	{"y":-46.0,"legs":[Vector3(-0.40,0.10,-0.08),Vector3(0.32,0.18,0.20)]},
	{"y":-47.28,"legs":[Vector3(-0.30,0.40,0.0),Vector3(0.25,0.40,0.18)]},
	{"y":-48.10,"legs":[Vector3(0.04,0.12,0.0),Vector3(-0.12,0.65,0.03)]},
	{"y":-48.45,"legs":[Vector3(0.12,0.08,0.18),Vector3(-0.30,0.40,-0.10)]},
]

func _initialize() -> void:
	call_deferred("_bake")

func _bake() -> void:
	var folder:=OS.get_environment("YOUJIA_CAPTURE_DIR")
	if folder.is_empty():
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(folder.path_join("baked"))
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(384,448)
	viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var actor:=ResidentWalker.new()
	viewport.add_child(actor)
	actor.position=Vector2(192,420)
	actor.scale=Vector2(4,4)
	actor.z_index=10
	var frames:=SpriteFrames.new()
	frames.add_animation("walk")
	frames.set_animation_speed("walk",12.0)
	frames.set_animation_loop("walk",true)
	for index: int in 16:
		var key: int=index/2
		var next: int=(key+1)%8
		var weight:=0.5 if index%2 else 0.0
		actor.pelvis.position.y=lerpf(KEYS[key].y,KEYS[next].y,weight)
		for side: int in 2:
			var pose: Vector3=KEYS[key].legs[side].lerp(KEYS[next].legs[side],weight)
			actor.thighs[side].rotation=pose.x
			actor.shins[side].rotation=pose.y
			actor.feet[side].rotation=pose.z-pose.x-pose.y
			actor.shoulders[side].rotation=cos((float(key)+weight)*TAU/8.0+float(side)*PI)*0.04
			actor.elbows[side].rotation=-0.045
		await process_frame
		await RenderingServer.frame_post_draw
		var picture:=viewport.get_texture().get_image()
		picture.save_png(folder.path_join("baked/%02d.png"%index))
		frames.add_frame("walk",ImageTexture.create_from_image(picture))
	viewport.queue_free()
	var bg:=ColorRect.new()
	bg.size=Vector2(1280,720)
	bg.color=Color("eee9df")
	root.add_child(bg)
	var players: Array[AnimatedSprite2D]=[]
	var labels: Array[Label]=[]
	for side: int in 2:
		var player:=AnimatedSprite2D.new()
		player.sprite_frames=frames
		player.centered=false
		player.scale=Vector2.ONE*0.88
		player.position=Vector2(315+side*575-192*0.88,555-420*0.88)
		player.speed_scale=1.0 if side==0 else 0.25
		root.add_child(player)
		player.play("walk")
		players.append(player)
		var line:=Line2D.new()
		line.points=PackedVector2Array([Vector2(95+side*575,555),Vector2(530+side*575,555)])
		line.default_color=Color("b5ad9d")
		line.width=1.0
		root.add_child(line)
		var label:=Label.new()
		label.position=Vector2(80+side*575,80)
		label.add_theme_color_override("font_color",Color("334953"))
		label.add_theme_font_size_override("font_size",22)
		root.add_child(label)
		labels.append(label)
	for index: int in 160:
		for side: int in 2:
			labels[side].text=("Authored frames - 12 fps" if side==0 else "Slow inspection - 3 fps")+" | "+str(players[side].frame+1)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder.path_join("%04d.png"%index))
	var manifest:=FileAccess.open(folder.path_join("manifest.json"),FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"method":"Eight manually authored poses, 16 baked frames; no procedural IK", "frame_canvas":[384,448],"anchor":[192,420],"animation_fps":12,"capture_fps":30,"runtime":"AnimatedSprite2D","script_sha256":FileAccess.get_sha256("res://tools/bake_resident_walk.gd")},"  "))
	root.get_node("AudioDirector").call("release_streams")
	quit(0)
