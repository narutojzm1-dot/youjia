extends SceneTree

## REQ-20261007-049: in the yard's big basket the take / put-back / check-again
## / close buttons used one #eadcc8 fill and one #b88a61 edge for hover, pressed
## AND disabled, with only the label dimmed to #7a6152 (about 4.25:1). With an
## empty basket, something already in hand or a save being confirmed, a whole
## column of "拿一条 / 拿一束 / 收回背篓" looked held down and read worse than
## the live ones. Disabled now uses the same pale warm paper fill and 1px soft
## tan edge as Main._soft_button (REQ-20261006-038), label >= 4.5:1 yet lighter
## than enabled; normal / hover / pressed / focus, sizes, copy and when a
## button is disabled are unchanged. Fixture only: the standalone panel never
## touches SaveStore; the Main pass runs in the runner's isolated profile.

const VIEWPORTS := [Vector2i(390, 844), Vector2i(360, 640), Vector2i(568, 320), Vector2i(844, 390), Vector2i(1280, 720)]
const TEXT_MIN := 4.5
const NORMAL_FILL := Color("fffaf1")
const ACTIVE_FILL := Color("eadcc8")
const EDGE := Color("b88a61")
const DISABLED_FILL := Color("f3e9db")
const DISABLED_EDGE := Color("bfa588")
const DISABLED_TEXT := Color("7a6152")
const INK := Color("5b4637")
const PANEL_PAPER := Color("fff6e8")

var checks := 0
var failures: Array[String] = []
var i18n


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)


func _run() -> void:
	i18n = root.get_node("/root/I18n")
	var original_locale: String = i18n.get_locale()
	_check_constants()
	for dims in VIEWPORTS:
		root.size = dims
		var panel: Control = load("res://scripts/ui/yard_basket_panel.gd").new()
		root.add_child(panel)
		await _settle()
		for locale in ["zh-CN", "en"]:
			i18n.set_locale(locale)
			for scenario: Dictionary in _scenarios():
				panel.update_view(scenario.inventory, {"stone": 1}, scenario.state, scenario.busy)
				await _settle()
				var tag := "%s %s %s" % [dims, locale, scenario.name]
				_check_states(panel, scenario, tag)
				for button: Button in _buttons(panel):
					_check_theme(button, "%s %s" % [tag, _button_name(panel, button)])
					if button.is_visible_in_tree():
						_check_fit(panel, button, dims, "%s %s" % [tag, _button_name(panel, button)])
		panel.queue_free()
		await _settle()
	await _check_main()
	i18n.set_locale(original_locale)
	_finish()


func _scenarios() -> Array:
	return [
		{"name": "empty", "inventory": {}, "state": "failed", "busy": false},
		{"name": "stocked", "inventory": {"grass": 3, "fish": {"small": 2}, "held": ""}, "state": "committed", "busy": false},
		{"name": "holding", "inventory": {"grass": 3, "fish": {"small": 2, "odd": 1}, "held": "medium"}, "state": "committed", "busy": false},
		{"name": "saving", "inventory": {"grass": 3, "fish": {"small": 2}, "held": "small"}, "state": "saving", "busy": true},
	]


