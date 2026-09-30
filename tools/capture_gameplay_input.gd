extends SceneTree
var main: Control
var stage:=0
var since:=0
var events:Array=[]
func _initialize()->void: call_deferred("record")
func mouse(point:Vector2)->void:
	for pressed in [true,false]:
		var ev:=InputEventMouseButton.new()
		ev.position=point
		ev.global_position=point
		ev.button_index=MOUSE_BUTTON_LEFT
		ev.pressed=pressed
		root.push_input(ev,true)
func tap_world(point:Vector2)->void:
	for pressed in [true,false]:
		var ev:=InputEventScreenTouch.new()
		ev.position=root.get_canvas_transform()*point
		ev.index=0
		ev.pressed=pressed
		root.push_input(ev,true)
func button(name:String)->void:
	var b:Control=main.get(name)
	for pressed in [true,false]:
		var ev:=InputEventScreenTouch.new()
		ev.position=b.get_global_transform_with_canvas()*(b.size*0.5)
		ev.pressed=pressed
		ev.index=0
		root.push_input(ev,true)
func advance(name:String,frame:int)->void:
	events.append({"frame":frame,"event":name})
	print("[input-capture] ",name," ",frame)
	stage+=1
	since=frame
func record()->void:
	var folder:=OS.get_environment("YOUJIA_CAPTURE_DIR")
	DirAccess.make_dir_recursive_absolute(folder)
	seed(72)
	main=load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for frame in 1800:
		if stage==0 and frame==15:
			button("_play_button")
			advance("touch UI: start holiday",frame)
		elif stage==1 and frame-since>30:
			tap_world(Vector2(340,600))
			advance("touch: grass pile",frame)
		elif stage==2 and main._world.get_player().carrying_grass:
			tap_world(main._world.actor_named("llama").position)
			advance("touch: approach and feed llama",frame)
		elif stage==3 and "llama_fed_gentle" in main._world.collected:
			advance("normal feeding photo collected",frame)
		elif stage==4 and frame-since>100:
			tap_world(main._world.actor_named("llama").position)
			advance("touch: lead llama",frame)
		elif stage==5 and main._world._leading and frame-since>30:
			tap_world(Vector2(780,480))
			advance("touch: walk together",frame)
		elif stage==6 and frame-since>150:
			button("_action_button")
			advance("touch UI: release lead",frame)
		elif stage==7 and frame-since>30:
			button("_pause_button")
			advance("touch UI: pause",frame)
		elif stage==8 and frame-since>30:
			button("_resume_button")
			advance("touch UI: resume",frame)
		elif stage==9 and frame-since>30:
			button("_album_chip")
			advance("touch UI: open album",frame)
		elif stage==10 and frame-since>50:
			button("_album_back_button")
			advance("touch UI: return to yard",frame)
		elif stage==11 and frame-since>30:
			tap_world(main._world.actor_named("llama").position+Vector2(110,20))
			button("_weather_chip")
			advance("touch UI: overcast, observe goose reaction",frame)
		elif stage==12 and main._world.actor_named("llama").current_expression=="annoyed":
			advance("normal goose-triggered spit",frame)
		await process_frame
		await RenderingServer.frame_post_draw
		if frame%3==0: root.get_texture().get_image().save_png(folder.path_join("%04d.png"%(frame/3)))
		if stage==13 and frame-since>45: break
	var f:=FileAccess.open(folder.path_join("events.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"stage":stage,"events":events,"player":str(main._world.get_player().position),"collected":main._world.collected},"  "))
	root.get_node("AudioDirector").call("release_streams")
	quit(0 if stage==13 else 1)
