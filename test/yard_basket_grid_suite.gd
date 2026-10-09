extends SceneTree
## REQ-20261007-064 (#565 picture 8, Owner GROK-CONTRIBUTOR): the big basket as a
## standard rows x columns grid. Every item (three fish, grass, millet, round stone,
## pine cone, feather) gets one cell with its art, a name and a count; the last row is
## padded with empty slots. Tapping an owned cell opens a small paper with that cell's
## action (take one / bundle / scoop, place in yard, put back) and "never mind";
## it works through press_at() for phones and through the cell buttons for a mouse.
## Fixture only: the grid emits action_requested and never reads or writes a save.
var checks := 0
var failures: Array[String] = []
const VIEWPORTS := [Vector2i(280, 653), Vector2i(390, 844), Vector2i(568, 320), Vector2i(844, 390), Vector2i(1280, 720)]
const INK := Color("5b4637")
const EMPTY_INK := Color("7a6152")
var emitted: Array = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func settle() -> void:
	for i in 3: await process_frame

func inner_width(vs: Vector2i) -> float:
	# Same paper as yard_basket_panel.fit(): min(520, w - 2 * 12), 16px margins each side.
	return minf(520.0, vs.x - 24.0) - 32.0

func nl_rect(g: Control, kind: String) -> Rect2:
	return g.name_labels[kind].get_global_rect()

func center(c: Control) -> Vector2:
	return c.get_global_rect().get_center()

