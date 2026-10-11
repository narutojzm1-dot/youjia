extends SceneTree
## Real Viewport dispatch in an isolated native profile, not ordinary Web proof.
var main
var checks := 0
var failures := 0
var weather_hits := [0]
var basket_hits := [0]

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ",label)

func run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await main._start_holiday(false)
	await process_frame
	main.set_process(false)
	main._weather_chip.pressed.connect(func(): weather_hits[0] += 1)
	main._hold_hotbar.basket_requested.connect(func(): basket_hits[0] += 1)
	for locale: String in ["zh-CN", "en"]:
		root.get_node("I18n").set_locale(locale)
		for dims: Vector2i in [Vector2i(1280,720),Vector2i(390,844),Vector2i(844,390)]:
			root.size = dims
			main.size = dims
			main._layout()
			await process_frame
			await process_frame
			main._process(1.0/60.0)
			main._camera.force_update_scroll()
			var label := locale + " " + str(dims)
			var weather: Vector2 = main._weather_chip.get_global_rect().get_center()
			var ground: Vector2 = root.get_canvas_transform() * Vector2(110,610)
			prepare()
			var started := Time.get_ticks_msec()
			mouse(weather)
			mouse(ground)
			check(Time.get_ticks_msec()-started < 400,label+" HUD/world fixture stays inside dedupe window")
			check(main._world._selected_target == "path_out",label+" real mouse HUD then world accepts entrance")
			check(weather_hits[0] == 1,label+" mouse HUD emits once")
			prepare()
			mouse(weather)
			mouse(weather)
			check(weather_hits[0] == 2,label+" two fast real mouse HUD clicks both execute")
			for ordering: String in ["touch-first","mouse-first"]:
				prepare()
				if ordering == "mouse-first": mouse(weather,InputEvent.DEVICE_ID_EMULATION,false)
				touch(weather,true)
				if ordering == "touch-first": mouse(weather,InputEvent.DEVICE_ID_EMULATION,false)
				touch(weather,false)
				mouse_release(weather,InputEvent.DEVICE_ID_EMULATION)
				check(weather_hits[0] == 1,label+" "+ordering+" touch HUD emits once")
				check(main._world._selected_target.is_empty(),label+" "+ordering+" HUD never requests world interaction")
			prepare()
			var empty: Vector2 = main._hold_hotbar.slot_cells[0].get_global_rect().get_center()
			mouse(empty)
			check(basket_hits[0] == 1 and main._basket_panel.visible,label+" empty hotbar mouse opens basket once")
			escape()
			mouse(ground)
			check(not main._basket_panel.visible and main._world._selected_target == "path_out",label+" real mouse after hotbar/close accepts entrance")
			prepare()
			mouse(empty,InputEvent.DEVICE_ID_EMULATION,false)
			touch(empty,true)
			touch(empty,false)
			mouse_release(empty,InputEvent.DEVICE_ID_EMULATION)
			check(basket_hits[0] == 1 and main._basket_panel.visible,label+" mouse-first hotbar touch opens basket once")
			escape()
			prepare()
			touch(ground,true)
			mouse(ground,InputEvent.DEVICE_ID_EMULATION)
			touch(ground,false)
			check(main._world._selected_target == "path_out",label+" real world touch remains accepted")
			await root.get_node("SaveStore").flush_pending()
	print("HUD_POINTER_INPUT checks=",checks," failures=",failures)
	main.queue_free()
	await process_frame
	root.get_node("AudioDirector").release_streams()
	quit(0 if failures == 0 else 1)

func prepare() -> void:
	if main._basket_panel.visible: main._hide_basket()
	main._last_touch_ms = -10000
	main._world._selected_target = ""
	weather_hits[0] = 0
	basket_hits[0] = 0

func mouse(point: Vector2, device: int = 0, release: bool = true) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.device = device
	root.push_input(event,true)
	if release: mouse_release(point,device)

func mouse_release(point: Vector2, device: int) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.device = device
	root.push_input(event,true)

func touch(point: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.pressed = down
	root.push_input(event,true)

func escape() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	root.push_input(event,true)
	event.pressed = false
	root.push_input(event,true)
