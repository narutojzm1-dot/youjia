extends SceneTree
# REQ-20261007-063：近郊画卷按钮不接鼠标事件，点按统一走 press_at，所以 Godot 的按下态从不出现。
# 点中可用按钮时短暂显示按下的杏纸 + 墨色边，然后回到原样；不可用、点路面、暂停都不留下按下的样子；
# 按钮大小、文字、点一次只触发一次都不变。

const MemoryStore := preload("res://test/fixtures/exploration_memory_store.gd")
const CLOCK := {"day": 3, "elapsed": 12.5}
const VIEWS := [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(568, 320), Vector2i(390, 844), Vector2i(320, 568), Vector2i(280, 653)]
const CREAM := Color("fffaf1")
const APRICOT := Color("f3b27a")
const INK := Color("5b4637")
const TAP_FILL := Color("f3d3ae")

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
	_style_checks()
	var before_locale: String = i18n.get_locale()
	for locale: String in ["zh-CN", "en"]:
		i18n.set_locale(locale)
		for view_size: Vector2i in VIEWS:
			await _view(locale, view_size)
	i18n.set_locale(before_locale)
	for store in stores:
		store.free()
	print("[exploration-tap-feedback] ", "PASS: %d checks" % checks if failures.is_empty() else "FAIL: %d/%d %s" % [failures.size(), checks, failures])
	quit(0 if failures.is_empty() else 1)


func _style_checks() -> void:
	var has_tap: bool = Scroll.get_script_method_list().any(func(m: Dictionary) -> bool: return m.name == "tap_style")
	check(has_tap, "tap_style exists")
	if not has_tap:
		return
	var tap: StyleBoxFlat = Scroll.tap_style()
	var normal: StyleBoxFlat = Scroll.button_style("normal")
	check(tap.bg_color == TAP_FILL, "tap fill warm apricot paper")
	check(tap.border_color == INK, "tap edge ink")
	check(tap.bg_color != normal.bg_color and tap.border_color != normal.border_color, "tap differs from normal")
	check(contrast(INK, TAP_FILL) >= 4.5, "ink on tap fill AA %.2f" % contrast(INK, TAP_FILL))
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		check(tap.get_border_width(side) == normal.get_border_width(side), "same edge width %d" % side)
		check(is_equal_approx(tap.get_margin(side), normal.get_margin(side)), "same content margin %d" % side)
	check(tap.corner_radius_top_left == normal.corner_radius_top_left and tap.corner_radius_bottom_right == normal.corner_radius_bottom_right, "same radius")
	check(normal.bg_color == CREAM and normal.border_color == APRICOT, "normal unchanged")


func _normal_is_cream(button: Button) -> bool:
	var style := button.get_theme_stylebox("normal") as StyleBoxFlat
	return style != null and style.bg_color == CREAM and style.border_color == APRICOT


