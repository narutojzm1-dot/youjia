extends SceneTree
## REQ-20261007-064 slice 2 (#565 picture 8, Owner GROK-CONTRIBUTOR): the basket grid is
## wired into the real game. Opening the basket in Main shows the rows x columns grid
## (the old per-row list stays hidden); a finger tap on a cell opens its action paper and a
## tap on the action really goes through the yard inventory (withdraw / put back) or opens
## the existing decor preview with that find chosen (no commit, nothing spent). Esc closes
## the basket together with any open paper. Runs against an isolated native save.
var checks := 0
var failures: Array[String] = []
var main
var store

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func settle() -> void:
	check(await store.flush_pending(), "native write and acknowledgement complete")
	for frame in 3: await process_frame

func frames(n: int = 4) -> void:
	for frame in n: await process_frame

func tap(at: Vector2) -> void:
	var down := InputEventScreenTouch.new()
	down.position = at
	down.pressed = true
	main._input(down)
	var up := InputEventScreenTouch.new()
	up.position = at
	main._input(up)

func esc() -> void:
	var event := InputEventAction.new()
	event.action = "pause"
	event.pressed = true
	main._input(event)

func center(c: Control) -> Vector2:
	return c.get_global_rect().get_center()

func bring_into_view(c: Control) -> void:
	main._basket_panel.scroll.ensure_control_visible(c)
	await frames()

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		push_error("Basket grid entry requires an isolated player profile")
		quit(2)
		return
	store = root.get_node("SaveStore")
	root.size = Vector2i(390, 844)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(3)
	await main._start_holiday()
	main._world._reel_in_fish()
	await settle()
	var fish: String = main._inventory.view().fish.keys()[0]
	for viewport: Vector2i in [Vector2i(390, 844), Vector2i(844, 390)]:
		var tag := str(viewport)
		root.size = viewport
		await frames()
		main._show_basket()
		await frames()
		var panel = main._basket_panel
		var grid = panel.grid
		check(panel.visible and grid.is_visible_in_tree(), tag + " opening the basket shows the grid")
		var legacy_hidden := true
		for row: Control in panel.list_rows: legacy_hidden = legacy_hidden and not row.is_visible_in_tree()
		check(legacy_hidden, tag + " old per-row list is not shown a second time")
		check(not grid.cells[fish].disabled and grid.count_labels[fish].text == "×1", tag + " caught fish cell shows ×1")
		check(grid.cells["pine_cone"].disabled, tag + " missing find cell cannot be tapped")
		# Tap the fish cell with a finger, then tap "take one".
		await bring_into_view(grid.cells[fish])
		tap(center(grid.cells[fish]))
		await frames()
		check(grid.menu.visible and grid.selected == fish, tag + " finger tap on a cell opens its action paper")
		check(Rect2(Vector2.ZERO, Vector2(viewport)).encloses(grid.menu.get_global_rect()), tag + " action paper stays on screen")
		check(not grid.menu_action.disabled, tag + " take action available while nothing is in hand")
		tap(center(grid.menu_action))
		check(not grid.menu.visible, tag + " paper closes after the action")
		check(main._inventory.busy(), tag + " take waits for the durable save")
		await settle()
		check(main._inventory.view().held == fish and int(main._inventory.view().fish.get(fish, 0)) == 0, tag + " grid take really moves the fish from basket to hand")
		check(main._world._fish_carry_type == fish, tag + " yard hand shows the fish")
		await frames()
		check(not grid.cells[fish].disabled and grid.count_labels[fish].text == "×0", tag + " held fish cell stays tappable at ×0 to put it back")
		# Tapping outside the open paper only closes the paper; nothing underneath fires.
		await bring_into_view(grid.cells[fish])
		tap(center(grid.cells[fish]))
		await frames()
		check(grid.menu.visible and grid.menu_action.text in ["收回背篓", "Put it back"], tag + " held cell offers put back")
		tap(center(panel.close_button))
		check(not grid.menu.visible and panel.visible, tag + " tap outside the paper closes only the paper")
		tap(center(grid.cells[fish]))
		await frames()
		tap(center(grid.menu_action))
		await settle()
		check(main._inventory.view().held == "" and int(main._inventory.view().fish.get(fish, 0)) == 1, tag + " grid put back conserves the fish")
		# Esc with a paper open closes the whole basket and the paper with it.
		await bring_into_view(grid.cells[fish])
		tap(center(grid.cells[fish]))
		await frames()
		esc()
		check(not panel.visible and not paused and not grid.menu.visible, tag + " Esc closes the basket and its paper, the yard resumes")
	# Finds: tapping a pine cone cell opens the decor preview with it chosen, nothing committed.
	root.size = Vector2i(390, 844)
	await frames()
	var cone: String = ExplorationRoutes.FIND_PINE_CONE
	store.request_exploration_trip(null, 1, PackedStringArray([cone]), {})
	await settle()
	main._show_basket()
	await frames()
	var g = main._basket_panel.grid
	check(not g.cells["pine_cone"].disabled and g.count_labels["pine_cone"].text == "×1", "found pine cone shows ×1")
	await bring_into_view(g.cells["pine_cone"])
	tap(center(g.cells["pine_cone"]))
	await frames()
	check(g.menu.visible and g.menu_action.text in ["摆到院里", "Place in yard"], "find cell offers place in yard")
	tap(center(g.menu_action))
	await frames()
	check(main._decor_panel.visible and not main._basket_panel.visible, "place in yard opens the decor editor")
	check(main._decor_panel.draft.get("find_id", "") == cone, "decor preview starts with the tapped find")
	check(main._world.decor_view.preview != null, "preview drawn in the yard")
	check(store.get_yard_decor().places.is_empty() and int(store.get_available_keepsakes().get(cone, 0)) == 1, "preview neither commits nor spends the find")
	main._decor_panel.commit()
	await settle()
	check(store.get_yard_decor().places.has(main._decor_panel.selected), "confirming through the decor panel still places it")
	var used: String = main._decor_panel.selected
	main._hide_decor()
	await frames()
	# With the current spot already taken, the next find goes to the first free spot.
	var feather: String = ExplorationRoutes.FIND_FEATHER
	store.request_exploration_trip(null, 2, PackedStringArray([feather]), {})
	await settle()
	main._on_inventory_changed()
	await frames()
	check(not g.cells["feather"].disabled, "found feather cell is tappable")
	await bring_into_view(g.cells["feather"])
	tap(center(g.cells["feather"]))
	await frames()
	tap(center(g.menu_action))
	await frames()
	check(main._decor_panel.visible and main._decor_panel.selected != used, "occupied spot is skipped for the next find")
	check(main._decor_panel.draft.get("find_id", "") == feather, "free spot previews the feather")
	main._hide_decor()
	main._hide_basket()
	root.get_node("AudioDirector").release_streams()
	print("[yard-basket-grid-entry] %s: %d checks" % ["PASS" if failures.is_empty() else "FAIL: %d of" % failures.size(), checks])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
