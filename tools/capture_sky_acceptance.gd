extends SceneTree

# 制作人验收用：按晴天晨/午/晚与阴天正午各截一帧，再截安静抬头。
# tools/ 不进可玩导出。用法：
# YOUJIA_SKY_CAPTURE_DIR=docs/playtests/2026-10-03-REQ-005-user-accept
# godot --path . --script res://tools/capture_sky_acceptance.gd

func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var folder := OS.get_environment("YOUJIA_SKY_CAPTURE_DIR")
	if folder.is_empty():
		push_error("YOUJIA_SKY_CAPTURE_DIR 必须指向输出目录")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(folder)
	seed(72)
	var main: Variant = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var i18n: Variant = root.get_node("I18n")
	i18n.set_locale("zh-CN")
	main._start_holiday()
	for _warm: int in 10:
		await process_frame
		await RenderingServer.frame_post_draw

	# 四态云带：与 main._tod_phase_name / YardWorld 换帧窗口对齐。
	await _shot_sky(main, folder, "sun-morning.png", "sun", 0.18)
	await _shot_sky(main, folder, "sun-noon.png", "sun", 0.40)
	await _shot_sky(main, folder, "sun-evening.png", "sun", 0.80)
	await _shot_sky(main, folder, "overcast-noon.png", "overcast", 0.40)

	# 安静抬头：回到晴天早晨，站定超过 5.5 秒。
	await _prepare_sky(main, "sun", 0.18)
	var world: Variant = main.get("_world")
	var until := Time.get_ticks_msec() + 7000
	while Time.get_ticks_msec() < until:
		await process_frame
		await RenderingServer.frame_post_draw
		if bool(world.get("_quiet_sky_active")):
			break
	await _save_png(folder.path_join("quiet-sky-look.png"))

	root.get_node("AudioDirector").call("release_streams")
	await process_frame
	quit(0)


func _shot_sky(main: Variant, folder: String, filename: String, weather: String, tod: float) -> void:
	await _prepare_sky(main, weather, tod)
	for _frame: int in 8:
		await process_frame
		await RenderingServer.frame_post_draw
	await _save_png(folder.path_join(filename))


func _prepare_sky(main: Variant, weather: String, tod: float) -> void:
	var world: Variant = main.get("_world")
	world.set_weather(weather)
	world._day_elapsed = world.DAY_DURATION_SECONDS * tod
	world._sync_cloud_band_art()
	main._update_tod_tint(tod)
	main._update_season_tint(int(world.holiday_day))


func _save_png(path: String) -> void:
	var image := root.get_texture().get_image()
	var error := image.save_png(path)
	print("[sky-capture] %s (%s)" % [path, error_string(error)])
	if error != OK:
		push_error("截图失败: %s" % path)
