extends SceneTree
# 首片体验证据：真实 main.tscn，全程用触屏事件驱动（开始 → 走到门前小路 → 出门走走 →
# 按住右半边走 → 停下看看 → 带上 → 接着走 → 回院）。逐阶段截图到 YOUJIA_CAPTURE_DIR。
# 需要真实渲染器（非 --headless）；可配合 --write-movie 录像。

var main: Control
var folder := ""
var stage := 0
var since := 0
var shots := 0
var log_lines: PackedStringArray = []


func _initialize() -> void:
	call_deferred("record")


func touch(point: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.position = point
	ev.index = 0
	ev.pressed = pressed
	root.push_input(ev, true)


func tap(point: Vector2) -> void:
	touch(point, true)
	touch(point, false)


func tap_world(point: Vector2) -> void:
	tap(root.get_canvas_transform() * point)


func tap_control(control: Control) -> void:
	tap(control.get_global_rect().get_center())


func shot(name: String) -> void:
	shots += 1
	var path := "%s/%02d-%s.png" % [folder, shots, name]
	root.get_texture().get_image().save_png(path)
	note("shot " + path.get_file())


func note(text: String) -> void:
	print("[exploration-capture] ", text)
	log_lines.append(text)


func next(text: String, frame: int) -> void:
	note("%d %s" % [frame, text])
	stage += 1
	since = frame


func record() -> void:
	folder = OS.get_environment("YOUJIA_CAPTURE_DIR")
	DirAccess.make_dir_recursive_absolute(folder)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var size := root.get_visible_rect().size
	var scroll: Node2D = null
	for frame in 5400:
		await process_frame
		var world = main._world
		scroll = main._exploration.scroll if main._exploration != null else null
		match stage:
			0:
				if frame == 20:
					tap_control(main._play_button)
					next("touch: start holiday", frame)
			1:
				if frame - since > 60:
					shot("yard")
					tap_world(Vector2(244, 598))
					next("touch: walk to the end of the stone path", frame)
			2:
				if frame - since > 30 and not world._has_walk_goal:
					next("arrived; action reads " + root.get_node("I18n").t(world.primary_action_key()), frame)
			3:
				if frame - since > 20:
					shot("yard-go-out-action")
					tap_control(main._action_button)
					next("touch: action button", frame)
			4:
				if main._screen == "exploring" and frame - since > 50:
					shot("scroll-start")
					touch(Vector2(size.x * 0.8, size.y * 0.55), true)
					next("touch hold: walk right", frame)
			5:
				if scroll != null and scroll.nearby_stop() == "brook" and absf(scroll.x - 1260.0) < 30.0:
					touch(Vector2(size.x * 0.8, size.y * 0.55), false)
					next("release at the brook", frame)
			6:
				if frame - since > 10:
					shot("brook-nearby")
					tap_control(scroll._look_button)
					next("touch: stop and look", frame)
			7:
				if frame - since > 30:
					shot("brook-look")
					note("brook offer: " + str(scroll.pick_choice()))
					if scroll._pick_button.visible:
						tap_control(scroll._pick_button)
						next("touch: take", frame)
					else:
						stage += 1
						next("nothing at the brook; just looked", frame)
			8:
				if frame - since > 30:
					shot("basket")
					tap_control(scroll._go_button)
					next("touch: keep walking", frame)
			9:
				if frame - since > 20:
					touch(Vector2(size.x * 0.8, size.y * 0.55), true)
					next("touch hold: walk right", frame)
			10:
				if scroll.nearby_stop() == "shade" and absf(scroll.x - 2160.0) < 30.0:
					touch(Vector2(size.x * 0.8, size.y * 0.55), false)
					tap_control(scroll._look_button)
					next("touch: look under the pine", frame)
			11:
				if frame - since > 30:
					shot("shade-look")
					note("shade choice: " + str(scroll.pick_choice()))
					tap_control(scroll._go_button)
					next("touch: keep walking", frame)
			12:
				if frame - since > 20:
					tap_control(scroll._return_button)
					next("touch: go back", frame)
			13:
				if main._screen == "game" and frame - since > 20:
					shot("yard-back")
					note("notice: " + main._notice.text)
					note("keepsakes: " + str(root.get_node("SaveStore").get_keepsakes()))
					next("done", frame)
			14:
				break
	var file := FileAccess.open(folder + "/capture-log.txt", FileAccess.WRITE)
	file.store_string("\n".join(log_lines) + "\n")
	file.close()
	main.queue_free()
	await process_frame
	quit(0 if stage >= 14 else 1)
