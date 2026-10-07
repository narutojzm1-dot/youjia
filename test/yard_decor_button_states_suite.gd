extends SceneTree
# REQ-20261007-054: in the yard decor panel the chosen place and an unavailable
# button must not look the same, and the change must not move any row.
var checks := 0
var failures: Array[String] = []
const VIEWPORTS := [Vector2(280, 653), Vector2(300, 560), Vector2(320, 568), Vector2(360, 640), Vector2(390, 844), Vector2(568, 320), Vector2(640, 300), Vector2(844, 390), Vector2(1280, 720)]
const FILL_GAP := 0.06

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

func layout_of(p: Control) -> Array:
	var rects: Array = [p.paper.get_global_rect()]
	for b: Button in p.buttons:
		rects.append(b.get_global_rect() if b.is_visible_in_tree() else Rect2())
	return rects

func run() -> void:
	var i18n := root.get_node("I18n")
	var counts := {ExplorationRoutes.FINDS[0]: 2, ExplorationRoutes.FINDS[1]: 0, ExplorationRoutes.FINDS[2]: 1}
	for loc: String in ["zh-CN", "en"]:
		i18n.set_locale(loc)
		for vs: Vector2 in VIEWPORTS:
			var tag := "%s %dx%d" % [loc, vs.x, vs.y]
			root.size = Vector2i(vs)
			var host := Control.new()
			root.add_child(host)
			host.size = vs
			var p: Control = load("res://scripts/ui/yard_decor_panel.gd").new()
			host.add_child(p)
			await process_frame
			p.size = vs
			p.update_view({"places": {}}, counts, "idle", false)
			await process_frame
			await process_frame
			var slot: Button = p.slot_buttons["house_edge"]
			var other: Button = p.slot_buttons["fence_edge"]
			var empty_find: Button = p.find_buttons[ExplorationRoutes.FINDS[1]]
			var ready_find: Button = p.find_buttons[ExplorationRoutes.FINDS[0]]
			check(slot.button_pressed and not slot.disabled, tag + " chosen place is pressed and enabled")
			check(not other.button_pressed and not other.disabled, tag + " other place is plain")
			check(empty_find.disabled and not ready_find.disabled, tag + " zero-count find is disabled, owned find is not")
			var pressed := flat(slot, "pressed")
			var hover_pressed := flat(slot, "hover_pressed")
			var disabled := flat(empty_find, "disabled")
			var normal := flat(other, "normal")
			var hover := flat(other, "hover")
			check(pressed != null and disabled != null and normal != null and hover != null and hover_pressed != null, tag + " every state has its own paper style")
			if pressed == null or disabled == null or normal == null or hover == null or hover_pressed == null:
				host.queue_free()
				await process_frame
				continue
			# Chosen vs unavailable: different fill, heavier and darker edge.
			check(absf(lum(pressed.bg_color) - lum(disabled.bg_color)) >= FILL_GAP, tag + " chosen fill differs from unavailable fill (%.3f vs %.3f)" % [lum(pressed.bg_color), lum(disabled.bg_color)])
			check(pressed.border_width_left >= 2 and disabled.border_width_left == 1, tag + " chosen edge is heavier than unavailable edge")
			check(contrast(pressed.border_color, pressed.bg_color) >= 3.0, tag + " chosen edge reads against its fill")
			check(contrast(disabled.border_color, disabled.bg_color) < contrast(pressed.border_color, pressed.bg_color), tag + " unavailable edge is quieter than chosen edge")
			check(hover_pressed.bg_color == pressed.bg_color and hover_pressed.border_width_left == pressed.border_width_left, tag + " hovering the chosen place keeps it chosen")
			check(absf(lum(normal.bg_color) - lum(disabled.bg_color)) >= 0.02, tag + " available and unavailable fills differ")
			check(hover.bg_color != normal.bg_color and hover.bg_color != disabled.bg_color, tag + " hover has its own fill")
			# Text stays readable in every state.
			check(contrast(slot.get_theme_color("font_pressed_color"), pressed.bg_color) >= 4.5, tag + " chosen text contrast")
			check(contrast(slot.get_theme_color("font_hover_pressed_color"), hover_pressed.bg_color) >= 4.5, tag + " chosen hover text contrast")
			check(contrast(other.get_theme_color("font_color"), normal.bg_color) >= 4.5, tag + " plain text contrast")
			check(contrast(other.get_theme_color("font_hover_color"), hover.bg_color) >= 4.5, tag + " hover text contrast")
			check(contrast(empty_find.get_theme_color("font_disabled_color"), disabled.bg_color) >= 3.0, tag + " unavailable text still legible")
			check(contrast(empty_find.get_theme_color("font_disabled_color"), disabled.bg_color) < contrast(slot.get_theme_color("font_pressed_color"), pressed.bg_color), tag + " unavailable text is quieter than chosen text")
			# Focus ring is a soft outline, not a filled block.
			var ring := p.close_button.get_theme_stylebox("focus") as StyleBoxFlat
			check(ring != null and not ring.draw_center and ring.border_width_left == 2, tag + " focus ring is a 2px outline")
			# Same margins in every state: choosing a place never moves a row.
			var margins_ok := true
			for mode: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
				var s := flat(slot, mode)
				if s == null or s.get_margin(SIDE_LEFT) != normal.get_margin(SIDE_LEFT) or s.get_margin(SIDE_TOP) != normal.get_margin(SIDE_TOP):
					margins_ok = false
			check(margins_ok, tag + " content margins identical across states")
			var before := layout_of(p)
			p.choose_spot("fence_edge")
			await process_frame
			await process_frame
			check(other.button_pressed and not slot.button_pressed, tag + " choosing another place moves the pressed state")
			check(layout_of(p) == before, tag + " choosing another place does not move any button")
			p.choose_find(ExplorationRoutes.FINDS[0])
			await process_frame
			await process_frame
			check(layout_of(p) == before, tag + " picking a find does not move any button")
			# Paper stays on screen with its 8px margin; buttons keep 44px targets.
			var r: Rect2 = p.paper.get_global_rect()
			check(r.position.x >= 7.5 and r.position.y >= 7.5 and r.end.x <= vs.x - 7.5 and r.end.y <= vs.y - 7.5, tag + " paper stays on screen " + str(r))
			var targets_ok := true
			for b: Button in p.buttons:
				if b.is_visible_in_tree() and (b.size.x < 44 or b.size.y < 44): targets_ok = false
			check(targets_ok, tag + " every visible button keeps a 44px target")
			# While a save is pending everything is disabled; the chosen place reads as disabled, not chosen.
			p.update_view({"places": {}}, counts, "idle", true)
			await process_frame
			check(p.slot_buttons["fence_edge"].disabled, tag + " busy disables places")
			host.queue_free()
			await process_frame
	if failures.is_empty():
		print("[yard-decor-button-states] PASS: %d checks" % checks)
		quit(0)
	else:
		for f in failures.slice(0, 20): push_error(f)
		print("[yard-decor-button-states] FAIL: %d/%d" % [failures.size(), checks])
		quit(1)
