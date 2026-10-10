extends SceneTree
## REQ-20261007-056: in the yard basket panel a hovered button, a pressed
## button and an unavailable one ("Take one" next to "Millet  x 0") used to
## share the same eadcc8 fill and 1px edge, and holding the mouse down fell back
## to the engine's grey hover_pressed slab. Each state now reads on its own,
## using the same palette as the old yard decor panel (#531), and no row moves.
## Fixture only: the panel is built on its own; no save is read or written.
var checks := 0
var failures: Array[String] = []
const VIEWPORTS := [Vector2i(280, 653), Vector2i(320, 568), Vector2i(390, 844), Vector2i(568, 320), Vector2i(844, 390), Vector2i(1280, 720)]
const MODES := ["normal", "hover", "pressed", "hover_pressed", "disabled"]
const FILL_GAP := 0.06
const OLD_SHARED_FILL := Color("eadcc8")

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

func flat(b: Button, mode: String) -> StyleBoxFlat:
	return b.get_theme_stylebox(mode) as StyleBoxFlat

func all_buttons(p: Control) -> Array:
	var list: Array = [p.close_button, p.retry_button, p.return_button, p.scoop_button]
	list.append_array(p.fish_buttons.values())
	return list

func layout_of(p: Control) -> Array:
	var rects: Array = [p.panel.get_global_rect()]
	for b: Button in all_buttons(p):
		rects.append(b.get_global_rect() if b.is_visible_in_tree() else Rect2())
	return rects

func settle() -> void:
	for i in 3: await process_frame

func run() -> void:
	var tuning := root.get_node_or_null("TuningStore")
	if tuning != null and tuning.has_method("end_run"): tuning.call("end_run")
	var i18n := root.get_node("I18n")
	# Millet 0: its "Take one" is unavailable while small fish can still be taken.
	var inventory := {"fish": {"small": 2, "medium": 0, "odd": 1}, "grass": 3, "millet": 0, "held": ""}
	var keepsakes := {ExplorationRoutes.FIND_STONE: 1, ExplorationRoutes.FIND_PINE_CONE: 0, ExplorationRoutes.FIND_FEATHER: 2}
	for loc: String in ["zh-CN", "en"]:
		i18n.set_locale(loc)
		for vs: Vector2i in VIEWPORTS:
			var tag := "%s %dx%d" % [loc, vs.x, vs.y]
			root.size = vs
			var p: Control = load("res://scripts/ui/yard_basket_panel.gd").new()
			root.add_child(p)
			await settle()
			p.update_view(inventory, keepsakes, "ready", false)
			await settle()
			var ready: Button = p.fish_buttons["small"]
			var empty: Button = p.fish_buttons["millet"]
			check(not ready.disabled and empty.disabled, tag + " zero-count row is disabled, owned row is not")
			for b: Button in all_buttons(p):
				var ok := true
				for mode: String in MODES:
					if flat(b, mode) == null: ok = false
				check(ok, tag + " %s has its own paper style for every state" % b.text)
				var shared := 0
				for mode: String in ["hover", "pressed", "hover_pressed", "disabled"]:
					if flat(b, mode) != null and flat(b, mode).bg_color == OLD_SHARED_FILL: shared += 1
				check(shared == 0, tag + " %s no longer uses the shared eadcc8 fill" % b.text)
			var normal := flat(ready, "normal")
			var hover := flat(ready, "hover")
			var pressed := flat(ready, "pressed")
			var hover_pressed := flat(ready, "hover_pressed")
			var disabled := flat(empty, "disabled")
			if normal == null or hover == null or pressed == null or hover_pressed == null or disabled == null:
				p.queue_free()
				await process_frame
				continue
			check(normal.bg_color == Color("fffaf1") and normal.border_color == Color("b88a61") and normal.border_width_left == 1, tag + " normal paper unchanged")
			check(absf(lum(pressed.bg_color) - lum(disabled.bg_color)) >= FILL_GAP, tag + " pressed fill differs from unavailable fill")
			check(absf(lum(normal.bg_color) - lum(disabled.bg_color)) >= 0.02, tag + " available and unavailable fills differ")
			check(hover.bg_color != normal.bg_color and hover.bg_color != disabled.bg_color and hover.bg_color != pressed.bg_color, tag + " hover has its own fill")
			check(pressed.border_width_left >= 2 and disabled.border_width_left == 1, tag + " pressed edge heavier than unavailable edge")
			check(contrast(pressed.border_color, pressed.bg_color) >= 3.0, tag + " pressed edge reads against its fill")
			check(contrast(disabled.border_color, disabled.bg_color) < contrast(pressed.border_color, pressed.bg_color), tag + " unavailable edge quieter than pressed edge")
			check(hover_pressed.bg_color == pressed.bg_color and hover_pressed.border_width_left == pressed.border_width_left, tag + " holding the mouse keeps the pressed paper, not engine grey")
			check(contrast(ready.get_theme_color("font_color"), normal.bg_color) >= 4.5, tag + " plain text contrast")
			check(contrast(ready.get_theme_color("font_hover_color"), hover.bg_color) >= 4.5, tag + " hover text contrast")
			check(contrast(ready.get_theme_color("font_pressed_color"), pressed.bg_color) >= 4.5, tag + " pressed text contrast")
			check(contrast(ready.get_theme_color("font_hover_pressed_color"), hover_pressed.bg_color) >= 4.5, tag + " hover-pressed text contrast")
			var dis_text := contrast(empty.get_theme_color("font_disabled_color"), disabled.bg_color)
			check(dis_text >= 3.0 and dis_text < contrast(ready.get_theme_color("font_pressed_color"), pressed.bg_color), tag + " unavailable text legible but quieter (%.2f)" % dis_text)
			var ring := p.close_button.get_theme_stylebox("focus") as StyleBoxFlat
			check(ring != null and not ring.draw_center and ring.border_width_left == 2 and ring.border_color == Color("916d49"), tag + " focus ring stays a 2px outline")
			var margins_ok := true
			for mode: String in MODES:
				var s := flat(ready, mode)
				for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
					if s == null or not is_equal_approx(s.get_margin(side), 1.0): margins_ok = false
			check(margins_ok, tag + " content margins stay 1px in every state (same as the old 1px edge)")
			# Taking a fish into hand flips which buttons are available; no button moves.
			var before := layout_of(p)
			var targets_ok := true
			for b: Button in all_buttons(p):
				if b.is_visible_in_tree() and b.size.y < 44.0 - 0.5: targets_ok = false
			check(targets_ok, tag + " every visible button keeps a 44px target")
			var held := inventory.duplicate(true)
			held["held"] = "small"
			p.update_view(held, keepsakes, "ready", false)
			await settle()
			check(ready.disabled and not p.return_button.disabled, tag + " holding something disables take and enables put back")
			check(layout_of(p) == before, tag + " availability change does not move any button")
			p.update_view(inventory, keepsakes, "saving", true)
			await settle()
			var all_off := true
			for b: Button in [p.scoop_button, p.return_button] + p.fish_buttons.values():
				if not b.disabled: all_off = false
			check(all_off, tag + " saving disables every take / put-back button")
			p.queue_free()
			await process_frame
	if failures.is_empty():
		print("[yard-basket-button-states] PASS: %d checks" % checks)
		quit(0)
	else:
		for f in failures.slice(0, 20): push_error(f)
		print("[yard-basket-button-states] FAIL: %d/%d" % [failures.size(), checks])
		quit(1)