func run() -> void:
	var tuning := root.get_node_or_null("TuningStore")
	if tuning != null and tuning.has_method("end_run"): tuning.call("end_run")
	var i18n := root.get_node("I18n")
	var inventory := {"fish": {"small": 2, "medium": 0, "odd": 1}, "grass": 3, "millet": 0, "held": ""}
	var keepsakes := {ExplorationRoutes.FIND_STONE: 1, ExplorationRoutes.FIND_PINE_CONE: 0, ExplorationRoutes.FIND_FEATHER: 2}
	for loc: String in ["zh-CN", "en"]:
		i18n.set_locale(loc)
		var en := loc == "en"
		for vs: Vector2i in VIEWPORTS:
			var tag := "%s %dx%d" % [loc, vs.x, vs.y]
			root.size = vs
			var host := Control.new()
			host.position = Vector2((vs.x - inner_width(vs)) * 0.5, 60)
			host.size = Vector2(inner_width(vs), 10)
			root.add_child(host)
			var g: Control = load("res://scripts/ui/yard_basket_grid.gd").new()
			g.size = host.size
			host.add_child(g)
			g.action_requested.connect(func(a: String, k: String) -> void: emitted.append([a, k]))
			await settle()
			g.update_view(inventory, keepsakes, "ready", false)
			await settle()
			# --- grid shape ---
			var cols: int = g.grid.columns
			var expect_cols := 3 if inner_width(vs) < 4 * 64 + 3 * 8 else 4
			check(cols == expect_cols, tag + " columns %d (expected %d)" % [cols, expect_cols])
			check(g.cells.size() == 8, tag + " one cell for each of 8 items")
			check((g.cells.size() + g.blanks.size()) % cols == 0, tag + " last row padded to full width")
			check(g.blanks.size() == (cols - 8 % cols) % cols, tag + " blank slot count")
			var rects: Array[Rect2] = []
			for kind: String in g.ORDER:
				var r: Rect2 = g.cells[kind].get_global_rect()
				rects.append(r)
				check(r.size.x >= 44.0 and r.size.y >= 44.0, tag + " %s cell is a 44px+ touch target (%s)" % [kind, r.size])
				check(r.position.x >= host.global_position.x - 0.5 and r.end.x <= host.global_position.x + host.size.x + 0.5, tag + " %s cell inside the paper width" % kind)
				check(g.icons[kind].texture != null, tag + " %s cell has its art" % kind)
				var ir: Rect2 = g.icons[kind].get_global_rect()
				check(r.encloses(ir), tag + " %s art stays inside its cell" % kind)
				check(not ir.intersects(g.count_labels[kind].get_global_rect()) and not ir.intersects(nl_rect(g, kind)), tag + " %s art clear of count and name" % kind)
				check(ir.size.y >= 28.0, tag + " %s art at least 28px tall (%.0f)" % [kind, ir.size.y])
				var nl: Label = g.name_labels[kind]
				var w := nl.get_theme_font("font").get_string_size(nl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, nl.get_theme_font_size("font_size")).x
				check(w <= nl.size.x + 0.5, tag + " %s name fits its cell (%.0f > %.0f)" % [kind, w, nl.size.x])
				check(nl.get_theme_font_size("font_size") >= 12, tag + " %s name font >= 12" % kind)
			var overlap := false
			for i in rects.size():
				for j in range(i + 1, rects.size()):
					if rects[i].grow(-0.5).intersects(rects[j].grow(-0.5)): overlap = true
			check(not overlap, tag + " cells never overlap")
			check(absf(rects[0].size.y - rects[0].size.x - 24.0) < 1.0, tag + " cells are near-square (24px taller for count + name)")
			# row-major order: first `cols` cells share a row
			check(is_equal_approx(rects[0].position.y, rects[cols - 1].position.y) and rects[cols].position.y > rects[0].position.y, tag + " row-major order")
			# --- counts and ink ---
			var expect := {"small": 2, "medium": 0, "odd": 1, "grass": 3, "millet": 0, "round_stone": 1, "pine_cone": 0, "feather": 2}
			for kind: String in expect:
				check(g.count_labels[kind].text == "×%d" % expect[kind], tag + " %s count" % kind)
				var owned: bool = expect[kind] > 0
				check(g.cells[kind].disabled == (not owned), tag + " %s enabled only when owned" % kind)
				check(g.name_labels[kind].get_theme_color("font_color") == (INK if owned else EMPTY_INK), tag + " %s ink" % kind)
			# --- tap a fish: paper opens next to the cell ---
			emitted.clear()
			check(g.press_at(center(g.cells["small"])), tag + " tap on small fish handled")
			check(g.menu.visible and g.selected == "small", tag + " small fish paper opens")
			check(g.cells["small"].button_pressed, tag + " selected cell stays pressed")
			check(g.menu_action.text == ("Take one" if en else "拿一条") and not g.menu_action.disabled, tag + " fish action is take one")
			check(g.menu_title.text.begins_with("Small fish" if en else "小鱼"), tag + " paper titled with full name")
			await process_frame
			var mr: Rect2 = g.menu.get_global_rect()
			check(Rect2(Vector2.ZERO, Vector2(vs)).encloses(mr), tag + " paper inside the screen %s" % mr)
			check(not mr.intersects(g.cells["small"].get_global_rect().grow(-1)), tag + " paper does not cover its cell")
			check(g.menu_action.has_focus() and g.menu_action.get_theme_color("font_focus_color") == INK, tag + " focused action keeps ink text")
			check(g.menu_action.get_global_rect().size.y >= 44 and g.menu_close.get_global_rect().size.y >= 44, tag + " paper buttons 44px tall")
			check(g.press_at(center(g.menu_action)), tag + " tap on take one handled")
			check(emitted == [["withdraw", "small"]], tag + " take one emits withdraw small: %s" % [emitted])
			check(not g.menu.visible and not g.cells["small"].button_pressed and g.selected == "", tag + " paper closes after action")
			# --- grass / keepsake actions ---
			emitted.clear()
			g.press_at(center(g.cells["grass"]))
			check(g.menu_action.text == ("Take a bundle" if en else "拿一束"), tag + " grass action")
			g.press_at(center(g.menu_action))
			# #594: a find's paper lists the free yard spots instead of opening a decor panel
			var free: Array[String] = ["house_edge", "fence_edge", "pond_path"]
			g.set_free_spots(free, false)
			g.press_at(center(g.cells["round_stone"]))
			await process_frame
			check(not g.menu_action.visible and g.spot_row.is_visible_in_tree(), tag + " stone paper shows spot buttons, not a single action")
			check(g.spot_buttons["fence_edge"].text == ("By the fence" if en else "摆在篱边") and not g.spot_buttons["fence_edge"].disabled, tag + " fence spot offered")
			check(g.spot_buttons["house_edge"].has_focus(), tag + " first free spot takes focus for the keyboard")
			check(Rect2(Vector2.ZERO, Vector2(vs)).encloses(g.menu.get_global_rect()), tag + " stone paper inside the screen %s" % g.menu.get_global_rect())
			var spot_rects_ok := true
			for spot: String in free:
				var r: Rect2 = g.spot_buttons[spot].get_global_rect()
				spot_rects_ok = spot_rects_ok and r.size.y >= 44 and g.menu.get_global_rect().encloses(r)
			check(spot_rects_ok, tag + " spot buttons 44px tall and inside the paper")
			g.press_at(center(g.spot_buttons["fence_edge"]))
			check(emitted == [["withdraw", "grass"], ["place:fence_edge", "round_stone"]], tag + " grass/stone emits: %s" % [emitted])
			check(not g.menu.visible, tag + " paper closes after choosing a spot")
			var two: Array[String] = ["house_edge", "pond_path"]
			g.set_free_spots(two, false)
			g.press_at(center(g.cells["round_stone"]))
			check(not g.spot_buttons["fence_edge"].visible and g.spot_buttons["pond_path"].visible, tag + " a taken spot is not offered")
			var none: Array[String] = []
			g.set_free_spots(none, false)
			check(g.menu.visible and not g.spot_row.visible and g.menu_note.visible and g.menu_note.text.contains("All three" if en else "三处"), tag + " all spots taken says how to free one: " + g.menu_note.text)
			g.set_free_spots(free, true)
			check(not g.spot_row.visible and g.menu_note.text == ("Checking the save…" if en else "正在确认保存，先等一下。"), tag + " placing waits while the yard saves")
			g.close_menu()
			g.set_free_spots(free, false)
			# --- empty cell, switching, outside tap, never mind, Esc ---
			emitted.clear()
			check(g.press_at(center(g.cells["medium"])) and not g.menu.visible, tag + " zero cell opens nothing")
			g.press_at(center(g.cells["small"]))
			g.press_at(center(g.cells["feather"]))
			check(g.selected == "feather" and not g.cells["small"].button_pressed and g.cells["feather"].button_pressed, tag + " tapping another cell switches")
			g.press_at(center(g.cells["feather"]))
			check(not g.menu.visible, tag + " tapping the selected cell again closes")
			g.press_at(center(g.cells["odd"]))
			check(g.press_at(Vector2(vs) - Vector2(2, 2)) and not g.menu.visible, tag + " tap outside closes paper")
			g.press_at(center(g.cells["odd"]))
			g.press_at(center(g.menu_close))
			check(not g.menu.visible, tag + " never mind closes")
			g.press_at(center(g.cells["odd"]))
			var esc := InputEventAction.new()
			esc.action = "ui_cancel"
			esc.pressed = true
			g._unhandled_key_input(esc)
			check(not g.menu.visible, tag + " Esc closes")
			check(not g.press_at(Vector2(vs) - Vector2(2, 2)), tag + " outside tap with no paper is not swallowed")
			check(emitted.is_empty(), tag + " no action from closing paths: %s" % [emitted])
			# --- mouse path: the cell button itself ---
			g.cells["grass"].button_pressed = true
			check(g.menu.visible and g.selected == "grass", tag + " mouse click opens paper")
			g.cells["grass"].button_pressed = false
			check(not g.menu.visible, tag + " second mouse click closes")
			# --- something in hand ---
			var holding := inventory.duplicate(true)
			holding["held"] = "grass"
			holding["grass"] = 2
			g.update_view(holding, keepsakes, "ready", false)
			g.press_at(center(g.cells["grass"]))
			check(g.menu_action.text == ("Put it back" if en else "收回背篓") and not g.menu_action.disabled, tag + " held item offers put back")
			g.press_at(center(g.menu_action))
			check(emitted == [["return", "grass"]], tag + " put back emits return grass: %s" % [emitted])
			g.press_at(center(g.cells["small"]))
			check(g.menu_action.disabled and g.menu_note.visible and g.menu_note.text.contains("grass" if en else "草束"), tag + " other food says put back first: " + g.menu_note.text)
			g.press_at(center(g.menu_action))
			check(emitted.size() == 1 and g.menu.visible, tag + " disabled action emits nothing")
			g.close_menu()
			g.press_at(center(g.cells["feather"]))
			check(not g.menu_action.disabled, tag + " finds can still be placed while holding food")
			g.close_menu()
			# --- held item whose basket count is 0 is still reachable ---
			var last := inventory.duplicate(true)
			last["held"] = "millet"
			g.update_view(last, keepsakes, "ready", false)
			check(not g.cells["millet"].disabled, tag + " held millet cell enabled at ×0")
			# --- saving / not loaded ---
			emitted.clear()
			g.update_view(inventory, keepsakes, "saving", true)
			g.press_at(center(g.cells["small"]))
			check(g.menu.visible and g.menu_action.disabled and g.menu_note.text == ("Checking the save…" if en else "正在确认保存，先等一下。"), tag + " saving disables action")
			g.update_view({}, keepsakes, "failed", false)
			check(not g.menu.visible, tag + " paper closes when its cell empties")
			var food_off := true
			for kind: String in ["small", "medium", "odd", "grass", "millet"]:
				if not g.cells[kind].disabled: food_off = false
			check(food_off, tag + " unloaded basket greys every food cell")
			g.press_at(center(g.cells["feather"]))
			check(g.menu_action.disabled, tag + " unloaded basket cannot place finds")
			g.close_menu()
			check(emitted.is_empty(), tag + " nothing emitted while saving/unloaded")
			# --- pressed look matches the basket's pressed buttons ---
			var ps: StyleBoxFlat = g.cells["small"].get_theme_stylebox("pressed")
			check(ps.bg_color == Color("f3d3ae") and ps.border_width_left == 2, tag + " selected cell uses basket pressed apricot + ink edge")
			host.queue_free()
			await process_frame
	if failures.is_empty():
		print("[yard-basket-grid] PASS: %d checks" % checks)
		quit(0)
	else:
		for f in failures.slice(0, 25): push_error(f)
		print("[yard-basket-grid] FAIL: %d/%d" % [failures.size(), checks])
		quit(1)
