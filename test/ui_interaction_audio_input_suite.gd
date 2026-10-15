extends SceneTree
## Actual viewport input routing. Headless acceptance counts are not sound output.
class ObservedAudio extends UiInteractionAudio:
	var accepted: Array[String] = []
	func _play(cue: String) -> bool:
		var ok := super._play(cue)
		if ok: accepted.append(cue)
		return ok

var main: Node
var audio: ObservedAudio
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func gap() -> void:
	var until := Time.get_ticks_msec() + 110
	while Time.get_ticks_msec() < until: await process_frame

func key(code: Key) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		root.push_input(event, true)
		await process_frame

func tap(button: Control, touch: bool) -> void:
	var point := button.get_global_rect().get_center()
	for down in [true, false]:
		if touch:
			var event := InputEventScreenTouch.new()
			event.position = point
			event.pressed = down
			root.push_input(event, true)
		else:
			var event := InputEventMouseButton.new()
			event.position = point
			event.global_position = point
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = down
			root.push_input(event, true)
		await process_frame

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated.trim_suffix("/") + "/"):
		quit(2)
		return
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await main.call("_start_holiday")
	main.set_process(false)
	audio = ObservedAudio.new()
	main.set("_ui_sfx", audio)
	for dims in [Vector2i(1280,720), Vector2i(390,844)]:
		root.size = dims
		main.set("size", Vector2(dims))
		main.call("_layout")
		for i in 3: await process_frame
		for touch in [false, true]:
			var tag := str(dims) + (" touch" if touch else " mouse")
			main.set("_last_touch_ms", -10000)
			await gap()
			var before := audio.accepted.size()
			await tap(main.get("_basket_chip"), touch)
			check(main.get("_basket_panel").visible, tag+" basket opens")
			check(audio.accepted.slice(before) == ["ui.confirm"], tag+" basket one open")
			await gap()
			await key(KEY_ESCAPE)
			check(not main.get("_basket_panel").visible, tag+" Esc closes basket")
			check(audio.accepted.slice(before) == ["ui.confirm", "ui.cancel"], tag+" basket one close")
			await gap()
			main.call("_hide_basket")
			main.call("_hide_album")
			check(audio.accepted.size() == before+2, tag+" hidden cleanup silent")
			main.set("_last_touch_ms", -10000)
			await tap(main.get("_album_chip"), touch)
			check(main.get("_album_screen").visible, tag+" album opens")
			check(audio.accepted.size() == before+3, tag+" album one open")
			# Fixture only provides page contents; navigation still goes through Main input.
			main.set("_album_entries", PackedStringArray(["a","b","c","d"]))
			main.set("_album_index", 0)
			main.call("_render_album_pages")
			await gap()
			var page_before := audio.accepted.size()
			await key(KEY_LEFT)
			check(audio.accepted.size() == page_before, tag+" first-page boundary silent")
			await key(KEY_RIGHT)
			check(int(main.get("_album_index")) > 0, tag+" right key advances")
			check(audio.accepted.back() == "ui.page" and audio.accepted.size() == page_before+1, tag+" valid page one cue")
			# Drain to last page outside debounce; narrow viewport has one page per spread.
			while int(main.get("_album_index")) < (2 if bool(main.get("_album_two_pages")) else 3):
				await gap()
				await key(KEY_RIGHT)
			await gap()
			page_before = audio.accepted.size()
			await key(KEY_RIGHT)
			check(audio.accepted.size() == page_before, tag+" last-page boundary silent")
			await gap()
			await key(KEY_ESCAPE)
			check(not main.get("_album_screen").visible and audio.accepted.size() == page_before+1, tag+" album closes once")
			await gap()
			var pause_before := audio.accepted.size()
			await key(KEY_ESCAPE)
			check(main.get("_pause_screen").visible and audio.accepted.size() == pause_before+1, tag+" pause opens once")
			await gap()
			await key(KEY_ESCAPE)
			check(not main.get("_pause_screen").visible and audio.accepted.size() == pause_before+2, tag+" pause resumes once")
	# Exercise actual adapter voices on native fallback, as the meal suite does.
	# Pause must stop automatic SFX without cutting the just-submitted UI cue;
	# application background must stop both, without replay on return.
	var director: Node = root.get_node("AudioDirector")
	var ui_voice: Node = director.call("_browser_cue_player", "ui.confirm")
	ui_voice.stream = load(UiInteractionAudio.OPEN_PATH)
	ui_voice.play()
	var meal_voice: Node = director.call("_browser_cue_player", "meal.spoon")
	meal_voice.stream = load("res://assets/holiday/audio/meal_grok/cook_spoon.tres")
	meal_voice.play()
	check(bool(director.call("is_cue_voice_active", "ui.confirm")), "UI adapter has actual native fallback voice")
	director.call("set_game_paused", true)
	check(bool(director.call("is_cue_voice_active", "ui.confirm")), "game pause preserves UI feedback")
	check(not bool(director.call("is_cue_voice_active", "meal.spoon")), "game pause still retires meal SFX")
	director.call("set_application_active", false)
	check(not bool(director.call("is_cue_voice_active", "ui.confirm")), "application background retires UI feedback")
	director.call("set_application_active", true)
	check(not bool(director.call("is_cue_voice_active", "ui.confirm")), "foreground does not replay discarded UI")
	director.call("set_game_paused", false)
	main.queue_free()
	await process_frame
	# Linux's mixer can still hold the just-stopped fallback playback at quit.
	# Retire our explicit adapter fixtures and their streams before terminating,
	# preserving the strict post-PASS log gate rather than hiding exit errors.
	ui_voice = null
	meal_voice = null
	audio = null
	director.call("release_streams")
	await create_timer(0.25).timeout
	await process_frame
	print("UI_INTERACTION_AUDIO_INPUT checks=%d failures=%d" % [checks, failures.size()])
	for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
