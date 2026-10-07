extends SceneTree
## REQ-20261007-058: the yard basket list and the yard decor list kept Godot's
## default scroll bar — a dark grey slab with a translucent white thumb — on
## their warm paper. Both now use a light paper groove with a brown thumb that
## darkens on hover and drag. The bar keeps its 8px width, so nothing in either
## panel moves. Fixture only: panels are built on their own; no save is touched.
const PaperScrollbarStyle := preload("res://scripts/ui/paper_scrollbar_style.gd")
var checks := 0
var failures: Array[String] = []
const VIEWPORTS := [Vector2i(280, 653), Vector2i(320, 568), Vector2i(390, 844), Vector2i(568, 320), Vector2i(844, 390), Vector2i(1280, 720)]
const MODES := ["scroll", "scroll_focus", "grabber", "grabber_highlight", "grabber_pressed"]
const PAPER := Color("fff6e8")
const BAR_WIDTH := 8.0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func lum(c: Color) -> float:
	var parts: Array[float] = []
	for v: float in [c.r, c.g, c.b]:
		parts.append(v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4))
	return 0.2126 * parts[0] + 0.7152 * parts[1] + 0.0722 * parts[2]

func contrast(a: Color, b: Color) -> float:
	var la := lum(a)
	var lb := lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)

func settle() -> void:
	for i in 4: await process_frame

func fill(bar: ScrollBar, mode: String) -> Color:
	var s := bar.get_theme_stylebox(mode) as StyleBoxFlat
	return s.bg_color if s != null else Color(0, 0, 0, 0)

func check_style(bar: ScrollBar, tag: String) -> void:
	var all_flat := true
	for mode: String in MODES:
		if not (bar.get_theme_stylebox(mode) is StyleBoxFlat) or not bar.has_theme_stylebox_override(mode): all_flat = false
	check(all_flat, tag + " every scroll-bar state has its own paper style")
	var track := fill(bar, "scroll")
	var thumb := fill(bar, "grabber")
	var hover := fill(bar, "grabber_highlight")
	var pressed := fill(bar, "grabber_pressed")
	check(track.a > 0.99 and thumb.a > 0.99 and hover.a > 0.99 and pressed.a > 0.99, tag + " track and thumb are opaque paper colours, not translucent grey/white")
	check(track.is_equal_approx(PaperScrollbarStyle.TRACK), tag + " track is the light paper groove eadcc8")
	check(contrast(track, PAPER) < 1.5, tag + " track stays a quiet groove on the paper (not a dark slab)")
	check(lum(track) > 0.6, tag + " track is light (old default composited to a ~0.18-luminance grey)")
	check(fill(bar, "scroll_focus").is_equal_approx(track), tag + " a focused bar keeps the same groove")
	check(contrast(thumb, track) >= 3.0, tag + " thumb reads on the track (>=3:1)")
	check(contrast(thumb, PAPER) >= 3.0, tag + " thumb reads on the paper (>=3:1)")
	check(lum(hover) < lum(thumb) and lum(pressed) < lum(hover), tag + " hover then drag darken the thumb step by step")
	check(is_equal_approx(bar.get_combined_minimum_size().x, BAR_WIDTH), tag + " bar keeps the default 8px width")
	for mode: String in MODES:
		var s := bar.get_theme_stylebox(mode)
		check(s != null and is_equal_approx(s.get_minimum_size().x, BAR_WIDTH), tag + " %s minimum width stays 8px" % mode)

func layout(p: Control, buttons: Array) -> Array:
	var rects: Array = [p.scroll.get_global_rect()]
	for b: Button in buttons:
		rects.append(b.get_global_rect() if b.is_visible_in_tree() else Rect2())
	return rects

func same_layout(a: Array, b: Array) -> bool:
	if a.size() != b.size(): return false
	for i in a.size():
		if not (a[i] as Rect2).is_equal_approx(b[i] as Rect2): return false
	return true

func strip(bar: ScrollBar) -> void:
	for mode: String in MODES:
		bar.remove_theme_stylebox_override(mode)

func basket_buttons(p: Control) -> Array:
	var list: Array = [p.close_button, p.retry_button, p.return_button, p.scoop_button]
	list.append_array(p.fish_buttons.values())
	return list

func decor_buttons(p: Control) -> Array:
	var list: Array = [p.close_button]
	list.append_array(p.slot_buttons.values())
	list.append_array(p.find_buttons.values())
	return list

