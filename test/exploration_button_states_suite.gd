extends SceneTree
# REQ-20261007-057：近郊画卷按钮（回院、暂停、看看、拿上/收养、继续走）不可用时
# 与可用时一眼分得开，字仍读得清；可用样式、按钮大小与点按逻辑不变。

const MemoryStore := preload("res://test/fixtures/exploration_memory_store.gd")
const CLOCK := {"day": 3, "elapsed": 12.5}
const VIEWS := [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(568, 320), Vector2i(390, 844), Vector2i(320, 568), Vector2i(280, 653)]
const CREAM := Color("fffaf1")
const APRICOT := Color("f3b27a")
const INK := Color("5b4637")
const MUTED := Color("8a7060")
const DISABLED_FILL := Color("f3e9db")
const DISABLED_EDGE := Color("bfa588")

var failures: Array[String] = []
var checks := 0
var stores: Array[Node] = []
var i18n: Node
var Scroll: GDScript


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


static func luminance(c: Color) -> float:
	var ch := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * ch.call(c.r) + 0.7152 * ch.call(c.g) + 0.0722 * ch.call(c.b)


static func contrast(a: Color, b: Color) -> float:
	var la := luminance(a)
	var lb := luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func run() -> void:
	i18n = root.get_node("I18n")
	Scroll = load("res://scripts/exploration/near_path_scroll.gd")
	var before_locale: String = i18n.get_locale()
	for locale: String in ["zh-CN", "en"]:
		i18n.set_locale(locale)
		for view_size: Vector2i in VIEWS:
			await _view(locale, view_size)
	i18n.set_locale(before_locale)
	for store in stores:
		store.free()
	print("[exploration-button-states] ", "PASS: %d checks" % checks if failures.is_empty() else "FAIL: %d/%d %s" % [failures.size(), checks, failures])
	quit(0 if failures.is_empty() else 1)


func _view(locale: String, view_size: Vector2i) -> void:
	root.size = view_size
	var store := MemoryStore.new()
	stores.append(store)
	var host := ExplorationHost.new(store)
	host.restore()
	host.begin(CLOCK, 1)
	var scroll: Node2D = Scroll.new()
	root.add_child(scroll)
	scroll.setup(host, "sunny")
	await process_frame
	await process_frame
	var names := ["_return_button", "_pause_button", "_look_button", "_pick_button", "_go_button"]
	for button_name: String in names:
		var button: Button = scroll.get(button_name)
		var tag := "[%s %dx%d %s] " % [locale, view_size.x, view_size.y, button_name]
		check(button != null, tag + "exists")
		if button == null:
			continue
		var normal := button.get_theme_stylebox("normal") as StyleBoxFlat
		var disabled := button.get_theme_stylebox("disabled") as StyleBoxFlat
		check(normal != null and disabled != null, tag + "flat styles")
		if normal == null or disabled == null:
			continue
		# 可用样式不变
		check(normal.bg_color == CREAM and normal.border_color == APRICOT, tag + "normal unchanged")
		check(normal.border_width_left == 2 and normal.corner_radius_top_left == 16, tag + "normal edge/radius unchanged")
		for state: String in ["hover", "pressed", "hover_pressed"]:
			var other := button.get_theme_stylebox(state) as StyleBoxFlat
			check(other != null and other.bg_color == CREAM and other.border_color == APRICOT, tag + state + " matches normal (no grey fallback)")
		# 不可用一眼分得开
		check(disabled.bg_color == DISABLED_FILL, tag + "disabled fill pale paper")
		check(disabled.border_color == DISABLED_EDGE, tag + "disabled faded edge")
		check(disabled.bg_color != normal.bg_color and disabled.border_color != normal.border_color, tag + "disabled differs from normal")
		check(disabled.border_width_left == normal.border_width_left and disabled.corner_radius_top_left == normal.corner_radius_top_left, tag + "disabled same edge width/radius")
		for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			check(is_equal_approx(disabled.get_margin(side), normal.get_margin(side)), tag + "same content margin %d" % side)
		# 字色：可用各状态都是墨色；不可用为 MUTED，在浅纸上仍有 ≥3:1 对比
		for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			check(button.get_theme_color(color_name) == INK, tag + color_name + " ink")
		var muted := button.get_theme_color("font_disabled_color")
		check(muted == MUTED, tag + "disabled font muted")
		check(contrast(muted, DISABLED_FILL) >= 3.0, tag + "disabled text readable %.2f" % contrast(muted, DISABLED_FILL))
		check(contrast(muted, DISABLED_FILL) < contrast(INK, CREAM), tag + "disabled text quieter than enabled")
		# 切换可用性时按钮矩形不变
		var was_visible := button.visible
		var was_disabled := button.disabled
		button.visible = true
		if button.text.is_empty():
			button.text = "Take" if locale == "en" else "带上"
		button.disabled = false
		await process_frame
		var enabled_size := button.get_combined_minimum_size()
		button.disabled = true
		await process_frame
		check(button.get_combined_minimum_size() == enabled_size, tag + "min size stable across disabled")
		# 不可用时点它不触发
		var fired := [0]
		var probe := func() -> void: fired[0] += 1
		button.pressed.connect(probe)
		button.disabled = true
		var center := button.get_global_rect().get_center()
		if button.get_global_rect().has_area():
			scroll.press_at(center)
			check(fired[0] == 0, tag + "disabled tap ignored")
		button.pressed.disconnect(probe)
		button.disabled = was_disabled
		button.visible = was_visible
	scroll.queue_free()
	await process_frame
