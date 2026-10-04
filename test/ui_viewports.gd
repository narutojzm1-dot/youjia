extends SceneTree
var main
var failures:Array=[]
func _initialize(): call_deferred("run")
func check(ok,label):
	print("[viewport] ","PASS " if ok else "FAIL ",label)
	if not ok: failures.append(label)
func tap(point:Vector2):
	for pressed in [true,false]:
		var e:=InputEventScreenTouch.new()
		e.position=point;e.pressed=pressed;e.index=0
		root.push_input(e,true)
func button(key:String):
	var b:Button=main.get(key)
	tap(b.get_global_transform_with_canvas()*(b.size*0.5))
func frames(count:int):
	for i in count:
		main._process(1.0/60.0)
		await process_frame
func bounds(key:String):
	var b:Control=main.get(key)
	check(b != null and b.is_inside_tree() and b.is_visible_in_tree(), str(root.size)+" in tree "+key)
	var r:=Rect2(b.get_global_transform_with_canvas().origin,b.size)
	check(r.size.x > 1.0 and r.size.y > 1.0, str(root.size)+" positive "+key+" "+str(r))
	check(Rect2(Vector2.ZERO,root.size).encloses(r),str(root.size)+" visible "+key+" "+str(r))
func run():
	seed(129)
	for dimensions in [Vector2i(1280,720),Vector2i(390,844),Vector2i(844,390)]:
		root.size=dimensions
		main=load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		await process_frame;await process_frame
		main.set_process(false)
		bounds("_play_button")
		button("_play_button")
		await frames(3)
		check(main._screen=="game","touch title starts "+str(dimensions))
		for key in ["_action_button","_album_chip","_weather_chip","_pause_button"]: bounds(key)
		var point:=root.get_canvas_transform()*Vector2(340,600)
		check(Rect2(Vector2.ZERO,dimensions).has_point(point),"grass touch is inside real viewport")
		tap(point)
		for i in 800:
			await frames(1)
			if main._world.get_player().carrying_grass: break
		check(main._world.get_player().carrying_grass,"touch grass works "+str(dimensions))
		main._on_focus(Vector2(600,470),1.16)
		await frames(90)
		bounds("_pause_button")
		button("_pause_button");await frames(2)
		check(main._pause_screen.visible,"touch pause works")
		bounds("_pause_title")
		bounds("_resume_button")
		bounds("_music_slider")
		bounds("_ambience_slider")
		bounds("_mute_toggle")
		main._music_slider.value = 0
		main._ambience_slider.value = 40
		await frames(1)
		check(is_equal_approx(root.get_node("AudioDirector").call("music_gain"), 0.0), str(dimensions)+" music slider mute")
		check(is_equal_approx(root.get_node("AudioDirector").call("ambience_gain"), 0.4), str(dimensions)+" ambience slider independent")
		button("_resume_button");await frames(2)
		check(not main._pause_screen.visible, "pause resumes "+str(dimensions))
		button("_album_chip");await frames(3)
		check(main._album_screen.visible,"touch album works")
		bounds("_album_back_button")
		button("_album_back_button");await frames(2)
		check(not main._album_screen.visible,"touch album closes")
		main.queue_free();await process_frame
	root.get_node("AudioDirector").call("release_streams")
	print("[viewport] failures=",failures)
	quit(0 if failures.is_empty() else 1)