func _check_constants() -> void:
	var panel_script = load("res://scripts/ui/yard_basket_panel.gd")
	var consts: Dictionary = panel_script.get_script_constant_map()
	check(consts.get("BUTTON_DISABLED_FILL") == DISABLED_FILL, "disabled fill matches Main soft disabled")
	check(consts.get("BUTTON_DISABLED_EDGE") == DISABLED_EDGE, "disabled edge matches Main soft disabled")
	check(consts.get("BUTTON_DISABLED_TEXT") == DISABLED_TEXT, "disabled text matches Main soft disabled")
	var main_consts: Dictionary = load("res://scripts/main.gd").get_script_constant_map()
	check(main_consts.get("SOFT_DISABLED_FILL") == DISABLED_FILL, "Main SOFT_DISABLED_FILL still the shared value")
	check(main_consts.get("SOFT_DISABLED_EDGE") == DISABLED_EDGE, "Main SOFT_DISABLED_EDGE still the shared value")
	check(main_consts.get("SOFT_DISABLED_TEXT") == DISABLED_TEXT, "Main SOFT_DISABLED_TEXT still the shared value")
	check(_contrast(DISABLED_TEXT, DISABLED_FILL) >= TEXT_MIN, "disabled label on disabled fill >= 4.5:1 (%.2f)" % _contrast(DISABLED_TEXT, DISABLED_FILL))
	check(_contrast(DISABLED_TEXT, ACTIVE_FILL) < TEXT_MIN, "old disabled fill really was below 4.5:1 (%.2f)" % _contrast(DISABLED_TEXT, ACTIVE_FILL))


func _check_states(panel: Control, scenario: Dictionary, tag: String) -> void:
	var inventory: Dictionary = scenario.inventory
	var held := str(inventory.get("held", ""))
	for kind: String in panel.FISH:
		var count := int(inventory.get("grass", 0)) if kind == "grass" else int(inventory.get("fish", {}).get(kind, 0))
		var expect_disabled: bool = inventory.is_empty() or scenario.busy or not held.is_empty() or count == 0
		check(panel.fish_buttons[kind].disabled == expect_disabled, "%s take %s disabled rule unchanged" % [tag, kind])
	check(panel.return_button.disabled == (scenario.busy or held.is_empty()), "%s put-back disabled rule unchanged" % tag)
	var en: bool = i18n.get_locale() == "en"
	for kind: String in panel.FISH:
		var want := "Take one" if en else ("拿一束" if kind == "grass" else "拿一条")
		check(panel.fish_buttons[kind].text == want, "%s take %s copy unchanged" % [tag, kind])
	check(panel.return_button.text == ("Put it back" if en else "收回背篓"), "%s put-back copy unchanged" % tag)
	check(panel.close_button.text == ("Back to the yard" if en else "合上背篓"), "%s close copy unchanged" % tag)
	var any_disabled := false
	var any_enabled := false
	for button: Button in _buttons(panel):
		if not button.is_visible_in_tree(): continue
		if button.disabled: any_disabled = true
		else: any_enabled = true
	check(any_enabled, "%s at least close stays enabled" % tag)
	check(any_disabled, "%s scenario exercises a disabled button" % tag)


func _check_theme(button: Button, tag: String) -> void:
	var disabled := button.get_theme_stylebox("disabled") as StyleBoxFlat
	var normal := button.get_theme_stylebox("normal") as StyleBoxFlat
	var hover := button.get_theme_stylebox("hover") as StyleBoxFlat
	var pressed := button.get_theme_stylebox("pressed") as StyleBoxFlat
	var focus := button.get_theme_stylebox("focus") as StyleBoxFlat
	check(disabled != null and normal != null and hover != null and pressed != null and focus != null, "%s has flat styles" % tag)
	if disabled == null or normal == null or hover == null or pressed == null or focus == null: return
	check(disabled.draw_center and disabled.bg_color == DISABLED_FILL, "%s disabled fill is pale warm paper" % tag)
	check(disabled.border_color == DISABLED_EDGE, "%s disabled edge is soft tan" % tag)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		check(disabled.get_border_width(side) == 1, "%s disabled edge 1px side %d" % [tag, side])
	for corner in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_RIGHT, CORNER_BOTTOM_LEFT]:
		check(disabled.get_corner_radius(corner) == 12, "%s disabled corner 12 #%d" % [tag, corner])
	check(disabled.bg_color != hover.bg_color and disabled.bg_color != pressed.bg_color, "%s disabled no longer looks hovered/pressed" % tag)
	check(disabled.border_color != pressed.border_color, "%s disabled edge differs from pressed edge" % tag)
	check(normal.bg_color == NORMAL_FILL and normal.border_color == EDGE, "%s normal unchanged" % tag)
	check(hover.bg_color == ACTIVE_FILL and hover.border_color == EDGE, "%s hover unchanged" % tag)
	check(pressed.bg_color == ACTIVE_FILL and pressed.border_color == EDGE, "%s pressed unchanged" % tag)
	check(not focus.draw_center and focus.border_color == Color("916d49") and focus.get_border_width(SIDE_TOP) == 2, "%s focus ring unchanged" % tag)
	var label_off := button.get_theme_color("font_disabled_color")
	var label_on := button.get_theme_color("font_color")
	check(label_off == DISABLED_TEXT, "%s disabled label colour" % tag)
	check(label_on == INK, "%s enabled label colour unchanged" % tag)
	var off_ratio := _contrast(label_off, disabled.bg_color)
	check(off_ratio >= TEXT_MIN, "%s disabled label %.2f:1 >= 4.5" % [tag, off_ratio])
	check(off_ratio < _contrast(label_on, normal.bg_color), "%s disabled label still lighter than enabled" % tag)
	check(_contrast(disabled.bg_color, PANEL_PAPER) < 1.2, "%s disabled fill stays a paper tone, not a dark slab" % tag)
	check(button.custom_minimum_size == Vector2(104, 44), "%s min size unchanged" % tag)
	check(button.get_theme_font_size("font_size") == 17, "%s font size unchanged" % tag)


