extends SceneTree
# Controlled real Main-node calls expose same-frame modal ordering. They are
# not a browser timing or hearing test; save data is isolated by daily's guard.
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
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await root.get_node("SaveStore").flush_pending()
	main._start_holiday(false)
	await process_frame
	await process_frame
	main.set_process(false)
	# Keep the actual UI, but exclude unrelated simulated yard events from a
	# four/ten-second synthetic UI delta and the independent startup timer.
	# This is controlled native isolation, never applied in ordinary Web play.
	main._world = null
	for locale in ["zh-CN", "en"]:
		root.get_node("I18n").set_locale(locale)
		for view in [Vector2i(844,390), Vector2i(390,844), Vector2i(1280,720), Vector2i(360,640)]:
			root.size = view
			main.size = view
			main._layout()
			await process_frame
			await process_frame
			var label: String = locale + " " + str(view)
			main._show_notice_key("notice.first_hint")
			check(main._notice.visible, label + " normal first hint visible")
			main._toggle_pause()
			check(main._pause_screen.visible and not main._notice.visible, label + " same-call pause hides existing notice")
			main._show_notice_key("notice.first_hint")
			check(not main._notice.visible, label + " late hint cannot show during pause")
			var before: float = main._notice_time
			main._process(4.0)
			check(is_equal_approx(main._notice_time, before), label + " pause preserves unread duration")
			for name in ["_music_slider", "_ambience_slider", "_music_toggle", "_ambience_toggle", "_mute_toggle"]:
				var control = main.get(name)
				check(control.is_visible_in_tree() and Rect2(Vector2.ZERO, Vector2(view)).encloses(control.get_global_rect()), label + " audio control visible inside viewport " + name)
			main._toggle_pause()
			check(main._notice.visible and is_equal_approx(main._notice_time,before), label + " resume immediately shows preserved hint")
			main._process(0.5)
			check(is_equal_approx(main._notice_time,before-0.5), label + " resumed time advances normally")
			main._process(10.0)
			check(not main._notice.visible, label + " resumed notice eventually expires")
			main._toggle_pause()
			main._on_fish_caught("small")
			check(not main._notice.visible, label + " late fish notification cannot show during pause")
			before = main._notice_time
			main._process(8.0)
			check(is_equal_approx(main._notice_time,before), label + " fish notification duration preserved")
			main._toggle_pause()
			check(main._notice.visible, label + " fish notification shown after resume")
			# Other existing modal guards must still reject late callbacks.
			main._show_album()
			main._process(0.0)
			main._show_notice_key("notice.first_hint")
			check(not main._notice.visible, label + " album rejects late hint")
			before = main._notice_time
			main._process(4.0)
			check(is_equal_approx(main._notice_time,before), label + " album preserves unread duration")
			main._hide_album()
			main._process(0.0)
			check(main._notice.visible, label + " album close can show hint")
			main._request_destructive_action("title")
			main._process(0.0)
			main._show_notice_key("notice.first_hint")
			check(not main._notice.visible, label + " confirmation rejects late hint")
			before = main._notice_time
			main._process(4.0)
			check(is_equal_approx(main._notice_time,before), label + " confirmation preserves unread duration")
			main._confirm_screen.hide()
			main._process(0.0)
			check(main._notice.visible, label + " confirmation cancel can show hint")
	main.queue_free()
	await process_frame
	print("PAUSE_NOTICE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
