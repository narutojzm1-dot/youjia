extends SceneTree
# Isolated native Viewport dispatch; ordinary Web/physical-device checks are separate.
var main
var audio
var checks := 0
var failures := 0

func _initialize():
	call_deferred("run")

func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", label)

func run():
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await root.get_node("SaveStore").flush_pending()
	await main._start_holiday(false)
	await process_frame
	main.set_process(false)
	audio = root.get_node("AudioDirector")
	for locale in ["zh-CN", "en"]:
		root.get_node("I18n").set_locale(locale)
		for dims in [Vector2i(390,844), Vector2i(360,640), Vector2i(844,390)]:
			root.size = dims
			main.size = dims
			main._layout()
			await process_frame
			await process_frame
			await exercise(locale + " " + str(dims))
	print("MODAL_TOUCH_INPUT checks=", checks, " failures=", failures)
	main.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

func prepare():
	main._cancel_destructive_action()
	if not main._pause_screen.visible:
		main._toggle_pause()
	audio.set_music_gain(0.83)
	audio.set_ambience_gain(0.67)
	main._refresh_volume_labels()
	main._last_touch_ms = -10000
	await process_frame
	await process_frame

func unchanged(label: String):
	check(is_equal_approx(audio.music_gain(), 0.83), label + " music unchanged")
	check(is_equal_approx(audio.ambience_gain(), 0.67), label + " ambience unchanged")

