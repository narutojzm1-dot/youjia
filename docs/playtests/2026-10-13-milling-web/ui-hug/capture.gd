extends SceneTree
var output := ""
func _initialize() -> void: call_deferred("run")
func run() -> void:
	# Public archive: the original capture SHA is recorded in sources.json.
	output = OS.get_environment("YOUJIA_FLOUR_PAPER_CAPTURE_DIR")
	if output.is_empty():
		push_error("Set YOUJIA_FLOUR_PAPER_CAPTURE_DIR to an isolated output directory")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	for locale in ["zh-CN","en"]:
		root.get_node("I18n").set_locale(locale)
		for viewport in [Vector2i(1280,720),Vector2i(390,844)]:
			root.size = viewport
			var panel = load("res://scripts/ui/yard_basket_panel.gd").new()
			root.add_child(panel)
			for i in 4: await process_frame
			panel.update_view({"fish":{"small":0,"medium":0,"odd":1},"grass":0,"millet":2,"wheat":1,"corn":2,"flour":1,"held":""},{},"ready",false)
			for i in 4: await process_frame
			panel.grid.open_menu("flour")
			print("FLOUR_PAPER initial ",locale," ",viewport," paper=",panel.grid.menu.get_global_rect())
			for i in 4: await process_frame
			await RenderingServer.frame_post_draw
			var name := "%s-%dx%d" % [locale,viewport.x,viewport.y]
			root.get_texture().get_image().save_png(output+"/after-"+name+".png")
			print("FLOUR_PAPER settled ",name," paper=",panel.grid.menu.get_global_rect()," bottom_gap=",panel.grid.menu.get_global_rect().end.y-panel.grid.menu_close.get_global_rect().end.y)
			panel.queue_free()
			await process_frame
	quit(0)
