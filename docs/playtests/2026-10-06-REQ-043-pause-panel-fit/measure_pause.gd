extends SceneTree

# REQ-20261006-043 evidence: print the pause paper rect and how much empty paper
# sits above the title / below the lowest control. This folder has .gdignore, so
# copy the script to the project root first, then per viewport:
#   M_W=844 M_H=390 godot --headless --path . --script res://measure_pause.gd
# Native 4.7.2 only; evidence script, never part of an export.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var dims := Vector2i(int(OS.get_environment("M_W")), int(OS.get_environment("M_H")))
	if dims.x > 0:
		root.size = dims
	var main: Variant = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	for i in 4: await process_frame
	main.set_process(false)
	await main._start_holiday()
	for i in 4: await process_frame
	main._toggle_pause()
	for i in 6: await process_frame
	var panel: Rect2 = main._pause_panel.get_global_rect()
	var top := INF
	var bottom := -INF
	for n: Control in [main._pause_title, main._resume_button, main._restart_button, main._pause_title_button, main._mute_toggle, main._music_toggle, main._music_slider, main._ambience_toggle, main._ambience_slider]:
		if n.is_visible_in_tree():
			top = minf(top, n.get_global_rect().position.y)
			bottom = maxf(bottom, n.get_global_rect().end.y)
	print("[pause-fit] viewport=%dx%d panel=(%d,%d %dx%d) empty_above_title=%d empty_below_last=%d" % [root.size.x, root.size.y, panel.position.x, panel.position.y, panel.size.x, panel.size.y, top - panel.position.y, panel.end.y - bottom])
	main.queue_free()
	await process_frame
	quit(0)
