extends SceneTree
## REQ-20261008-067 (Owner GROK-CONTRIBUTOR): pressing "Never mind" / 算了 on a basket
## cell's paper puts keyboard focus back on that same cell, so a keyboard player can keep
## moving from there (Enter / Space reopens it) instead of losing focus to nothing.
## Passive closes (tap outside, close_menu() from scroll / drag start, the cell running
## out) do not grab focus, so a scrolling list is never yanked back to the cell.
## Fixture only: the grid emits action_requested and never reads or writes a save.
var checks := 0
var failures: Array[String] = []
const VIEWPORTS := [Vector2i(280, 653), Vector2i(390, 844), Vector2i(568, 320), Vector2i(844, 390), Vector2i(1280, 720)]
var emitted: Array = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func settle() -> void:
	for i in 3: await process_frame

func inner_width(vs: Vector2i) -> float:
	return minf(520.0, vs.x - 24.0) - 32.0

func center(c: Control) -> Vector2:
	return c.get_global_rect().get_center()

func focus_owner() -> Control:
	return root.gui_get_focus_owner()

func key(code: Key) -> void:
	for down: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.pressed = down
		root.push_input(ev)
		await process_frame

func run() -> void:
	var tuning := root.get_node_or_null("TuningStore")
	if tuning != null and tuning.has_method("end_run"): tuning.call("end_run")
	var i18n := root.get_node("I18n")
	var keepsakes := {ExplorationRoutes.FIND_STONE: 1, ExplorationRoutes.FIND_PINE_CONE: 0, ExplorationRoutes.FIND_FEATHER: 2}
	for loc: String in ["zh-CN", "en"]:
		i18n.set_locale(loc)
		for vs: Vector2i in VIEWPORTS:
			var tag := "%s %dx%d" % [loc, vs.x, vs.y]
			var inventory := {"fish": {"small": 2, "medium": 0, "odd": 1}, "grass": 3, "millet": 0, "held": ""}
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
			# --- mouse / keyboard: "Never mind" button returns focus to the cell ---
			for kind: String in ["small", "grass", "feather"]:
				g.open_menu(kind)
				await settle()
				check(g.menu.visible and g.menu_action.has_focus(), tag + " " + kind + " paper opens with focus on its action")
				g.menu_close.pressed.emit()
				await settle()
				check(not g.menu.visible and g.selected.is_empty(), tag + " " + kind + " never mind closes the paper")
				check(focus_owner() == g.cells[kind], tag + " " + kind + " never mind puts focus back on the same cell")
				check(not g.cells[kind].button_pressed, tag + " " + kind + " cell no longer looks selected")
			# Enter on the refocused cell opens its paper again; never mind returns again.
			g.open_menu("odd")
			await settle()
			g.menu_close.pressed.emit()
			await settle()
			check(focus_owner() == g.cells["odd"], tag + " focus back on odd fish cell")
			await key(KEY_ENTER)
			await settle()
			check(g.menu.visible and g.selected == "odd", tag + " Enter on the refocused cell reopens its paper")
			check(focus_owner() == g.menu_action, tag + " reopened paper focuses its action again")
			g.menu_close.pressed.emit()
			await settle()
			check(focus_owner() == g.cells["odd"], tag + " second never mind returns focus again")
			# --- phone: tapping "never mind" through press_at behaves the same ---
			g.open_menu("round_stone")
			await settle()
			check(g.press_at(center(g.menu_close)), tag + " tap on never mind is taken")
			await settle()
			check(not g.menu.visible and focus_owner() == g.cells["round_stone"], tag + " tapped never mind returns focus to the stone cell")
			# --- passive closes keep their old behaviour: no focus grab ---
			g.open_menu("small")
			await settle()
			check(g.press_at(Vector2(vs.x - 2, vs.y - 2)), tag + " tap outside is taken while paper is open")
			await settle()
			check(not g.menu.visible and focus_owner() != g.cells["small"], tag + " tap outside does not move focus to the cell")
			g.open_menu("grass")
			await settle()
			g.close_menu()
			await settle()
			check(not g.menu.visible and focus_owner() != g.cells["grass"], tag + " close_menu (scroll / drag start) does not grab focus")
			# The opened cell runs out while its paper is open: the paper closes, nothing grabs focus.
			g.open_menu("feather")
			await settle()
			keepsakes[ExplorationRoutes.FIND_FEATHER] = 0
			g.update_view(inventory, keepsakes, "ready", false)
			await settle()
			check(not g.menu.visible and g.cells["feather"].disabled and focus_owner() != g.cells["feather"], tag + " emptied cell closes paper without taking focus")
			keepsakes[ExplorationRoutes.FIND_FEATHER] = 2
			# Held fish with zero left in the basket: the cell stays usable, never mind returns focus.
			inventory = {"fish": {"small": 0, "medium": 0, "odd": 0}, "grass": 0, "millet": 0, "held": "medium"}
			g.update_view(inventory, keepsakes, "ready", false)
			await settle()
			g.open_menu("medium")
			await settle()
			check(g.menu.visible and g.menu_action.text in ["收回背篓", "Put it back"], tag + " held fish paper offers put back")
			g.menu_close.pressed.emit()
			await settle()
			check(focus_owner() == g.cells["medium"], tag + " never mind on held fish returns focus to its cell")
			# Never mind is not an action: nothing was emitted through this whole run.
			check(emitted.is_empty(), tag + " never mind emits no basket action")
			# Hidden grid: dismiss must not focus an invisible cell.
			g.open_menu("round_stone")
			await settle()
			host.visible = false
			g.menu_close.pressed.emit()
			await settle()
			check(not g.menu.visible and focus_owner() != g.cells["round_stone"], tag + " hidden grid: dismiss does not focus an invisible cell")
			host.queue_free()
			await process_frame
	if failures.is_empty():
		print("[yard-basket-dismiss-focus] PASS: %d checks" % checks)
		quit(0)
	else:
		for f in failures.slice(0, 25): push_error(f)
		print("[yard-basket-dismiss-focus] FAIL: %d/%d" % [failures.size(), checks])
		quit(1)
