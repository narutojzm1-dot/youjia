extends SceneTree

## REQ-20261006-041: the album chip's mouse tooltip used Godot's default
## TooltipPanel (black at alpha 0.5) and TooltipLabel (light grey 0.875) on the
## cream HUD. The shared runtime Theme now gives it a near-opaque warm paper
## slip, a 1px soft-brown edge and INK text. This suite checks the resolved
## theme values and a real hover on the live album chip (pushed mouse motion,
## engine tooltip timer), in two locales and five viewports.

const PaperTooltipStyle = preload("res://scripts/ui/paper_tooltip_style.gd")
const VIEWPORTS := [Vector2i(1280, 720), Vector2i(390, 844), Vector2i(568, 320), Vector2i(844, 390), Vector2i(640, 300)]
const PAPER := Color("fff6e8")
const INK := Color("5b4637")
const TEXT_MIN := 4.5
const EDGE_MIN := 3.0

var checks := 0
var failures: Array[String] = []
var main
var i18n


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	i18n = root.get_node("/root/I18n")
	_check_theme_values()
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await main._start_holiday()
	for _f in 6:
		await process_frame
	for dims: Vector2i in VIEWPORTS:
		root.size = dims
		for locale: String in ["zh-CN", "en"]:
			i18n.set_locale(locale)
			for _f in 3:
				await process_frame
			await _check_hover("%s %s" % [dims, locale], dims)
	i18n.set_locale("zh-CN")
	root.get_node("AudioDirector").call("release_streams")
	main.queue_free()
	await process_frame
	_finish()


func _check_theme_values() -> void:
	var theme: Theme = root.get_node("/root/ManusFontTheme").get("_theme")
	_check(theme != null, "ManusFontTheme exposes its runtime Theme")
	if theme == null:
		return
	var panel := theme.get_stylebox("panel", "TooltipPanel") as StyleBoxFlat
	_check(panel != null, "runtime Theme defines TooltipPanel/panel as StyleBoxFlat")
	if panel != null:
		_check(panel.bg_color.a >= 0.95, "tooltip paper is near-opaque (a=%.2f)" % panel.bg_color.a)
		_check(_close(_flat(panel.bg_color), PAPER, 0.01), "tooltip paper is Main PAPER")
		_check(panel.get_border_width(SIDE_TOP) == 1 and panel.get_border_width(SIDE_LEFT) == 1, "tooltip has a 1px edge")
		_check(_contrast(panel.border_color, PAPER) >= EDGE_MIN, "tooltip edge >= 3:1 on PAPER (%.2f)" % _contrast(panel.border_color, PAPER))
		for under: Color in [Color.BLACK, Color.WHITE, PAPER, Color("4f6b3a")]:
			var bg := _over(panel.bg_color, under)
			var ratio := _contrast(INK, bg)
			_check(ratio >= TEXT_MIN, "INK on tooltip paper over %s >= 4.5:1 (%.2f)" % [under.to_html(false), ratio])
		_check(panel.content_margin_left >= 8 and panel.content_margin_top >= 4, "tooltip text keeps paper padding")
	_check(theme.has_color("font_color", "TooltipLabel") and _close(theme.get_color("font_color", "TooltipLabel"), INK, 0.002), "TooltipLabel font_color is INK")
	_check(theme.get_color("font_shadow_color", "TooltipLabel").a == 0.0, "TooltipLabel has no dark shadow")
	# The default being replaced, recorded so the failure mode stays visible.
	var old_bg := _over(Color(0, 0, 0, 0.5), PAPER)
	_check(_contrast(Color(0.875, 0.875, 0.875), old_bg) < TEXT_MIN, "old default tooltip was below 4.5:1 on cream (%.2f)" % _contrast(Color(0.875, 0.875, 0.875), old_bg))


func _check_hover(tag: String, dims: Vector2i) -> void:
	var chip: Control = main.get("_album_chip")
	_check(chip != null and chip.is_visible_in_tree(), "album chip visible " + tag)
	if chip == null:
		return
	var expected: String = i18n.t("hud.album.tooltip")
	_check(chip.tooltip_text == expected, "album chip tooltip text follows locale " + tag)
	var center := chip.get_global_rect().get_center()
	for i in 3:
		var ev := InputEventMouseMotion.new()
		ev.position = center + Vector2(i, 0)
		ev.global_position = ev.position
		root.push_input(ev)
		await process_frame
	var delay: float = ProjectSettings.get_setting("gui/timers/tooltip_delay_sec", 0.5)
	await create_timer(delay + 0.6).timeout
	var popup: PopupPanel = null
	for child in chip.get_children(true):
		if child is PopupPanel and child.visible:
			popup = child
	_check(popup != null, "real hover opens the album tooltip " + tag)
	if popup != null:
		var panel := popup.get_theme_stylebox("panel") as StyleBoxFlat
		_check(panel != null and panel.bg_color.a >= 0.95 and _close(_flat(panel.bg_color), PAPER, 0.01), "live tooltip resolves warm paper panel " + tag)
		var label: Label = null
		for k in popup.find_children("*", "Label", true, false):
			label = k
		_check(label != null and label.text == expected, "live tooltip shows the locale text " + tag)
		if label != null:
			_check(_close(label.get_theme_color("font_color"), INK, 0.002), "live tooltip text is INK " + tag)
			_check(label.get_theme_color("font_shadow_color").a == 0.0, "live tooltip text has no shadow " + tag)
			_check(label.get_theme_font("font") != null and label.get_theme_font("font").has_char(expected.unicode_at(0)), "live tooltip font draws the first glyph " + tag)
		var rect := Rect2(Vector2(popup.position), Vector2(popup.size))
		_check(rect.size.x > 0 and rect.size.y > 0, "live tooltip has size " + tag)
	# Leave the chip so the tooltip closes before the next viewport.
	var away := InputEventMouseMotion.new()
	away.position = Vector2(dims.x * 0.5, 4)
	away.global_position = away.position
	root.push_input(away)
	await process_frame
	await process_frame


func _flat(c: Color) -> Color:
	return Color(c.r, c.g, c.b, 1.0)


func _over(top: Color, under: Color) -> Color:
	return Color(lerpf(under.r, top.r, top.a), lerpf(under.g, top.g, top.a), lerpf(under.b, top.b, top.a), 1.0)


func _lum(c: Color) -> float:
	var ch := func(v: float) -> float: return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * ch.call(c.r) + 0.7152 * ch.call(c.g) + 0.0722 * ch.call(c.b)


func _contrast(a: Color, b: Color) -> float:
	var la := _lum(a)
	var lb := _lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _close(a: Color, b: Color, eps: float) -> bool:
	return absf(a.r - b.r) <= eps and absf(a.g - b.g) <= eps and absf(a.b - b.b) <= eps and absf(a.a - b.a) <= eps


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error("FAIL: " + label)


func _finish() -> void:
	if failures.is_empty():
		print("PASS: paper_tooltip_style %d checks" % checks)
		quit(0)
	else:
		print("FAIL: paper_tooltip_style %d/%d failed" % [failures.size(), checks])
		for f in failures:
			print("  - " + f)
		quit(1)
