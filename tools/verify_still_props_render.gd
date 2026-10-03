extends Node

# Run the paired scene with a real renderer. Also usable in a temporary Web
# acceptance entry; the normal game's export excludes tools and this scene.
var checks := 0
var failures: Array[String] = []
var viewport: SubViewport
var prop: YardPropVisual
var tuning: Node

func _ready() -> void:
	call_deferred("_run")

func _state(kind: String, reduced: bool, phase: float, flash: float = 0.0) -> Dictionary:
	var state := {"nearby": true, "phase": phase, "reduced_motion": reduced}
	if kind in ["sprout", "bloom", "harvest"]:
		state.merge({"plant_state": 2 if kind == "sprout" else 3, "soil_reveal": 1.0, "harvest_flash": flash})
	else:
		state.merge({"fish_state": 2 if kind == "bite" else 0, "fish_type": ""})
	return state

func _picture(kind: String, state: Dictionary) -> Image:
	prop.configure("plant" if kind in ["sprout", "bloom", "harvest"] else "fishing", state)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func _run() -> void:
	tuning = get_node("/root/TuningStore")
	viewport = SubViewport.new()
	viewport.size = Vector2i(256, 192)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	prop = YardPropVisual.new()
	prop.position = Vector2(128, 96)
	prop.scale = Vector2.ONE * 2.0
	viewport.add_child(prop)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.dispatchEvent(new Event('youjia:first-frame'));", true)
	for kind: String in ["sprout", "bloom", "harvest", "ripple", "bite"]:
		var a := await _picture(kind, _state(kind, true, 0.7, 1.4 if kind == "harvest" else 0.0))
		var b := await _picture(kind, _state(kind, true, 2.3, 0.9 if kind == "harvest" else 0.0))
		_check(a.get_data() == b.get_data(), kind + " reduced drawing is pixel-stable across time")
		a = await _picture(kind, _state(kind, false, 0.7, 1.4 if kind == "harvest" else 0.0))
		b = await _picture(kind, _state(kind, false, 2.3, 0.9 if kind == "harvest" else 0.0))
		_check(a.get_data() != b.get_data(), kind + " ordinary motion remains visible")
		for reduced: bool in [false, true]:
			tuning.set_value("ui.reduced_motion", reduced, false)
			var frozen := YardPropVisual.sanitize_state("plant" if kind in ["sprout", "bloom", "harvest"] else "fishing", JSON.parse_string(JSON.stringify(_state(kind, reduced, 1.4, 1.2 if kind == "harvest" else 0.0))))
			a = await _picture(kind, frozen)
			tuning.set_value("ui.reduced_motion", not reduced, false)
			b = await _picture(kind, frozen)
			_check(a.get_data() == b.get_data(), kind + " saved prop pixels ignore later preferences")
	tuning.set_value("ui.reduced_motion", false, false)
	viewport.queue_free()
	_show_gallery()
	print("[still-prop-render] %s: %d checks, failures=%s" % ["PASS" if failures.is_empty() else "FAIL", checks, failures])
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.stillPropsResult=" + JSON.stringify({"checks": checks, "failures": failures}) + ";", true)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var output := OS.get_environment("YOUJIA_CAPTURE_PATH")
	if not output.is_empty():
		get_viewport().get_texture().get_image().save_png(output)
	if "--quit-after-test" in OS.get_cmdline_user_args():
		get_node("/root/AudioDirector").call("release_streams")
		get_tree().quit(0 if failures.is_empty() else 1)

func _show_gallery() -> void:
	var paper := ColorRect.new()
	paper.size = Vector2(1280, 720)
	paper.color = Color("fff6e8")
	add_child(paper)
	for row: int in 2:
		var heading := Label.new()
		heading.text = "Captured reduced motion" if row == 1 else "Captured ordinary phase"
		heading.position = Vector2(40, 55 + row*300)
		heading.add_theme_color_override("font_color", Color("5b4637"))
		heading.add_theme_font_size_override("font_size", 24)
		add_child(heading)
		var kinds := ["sprout", "bloom", "harvest", "ripple", "bite"]
		for index: int in kinds.size():
			var visual := YardPropVisual.new()
			visual.position = Vector2(130 + index*245, 195 + row*300)
			visual.scale = Vector2.ONE * 3.0
			visual.configure("plant" if index < 3 else "fishing", _state(kinds[index], row == 1, 1.4, 1.2 if index == 2 else 0.0))
			add_child(visual)
			var label := Label.new()
			label.position = Vector2(85 + index*245, 260 + row*300)
			label.text = kinds[index]
			label.add_theme_color_override("font_color", Color("5b4637"))
			add_child(label)
