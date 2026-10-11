extends SceneTree
## Controlled Viewport input diagnostic. Never ordinary browser proof.
var main
var hud_events: Array = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await main._start_holiday(false)
	await process_frame
	main.set_process(false)
	main._hud.gui_input.connect(func(e: InputEvent): hud_events.append(e.as_text()))
	for dims: Vector2i in [Vector2i(844,390), Vector2i(390,844), Vector2i(1280,720)]:
		root.size = dims
		main.size = dims
		main._layout()
		await process_frame
		await process_frame
		main._process(0.1)
		main._camera.force_update_scroll()
		var point: Vector2 = main.get_viewport().get_canvas_transform() * Vector2(110,610)
		for kind: String in ["mouse", "touch", "emulated_mouse_then_touch", "direct_touch"]:
			main._last_touch_ms = -10000
			main._world._selected_target = ""
			hud_events.clear()
			var mouse := InputEventMouseButton.new()
			mouse.position = point
			mouse.global_position = point
			mouse.button_index = MOUSE_BUTTON_LEFT
			mouse.pressed = true
			var touch := InputEventScreenTouch.new()
			touch.position = point
			touch.pressed = true
			if kind == "mouse":
				root.push_input(mouse, true)
			elif kind == "touch":
				root.push_input(touch, true)
			elif kind == "emulated_mouse_then_touch":
				mouse.device = InputEvent.DEVICE_ID_EMULATION
				root.push_input(mouse, true)
				root.push_input(touch, true)
			else:
				main._input(touch)
				main._unhandled_input(touch)
			print("NEAR_ENTRY_DISPATCH ",JSON.stringify({"dims":[dims.x,dims.y],"screen":[point.x,point.y],"world":str(main._screen_to_world(point)),"legacy_point_world":str(main._screen_to_world(Vector2(67,300))),"kind":kind,"target":main._world._selected_target,"input_handled":root.is_input_handled(),"hud_events":hud_events,"gui_hovered":str(root.gui_get_hovered_control()),"screen_state":main._screen,"world_enabled":main._world.input_enabled}))
			mouse.pressed = false
			touch.pressed = false
			root.push_input(mouse, true)
			root.push_input(touch, true)
			await process_frame
	main.queue_free()
	root.get_node("AudioDirector").release_streams()
	quit(0)
