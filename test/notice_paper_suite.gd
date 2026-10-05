extends SceneTree

## REQ-20261005-025: bottom notice sits on a fitted paper backing so brown ink
## stays readable over the painted foreground (sun and overcast alike).
## Ink colour, font sizes, position band, timing and wrap limit are unchanged.

const INK := Color("5b4637")
const PAPER := Color("fff6e8")

var checks := 0
var failures: Array[String] = []
var main


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for dims in [Vector2i(1280, 720), Vector2i(390, 844), Vector2i(844, 390)]:
		root.size = dims
		main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		await process_frame
		await process_frame
		main.set_process(false)
		main._start_holiday()
		main._layout()
		_check_style(dims)
		_check_short(dims)
		_check_long(dims)
		_check_big_font_refit(dims)
		_check_hidden_states(dims)
		main.queue_free()
		await process_frame
	_check_contrast()
	_finish()


func _check_style(dims: Vector2i) -> void:
	var n: Label = main._notice
	var style = n.get_theme_stylebox("normal")
	_check(style is StyleBoxFlat, "%s notice has a flat paper backing" % dims)
	if style is StyleBoxFlat:
		_check(style.bg_color.a >= 0.85 and style.bg_color.a < 1.0, "%s backing is mostly opaque paper (a=%.2f)" % [dims, style.bg_color.a])
		_check(Color(style.bg_color, 1.0).is_equal_approx(PAPER), "%s backing uses the existing PAPER colour" % dims)
		_check(style.corner_radius_top_left >= 10, "%s backing has soft corners" % dims)
	_check(n.get_theme_color("font_color").is_equal_approx(INK), "%s ink colour unchanged" % dims)
	_check(n.grow_vertical == Control.GROW_DIRECTION_BEGIN, "%s wrapped notice grows upward, not onto buttons" % dims)
	_check(n.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s notice still ignores taps" % dims)


func _half_limit() -> float:
	return minf(220.0, main.size.x * 0.5 - 20.0)


func _check_short(dims: Vector2i) -> void:
	var n: Label = main._notice
	main._show_notice_key("notice.fishing.miss")
	_check(n.get_theme_font_size("font_size") == 16, "%s ordinary notice still 16px" % dims)
	var w := n.offset_right - n.offset_left
	var text_w := n.get_theme_font("font").get_string_size(n.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	_check(is_equal_approx(n.offset_left, -n.offset_right), "%s short notice centred" % dims)
	_check(w < _half_limit() * 2.0 - 1.0, "%s short notice paper hugs text (w=%.0f)" % [dims, w])
	_check(w >= text_w + 28.0, "%s short notice paper covers text plus padding (w=%.0f text=%.0f)" % [dims, w, text_w])
	_check(n.get_line_count() == 1, "%s short notice stays one line" % dims)
	var before := [n.offset_left, n.offset_right, n.offset_top, n.offset_bottom]
	main._screen = "game"
	main._process(1.0 / 60.0)
	main._process(1.0 / 60.0)
	_check(before == [n.offset_left, n.offset_right, n.offset_top, n.offset_bottom], "%s backing does not move between frames" % dims)


func _check_long(dims: Vector2i) -> void:
	var n: Label = main._notice
	main._show_notice_key("notice.first_hint")
	n.add_theme_font_size_override("font_size", 18)
	main._fit_notice()
	var half := _half_limit()
	_check(is_equal_approx(n.offset_right, half) and is_equal_approx(n.offset_left, -half), "%s long notice keeps the original wrap width (%.0f)" % [dims, half])


func _check_big_font_refit(dims: Vector2i) -> void:
	var n: Label = main._notice
	main._show_notice_key("notice.fishing.miss")
	var w16 := n.offset_right - n.offset_left
	n.add_theme_font_size_override("font_size", 22)
	main._notice_time = 3.0
	main._screen = "game"
	main._process(1.0 / 60.0)
	var w22 := n.offset_right - n.offset_left
	_check(n.visible and w22 > w16, "%s catch-size text refits on the next frame (%.0f -> %.0f)" % [dims, w16, w22])


func _check_hidden_states(dims: Vector2i) -> void:
	var n: Label = main._notice
	main._show_notice_key("notice.fishing.miss")
	main._notice_time = 0.01
	main._process(0.05)
	_check(not n.visible, "%s backing disappears with the notice" % dims)


func _luminance(c: Color) -> float:
	var f := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)


func _contrast(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _check_contrast() -> void:
	# Worst case: paper backing over pure black. INK must still clear WCAG AA (4.5:1).
	var alpha := 0.88
	var worst := Color(PAPER.r * alpha, PAPER.g * alpha, PAPER.b * alpha)
	var ratio := _contrast(INK, worst)
	_check(ratio >= 4.5, "ink on paper over black still >= 4.5:1 (%.2f)" % ratio)


func _check(ok: bool, label: String) -> void:
	checks += 1
	print("[notice_paper] ", "PASS " if ok else "FAIL ", label)
	if not ok:
		failures.append(label)


func _finish() -> void:
	print("notice paper suite checks=%d failures=%s" % [checks, failures])
	quit(0 if failures.is_empty() else 1)
