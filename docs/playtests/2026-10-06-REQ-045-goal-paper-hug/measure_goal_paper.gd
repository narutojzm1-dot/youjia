extends SceneTree

## REQ-20261006-045 evidence: prints the real first-arrival goal paper geometry
## (paper x, y, w, h, the widest text line, and the empty paper right of it) for each viewport, Chinese copy.
## Run from the repo root: godot --headless --path . -s <this file>

const VIEWPORTS := [Vector2i(844, 390), Vector2i(915, 412), Vector2i(1280, 720), Vector2i(1024, 600), Vector2i(700, 400), Vector2i(640, 360), Vector2i(568, 320), Vector2i(390, 844), Vector2i(360, 640)]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var i18n = root.get_node("/root/I18n")
	i18n.set_locale("zh-CN")
	for dims in VIEWPORTS:
		root.size = dims
		var main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		for i in 4: await process_frame
		main.set_process(false)
		await main._start_holiday()
		for i in 4: await process_frame
		main._refresh_hud()
		await process_frame
		var label: Label = main._hint_label
		var paper: Panel = main._hint_panel
		var font := label.get_theme_font("font")
		var text_w := 0.0
		for segment: String in label.text.split("\n"):
			text_w = maxf(text_w, font.get_string_size(segment, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x)
		var lines := label.get_line_count()
		var right_gap: float = paper.position.x + paper.size.x - (label.position.x + text_w)
		print("%dx%d | %s | lines %d | paper %d,%d,%d,%d | widest line %.0fpx | empty paper right of text %.0fpx" % [dims.x, dims.y, label.text.replace("\n", "/"), lines, paper.position.x, paper.position.y, paper.size.x, paper.size.y, text_w, right_gap])
		main.queue_free()
		await process_frame
	quit(0)
