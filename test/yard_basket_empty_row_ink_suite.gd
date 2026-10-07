extends SceneTree
## REQ-20261007-061: in the yard basket panel a row whose count is zero
## ("Millet  x 0", "Pine cone  x 0") used to share the same dark 5b4637 ink as
## rows you actually own, so the list did not show at a glance what is in the
## basket. Zero rows now use the quieter 7a6152 ink (the same ink as the greyed
## "Take one" beside them, still >= 4.5:1 on the paper); owned rows keep 5b4637.
## Counts changing in either direction re-ink the row; font size, wrapping and
## layout do not change. Fixture only: no save is read or written.
var checks := 0
var failures: Array[String] = []
const VIEWPORTS := [Vector2i(280, 653), Vector2i(390, 844), Vector2i(568, 320), Vector2i(1280, 720)]
const OWNED := Color("5b4637")
const EMPTY := Color("7a6152")
const PAPER := Color("fff6e8")

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

func ink(l: Label) -> Color:
	return l.get_theme_color("font_color")

func rects(p: Control) -> Array:
	var out: Array = [p.panel.get_global_rect()]
	for l: Label in p.keepsake_labels.values() + p.fish_labels.values():
		out.append(l.get_global_rect())
	for b: Button in p.fish_buttons.values():
		out.append(b.get_global_rect())
	return out

func settle() -> void:
	for i in 3: await process_frame

func run() -> void:
	var tuning := root.get_node_or_null("TuningStore")
	if tuning != null and tuning.has_method("end_run"): tuning.call("end_run")
	var i18n := root.get_node("I18n")
	var inventory := {"fish": {"small": 2, "medium": 0, "odd": 1}, "grass": 3, "millet": 0, "held": ""}
	var keepsakes := {ExplorationRoutes.FIND_STONE: 1, ExplorationRoutes.FIND_PINE_CONE: 0, ExplorationRoutes.FIND_FEATHER: 2}
	check(contrast(EMPTY, PAPER) >= 4.5, "zero-row ink still meets 4.5:1 on the paper (%.2f)" % contrast(EMPTY, PAPER))
	check(contrast(OWNED, PAPER) - contrast(EMPTY, PAPER) >= 2.0, "owned rows clearly darker than zero rows")
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
			for kind: String in ["small", "odd", "grass"]:
				check(ink(p.fish_labels[kind]) == OWNED, tag + " owned %s keeps 5b4637" % kind)
			for kind: String in ["medium", "millet"]:
				check(ink(p.fish_labels[kind]) == EMPTY, tag + " zero %s uses 7a6152" % kind)
				check(ink(p.fish_labels[kind]) == p.fish_buttons[kind].get_theme_color("font_disabled_color"), tag + " zero %s name matches its greyed button" % kind)
			check(ink(p.keepsake_labels["round_stone"]) == OWNED and ink(p.keepsake_labels["feather"]) == OWNED, tag + " owned finds keep 5b4637")
			check(ink(p.keepsake_labels["pine_cone"]) == EMPTY, tag + " zero pine cone uses 7a6152")
			check(ink(p.held_label) == OWNED and ink(p.title) == OWNED, tag + " title and in-hand line unchanged")
			var sizes_ok := true
			for l: Label in p.keepsake_labels.values() + p.fish_labels.values():
				if l.get_theme_font_size("font_size") != 18: sizes_ok = false
			check(sizes_ok, tag + " row font size stays 18")
			var before := rects(p)
			# Counts flip both ways: take the last grass out of the save, scoop some millet in, find a pine cone.
			var next := inventory.duplicate(true)
			next["grass"] = 0
			next["millet"] = 2
			var next_finds := keepsakes.duplicate()
			next_finds[ExplorationRoutes.FIND_PINE_CONE] = 1
			p.update_view(next, next_finds, "ready", false)
			await settle()
			check(ink(p.fish_labels["grass"]) == EMPTY, tag + " grass going to 0 re-inks quieter")
			check(ink(p.fish_labels["millet"]) == OWNED, tag + " millet coming back re-inks dark")
			check(ink(p.keepsake_labels["pine_cone"]) == OWNED, tag + " found pine cone re-inks dark")
			check(rects(p) == before, tag + " re-inking moves no row, label or button")
			# Save not confirmed: everything reads 0 and quiet, nothing pretends to be available.
			p.update_view({}, {}, "failed", false)
			await settle()
			var all_quiet := true
			for l: Label in p.keepsake_labels.values() + p.fish_labels.values():
				if ink(l) != EMPTY: all_quiet = false
			check(all_quiet, tag + " unsaved basket shows every row quiet")
			p.queue_free()
			await process_frame
	if failures.is_empty():
		print("[yard-basket-empty-row-ink] PASS: %d checks" % checks)
		quit(0)
	else:
		for f in failures.slice(0, 20): push_error(f)
		print("[yard-basket-empty-row-ink] FAIL: %d/%d" % [failures.size(), checks])
		quit(1)
