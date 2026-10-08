extends SceneTree
## REQ-20261008-075 Main-mount evidence: HoldHotbar child on real Main,
## update_view syncs held, withdraw_requested hits inventory request path,
## layout clears bottom chips on 390×844 / 1280×720 / 568×320, place-armed
## yard tap routes through HoldPlaceIntent without deducting on illegal,
## cancel disarm + pause/basket reopen restore held without deduct.

var checks := 0
var failures: Array[String] = []
var main
var store

func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


func settle() -> void:
	check(await store.flush_pending(), "native write and acknowledgement complete")
	for _frame in 3:
		await process_frame


func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		push_error("Hold hotbar mount requires an isolated player profile")
		quit(2)
		return
	store = root.get_node("SaveStore")
	root.size = Vector2i(390, 844)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for _frame in 3:
		await process_frame
	# Methods exist even before holiday (created in _ready)
	for method: String in [
		"_ensure_hold_hotbar",
		"_layout_hold_hotbar",
		"_on_hold_withdraw",
		"_try_hold_place_at",
		"_sync_hold_hotbar_visibility",
	]:
		check(main.has_method(method), "Main exposes %s" % method)
	check(main._hold_hotbar != null, "HoldHotbar created under Main")
	check(main._hold_hotbar.get_parent() == main._ui_layer, "HoldHotbar lives on _ui_layer")
	check(main._ui_layer.get_node_or_null("HoldHotbar") == main._hold_hotbar, "HoldHotbar named child present")
	await main._start_holiday()
	for _frame in 3:
		await process_frame
	check(main._hold_hotbar.visible, "hotbar visible on open yard game screen")
	check(not main._basket_panel.visible, "basket closed while hotbar shown")
	# Catch one fish into basket, withdraw via hotbar signal path
	main._world._reel_in_fish()
	await settle()
	var fish: String = main._inventory.view().fish.keys()[0]
	check(not fish.is_empty(), "caught fish stored in basket")
	main._on_inventory_changed()
	await process_frame
	check(main._hold_hotbar.counts.get(fish, 0) >= 1, "hotbar update_view shows basket count")
	main._hold_hotbar.withdraw_requested.emit(fish)
	await settle()
	check(main._inventory.view().held == fish, "withdraw_requested triggers controller withdraw")
	check(main._hold_hotbar.selected_kind() == fish and main._hold_hotbar.is_place_armed(), "held fish selects and arms place")
	# Layout clearance vs action/basket chips across viewports
	for vs: Vector2i in [Vector2i(390, 844), Vector2i(1280, 720), Vector2i(568, 320)]:
		root.size = vs
		main.size = Vector2(vs)
		main._layout()
		for _frame in 4:
			await process_frame
		var bar: Rect2 = main._hold_hotbar.get_global_rect()
		var action: Rect2 = main._action_button.get_global_rect()
		var basket: Rect2 = main._basket_chip.get_global_rect()
		var album: Rect2 = main._album_chip.get_global_rect()
		var tag := "%dx%d" % [vs.x, vs.y]
		check(Rect2(Vector2.ZERO, Vector2(vs)).encloses(bar), tag + " hotbar stays on screen")
		check(not bar.intersects(action), tag + " hotbar does not cover action chip")
		check(not bar.intersects(basket), tag + " hotbar does not cover basket chip")
		check(not bar.intersects(album), tag + " hotbar does not cover album chip")
		check(main._hold_hotbar.visible, tag + " hotbar remains visible in open yard")
		main._show_notice_key("notice.cannot_walk")
		for _frame in 3: await process_frame
		check(not bar.intersects(main._notice.get_global_rect()), tag + " hotbar does not obscure ordinary notices")
	# Overlay hides
	main._show_basket()
	await process_frame
	check(not main._hold_hotbar.visible, "hotbar hidden while basket open")
	main._hide_basket()
	await process_frame
	check(main._hold_hotbar.visible, "hotbar returns after basket close")
	main._toggle_pause()
	await process_frame
	check(not main._hold_hotbar.visible, "hotbar hidden while paused")
	main._toggle_pause()
	await process_frame
	check(main._hold_hotbar.visible, "hotbar returns after unpause")
	# Experience path on desktop viewport: illegal → cancel/reopen → lawful
	root.size = Vector2i(1280, 720)
	main.size = Vector2(1280, 720)
	main._layout()
	for _frame in 3:
		await process_frame
	main._hold_hotbar.arm_placement(true)
	var held_before: String = main._inventory.view().held
	var rev_before: int = int(main._inventory.view().revision)
	var pond_world: Vector2 = YardGround.POND_CENTER
	var canvas: Transform2D = main.get_viewport().get_canvas_transform()
	var pond_screen: Vector2 = canvas * pond_world
	var lawn_world := Vector2(400, 520)
	var lawn_screen: Vector2 = canvas * lawn_world
	var consumed: bool = main._try_hold_place_at(pond_screen)
	check(consumed, "armed pond tap is consumed by hold place path")
	await process_frame
	check(main._inventory.view().held == held_before, "illegal pond tap does not clear held")
	check(int(main._inventory.view().revision) == rev_before, "illegal pond tap does not advance revision")
	# Cancel disarm: held stays; yard tap must not consume / deduct
	main._hold_hotbar.arm_placement(false)
	await process_frame
	check(main._inventory.view().held == held_before, "cancel disarm keeps held")
	check(not main._hold_hotbar.is_place_armed(), "cancel disarm clears place arm")
	var cancel_consumed: bool = main._try_hold_place_at(lawn_screen)
	check(not cancel_consumed, "disarmed yard tap is not consumed by hold place")
	check(main._inventory.view().held == held_before, "disarmed tap does not deduct")
	# Re-arm then pause/basket reopen: visibility restores; held stays
	main._hold_hotbar.arm_placement(true)
	await process_frame
	check(main._hold_hotbar.is_place_armed(), "re-arm after cancel")
	main._toggle_pause()
	await process_frame
	check(not main._hold_hotbar.visible, "hotbar hidden while paused (reopen path)")
	check(main._inventory.view().held == held_before, "pause does not clear held")
	main._toggle_pause()
	await process_frame
	check(main._hold_hotbar.visible, "hotbar returns after unpause")
	check(main._inventory.view().held == held_before, "held restored after unpause")
	check(main._hold_hotbar.selected_kind() == held_before, "selection restored after unpause")
	main._show_basket()
	await process_frame
	check(not main._hold_hotbar.visible, "hotbar hidden while basket open (reopen path)")
	main._hide_basket()
	await process_frame
	main._on_inventory_changed()
	await process_frame
	check(main._hold_hotbar.visible, "hotbar returns after basket close")
	check(main._inventory.view().held == held_before, "held restored after basket reopen")
	check(main._hold_hotbar.selected_kind() == held_before, "selection restored after basket reopen")
	# Lawful lawn drop via helper
	main._hold_hotbar.arm_placement(true)
	consumed = main._try_hold_place_at(lawn_screen)
	check(consumed, "armed lawn tap consumed")
	await settle()
	check(main._inventory.view().held.is_empty(), "lawful drop clears held via inventory request")
	check(main._inventory.view().ground.size() >= 1, "lawful drop adds ground food")
	# 院子拔草让 held 变成草束。草束不自动武装，点地仍走既有走路/互动。
	main._on_ground_food_action("harvest", "grass", {}, "")
	await settle()
	check(main._inventory.view().held == "grass", "yard harvest puts grass in hand")
	check(not main._hold_hotbar.is_place_armed(), "yard harvest does not keep tap-to-place armed")
	main._on_inventory_changed()
	await process_frame
	check(not main._hold_hotbar.is_place_armed(), "inventory refresh does not re-arm world grass")
	_finish()


func _finish() -> void:
	check(checks >= 35, "mount suite ran enough checks (%d)" % checks)
	if root.has_node("AudioDirector"):
		root.get_node("AudioDirector").release_streams()
	if failures.is_empty():
		print("[hold-hotbar-mount] PASS: %d checks" % checks)
		quit(0)
	else:
		for failure: String in failures.slice(0, 40):
			printerr("[hold-hotbar-mount] " + failure)
		print("[hold-hotbar-mount] FAIL: %d of %d" % [failures.size(), checks])
		quit(1)
