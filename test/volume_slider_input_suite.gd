extends SceneTree

## Controlled native fixture, not ordinary browser/device evidence. Opens the
## real Main pause screen; value changes below use Viewport.push_input through
## Main._input and the native Slider GUI, never direct slider value/handler calls.
## #382's touch/modal routing and #459 focus behavior are not repaired here.
var checks := 0
var failures: Array[String] = []
var main
var audio
var music_events := [0]
var ambience_events := [0]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(390, 844)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _settle()
	main.set_process(false)
	await main._start_holiday()
	main._layout()
	main._toggle_pause()
	await _settle()
	audio = root.get_node("AudioDirector")
	main._music_slider.value_changed.connect(func(_v: float): music_events[0] += 1)
	main._ambience_slider.value_changed.connect(func(_v: float): ambience_events[0] += 1)
	# Same Main and same slider instances: exercise real reparent across portrait
	# and short landscape rather than replacing the whole UI between cases.
	var music_id: int = main._music_slider.get_instance_id()
	var ambience_id: int = main._ambience_slider.get_instance_id()
	for dims in [Vector2i(390, 844), Vector2i(568, 320), Vector2i(390, 844)]:
		root.size = dims
		await _settle()
		main._layout()
		await _settle()
		_check(main._music_slider.get_instance_id() == music_id and main._ambience_slider.get_instance_id() == ambience_id, "%s same controls survive reparent" % dims)
		for kind in ["music", "ambience"]:
			await _exercise(kind, dims)
	main.queue_free()
	await _settle()
	audio.release_streams()
	print("[volume-slider-input] checks=%d failures=%s" % [checks, JSON.stringify(failures)])
	quit(0 if failures.is_empty() else 1)


func _exercise(kind: String, dims: Vector2i) -> void:
	var slider: HSlider = main._music_slider if kind == "music" else main._ambience_slider
	var other: HSlider = main._ambience_slider if kind == "music" else main._music_slider
	var label: Label = main._music_volume_label if kind == "music" else main._ambience_volume_label
	var own_events: Array = music_events if kind == "music" else ambience_events
	var other_events: Array = ambience_events if kind == "music" else music_events
	var untouched_value := other.value
	var untouched_gain := _gain("ambience" if kind == "music" else "music")
	var untouched_count: int = other_events[0]
	var connections := slider.value_changed.get_connections().size()
	var tag := "%s %s" % [dims, kind]
	_check(slider.is_visible_in_tree(), tag + " visible")
	_check(slider.get_theme_icon("grabber") is DPITexture, tag + " vector handle applied after layout")
	_check(is_equal_approx(slider.get_theme_icon("grabber").get_width(), 24.0), tag + " logical handle width24")
	_check(slider.get_theme_stylebox("slider") is StyleBoxFlat, tag + " warm track retained")
	_check(not slider.has_theme_stylebox_override("focus"), tag + " focus not overridden")
	_check(slider.custom_minimum_size.y == (28.0 if dims.y < 500 else 32.0), tag + " configured hit height unchanged")
	_check(main._pause_panel.get_global_rect().encloses(slider.get_global_rect()), tag + " control fits panel")
	# Engine's default center_grabber=0 maps positions over width-handle_width.
	# This is deliberately different from assuming full-rect pointer mapping.
	for value in [0, 40, 100]:
		var count_before: int = own_events[0]
		var point := _point(slider, value)
		_move(point, false)
		_mouse(point, true)
		await _settle()
		_assert_value(slider, label, kind, value, tag + " click held%d" % value)
		_mouse(point, false)
		await _settle()
		_assert_value(slider, label, kind, value, tag + " click released%d" % value)
		# Native Slider notifies on every press, including a click at the current value.
		_check(own_events[0] == count_before + 1, tag + " one native press value notification, including unchanged value")
	# One held gesture traverses both inner and edge values. Native gui_input
	# must read actual button/motion events; moving after release must not drag.
	var start := _point(slider, 0)
	_move(start, false)
	_mouse(start, true)
	await _settle()
	for value in [40, 100, 0]:
		_move(_point(slider, value), true)
		await _settle()
		_assert_value(slider, label, kind, value, tag + " drag%d" % value)
	_mouse(_point(slider, 0), false)
	await _settle()
	var released_count: int = own_events[0]
	_move(_point(slider, 100), false)
	await _settle()
	_assert_value(slider, label, kind, 0, tag + " no drag after release")
	_check(own_events[0] == released_count, tag + " release stops value_changed")
	_check(is_equal_approx(other.value, untouched_value) and is_equal_approx(_gain("ambience" if kind == "music" else "music"), untouched_gain), tag + " other track value/gain untouched")
	_check(other_events[0] == untouched_count, tag + " no other-track signal")
	_check(slider.value_changed.get_connections().size() == connections, tag + " no new handler while exercising")
	print("VOLUME_SLIDER_INPUT_TRACE ", JSON.stringify({"viewport": str(dims), "track": kind, "value": slider.value, "gain": _gain(kind), "other_value": other.value, "rect": str(slider.get_global_rect()), "handle": str(slider.get_theme_icon("grabber").get_size()), "connections": connections}))


func _point(slider: HSlider, value: int) -> Vector2:
	var rect := slider.get_global_rect()
	var width: float = slider.get_theme_icon("grabber_highlight").get_width()
	return rect.position + Vector2(width * 0.5 + (rect.size.x - width) * float(value) / 100.0, rect.size.y * 0.5)


func _gain(kind: String) -> float:
	return audio.music_gain() if kind == "music" else audio.ambience_gain()


func _assert_value(slider: HSlider, label: Label, kind: String, expected: int, tag: String) -> void:
	_check(is_equal_approx(slider.value, float(expected)), tag + " actual Slider value")
	_check(is_equal_approx(_gain(kind), float(expected) / 100.0), tag + " actual AudioDirector gain")
	_check(label.text.ends_with(" %d%%" % expected), tag + " gain label matches: " + label.text)


func _mouse(point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	event.pressed = down
	root.push_input(event, true)


func _move(point: Vector2, down: bool) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	root.push_input(event, true)


func _settle() -> void:
	for i in 4:
		await process_frame


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
