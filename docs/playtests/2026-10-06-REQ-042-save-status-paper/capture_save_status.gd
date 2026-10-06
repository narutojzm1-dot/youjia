extends SceneTree
const VIEWPORTS := [Vector2i(360, 640), Vector2i(390, 844), Vector2i(568, 320), Vector2i(640, 300)]
var out := OS.get_environment("CAP_OUT")
func _initialize() -> void:
	call_deferred("_run")
func _settle(n := 8) -> void:
	for i in n:
		await process_frame
func _run() -> void:
	var i18n = root.get_node("/root/I18n")
	for dims in VIEWPORTS:
		root.size = dims
		DisplayServer.window_set_size(dims)
		var main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		await _settle()
		main._start_holiday()
		await _settle(30)
		for locale in ["zh-CN", "en"]:
			i18n.set_locale(locale)
			await _settle()
			main._show_save_pending(false)
			await _settle(6)
			var img := root.get_texture().get_image()
			var p := "%s/%dx%d-%s.png" % [out, dims.x, dims.y, locale]
			img.save_png(p)
			var r: Rect2 = main._save_status_panel.get_global_rect()
			print("CAP %s panel=%s day=%s hint=%s btn=%s" % [p, r, main._day_label.get_global_rect(), main._hint_panel.get_global_rect(), main._save_retry_button.text])
			main._save_status_panel.hide()
		main.queue_free()
		await _settle()
	quit(0)
