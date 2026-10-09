extends SceneTree
const Clock := preload("res://scripts/ui/regional_clock.gd")
var checks := 0
var failures: Array[String] = []
var main

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func fraction(hour: float) -> float: return fposmod(hour - 6.0, 24.0) / 24.0

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return
	var i18n = root.get_node("I18n")
	for locale in ["zh-CN", "en"]:
		i18n.set_locale(locale)
		for row in [[0.0,12,0,"am"],[6.0,6,0,"am"],[11.9833333333,11,59,"am"],
			[12.0,12,0,"pm"],[12.0166666667,12,1,"pm"],[23.9833333333,11,59,"pm"]]:
			var value := Clock.parts(fraction(row[0]))
			check(value.hour == row[1] and value.minute == row[2] and value.period == row[3], "12h boundary %s %s" % [locale,row])
			var expected := ("上午 " if row[3] == "am" else "下午 ") + "%d:%02d" % [row[1],row[2]] if locale == "zh-CN" else "%d:%02d %s" % [row[1],row[2],row[3].to_upper()]
			check(Clock.caption(fraction(row[0]), i18n) == expected, "localized caption %s" % expected)
	check(Clock.parts(NAN).hour == 6 and Clock.parts(NAN).minute == 0, "invalid clock safe")
	i18n.set_locale("zh-CN")
	root.size = Vector2i(1280,720)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	main._world.set_process(false)
	main._world._day_elapsed = fraction(23.9833333333) * main._world.DAY_DURATION_SECONDS
	main._process(0.0)
	check(main._regional_clock.visible and main._regional_clock.text == "下午 11:59", "actual yard clock before midnight")
	var day: int = main._world.holiday_day
	main._process(0.5)
	check(main._regional_clock.text == "上午 12:00", "outdoors naturally crosses midnight")
	check(main._world.holiday_day == day and not main._world.house.busy(), "midnight does not force sleep or advance 06:00 day")
	for dims in [Vector2i(1280,720),Vector2i(390,844),Vector2i(360,640),Vector2i(844,390),Vector2i(568,320)]:
		root.size = dims
		main.size = Vector2(dims)
		main._layout()
		main._sync_regional_clock()
		check_rect("yard %s" % dims)
		check(not main._regional_clock.get_rect().intersects(main._day_label.get_rect()), "date and clock separate")
		check(not main._regional_clock.get_rect().intersects(main._pause_button.get_rect()), "pause target clear")
	var before: float = main._world._day_elapsed
	main._toggle_pause()
	main._process(2.0)
	check(not main._regional_clock.visible and main._world._day_elapsed == before, "pause hides and freezes clock")
	main._toggle_pause()
	main._show_album()
	main._process(2.0)
	check(not main._regional_clock.visible and main._world._day_elapsed == before, "album freezes shared clock")
	main._hide_album()
	main._on_exploration_requested()
	for i in 20: await process_frame
	check(main._screen == "exploring", "actual exploration entry")
	if main._screen == "exploring":
		main._exploration.scroll.set_process(false)
		main._sync_regional_clock()
		check(main._regional_clock.text == "上午 12:00", "same clock at entry")
		main._process(0.5)
		check(main._regional_clock.text == "上午 12:01", "same regional clock advances while exploring")
		for dims in [Vector2i(1280,720),Vector2i(390,844),Vector2i(360,640),Vector2i(844,390)]:
			root.size = dims
			main.size = Vector2(dims)
			main._exploration.scroll._refresh()
			main._sync_regional_clock()
			check_rect("near path %s" % dims)
			for button in [main._exploration.scroll._pause_button,main._exploration.scroll._return_button,main._exploration.scroll._look_button]:
				if button.visible: check(not main._regional_clock.get_rect().intersects(button.get_rect()), "path button clear %s" % button.text)
		main._on_exploration_returned("")
		main._sync_regional_clock()
		check(main._regional_clock.text == "上午 12:01", "return preserves shared minute")
	# The existing progress writer is the only persistence path.
	main._world._save_progress()
	check(await root.get_node("SaveStore").flush_pending(), "real progress flush")
	var saved: float = root.get_node("SaveStore").get_holiday_day_elapsed()
	check(is_equal_approx(saved, main._world._day_elapsed), "durable elapsed retains clock")
	await main._show_title()
	main._sync_regional_clock()
	check(not main._regional_clock.visible, "title hides clock")
	await main._start_holiday()
	main._sync_regional_clock()
	check(main._regional_clock.text == Clock.caption(saved/main._world.DAY_DURATION_SECONDS, i18n), "reenter restores from persisted elapsed")
	main.queue_free()
	await process_frame
	root.get_node("AudioDirector").release_streams()
	print("REGIONAL_CLOCK checks=%d failures=%d" % [checks,failures.size()])
	for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)

func check_rect(tag: String) -> void:
	var clock: Label = main._regional_clock
	check(clock.visible, tag+" visible")
	check(Rect2(Vector2.ZERO,main.size).encloses(clock.get_rect()),tag+" on screen")
	check(clock.get_minimum_size().x <= clock.size.x+0.5,tag+" complete text fits")
	check(clock.mouse_filter == Control.MOUSE_FILTER_IGNORE,tag+" never steals walking input")
