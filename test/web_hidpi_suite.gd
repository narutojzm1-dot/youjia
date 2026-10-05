extends SceneTree

## REQ-20261005-026: on HiDPI Web (devicePixelRatio > 1) the UI lays out in CSS
## pixels. A 390×844 phone at DPR 3 must get the same compact portrait layout,
## font sizes and camera framing as a DPR 1 browser of the same CSS size,
## instead of a 1170×2532 desktop layout with 1/3-size text.

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_factor_rules()
	# physical canvas, browser scale, CSS size
	var cases := [
		[Vector2i(1170, 2532), 3.0, Vector2i(390, 844)],
		[Vector2i(1688, 780), 2.0, Vector2i(844, 390)],
		[Vector2i(1920, 1080), 1.5, Vector2i(1280, 720)],
		[Vector2i(1280, 720), 1.0, Vector2i(1280, 720)],
	]
	for c in cases:
		await _check_case(c[0], c[1], c[2])
	await _check_fractional()
	await _check_rescale_on_resize()
	WebHiDpi.override_scale = -1.0
	root.content_scale_factor = 1.0
	_finish()


func _check_factor_rules() -> void:
	_check(root.has_node("WebHiDpiBoot"), "WebHiDpiBoot autoload is registered")
	_check(WebHiDpi.factor_for(1.0) == 1.0, "DPR 1 keeps factor 1")
	_check(WebHiDpi.factor_for(0.5) == 1.0, "DPR below 1 never shrinks the UI")
	_check(WebHiDpi.factor_for(NAN) == 1.0, "NaN scale falls back to 1")
	_check(WebHiDpi.factor_for(INF) == 1.0, "infinite scale falls back to 1")
	_check(WebHiDpi.factor_for(2.0) == 2.0, "DPR 2 gives factor 2")
	_check(is_equal_approx(WebHiDpi.factor_for(2.625), 2.625), "fractional DPR kept as-is")
	_check(WebHiDpi.factor_for(9.0) == WebHiDpi.MAX_FACTOR, "absurd DPR clamped to MAX_FACTOR")
	WebHiDpi.override_scale = -1.0
	_check(WebHiDpi.screen_scale() == 1.0, "native/headless reads scale 1 (no web feature)")
	root.content_scale_factor = 1.0
	_check(WebHiDpi.apply(root, 2.0), "apply reports a change")
	_check(not WebHiDpi.apply(root, 2.0), "apply is a no-op when already at that factor")
	_check(not WebHiDpi.apply(null, 2.0), "apply tolerates a null window")
	root.content_scale_factor = 1.0


func _spawn(physical: Vector2i, scale: float) -> Node:
	WebHiDpi.override_scale = scale
	root.content_scale_factor = 1.0
	root.size = physical
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.set_process(false)
	main._start_holiday()
	main._layout()
	main._refresh_hud()
	return main


func _snapshot(main) -> Dictionary:
	main._process(0.016)
	return {
		"size": main.size,
		"hint_pos": main._hint_label.position,
		"hint_size": main._hint_label.size,
		"day_pos": main._day_label.position,
		"album_pos": main._album_chip.position,
		"album_size": main._album_chip.size,
		"weather_pos": main._weather_chip.position,
		"action_pos": main._action_button.position,
		"action_size": main._action_button.size,
		"pause_pos": main._pause_button.position,
		"notice_top": main._notice.offset_top,
		"zoom": main._camera.zoom,
		"hint_font": main._hint_label.get_theme_font_size("font_size"),
		"day_font": main._day_label.get_theme_font_size("font_size"),
	}


func _check_case(physical: Vector2i, scale: float, css: Vector2i) -> void:
	var tag := "%s@%.2f" % [physical, scale]
	var main = await _spawn(physical, scale)
	_check(is_equal_approx(root.content_scale_factor, scale), "%s window factor follows browser scale" % tag)
	_check(main.size.distance_to(Vector2(css)) < 0.6, "%s main lays out in CSS pixels %s (got %s)" % [tag, css, main.size])
	_check(is_equal_approx(root.get_final_transform().get_scale().x, scale), "%s still renders at physical resolution" % tag)
	var hidpi := _snapshot(main)
	var rect := Rect2(Vector2.ZERO, main.size)
	for b in [main._album_chip, main._weather_chip, main._pause_button, main._action_button]:
		_check(rect.encloses(Rect2(b.position, b.size)), "%s %s stays on screen" % [tag, b.text])
	main.queue_free()
	await process_frame
	var ref = await _spawn(css, 1.0)
	var base := _snapshot(ref)
	for key in base.keys():
		var a = hidpi[key]
		var b = base[key]
		var same: bool = a == b if typeof(a) == TYPE_INT else (a.distance_to(b) < 0.6 if a is Vector2 else absf(a - b) < 0.6)
		_check(same, "%s %s matches DPR-1 %s (%s vs %s)" % [tag, key, css, a, b])
	ref.queue_free()
	await process_frame


func _check_fractional() -> void:
	# Pixel phones: 412×915 CSS at DPR 2.625 → 1082×2402 canvas.
	var main = await _spawn(Vector2i(1082, 2402), 2.625)
	_check(absf(main.size.x - 412.2) < 0.6, "DPR 2.625 width back to ~412 CSS px (got %.1f)" % main.size.x)
	_check(main.size.x < 700.0, "DPR 2.625 portrait phone gets the compact layout")
	_check(main._action_button.size.x < main.size.x, "DPR 2.625 full-width action button fits")
	main.queue_free()
	await process_frame


func _check_rescale_on_resize() -> void:
	var main = await _spawn(Vector2i(1170, 2532), 3.0)
	# Browser zoom / moving to another monitor: new DPR arrives with a resize.
	WebHiDpi.override_scale = 2.0
	root.size = Vector2i(780, 1688)
	await process_frame
	await process_frame
	await process_frame
	_check(is_equal_approx(root.content_scale_factor, 2.0), "factor re-read after the canvas resizes")
	_check(main.size.distance_to(Vector2(390, 844)) < 0.6, "layout stays 390×844 CSS after DPR change (got %s)" % main.size)
	_check(main.size.x < 700.0 and main._action_button.size.x > 300.0, "still compact portrait after DPR change")
	main.queue_free()
	await process_frame


func _check(ok: bool, label: String) -> void:
	checks += 1
	if ok:
		print("PASS ", label)
	else:
		failures.append(label)
		print("FAIL ", label)


func _finish() -> void:
	print("web_hidpi: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)