func _normal_is_tap(button: Button) -> bool:
	var style := button.get_theme_stylebox("normal") as StyleBoxFlat
	return style != null and style.bg_color == TAP_FILL and style.border_color == INK


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
	if not scroll.has_method("flash_tap"):
		check(false, "[%s %dx%d] flash_tap exists" % [locale, view_size.x, view_size.y])
		scroll.queue_free()
		await process_frame
		return
	# 只测点按回应本身：先把按钮原来的动作摘下，换成计数探针，免得回院/暂停改掉场景
	scroll.set_process(false)
	for button_name: String in ["_return_button", "_pause_button", "_look_button", "_pick_button", "_go_button"]:
		var button: Button = scroll.get(button_name)
		var tag := "[%s %dx%d %s] " % [locale, view_size.x, view_size.y, button_name]
		var saved: Array = button.pressed.get_connections()
		for connection: Dictionary in saved:
			button.pressed.disconnect(connection.callable)
		var fired := [0]
		var probe := func() -> void: fired[0] += 1
		button.pressed.connect(probe)
		var was_visible := button.visible
		var was_disabled := button.disabled
		var was_text := button.text
		button.visible = true
		if button.text.is_empty():
			button.text = "Take" if locale == "en" else "带上"
		button.disabled = false
		await process_frame
		var rest_size := button.get_combined_minimum_size()
		check(_normal_is_cream(button), tag + "rests cream")
		var center := button.get_global_rect().get_center()
		scroll.press_at(center)
		check(fired[0] == 1, tag + "tap fires once (%d)" % fired[0])
		check(scroll.tap_flashing(button), tag + "tap shows pressed look")
		check(_normal_is_tap(button), tag + "pressed look is apricot paper + ink edge")
		await process_frame
		check(button.get_combined_minimum_size() == rest_size, tag + "size stable while pressed")
		check(button.text == (was_text if not was_text.is_empty() else button.text), tag + "text unchanged")
		scroll._tick_tap_flash(0.05)
		check(scroll.tap_flashing(button), tag + "still pressed after 0.05s")
		scroll._tick_tap_flash(0.12)
		check(not scroll.tap_flashing(button), tag + "released after 0.17s")
		check(_normal_is_cream(button), tag + "back to cream")
		# 连点两下：第二下重新计时，只算两次
		scroll.press_at(center)
		scroll._tick_tap_flash(0.1)
		scroll.press_at(center)
		scroll._tick_tap_flash(0.1)
		check(fired[0] == 3, tag + "double tap fires twice more (%d)" % fired[0])
		check(scroll.tap_flashing(button), tag + "second tap restarts pressed look")
		# 暂停/失焦立即收回
		scroll.notification(Node.NOTIFICATION_PAUSED)
		check(not scroll.tap_flashing(button) and _normal_is_cream(button), tag + "pause settles pressed look")
		scroll.press_at(center)
		scroll.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		check(not scroll.tap_flashing(button) and _normal_is_cream(button), tag + "focus out settles pressed look")
		# 不可用时点它：不触发、不显示按下
		button.disabled = true
		scroll.press_at(center)
		check(fired[0] == 4, tag + "disabled tap ignored (%d)" % fired[0])
		check(not scroll.tap_flashing(button), tag + "disabled tap no pressed look")
		button.disabled = false
		button.pressed.disconnect(probe)
		for connection: Dictionary in saved:
			button.pressed.connect(connection.callable)
		button.disabled = was_disabled
		button.visible = was_visible
		button.text = was_text
	# 点路面：没有按钮显示按下
	var size := Vector2(view_size)
	scroll.walk_target = {}
	scroll.press_at(Vector2(size.x * 0.5, size.y * 0.62))
	for button_name: String in ["_return_button", "_pause_button", "_look_button", "_pick_button", "_go_button"]:
		var b: Button = scroll.get(button_name)
		if scroll.tap_flashing(b):
			check(false, "[%s %dx%d] road tap flashed %s" % [locale, view_size.x, view_size.y, button_name])
	checks += 1
	# 真实帧推进也会收回（不只靠手动 tick）
	var go: Button = scroll.get("_go_button")
	go.visible = true
	await process_frame
	var saved_go: Array = go.pressed.get_connections()
	for connection: Dictionary in saved_go:
		go.pressed.disconnect(connection.callable)
	scroll.press_at(go.get_global_rect().get_center())
	check(scroll.tap_flashing(go), "[%s %dx%d] go flashes" % [locale, view_size.x, view_size.y])
	scroll.set_process(true)
	var waited := 0
	while scroll.tap_flashing(go) and waited < 60:
		await process_frame
		waited += 1
	check(not scroll.tap_flashing(go) and _normal_is_cream(go), "[%s %dx%d] frames release pressed look" % [locale, view_size.x, view_size.y])
	for connection: Dictionary in saved_go:
		go.pressed.connect(connection.callable)
	# 离开画卷时也收回
	scroll.flash_tap(go)
	scroll.release()
	check(not scroll.tap_flashing(go) and _normal_is_cream(go), "[%s %dx%d] release settles" % [locale, view_size.x, view_size.y])
	scroll.queue_free()
	await process_frame
