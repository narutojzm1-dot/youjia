extends SceneTree
# Real viewport GUI streams, with emulated mouse/touch ordering made explicit.
# These are isolated native input cases, not physical-device or hearing tests.
var main
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
	main=load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await root.get_node("SaveStore").flush_pending()
	main._start_holiday(false)
	await process_frame
	main.set_process(false)
	main._toggle_pause()
	for locale in ["zh-CN","en"]:
		root.get_node("I18n").set_locale(locale)
		for dims in [Vector2i(844,390),Vector2i(390,844),Vector2i(360,640)]:
			root.size=dims
			main.size=dims
			main._layout()
			await process_frame
			await process_frame
			for key in ["_mute_toggle","_music_toggle","_ambience_toggle"]:
				for mode in ["mouse", "gui-touch", "held-gui-touch", "touch-first", "touch-only", "recent-touch", "drag-cancel", "keyboard"]:
					await exercise(key,mode,locale+" "+str(dims)+" "+key+" "+mode)
	print("AUDIO_BUTTON_INPUT checks=",checks," failures=",failures)
	main.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)

func exercise(key: String, mode: String, label: String):
	var audio=root.get_node("AudioDirector")
	audio.set_music_enabled(true)
	audio.set_ambience_enabled(true)
	root.get_node("TuningStore").set_value("audio.master.muted",false)
	main._refresh_texts()
	await process_frame
	var button: Button=main.get(key)
	var point:=button.get_global_rect().get_center()
	var hits: Array=[0]
	var cb:=func():hits[0]+=1
	button.pressed.connect(cb)
	main._last_touch_ms=Time.get_ticks_msec() if mode=="recent-touch" else -10000
	check(button.is_visible_in_tree() and not button.is_pressed(),label+" ready")
	if mode=="keyboard":
		button.grab_focus()
		key_event(true)
		key_event(false)
	elif mode in ["touch-first","touch-only"]:
		touch(point,true)
		if mode=="touch-first":
			mouse(point,true)
			mouse(point,false)
		touch(point,false)
	else:
		mouse(point,true)
		if mode!="mouse":
			touch(point,true)
			if mode!="recent-touch":
				check(button.is_pressed() and enabled(key),label+" GUI hold has not toggled on touch-down")
		if mode=="held-gui-touch":
			for i in 3:
				await process_frame
			check(enabled(key),label+" held across frames still awaits release")
		if mode=="drag-cancel":
			var outside:=Vector2(-30,-30)
			var motion:=InputEventMouseMotion.new()
			motion.position=outside
			motion.global_position=outside
			motion.button_mask=MOUSE_BUTTON_MASK_LEFT
			root.push_input(motion,true)
			mouse(outside,false)
			touch(outside,false)
		else:
			mouse(point,false)
			if mode!="mouse":
				touch(point,false)
	check(hits[0]==(0 if mode=="drag-cancel" else 1),label+" one completed gesture has one pressed (cancel has zero)")
	check(enabled(key)==(mode=="drag-cancel"),label+" exact toggle state")
	check(not button.is_pressed(),label+" released, no stuck button")
	button.pressed.disconnect(cb)
	await process_frame

func enabled(key: String)->bool:
	if key=="_mute_toggle":
		return not bool(root.get_node("TuningStore").get_value("audio.master.muted",false))
	var audio=root.get_node("AudioDirector")
	return audio.music_enabled() if key=="_music_toggle" else audio.ambience_enabled()

func mouse(point: Vector2, down: bool):
	var event:=InputEventMouseButton.new()
	event.position=point
	event.global_position=point
	event.button_index=MOUSE_BUTTON_LEFT
	event.pressed=down
	root.push_input(event,true)

func touch(point: Vector2, down: bool):
	var event:=InputEventScreenTouch.new()
	event.position=point
	event.index=0
	event.pressed=down
	root.push_input(event,true)

func key_event(down: bool):
	var event:=InputEventKey.new()
	event.keycode=KEY_ENTER
	event.physical_keycode=KEY_ENTER
	event.pressed=down
	root.push_input(event,true)
