extends SceneTree
# Controlled native Main lifecycle + real viewport input dispatch. Storage state
# delays/refusals below are test faults, not ordinary Web or durability evidence.
var main
var store
var checks := 0
var failures := 0
func _initialize():
	call_deferred("run")
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", label)
func mouse(point: Vector2, down: bool):
	var e := InputEventMouseButton.new()
	e.position = point
	e.global_position = point
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	root.push_input(e, true)
func touch(point: Vector2, down: bool):
	var e := InputEventScreenTouch.new()
	e.position = point
	e.pressed = down
	root.push_input(e, true)
func settle():
	await store.flush_pending()
	await process_frame
	await process_frame
func run():
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	store = root.get_node("SaveStore")
	await settle()
	root.size = Vector2i(1280,720)
	main.size = Vector2(1280,720)
	main._layout()
	await process_frame
	# Real emulated-mouse-first ordering seen in the diagnostic Web recording.
	# Delay actual SaveStore.flush_pending without replacing Main or its awaits.
	var coordinator = store._coordinator
	coordinator._state = "preparing"
	var point: Vector2 = main._play_button.get_global_rect().get_center()
	var pressed := [0]
	main._play_button.pressed.connect(func(): pressed[0] += 1)
	main._last_touch_ms = -10000
	mouse(point, true)
	touch(point, true)
	mouse(point, false)
	touch(point, false)
	check(pressed[0] == 2, "real mouse-first touch dispatch reproduces two play signals")
	check(main._holiday_start_pending and main._world == null, "start waits before world creation")
	main._on_play_pressed()
	main._start_holiday(false)
	await process_frame
	check(main._world == null and main._holiday_start_pending, "duplicate calls during await cannot create world")
	coordinator._state = "ready"
	await settle()
	check(main._screen == "game" and main._world != null, "one successful startup reaches yard")
	check(not main._holiday_start_pending, "successful startup releases pending guard")
	var first_world = main._world
	await settle()
	check(main._world == first_world, "no delayed second startup after flush")
	# A late native pressed signal must not recreate an already entered yard.
	main._play_button.pressed.emit()
	await settle()
	check(main._world == first_world, "late title pressed preserves exact world")
	main._on_exploration_requested()
	await settle()
	check(main._screen == "exploring", "controlled normal exploration begin succeeds")
	var scroll = main._exploration.scroll
	main._play_button.pressed.emit()
	await settle()
	check(main._screen == "exploring" and main._world == first_world and main._exploration.scroll == scroll, "late title signal cannot interrupt exploration")
	# Legitimate title round-trip remains possible.
	await main._show_title()
	await settle()
	check(main._screen == "title", "legitimate title return")
	# Refused flush cannot strand title entry behind the new lock.
	coordinator._state = "blocked"
	main._on_play_pressed()
	check(not main._holiday_start_pending and main._world == null, "flush refusal releases lock without creating world")
	coordinator._state = "ready"
	coordinator.state_changed.emit("ready")
	main._on_play_pressed()
	await settle()
	check(main._screen == "game" and main._world != null, "title retry after flush refusal succeeds")
	var second_world = main._world
	main._request_destructive_action("restart")
	await main._confirm_destructive_action()
	await settle()
	check(main._screen == "game" and main._world != second_world, "confirmed restart still creates replacement world")
	check(not main._holiday_start_pending, "restart releases lock")
	main.queue_free()
	await process_frame
	print("HOLIDAY_START_ONCE checks=", checks, " failures=", failures)
	quit(1 if failures else 0)
