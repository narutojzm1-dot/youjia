extends SceneTree

## REQ-20261006-040: the pause page's music/ambience volume sliders are drawn
## on the warm paper panel instead of Godot's default grey bar and near-white
## dot. Styled by the PaperSliderBoot autoload, so scripts/main.gd is not
## edited. Visual only: range, step, size, focus mode, mouse filter, signal wiring,
## input routing (#382) and the default focus ring (#459) are unchanged.

const PAPER := Color("fff6e8")
const CREAM := Color("fffaf1")
const VIEWPORTS := [
	Vector2i(1280, 720), Vector2i(1024, 600), Vector2i(390, 844), Vector2i(360, 640),
	Vector2i(320, 568), Vector2i(844, 390), Vector2i(667, 375), Vector2i(568, 320),
	Vector2i(640, 300),
]

var checks := 0
var failures: Array[String] = []
var main


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for dims in VIEWPORTS:
		root.size = dims
		main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		await process_frame
		await process_frame
		main.set_process(false)
		await main._start_holiday()
		main._layout()
		main._toggle_pause()
		await _settle()
		for pair in [["music", main._music_slider, main._music_volume_label], ["ambience", main._ambience_slider, main._ambience_volume_label]]:
			_check_slider("%s %s" % [dims, pair[0]], dims, pair[1])
		await _check_value_still_drives_label(dims)
		main._toggle_pause()
		await _settle()
		main.queue_free()
		await process_frame
		await process_frame
	_check_palette()
	_finish()


func _check_slider(tag: String, dims: Vector2i, slider: HSlider) -> void:
	_check(slider != null and slider.is_visible_in_tree(), "%s slider visible on pause page" % tag)
	if slider == null:
		return
	# Unchanged behaviour surface.
	_check(slider.min_value == 0.0 and slider.max_value == 100.0 and slider.step == 1.0, "%s range/step unchanged" % tag)
	_check(slider.focus_mode == Control.FOCUS_ALL, "%s focus mode unchanged" % tag)
	_check(slider.mouse_filter == Control.MOUSE_FILTER_STOP, "%s mouse filter unchanged" % tag)
	var short: bool = main.size.y < 500.0
	_check(is_equal_approx(slider.custom_minimum_size.y, 28.0 if short else 32.0), "%s hit height unchanged (%.0f)" % [tag, slider.custom_minimum_size.y])
	_check(not slider.has_theme_stylebox_override("focus"), "%s focus ring left to #459 (no override)" % tag)
	_check(slider.value_changed.get_connections().size() >= 1, "%s still wired to its gain handler" % tag)
	# Track.
	var track = slider.get_theme_stylebox("slider")
	_check(track is StyleBoxFlat, "%s track is a warm flat stylebox" % tag)
	if track is StyleBoxFlat:
		_check(not _is_greyish(track.bg_color), "%s track is not the default grey (%s)" % [tag, track.bg_color.to_html(false)])
		_check(track.bg_color.a >= 0.99, "%s track opaque" % tag)
		_check(track.border_width_top >= 1, "%s track has an edge" % tag)
		_check(_contrast(track.border_color, PAPER) >= 3.0, "%s track edge ≥3:1 on PAPER (%.2f)" % [tag, _contrast(track.border_color, PAPER)])
		var h: float = track.get_minimum_size().y
		_check(h >= 6.0 and h <= 12.0, "%s track 6–12px tall (%.0f)" % [tag, h])
		_check(track.corner_radius_top_left >= int(h * 0.5) - 1, "%s track ends are rounded" % tag)
	# Filled part.
	for name in ["grabber_area", "grabber_area_highlight"]:
		var area = slider.get_theme_stylebox(name)
		_check(area is StyleBoxFlat, "%s %s is flat" % [tag, name])
		if area is StyleBoxFlat and track is StyleBoxFlat:
			_check(not _is_greyish(area.bg_color), "%s %s is warm, not grey" % [tag, name])
			_check(_contrast(area.bg_color, PAPER) >= 3.0, "%s %s ≥3:1 on PAPER (%.2f)" % [tag, name, _contrast(area.bg_color, PAPER)])
			_check(_contrast(area.bg_color, track.bg_color) >= 3.0, "%s %s ≥3:1 against the unfilled track (%.2f)" % [tag, name, _contrast(area.bg_color, track.bg_color)])
			_check(is_equal_approx(area.get_minimum_size().y, track.get_minimum_size().y), "%s %s same height as track" % [tag, name])
	# Handle.
	for name in ["grabber", "grabber_highlight", "grabber_disabled"]:
		var icon: Texture2D = slider.get_theme_icon(name)
		_check(icon != null, "%s %s icon present" % [tag, name])
		if icon == null:
			continue
		var sz := icon.get_size()
		_check(sz.x >= 20.0 and sz.x <= 28.0 and is_equal_approx(sz.x, sz.y), "%s %s is a 20–28px disc (%s)" % [tag, name, sz])
		_check(sz.y <= slider.size.y + 0.5, "%s %s fits inside the slider rect (%.0f ≤ %.0f)" % [tag, name, sz.y, slider.size.y])
		_check(icon is DPITexture, "%s %s is vector (stays crisp on HiDPI)" % [tag, name])
	# Geometry stays inside the panel and screen.
	var r: Rect2 = slider.get_global_rect()
	var panel: Rect2 = main._pause_panel.get_global_rect()
	_check(panel.grow(0.5).encloses(r), "%s slider inside pause panel" % tag)
	_check(Rect2(Vector2.ZERO, Vector2(dims)).grow(0.5).encloses(r), "%s slider on screen" % tag)