func run() -> void:
	var tuning := root.get_node_or_null("TuningStore")
	if tuning != null and tuning.has_method("end_run"): tuning.call("end_run")
	var i18n := root.get_node("I18n")
	var inventory := {"fish": {"small": 2, "medium": 0, "odd": 1}, "grass": 3, "millet": 0, "held": ""}
	var keepsakes := {ExplorationRoutes.FIND_STONE: 1, ExplorationRoutes.FIND_PINE_CONE: 0, ExplorationRoutes.FIND_FEATHER: 2}
	var stone: String = ExplorationRoutes.FINDS[0]
	var counts := {stone: 2, ExplorationRoutes.FINDS[1]: 0, ExplorationRoutes.FINDS[2]: 1}
	var basket_scrolled := 0
	var decor_scrolled := 0
	for loc: String in ["zh-CN", "en"]:
		i18n.set_locale(loc)
		for vs: Vector2i in VIEWPORTS:
			root.size = vs
			# Yard basket panel
			var tag := "basket %s %dx%d" % [loc, vs.x, vs.y]
			var p: Control = load("res://scripts/ui/yard_basket_panel.gd").new()
			root.add_child(p)
			await settle()
			p.update_view(inventory, keepsakes, "ready", false)
			await settle()
			var bar: VScrollBar = p.scroll.get_v_scroll_bar()
			check_style(bar, tag)
			if bar.is_visible_in_tree():
				check(is_equal_approx(bar.get_global_rect().size.x, BAR_WIDTH), tag + " visible bar is 8px wide")
				check(p.panel.get_global_rect().encloses(bar.get_global_rect()), tag + " visible bar sits inside the paper")
				if bar.max_value - bar.page >= 20.0:
					basket_scrolled += 1
					p.scroll.scroll_vertical = 20
					await settle()
					check(is_equal_approx(bar.value, 20.0), tag + " list still scrolls with the paper bar")
					p.scroll.scroll_vertical = 0
					await settle()
			var styled := layout(p, basket_buttons(p))
			strip(bar)
			await settle()
			check(same_layout(styled, layout(p, basket_buttons(p))), tag + " paper bar moves no row, button or list edge")
			p.queue_free()
			await process_frame
			# Yard decor panel (idle and with a find chosen)
			for state: String in ["idle", "draft"]:
				tag = "decor %s %dx%d %s" % [loc, vs.x, vs.y, state]
				var host := Control.new()
				root.add_child(host)
				host.size = Vector2(vs)
				var d: Control = load("res://scripts/ui/yard_decor_panel.gd").new()
				host.add_child(d)
				await process_frame
				d.size = Vector2(vs)
				d.update_view({"places": {}}, counts, "idle", false)
				if state == "draft": d.choose_find(stone)
				await settle()
				var dbar: VScrollBar = d.scroll.get_v_scroll_bar()
				check_style(dbar, tag)
				if dbar.is_visible_in_tree():
					check(is_equal_approx(dbar.get_global_rect().size.x, BAR_WIDTH), tag + " visible bar is 8px wide")
					check(d.paper.get_global_rect().encloses(dbar.get_global_rect()), tag + " visible bar sits inside the paper")
					if dbar.max_value - dbar.page >= 8.0:
						decor_scrolled += 1
						d.scroll.scroll_vertical = 8
						await settle()
						check(is_equal_approx(dbar.value, 8.0), tag + " list still scrolls with the paper bar")
						d.scroll.scroll_vertical = 0
						await settle()
				var dstyled := layout(d, decor_buttons(d))
				strip(dbar)
				await settle()
				check(same_layout(dstyled, layout(d, decor_buttons(d))), tag + " paper bar moves no row, button or list edge")
				host.queue_free()
				await process_frame
	check(basket_scrolled > 0, "at least one basket layout actually scrolls (bar is really shown)")
	check(decor_scrolled > 0, "at least one decor layout actually scrolls (bar is really shown)")
	if failures.is_empty():
		print("[paper-scrollbar] PASS: %d checks" % checks)
	else:
		for f: String in failures.slice(0, 30): print("FAIL ", f)
		print("[paper-scrollbar] FAIL: %d of %d checks" % [failures.size(), checks])
	quit(0 if failures.is_empty() else 1)
