extends SceneTree
# #399 点按回院的体验证据：真实 Main 从院子出门到近郊，鼠标点（竖屏用触屏点）右上院门，
# 人物从“门口”停留点沿路走到门口后回院；按帧截图并记录屏幕状态。需要真实渲染器（非 --headless），XDG 用一次性目录。
# YOUJIA_CAPTURE_DIR=<dir> YOUJIA_CAPTURE_TAG=<tag> godot --path . --resolution 1280x720 --script tools/capture_tap_home.gd

const L := preload("res://scripts/exploration/near_path_layout.gd")

var folder := ""
var tag := ""
var log_lines: PackedStringArray = []


func _initialize() -> void:
	call_deferred("record")


func note(text: String) -> void:
	print("[tap-home-capture] ", text)
	log_lines.append(text)


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("%s/%s-%s.png" % [folder, tag, name])


func tap(point: Vector2, touch: bool) -> void:
	for pressed: bool in [true, false]:
		var event: InputEvent
		if touch:
			var screen := InputEventScreenTouch.new()
			screen.position = point
			screen.pressed = pressed
			event = screen
		else:
			var mouse := InputEventMouseButton.new()
			mouse.button_index = MOUSE_BUTTON_LEFT
			mouse.position = point
			mouse.global_position = point
			mouse.pressed = pressed
			event = mouse
		root.push_input(event)


func record() -> void:
	folder = OS.get_environment("YOUJIA_CAPTURE_DIR")
	tag = OS.get_environment("YOUJIA_CAPTURE_TAG")
	DirAccess.make_dir_recursive_absolute(folder)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await main._start_holiday()
	for i in 30:
		await process_frame
	var world = main._world
	var exit := YardSceneHotspots.get_hotspot(YardSceneHotspots.PATH_OUT)
	world.debug_place_player(exit.approach_points[0] + Vector2(3, 2))
	world._interact_with_target(YardSceneHotspots.PATH_OUT)
	for i in 20:
		await process_frame
	var scroll = main._exploration.scroll
	# 出门处离门口只有 20 像素，一眨眼就到；先站到“门口”停留点，走路过程看得见
	scroll.place_at("gate")
	var size := root.get_visible_rect().size
	note("%s view %dx%d screen %s spot %s" % [tag, size.x, size.y, main._screen, scroll.spot])
	await shot("1-near-path")
	var door: Vector2 = scroll.art_to_screen(L.point(L.HOME_ARM, L.arm_length(L.HOME_ARM)) + Vector2(10, -45))
	var touch := size.x < size.y
	tap(door, touch)
	await process_frame
	note("%s %s tap at (%d,%d) target %s" % [tag, "touch" if touch else "mouse", door.x, door.y, scroll.walk_target])
	await shot("2-tapped-gate")
	var start := Time.get_ticks_msec()
	var mid_saved := false
	while main._screen == "exploring" and Time.get_ticks_msec() - start < 5000:
		if not mid_saved and Time.get_ticks_msec() - start > 450:
			await shot("3-walking")
			note("%s walking spot d=%.1f of %.1f" % [tag, float(scroll.spot.d), L.arm_length(L.HOME_ARM)])
			mid_saved = true
		await process_frame
	note("%s after %d ms screen %s notice %s" % [tag, Time.get_ticks_msec() - start, main._screen, main._notice_key])
	for i in 20:
		await process_frame
	await shot("4-back-in-yard")
	note("%s final screen %s world visible %s notice %s" % [tag, main._screen, world.visible, main._notice_key])
	var file := FileAccess.open("%s/%s-capture-log.txt" % [folder, tag], FileAccess.WRITE)
	file.store_string("\n".join(log_lines) + "\n")
	file.close()
	quit(0)
