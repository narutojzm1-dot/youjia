extends SceneTree
## The chick care and crop papers scroll inside the same warm paper as the yard
## basket, but kept Godot's default dark scroll bar and default (thin, bright)
## keyboard focus frame, and the chick paper left focus behind on the yard. They
## now share the basket's paper scroll bar and 2px ink focus ring, and both open
## with focus on 「回到院子」. Visual / focus only: sizes and layout are unchanged.
const PaperScrollbarStyle := preload("res://scripts/ui/paper_scrollbar_style.gd")
const VIEWPORTS := [Vector2i(280, 653), Vector2i(320, 568), Vector2i(390, 844), Vector2i(568, 320), Vector2i(844, 390), Vector2i(1280, 720)]
const BAR_MODES := ["scroll", "scroll_focus", "grabber", "grabber_highlight", "grabber_pressed"]
var checks := 0
var failures: Array[String] = []
var Basket: GDScript

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func settle() -> void:
	for i in 4: await process_frame

func check_bar(bar: ScrollBar, tag: String) -> void:
	var all_set := true
	for mode: String in BAR_MODES:
		if not bar.has_theme_stylebox_override(mode) or not (bar.get_theme_stylebox(mode) is StyleBoxFlat): all_set = false
	check(all_set, tag + " every scroll-bar state uses the paper style")
	check((bar.get_theme_stylebox("scroll") as StyleBoxFlat).bg_color.is_equal_approx(PaperScrollbarStyle.TRACK), tag + " track is the paper groove eadcc8")
	check((bar.get_theme_stylebox("grabber") as StyleBoxFlat).bg_color.is_equal_approx(PaperScrollbarStyle.GRABBER), tag + " thumb is the paper brown")
	check(is_equal_approx(bar.get_combined_minimum_size().x, 8.0), tag + " bar keeps its 8px width")

func check_focus(button: Button, tag: String) -> void:
	var focus := button.get_theme_stylebox("focus") as StyleBoxFlat
	check(button.has_theme_stylebox_override("focus") and focus != null, tag + " has its own focus style")
	if focus == null: return
	check(not focus.draw_center, tag + " focus ring does not fill the button")
	check(focus.border_color.is_equal_approx(Color("916d49")), tag + " focus ring is the basket ink 916d49")
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		check(focus.get_border_width(side) == 2, tag + " focus ring is 2px on every side")
	check(focus.corner_radius_top_left == 12, tag + " focus ring follows the 12px button corners")
	check(button.get_theme_color("font_focus_color").is_equal_approx(Color("5b4637")), tag + " focused text keeps the paper ink")

func button_sizes(buttons: Array) -> Array:
	var out: Array = []
	for b: Button in buttons: out.append(b.get_combined_minimum_size())
	return out

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		print("[care_panels_paper] refused: not an isolated data dir")
		quit(2)
		return
	Basket = load("res://scripts/ui/yard_basket_panel.gd")
	var shared: StyleBoxFlat = Basket.focus_style()
	check(shared != Basket.focus_style(), "each caller gets its own focus style instance")
	var store = root.get_node("SaveStore")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	check(await store.flush_pending(), "isolated production save ready")
	await settle()
	check_focus(main._basket_panel.close_button, "basket close")
	var chick: Control = main._chick_panel
	var crop: Control = main._crop_panel
	check_bar(chick.scroll.get_v_scroll_bar(), "chick")
	check_bar(crop.scroll.get_v_scroll_bar(), "crop")
	check_focus(chick.close_button, "chick close")
	check_focus(crop.close_button, "crop close")
	crop.open()
	await settle()
	var actions := 0
	for child in crop.actions.get_children():
		if child is Button:
			actions += 1
			check_focus(child, "crop action " + (child as Button).text)
	check(actions >= 4, "crop paper lists its sow and flower buttons")
	crop.visible = false
	for locale: String in ["zh-CN", "en"]:
		root.get_node("I18n").set_locale(locale)
		for viewport: Vector2i in VIEWPORTS:
			root.size = viewport
			var tag := " %s %s" % [locale, viewport]
			root.gui_release_focus()
			chick.open()
			await settle()
			check(chick.close_button.has_focus(), "chick paper opens with focus on its close button" + tag)
			check(Rect2(Vector2.ZERO, Vector2(viewport)).encloses(chick.paper.get_global_rect()), "chick paper fits" + tag)
			var pressed := [false]
			var mark := func() -> void: pressed[0] = true
			chick.close_requested.connect(mark)
			var key := InputEventAction.new()
			key.action = "ui_accept"
			key.pressed = true
			root.push_input(key)
			var release := InputEventAction.new()
			release.action = "ui_accept"
			root.push_input(release)
			await settle()
			check(pressed[0], "Enter on the focused close button returns to the yard" + tag)
			chick.close_requested.disconnect(mark)
			chick.visible = false
			root.gui_release_focus()
			crop.open()
			await settle()
			check(crop.close_button.has_focus(), "crop paper opens with focus on its close button" + tag)
			check(Rect2(Vector2.ZERO, Vector2(viewport)).encloses(crop.paper.get_global_rect()), "crop paper fits" + tag)
			var buttons: Array = [crop.close_button, chick.close_button]
			var before := button_sizes(buttons)
			for b: Button in buttons: b.remove_theme_stylebox_override("focus")
			var after := button_sizes(buttons)
			for b: Button in buttons: b.add_theme_stylebox_override("focus", Basket.focus_style())
			check(before == after, "focus ring changes no button size" + tag)
			crop.visible = false
	if failures.is_empty():
		print("[care_panels_paper] PASS: %d checks" % checks)
		quit(0)
	else:
		for f: String in failures.slice(0, 30): printerr("FAIL: " + f)
		print("[care_panels_paper] FAIL: %d of %d" % [failures.size(), checks])
		quit(1)
