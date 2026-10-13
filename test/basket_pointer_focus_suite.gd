extends SceneTree
## 背篓格子纸片：鼠标 / 触屏打开纸片、点「算了」时，焦点照样交给第一项 / 原格子（键盘随时能接着按），
## 但先不画焦点圈，免得点按玩家看到一圈像是“已经选好了”的框；键盘一导航圈就显出来。
## 键盘打开纸片、键盘按「算了」时照常亮圈。只测格子组件，不读写存档。

const VIEWPORTS := [Vector2i(280, 653), Vector2i(390, 844), Vector2i(844, 390), Vector2i(1280, 720)]

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


func settle() -> void:
	for i in 3:
		await process_frame


func owner() -> Control:
	return root.gui_get_focus_owner()


func ring_shown() -> bool:
	return owner() != null and owner().has_focus(true)


func label(c: Control) -> String:
	return "<none>" if c == null else "%s '%s'" % [c.name, (c as Button).text if c is Button else ""]


func key(code: Key) -> void:
	for down: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.pressed = down
		root.push_input(ev)
		await process_frame


func click(c: Control) -> void:
	var at := c.get_global_rect().get_center()
	for down: bool in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.position = at
		ev.global_position = at
		ev.pressed = down
		root.push_input(ev)
		await process_frame


func run() -> void:
	var tuning := root.get_node_or_null("TuningStore")
	if tuning != null and tuning.has_method("end_run"): tuning.call("end_run")
	var keepsakes := {ExplorationRoutes.FIND_STONE: 1, ExplorationRoutes.FIND_PINE_CONE: 0, ExplorationRoutes.FIND_FEATHER: 2}
	for vs: Vector2i in VIEWPORTS:
		var tag := "%dx%d" % [vs.x, vs.y]
		root.size = vs
		var width := minf(520.0, vs.x - 24.0) - 32.0
		var host := Control.new()
		host.position = Vector2((vs.x - width) * 0.5, 60)
		host.size = Vector2(width, 10)
		root.add_child(host)
		var g: Control = load("res://scripts/ui/yard_basket_grid.gd").new()
		g.size = host.size
		host.add_child(g)
		await settle()
		g.update_view({"fish": {"small": 2, "medium": 0, "odd": 1}, "grass": 3, "millet": 0, "held": ""}, keepsakes, "ready", false)
		g.set_free_spots(["house_edge", "fence_edge", "pond_path"] as Array[String], false)
		await settle()

		for kind: String in ["small", "grass", "feather"]:
			var first: Button = g.spot_buttons["house_edge"] if kind == "feather" else g.menu_action
			# 矮屏上下面几行格子在视口外（真实背篓里由滚动窗带进来），把宿主上移到这一格看得见
			host.position.y = 60.0
			await settle()
			var below: float = g.cells[kind].get_global_rect().end.y - (vs.y - 120.0)
			if below > 0.0:
				host.position.y -= below
				await settle()
			check(Rect2(Vector2.ZERO, Vector2(vs)).has_point(g.cells[kind].get_global_rect().get_center()), "%s %s: cell is on screen for the click" % [tag, kind])
			await click(g.cells[kind])
			await settle()
			check(g.menu.visible and g.selected == kind, "%s %s: mouse click opens the paper" % [tag, kind])
			check(owner() == first, "%s %s: mouse-opened paper still hands focus to its first action, got %s" % [tag, kind, label(owner())])
			check(not ring_shown(), "%s %s: mouse-opened paper draws no focus ring" % [tag, kind])
			await key(KEY_TAB)
			check(ring_shown() and g.menu.is_ancestor_of(owner()), "%s %s: first Tab after a click shows the ring inside the paper, got %s" % [tag, kind, label(owner())])
			g.close_menu()
			await settle()

			await click(g.cells[kind])
			await settle()
			await click(g.menu_close)
			await settle()
			check(not g.menu.visible and owner() == g.cells[kind], "%s %s: clicked never mind puts focus back on the cell, got %s" % [tag, kind, label(owner())])
			check(not ring_shown(), "%s %s: clicked never mind draws no ring on the cell" % [tag, kind])

			await key(KEY_ENTER)
			await settle()
			check(g.menu.visible and owner() == first, "%s %s: Enter on the cell opens the paper on its first action, got %s" % [tag, kind, label(owner())])
			check(ring_shown(), "%s %s: keyboard-opened paper shows the ring" % [tag, kind])
			g.menu_close.grab_focus()
			await key(KEY_ENTER)
			await settle()
			check(not g.menu.visible and owner() == g.cells[kind], "%s %s: Enter on never mind returns to the cell, got %s" % [tag, kind, label(owner())])
			check(ring_shown(), "%s %s: keyboard never mind shows the ring on the cell" % [tag, kind])

		check(g.press_at(g.cells["odd"].get_global_rect().get_center()), "%s: tap on the odd fish cell is taken" % tag)
		await settle()
		check(g.menu.visible and owner() == g.menu_action and not ring_shown(), "%s: tapped paper focuses its action without a ring, got %s" % [tag, label(owner())])
		check(g.press_at(g.menu_close.get_global_rect().get_center()), "%s: tap on never mind is taken" % tag)
		await settle()
		check(not g.menu.visible and owner() == g.cells["odd"] and not ring_shown(), "%s: tapped never mind returns focus to the cell without a ring" % tag)

		host.queue_free()
		await process_frame
	_finish()


func _finish() -> void:
	check(checks >= 100, "suite ran enough checks (%d)" % checks)
	if failures.is_empty():
		print("BASKET_POINTER_FOCUS checks=%d failures=0" % checks)
		quit(0)
	else:
		for failure: String in failures.slice(0, 30):
			printerr("[basket-pointer-focus] " + failure)
		print("BASKET_POINTER_FOCUS checks=%d failures=%d" % [checks, failures.size()])
		quit(1)
