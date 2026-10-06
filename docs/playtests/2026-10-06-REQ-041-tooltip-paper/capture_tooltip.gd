extends SceneTree

# REQ-20261006-041 evidence only (not in daily, not exported). Real hover on the
# album chip, then a native screenshot. Usage (Xvfb, opengl3):
# CAP_OUT=/tmp/out.png CAP_LOCALE=zh-CN xvfb-run -a godot --path . --rendering-driver opengl3 \
#   --resolution 1280x720 -s docs/playtests/2026-10-06-REQ-041-tooltip-paper/capture_tooltip.gd
func _initialize() -> void:
	call_deferred("_capture")
func _capture() -> void:
	var out := OS.get_environment("CAP_OUT")
	var main: Variant = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	root.get_node("I18n").set_locale(OS.get_environment("CAP_LOCALE") if OS.get_environment("CAP_LOCALE") != "" else "zh-CN")
	main._start_holiday()
	for _f in 10:
		await process_frame
	await create_timer(0.5).timeout
	var chip: Control = main.get("_album_chip")
	var c := chip.get_global_rect().get_center()
	print("chip rect ", chip.get_global_rect(), " tooltip=", chip.tooltip_text)
	for i in 3:
		var ev := InputEventMouseMotion.new()
		ev.position = c + Vector2(i, 0)
		ev.global_position = ev.position
		root.push_input(ev)
		await process_frame
	await create_timer(1.6).timeout
	var image := root.get_texture().get_image()
	image.save_png(out)
	# report tooltip nodes
	for n in root.find_children("*", "", true, false):
		if n is Window and n != root:
			print("window ", n.get_class(), " ", n.name, " vis=", n.visible, " pos=", n.position, " size=", n.size, " parent=", n.get_parent().name)
			for k in n.find_children("*", "", true, false):
				if k is Label:
					print("  label ", k.text, " color=", k.get_theme_color("font_color"), " size=", k.get_theme_font_size("font_size"))
			if n is PopupPanel:
				var sb = n.get_theme_stylebox("panel")
				print("  panel ", sb, " ", (sb.bg_color if sb is StyleBoxFlat else ""))
	root.get_node("AudioDirector").call("release_streams")
	await process_frame
	quit(0)
