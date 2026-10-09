extends SceneTree

# 制作人验收用：按晴天晨/午/晚/夜与阴天正午各截一帧，再截安静抬头。
# tools/ 不进可玩导出。用法：
# YOUJIA_SKY_CAPTURE_DIR=docs/playtests/2026-10-04-REQ-005-godot-accept
# godot --path . --script res://tools/capture_sky_acceptance.gd
#
# 注意：
# 1) 不要 await RenderingServer.frame_post_draw（可能永不返回）。
# 2) 出 PNG 需要真实渲染器：不要加 --headless（dummy 纹理为 null）。


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
	await main._start_holiday()
	await _settle_frames(10)

	# 云带时段：与 main._tod_phase_name / YardWorld 换帧与夜里 modulate 对齐。
	await _shot_sky(main, folder, "sun-morning.png", "sun", 0.18)
	await _shot_sky(main, folder, "sun-noon.png", "sun", 0.40)
	await _shot_sky(main, folder, "sun-evening.png", "sun", 0.80)
	await _shot_sky(main, folder, "sun-night.png", "sun", 0.92)
	await _shot_sky(main, folder, "overcast-noon.png", "overcast", 0.40)

	# 安静抬头：不空等 5.5s（headless 帧推进不可靠），直接越过静止阈值触发镜头。
	await _prepare_sky(main, "sun", 0.18)
	var world: Variant = main.get("_world")
	world.set("_quiet_sky_still", world.QUIET_SKY_STILL_SECONDS + 0.1)
	world.set("_quiet_sky_cooldown", 0.0)
	world.call("_tick_quiet_sky_look", 0.016, Vector2.ZERO)
	await _settle_frames(8)
	await _save_png(folder.path_join("quiet-sky-look.png"))

	root.get_node("AudioDirector").call("release_streams")
	await process_frame
	quit(0)


func _shot_sky(main: Variant, folder: String, filename: String, weather: String, tod: float) -> void:
	await _prepare_sky(main, weather, tod)
	await _settle_frames(8)
	await _save_png(folder.path_join(filename))


func _prepare_sky(main: Variant, weather: String, tod: float) -> void:
	var world: Variant = main.get("_world")
	world.set_weather(weather)
	world._day_elapsed = world.DAY_DURATION_SECONDS * tod
	world._sync_cloud_band_art()
	main._update_tod_tint(tod)
	main._update_season_tint(int(world.holiday_day))


## headless 安全等帧：不用 frame_post_draw。
func _settle_frames(count: int) -> void:
	for _frame: int in count:
		await process_frame
	await create_timer(0.05).timeout


func _save_png(path: String) -> void:
	var tex: Variant = root.get_texture()
	if tex == null:
		push_error("截图失败: 根视口无纹理（请去掉 --headless，用真实显示驱动）")
		quit(1)
		return
	var image: Image = tex.get_image()
	if image == null:
		push_error("截图失败: get_image() 为空")
		quit(1)
		return
	var error: Error = image.save_png(path)
	print("[sky-capture] %s (%s)" % [path, error_string(error)])
	if error != OK:
		push_error("截图失败: %s" % path)
