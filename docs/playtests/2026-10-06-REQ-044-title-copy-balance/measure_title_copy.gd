extends SceneTree

# REQ-20261006-044 evidence: print how the title tagline and controls hint wrap.
# This folder has .gdignore, so copy the script to the project root first, then:
#   M_W=844 M_H=390 godot --headless --path . --script res://measure_title_copy.gd
# Native 4.7.2 only; evidence script, never part of an export.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var dims := Vector2i(int(OS.get_environment("M_W")), int(OS.get_environment("M_H")))
	if dims.x > 0:
		root.size = dims
	var main: Variant = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	for i in 6: await process_frame
	var ts := TextServerManager.get_primary_interface()
	for label: Label in [main._tagline_label, main._title_hint]:
		var font: Font = label.get_theme_font("font")
		var lines: PackedStringArray = []
		for para: String in label.text.split("\n"):
			var shaped := ts.create_shaped_text()
			ts.shaped_text_add_string(shaped, para, font.get_rids(), label.get_theme_font_size("font_size"))
			var br := ts.shaped_text_get_line_breaks(shaped, label.size.x, 0, TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE)
			ts.free_rid(shaped)
			for i in range(0, br.size(), 2):
				lines.append(para.substr(br[i], br[i + 1] - br[i]).strip_edges())
		print("[title-copy] viewport=%dx%d %s width=%d lines=%d | %s" % [root.size.x, root.size.y, "tagline" if label == main._tagline_label else "hint", label.size.x, label.get_line_count(), " / ".join(lines)])
	main.queue_free()
	await process_frame
	quit(0)