func exercise(label: String):
	await prepare()
	main._request_destructive_action("title")
	await process_frame
	await process_frame
	var cancel: Vector2 = main._confirm_cancel_button.get_global_rect().get_center()
	print("CASE ", label, " cancel=", cancel, " music=", main._music_slider.get_global_rect(), " pause=", main._pause_screen.visible, " screen=", main._screen)
	mouse(cancel, true)
	touch(cancel, true)
	unchanged(label + " cancel down")
	check(main._confirm_screen.visible, label + " GUI cancel waits for release")
	await process_frame
	await process_frame
	mouse(cancel, false)
	touch(cancel, false)
	check(not main._confirm_screen.visible and main._pause_screen.visible, label + " cancel returns to pause")
	unchanged(label + " cancel release")
	main._last_touch_ms = -10000
	var resume: Vector2 = main._resume_button.get_global_rect().get_center()
	mouse(resume, true)
	touch(resume, true)
	check(main._pause_screen.visible, label + " GUI resume waits for release")
	mouse(resume, false)
	touch(resume, false)
	check(not main._pause_screen.visible and not paused and main._world.input_enabled, label + " resume fully restores yard")
	check(not main._music_slider.is_visible_in_tree() and not main._resume_button.is_visible_in_tree(), label + " no partial pause controls")
	await prepare()
	var music: Vector2 = main._music_slider.get_global_rect().get_center()
	var ambience: Vector2 = main._ambience_slider.get_global_rect().get_center()
	# A release or a drag whose gesture began elsewhere must not start a slider.
	touch(music, false)
	drag(ambience)
	unchanged(label + " orphan events")
	touch(Vector2(2,2), true)
	drag(music)
	touch(music, false)
	unchanged(label + " gesture from outside sliders")
	# A modal gesture cannot acquire or modify either obscured slider.
	main._request_destructive_action("title")
	touch(Vector2(2,2), true)
	drag(music)
	drag(ambience)
	touch(ambience, false)
	unchanged(label + " modal drag")
	check(main._confirm_screen.visible, label + " modal blank gesture stays modal")
	main._cancel_destructive_action()
	# A real new gesture remains usable, with exclusive finger/slider ownership.
	main._last_touch_ms = -10000
	mouse(music, true)
	touch(music, true)
	print("FRESH ", label, " point=", music, " value=", audio.music_gain(), " visible=", main._pause_screen.visible, " confirm=", main._confirm_screen.visible, " sliderVisible=", main._music_slider.is_visible_in_tree(), " sliderParent=", main._music_slider.get_parent(), " mainInput=", main.is_processing_input())
	check(is_equal_approx(audio.music_gain(), 0.5), label + " fresh music touch works")
	var synthetic_motion := InputEventMouseMotion.new()
	synthetic_motion.position = music + Vector2(40, 135)
	synthetic_motion.global_position = synthetic_motion.position
	synthetic_motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(synthetic_motion, true)
	check(is_equal_approx(audio.music_gain(), 0.5), label + " synthesized mouse motion cannot move touch-owned slider")
	touch(ambience, true, 1)
	drag(ambience, 1)
	check(is_equal_approx(audio.ambience_gain(), 0.67), label + " second finger cannot acquire another slider")
	drag(ambience)
	check(is_equal_approx(audio.ambience_gain(), 0.67), label + " drag cannot switch sliders")
	touch(ambience, false, 1)
	drag(music + Vector2(20,0))
	check(audio.music_gain() > 0.5, label + " other finger release cannot cancel owner")
	touch(music, false)
	mouse(music, false)
	audio.set_music_gain(0.83)
	main._refresh_volume_labels()
	drag(music)
	unchanged(label + " released ownership")
	# Layer changes invalidate ownership, even if the pause is reopened.
	touch(music, true)
	main._toggle_pause()
	main._toggle_pause()
	audio.set_music_gain(0.83)
	main._refresh_volume_labels()
	drag(music)
	touch(music, false)
	unchanged(label + " closed and reopened pause rejects old gesture")
	# Rotation preserves the owned slider identity, never retargeting another.
	touch(music, true)
	var old_size: Vector2i = root.size
	root.size = Vector2i(old_size.y, old_size.x)
	main.size = root.size
	main._layout()
	await process_frame
	await process_frame
	drag(main._ambience_slider.get_global_rect().get_center())
	touch(main._ambience_slider.get_global_rect().get_center(), false)
	check(is_equal_approx(audio.ambience_gain(), 0.67), label + " rotation cannot switch owned slider")
	root.size = old_size
	main.size = old_size
	main._layout()
	await prepare()
	# Pure touch fallback still cancels without leaking its release.
	main._request_destructive_action("title")
	touch(cancel, true)
	touch(cancel, false)
	check(not main._confirm_screen.visible, label + " touch-only cancel works")
	unchanged(label + " touch-only cancellation")
	# Escape preserves the same state and leaves the next touch usable.
	main._request_destructive_action("title")
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.physical_keycode = KEY_ESCAPE
	key.pressed = true
	root.push_input(key, true)
	key.pressed = false
	root.push_input(key, true)
	check(not main._confirm_screen.visible and main._pause_screen.visible, label + " Escape cancels only modal")
	unchanged(label + " keyboard cancellation")
	main._request_destructive_action("title")
	await process_frame
	main._last_touch_ms = -10000
	mouse(cancel, true)
	touch(cancel, true)
	key.pressed = true
	root.push_input(key, true)
	key.pressed = false
	root.push_input(key, true)
	mouse(cancel, false)
	touch(cancel, false)
	check(not main._confirm_screen.visible and main._pause_screen.visible, label + " Escape during GUI hold cancels old release")
	unchanged(label + " Escape during held touch")
	# Confirm executes once on release; existing unsaved-state protection wins.
	for blocked in [true, false]:
		if blocked:
			main._on_save_problem("modal-input-test", "yard", "UNKNOWN")
		main._request_destructive_action("title")
		await process_frame
		await process_frame
		var accept: Vector2 = main._confirm_accept_button.get_global_rect().get_center()
		var hits := [0]
		var count := func(): hits[0] += 1
		main._confirm_accept_button.pressed.connect(count)
		main._last_touch_ms = -10000
		mouse(accept, true)
		var gui_held: bool = main._confirm_accept_button.is_pressed()
		touch(accept, true)
		await process_frame
		await process_frame
		check(hits[0] == (0 if gui_held else 1), label + " GUI accept waits; touch-only fallback fires once")
		unchanged(label + " accept hold")
		mouse(accept, false)
		touch(accept, false)
		for frame in 12:
			await process_frame
		check(hits[0] == 1, label + " accept signal once")
		check(main._screen == ("game" if blocked else "title"), label + " pending save blocks departure; clean save allows it")
		main._confirm_accept_button.pressed.disconnect(count)
		if blocked:
			main._on_save_confirmed("modal-input-test", "yard")
			main._on_save_state_changed("ready")
	await main._start_holiday(false)
	await process_frame

func mouse(point: Vector2, down: bool):
	var e := InputEventMouseButton.new()
	e.position = point
	e.global_position = point
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	root.push_input(e, true)

func touch(point: Vector2, down: bool, finger: int = 0):
	var e := InputEventScreenTouch.new()
	e.position = point
	e.index = finger
	e.pressed = down
	root.push_input(e, true)

func drag(point: Vector2, finger: int = 0):
	var e := InputEventScreenDrag.new()
	e.position = point
	e.index = finger
	root.push_input(e, true)
