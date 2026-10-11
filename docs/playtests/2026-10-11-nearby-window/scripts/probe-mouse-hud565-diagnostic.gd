extends SceneTree
## Controlled input-path diagnostic, not an ordinary browser proof or an acceptance suite.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main);await process_frame;await main._start_holiday();await process_frame
	var weather := InputEventMouseButton.new();weather.button_index=MOUSE_BUTTON_LEFT;weather.pressed=true
	weather.position=main._weather_chip.get_global_rect().get_center()
	var before:int=main._last_touch_ms
	main._input(weather)
	var mouse_sets_touch_token:bool=main._last_touch_ms>before
	var original:String=main._world._selected_target
	var ground:=InputEventMouseButton.new();ground.button_index=MOUSE_BUTTON_LEFT;ground.pressed=true
	ground.position=main.get_viewport().get_canvas_transform()*Vector2(120,680)
	main._input(ground);main._unhandled_input(ground)
	var immediate_ignored:bool=main._world._selected_target==original
	await create_timer(0.6).timeout
	main._input(ground);main._unhandled_input(ground)
	var later_accepted:bool=main._world._selected_target=="path_out"
	var result:Dictionary={"diagnostic":"controlled Main mouse event calls, not ordinary input", "mouse_sets_touch_token":mouse_sets_touch_token,"immediate_ground_ignored":immediate_ignored,"after_600ms_ground_accepted":later_accepted,"delay_threshold_ms":400,"original_target":original}
	print("MOUSE_HUD_DIAGNOSTIC ",JSON.stringify(result))
	root.size=Vector2i(844,390)
	await process_frame;await process_frame;await process_frame
	main._camera.force_update_scroll()
	var coordinates:=[]
	for point:Vector2 in [Vector2(67,300),Vector2(100,315)]:
		var world:Vector2=main._screen_to_world(point)
		coordinates.append({"screen":[point.x,point.y],"world":[world.x,world.y],"hotspot":YardSceneHotspots.at_point(main._world,world)})
	for world:Vector2 in [Vector2(100,590),Vector2(130,610),Vector2(150,660)]:
		var screen:Vector2=main.get_viewport().get_canvas_transform()*world
		coordinates.append({"world":[world.x,world.y],"screen":[screen.x,screen.y],"hotspot":YardSceneHotspots.at_point(main._world,world)})
	print("LANDSCAPE_COORDINATES ",JSON.stringify(coordinates))
	main.queue_free();root.get_node("AudioDirector").release_streams()
	quit(0 if mouse_sets_touch_token and immediate_ignored and later_accepted else 1)
