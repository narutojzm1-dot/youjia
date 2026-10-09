extends SceneTree
## REQ-20261007-064 slice 3 (#565 picture 8 drag-out, Owner GROK-CONTRIBUTOR): in the real
## Main, a round stone / pine cone / feather cell can be dragged out of the big basket with a
## finger or the mouse. While dragging the basket paper turns translucent, the dim shade goes
## away and only the still-empty fixed yard spots light up, at the spot's world position
## converted to the screen. #594 (CURSOR-CLOUD): dropping on a lit spot places that find there
## at once through YardDecorController (no separate decor panel); the basket stays open and says
## where it went. Dropping elsewhere, Esc, or the basket closing cancel without committing.
## Runs against an isolated native save.
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

func touch(at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = at
	event.pressed = pressed
	main._input(event)

func finger_drag(from: Vector2, to: Vector2, steps: int = 6) -> void:
	for i in range(1, steps + 1):
		var event := InputEventScreenDrag.new()
		var previous: Vector2 = from.lerp(to, float(i - 1) / steps)
		event.position = from.lerp(to, float(i) / steps)
		event.relative = event.position - previous
		main._input(event)

func mouse_button(at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = at
	event.global_position = at
	if pressed: event.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(event)

func mouse_move(from: Vector2, to: Vector2, steps: int = 6) -> void:
	for i in range(1, steps + 1):
		var event := InputEventMouseMotion.new()
		event.position = from.lerp(to, float(i) / steps)
		event.global_position = event.position
		event.relative = (to - from) / steps
		event.button_mask = MOUSE_BUTTON_MASK_LEFT
		root.push_input(event)

func esc() -> void:
	var event := InputEventAction.new()
	event.action = "pause"
	event.pressed = true
	main._input(event)

func center(c: Control) -> Vector2:
	return c.get_global_rect().get_center()

func open_basket() -> void:
	main._show_basket()
	await frames()

func bring_into_view(c: Control) -> void:
	main._basket_panel.scroll.ensure_control_visible(c)
	await frames()

func committed_nothing(cone_before: int, places_before: int) -> bool:
	return store.get_yard_decor().places.size() == places_before and int(store.get_available_keepsakes().get(ExplorationRoutes.FIND_PINE_CONE, 0)) == cone_before

## Drop on a lit spot: placed there, one spent, basket stays open; then put it back for the next case.
func placed_by_drop(tag: String, spot: String, cone_before: int, places_before: int) -> void:
	await settle()
	var panel = main._basket_panel
	check(panel.visible, tag + " drop keeps the basket open")
	check(store.get_yard_decor().places.get(spot, {}).get("find_id", "") == ExplorationRoutes.FIND_PINE_CONE, tag + " drop places the cone at %s" % spot)
	check(int(store.get_available_keepsakes().get(ExplorationRoutes.FIND_PINE_CONE, 0)) == cone_before - 1 and store.get_yard_decor().places.size() == places_before + 1, tag + " drop spends exactly one cone")
	check(panel.status.visible and (panel.status.text.contains("摆在") or panel.status.text.contains("Tap it in the yard")), tag + " basket says where it went: " + panel.status.text)
	check(not panel.legal_spots().has(spot), tag + " the filled spot no longer lights up")
	main._decor.request("remove", spot)
	await settle()
	check(committed_nothing(cone_before, places_before), tag + " putting it back restores the basket")

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		push_error("Basket drag requires an isolated player profile")
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
	var cone: String = ExplorationRoutes.FIND_PINE_CONE
	var feather: String = ExplorationRoutes.FIND_FEATHER
	store.request_exploration_trip(null, 1, PackedStringArray([cone, cone, feather]), {})
	await settle()
	main._on_inventory_changed()
	main._on_decor_changed()
	var spots: Dictionary = load("res://scripts/inventory/yard_decor.gd").SPOTS
	for viewport: Vector2i in [Vector2i(390, 844), Vector2i(1280, 720), Vector2i(844, 390)]:
		var tag := str(viewport)
		root.size = viewport
		await frames()
		await open_basket()
		var panel = main._basket_panel
		var grid = panel.grid
		var view_rect := Rect2(Vector2.ZERO, Vector2(viewport))
		check(panel.can_drag("pine_cone") and not panel.can_drag(fish), tag + " finds can be dragged, fish cannot")
		check(panel.legal_spots().size() == 3, tag + " all three fixed spots are free")
		# Zones sit at the world spot converted through the yard camera, kept on screen.
		var canvas: Transform2D = main._world.decor_view.get_global_transform_with_canvas()
		for spot: String in spots:
			var raw: Vector2 = canvas * Vector2(spots[spot])
			var shown: Vector2 = panel.spot_screen_position(spot)
			check(view_rect.has_point(shown), tag + " zone %s is on screen" % spot)
			if view_rect.grow(-panel.ZONE_RADIUS - 24.0).has_point(raw):
				check(shown.distance_to(raw) < 0.5, tag + " zone %s is at its yard position" % spot)
		var places_before: int = store.get_yard_decor().places.size()
		var cone_before := int(store.get_available_keepsakes().get(cone, 0))
		# Finger: press on the cone cell, move sideways -> drag starts.
		await bring_into_view(grid.cells["pine_cone"])
		var start := center(grid.cells["pine_cone"])
		touch(start, true)
		finger_drag(start, start + Vector2(40, 0), 2)
		check(panel.drag_kind == "pine_cone", tag + " sideways finger drag picks up the cone")
		check(panel.panel.modulate.a < 0.5 and not panel.shade.visible, tag + " basket paper is translucent while dragging")
		check(panel.drag_layer.visible and not grid.menu.visible, tag + " zones shown, no action paper")
		check(panel.drag_ghost.texture != null and view_rect.has_point(panel.drag_ghost.get_global_rect().get_center()), tag + " the cone follows the finger")
		var target_spot := "fence_edge"
		var target: Vector2 = panel.spot_screen_position(target_spot)
		finger_drag(start + Vector2(40, 0), target)
		check(panel.drag_spot == target_spot, tag + " zone under the finger lights up")
		touch(target, false)
		await frames()
		check(panel.drag_kind.is_empty() and panel.panel.modulate.a == 1.0 and panel.shade.visible, tag + " drop restores the basket look")
		await placed_by_drop(tag + " finger", target_spot, cone_before, places_before)
		# Drop away from every lit spot -> nothing happens, the find stays in the basket.
		await bring_into_view(grid.cells["pine_cone"])
		start = center(grid.cells["pine_cone"])
		var away := Vector2(4, 4)
		for spot: String in spots:
			if away.distance_to(panel.spot_screen_position(spot)) < 60.0: away = Vector2(viewport.x - 4, 4)
		touch(start, true)
		finger_drag(start, start + Vector2(-40, 0), 2)
		finger_drag(start + Vector2(-40, 0), away)
		check(panel.drag_kind == "pine_cone" and panel.drag_spot.is_empty(), tag + " nothing lit away from the spots")
		touch(away, false)
		await frames()
		check(panel.visible and panel.drag_kind.is_empty(), tag + " drop elsewhere cancels")
		check(panel.status.visible and panel.status.text in ["要松在院里亮着的圈上；东西还在背篓里。", "Drop it on a lit spot in the yard. It is still in the basket."], tag + " cancelled drop says the find is still in the basket")
		check(committed_nothing(cone_before, places_before), tag + " cancelled drop commits nothing")
		# Esc mid-drag: basket closes, nothing committed, look restored next time.
		touch(start, true)
		finger_drag(start, start + Vector2(40, 0), 2)
		check(panel.drag_kind == "pine_cone", tag + " drag again")
		esc()
		await frames()
		check(not panel.visible and panel.drag_kind.is_empty() and not panel.drag_layer.visible, tag + " Esc mid-drag closes the basket and drops the drag")
		touch(start, false)
		check(committed_nothing(cone_before, places_before), tag + " Esc mid-drag commits nothing")
		await open_basket()
		check(panel.panel.modulate.a == 1.0 and panel.shade.visible, tag + " basket reopens opaque")
		# A fish cell does not drag; a sideways move on it is just a cancelled tap.
		await bring_into_view(grid.cells[fish])
		var fish_at := center(grid.cells[fish])
		touch(fish_at, true)
		finger_drag(fish_at, fish_at + Vector2(40, 0), 2)
		check(panel.drag_kind.is_empty(), tag + " fish cell is not dragged")
		touch(fish_at + Vector2(40, 0), false)
		await frames()
		check(not grid.menu.visible, tag + " moved finger on fish opens no paper")
		# Vertical finger move on a scrolling list scrolls; holding first still drags.
		await bring_into_view(grid.cells["pine_cone"])
		start = center(grid.cells["pine_cone"])
		if panel.scroll.get_v_scroll_bar().visible:
			touch(start, true)
			finger_drag(start, start + Vector2(0, -30), 3)
			check(panel.drag_kind.is_empty() and panel._touch_scrolled, tag + " vertical swipe on a scrolling list still scrolls")
			touch(start + Vector2(0, -30), false)
			await bring_into_view(grid.cells["pine_cone"])
			start = center(grid.cells["pine_cone"])
			touch(start, true)
			panel._touch_time -= panel.HOLD_MS + 10
			finger_drag(start, start + Vector2(0, -30), 3)
			check(panel.drag_kind == "pine_cone", tag + " press-and-hold then vertical move drags")
			touch(start + Vector2(0, -30), false)
			await frames()
			check(panel.drag_kind.is_empty() and committed_nothing(cone_before, places_before), tag + " hold drag dropped on nothing commits nothing")
		# Mouse: press on the cone, move to a spot, release -> placed there.
		main._last_touch_ms = -100000
		await bring_into_view(grid.cells["pine_cone"])
		start = center(grid.cells["pine_cone"])
		mouse_button(start, true)
		mouse_move(start, start + Vector2(20, 0), 2)
		check(panel.drag_kind == "pine_cone" and panel.panel.modulate.a < 0.5, tag + " mouse drag picks up the cone")
		target_spot = "pond_path"
		target = panel.spot_screen_position(target_spot)
		mouse_move(start + Vector2(20, 0), target)
		check(panel.drag_spot == target_spot, tag + " zone under the mouse lights up")
		mouse_button(target, false)
		await frames()
		await placed_by_drop(tag + " mouse", target_spot, cone_before, places_before)
		# Mouse drag that ends back on its own cell cancels and does not open the paper.
		await bring_into_view(grid.cells["pine_cone"])
		start = center(grid.cells["pine_cone"])
		mouse_button(start, true)
		mouse_move(start, start + Vector2(20, 0), 2)
		mouse_move(start + Vector2(20, 0), start, 2)
		var lit_under_cell: String = panel.zone_at(start)
		mouse_button(start, false)
		await frames()
		if lit_under_cell.is_empty():
			check(panel.drag_kind.is_empty() and not grid.menu.visible and committed_nothing(cone_before, places_before), tag + " mouse drag back onto the cell cancels without opening the paper")
		else:
			# Landscape: a lit spot can sit behind the cell itself; the lit spot wins.
			check(panel.drag_kind.is_empty() and not grid.menu.visible, tag + " drop on a lit spot behind the cell places there, no paper")
			await placed_by_drop(tag + " behind cell", lit_under_cell, cone_before, places_before)
		check(committed_nothing(cone_before, places_before), tag + " drag back commits nothing")
		mouse_button(start, true)
		mouse_button(start, false)
		await frames()
		check(grid.menu.visible and grid.selected == "pine_cone", tag + " a plain click still opens the paper afterwards")
		grid.close_menu()
		main._hide_basket()
		await frames()
	# Occupied spot: place the cone at the house, then drag the feather.
	root.size = Vector2i(1280, 720)
	await frames()
	await open_basket()
	var p = main._basket_panel
	var g = p.grid
	main._place_from_basket(ExplorationRoutes.FIND_PINE_CONE, "house_edge")
	await settle()
	check(store.get_yard_decor().places.has("house_edge"), "the cone is placed at the house")
	await frames()
	check(p.legal_spots().size() == 2 and not p.legal_spots().has("house_edge"), "occupied house spot is no longer legal")
	await bring_into_view(g.cells["feather"])
	var s := center(g.cells["feather"])
	var house: Vector2 = p.get_global_transform_with_canvas().affine_inverse() * (main._world.decor_view.get_global_transform_with_canvas() * Vector2(spots.house_edge))
	touch(s, true)
	finger_drag(s, s + Vector2(40, 0), 2)
	finger_drag(s + Vector2(40, 0), house)
	check(p.drag_kind == "feather" and p.drag_spot != "house_edge", "occupied spot does not light up")
	touch(house, false)
	await frames()
	check(p.visible and not main._decor.busy(), "drop on the occupied spot submits nothing")
	await frames()
	check(store.get_yard_decor().places.size() == 1 and int(store.get_available_keepsakes().get(feather, 0)) == 1, "feather not spent")
	# Saving: while the inventory is busy no drag starts, and a drag in progress is cancelled.
	await bring_into_view(g.cells["feather"])
	s = center(g.cells["feather"])
	touch(s, true)
	finger_drag(s, s + Vector2(40, 0), 2)
	check(p.drag_kind == "feather", "feather drag starts")
	main._world._reel_in_fish()
	main._on_inventory_changed()
	await frames(1)
	if main._inventory.busy():
		check(p.drag_kind.is_empty() and not p.drag_layer.visible and not p.can_drag("feather"), "saving cancels the drag and blocks new ones")
	touch(s + Vector2(40, 0), false)
	await settle()
	main._on_inventory_changed()
	await frames()
	check(p.can_drag("feather"), "after the save the feather can be dragged again")
	main._hide_basket()
	root.get_node("AudioDirector").release_streams()
	print("[yard-basket-drag] %s: %d checks" % ["PASS" if failures.is_empty() else "FAIL: %d of" % failures.size(), checks])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
