extends SceneTree

# Standalone artwork gate: genuine SpriteFrames, identical cell/anchor/scale.
# No per-frame alignment, interpolation, mesh warping, or game integration.
var _actors: Array[AnimatedSprite2D]=[]
var _labels: Array[Label]=[]

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var path:=OS.get_environment("YOUJIA_SEQUENCE_SHEET")
	var folder:=OS.get_environment("YOUJIA_CAPTURE_DIR")
	if path.is_empty() or folder.is_empty():
		push_error("Set YOUJIA_SEQUENCE_SHEET and YOUJIA_CAPTURE_DIR")
		quit(1)
		return
	var texture: Texture2D
	if path.begins_with("res://"):
		texture=load(path) as Texture2D
	else:
		var source:=Image.load_from_file(path)
		if source!=null:
			texture=ImageTexture.create_from_image(source)
	if texture==null:
		push_error("Expected a readable 4-by-2 sheet")
		quit(1)
		return
	var cell:=Vector2(texture.get_width()/4.0,texture.get_height()/2.0)
	var ground_fraction:=float(OS.get_environment("YOUJIA_SEQUENCE_GROUND"))
	if ground_fraction<=0.0:
		ground_fraction=0.922
	var backdrop:=ColorRect.new()
	backdrop.color=Color("eee9df")
	backdrop.size=Vector2(1280,720)
	root.add_child(backdrop)
	for side: int in 2:
		var frames:=SpriteFrames.new()
		frames.add_animation("walk")
		frames.set_animation_loop("walk",true)
		frames.set_animation_speed("walk",8.0 if side==0 else 2.0)
		for index: int in 8:
			var region:=AtlasTexture.new()
			region.atlas=texture
			region.region=Rect2(Vector2(index%4,index/4)*cell,cell)
			region.filter_clip=true
			frames.add_frame("walk",region)
		var actor:=AnimatedSprite2D.new()
		actor.sprite_frames=frames
		actor.centered=false
		var size:=460.0/cell.y
		actor.scale=Vector2.ONE*size
		actor.position=Vector2(330+side*580-cell.x*size*0.5,570-cell.y*ground_fraction*size)
		actor.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		root.add_child(actor)
		actor.play("walk")
		_actors.append(actor)
		var line:=Line2D.new()
		line.points=PackedVector2Array([Vector2(120+side*580,570),Vector2(540+side*580,570)])
		line.width=1.0
		line.default_color=Color("b5ad9d")
		root.add_child(line)
		var label:=Label.new()
		label.position=Vector2(150+side*580,35)
		label.add_theme_color_override("font_color",Color("334953"))
		label.add_theme_font_size_override("font_size",23)
		root.add_child(label)
		_labels.append(label)
	DirAccess.make_dir_recursive_absolute(folder)
	for frame: int in 120:
		for side: int in 2:
			_labels[side].text=("Walk - 8 fps" if side==0 else "Pose inspection - 2 fps")+" | frame "+str(_actors[side].frame+1)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder.path_join("%04d.png"%frame))
	var manifest:=FileAccess.open(folder.path_join("manifest.json"),FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"sheet":path,"sheet_sha256":FileAccess.get_sha256(path),"cell":str(cell),"ground_fraction":ground_fraction,"frames":120,"fps":30,"left_animation_fps":8,"right_animation_fps":2,"uniform_alignment":true},"  "))
	root.get_node("AudioDirector").call("release_streams")
	quit(0)
