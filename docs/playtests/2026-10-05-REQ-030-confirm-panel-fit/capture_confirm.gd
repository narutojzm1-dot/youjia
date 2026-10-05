extends SceneTree
var main
func _initialize(): call_deferred("run")
func shot(path):
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run():
	var folder := OS.get_environment("YOUJIA_CAPTURE_DIR")
	var i18n = root.get_node("/root/I18n")
	for dims in [Vector2i(int(OS.get_environment("W")), int(OS.get_environment("H")))]:
		pass
		main = load("res://scenes/main.tscn").instantiate(); root.add_child(main)
		for i in 4: await process_frame
		await main._start_holiday()
		for i in 20: await process_frame
		for loc in ["zh-CN","en"]:
			i18n.set_locale(loc)
			main._toggle_pause()
			main._request_destructive_action("title")
			for i in 3: await process_frame
			var p = main._confirm_title.get_parent().get_parent()
			print(dims, loc, " panel ", p.get_global_rect(), " msg ", main._confirm_message.get_global_rect())
			await shot(folder.path_join("%dx%d-%s-confirm.png" % [dims.x, dims.y, loc]))
			main._cancel_destructive_action()
			main._toggle_pause()
		i18n.set_locale("zh-CN")
		main.queue_free(); await process_frame
	root.get_node("AudioDirector").call("release_streams")
	quit()