func _check_value_still_drives_label(dims: Vector2i) -> void:
	var slider: HSlider = main._music_slider
	var before: float = slider.value
	slider.value = 40.0
	await process_frame
	_check(main._music_volume_label.text.contains("40"), "%s moving music slider still updates its label (%s)" % [dims, main._music_volume_label.text])
	slider.value = before
	await process_frame
	_check(main._music_volume_label.text.contains(str(int(before))), "%s label returns with value" % dims)


func _check_palette() -> void:
	_check(root.has_node("PaperSliderBoot"), "PaperSliderBoot autoload is registered")
	var style = load("res://scripts/ui/paper_slider_style.gd")
	_check(style != null, "PaperSliderStyle script loads")
	if style == null:
		return
	_check(_contrast(style.GRABBER_RING, style.GRABBER_FILL) >= 3.0, "handle ring ≥3:1 on its own fill")
	_check(_contrast(style.GRABBER_RING, PAPER) >= 3.0, "handle ring ≥3:1 on PAPER")
	_check(_contrast(style.GRABBER_HOVER_RING, style.GRABBER_HOVER_FILL) >= 3.0, "hover handle ring ≥3:1 on hover fill")
	_check(_contrast(style.GRABBER_RING, style.TRACK_FILL) >= 3.0, "handle ring ≥3:1 on the unfilled track")


func _is_greyish(c: Color) -> bool:
	return absf(c.r - c.g) < 0.03 and absf(c.g - c.b) < 0.03


func _lum(c: Color) -> float:
	var ch := func(v: float) -> float:
		return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * ch.call(c.r) + 0.7152 * ch.call(c.g) + 0.0722 * ch.call(c.b)


func _contrast(a: Color, b: Color) -> float:
	var la := _lum(a)
	var lb := _lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)


func _settle() -> void:
	for i in 4:
		await process_frame


func _finish() -> void:
	if failures.is_empty():
		print("[volume-slider-style] PASS: %d checks" % checks)
	else:
		for failure in failures:
			printerr("[volume-slider-style] " + failure)
		print("[volume-slider-style] FAIL: %d failures across %d checks" % [failures.size(), checks])
	root.get_node("AudioDirector").call("release_streams")
	quit(0 if failures.is_empty() else 1)