func _check_fit(panel: Control, button: Button, dims: Vector2i, tag: String) -> void:
	var r := button.get_global_rect()
	check(r.size.x >= 104.0 - 0.5 and r.size.y >= 44.0 - 0.5, "%s laid out at least min size" % tag)
	var host: Rect2 = panel.scroll.get_global_rect() if (button in panel.fish_buttons.values() or button == panel.return_button) else panel.panel.get_global_rect()
	if button in panel.fish_buttons.values() or button == panel.return_button:
		check(r.position.x >= host.position.x - 0.5 and r.end.x <= host.end.x + 0.5, "%s inside scroll horizontally" % tag)
	else:
		check(host.encloses(r.grow(-0.5)), "%s inside basket paper" % tag)
	check(Rect2(Vector2.ZERO, Vector2(dims)).encloses(panel.panel.get_global_rect().grow(-0.5)), "%s paper inside viewport" % tag)


func _check_main() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		check(false, "Main pass requires an isolated player profile")
		return
	root.size = Vector2i(390, 844)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _settle()
	check(main._basket_panel != null, "Main builds the basket panel")
	if main._basket_panel != null:
		for button: Button in _buttons(main._basket_panel):
			_check_theme(button, "Main basket %s" % _button_name(main._basket_panel, button))
	main.queue_free()
	await _settle()


func _buttons(panel: Control) -> Array:
	var list: Array = panel.fish_buttons.values()
	list.append_array([panel.return_button, panel.retry_button, panel.close_button])
	return list


func _button_name(panel: Control, button: Button) -> String:
	for kind: String in panel.fish_buttons:
		if panel.fish_buttons[kind] == button: return "take_" + kind
	if button == panel.return_button: return "put_back"
	if button == panel.retry_button: return "retry"
	return "close"


func _linear(c: float) -> float:
	return c / 12.92 if c <= 0.04045 else pow((c + 0.055) / 1.055, 2.4)


func _lum(c: Color) -> float:
	return 0.2126 * _linear(c.r) + 0.7152 * _linear(c.g) + 0.0722 * _linear(c.b)


func _contrast(a: Color, b: Color) -> float:
	var la := _lum(a)
	var lb := _lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _settle() -> void:
	for i in 4:
		await process_frame


func _finish() -> void:
	if failures.is_empty():
		print("PASS: basket_button_disabled %d checks" % checks)
		quit(0)
	else:
		print("FAIL: basket_button_disabled %d/%d failed" % [failures.size(), checks])
		for f in failures.slice(0, 40):
			print("  - " + f)
		quit(1)
