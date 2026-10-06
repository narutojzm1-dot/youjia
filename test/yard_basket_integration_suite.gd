extends SceneTree
var checks := 0
var failures: Array[String] = []
var main
var store

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func settle() -> void:
	check(await store.flush_pending(), "native write and acknowledgement complete")
	for frame in 3: await process_frame

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		push_error("Basket integration requires an isolated player profile")
		quit(2)
		return
	store = root.get_node("SaveStore")
	root.size = Vector2i(390, 844)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for frame in 3: await process_frame
	await main._start_holiday()
	check(main._world.inventory_enabled, "production yard uses inventory")
	check(main._inventory.view().fish.is_empty(), "fresh profile has no fish")
	main._world._reel_in_fish()
	check(main._inventory.busy(), "catch waits for commit")
	check(main._inventory.view().fish.is_empty(), "catch not granted on acceptance")
	await settle()
	var fish: String = main._inventory.view().fish.keys()[0]
	check(main._inventory.view().fish[fish] == 1, "catch stored exactly once")
	check(main._world._fish_carry_type == "", "catch is in basket rather than duplicate hand")
	main._show_basket()
	check(paused and not main._world.input_enabled, "basket pauses world input")
	var paused_elapsed: float = main._world._day_elapsed
	main._process(5.0)
	check(is_equal_approx(main._world._day_elapsed, paused_elapsed), "open basket stops world time")
	main._basket_panel.fish_buttons[fish].pressed.emit()
	await settle()
	check(main._inventory.view().held == fish, "button takes fish from durable basket")
	check(main._inventory.view().fish.get(fish, 0) == 0, "withdraw decrements stored count")
	check(main._world._fish_carry_type == fish and main._world._fish_carry_timer == 0, "hand synchronized without expiry timer")
	main._hide_basket()
	main._world.tick(21.0, Vector2.ZERO)
	check(main._world._fish_carry_type == fish, "old twenty second timeout cannot remove durable fish")
	await settle()
	store._load()
	check(store.get_yard_inventory().held == fish, "real file close and reopen keeps held fish")
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(store.SAVE_PATH))
	check(saved is Dictionary and saved.yard_inventory.held == fish, "hand present in actual native save bytes")
	main._show_basket()
	main._basket_panel.return_button.pressed.emit()
	await settle()
	check(main._inventory.view().held == "" and main._inventory.view().fish[fish] == 1, "return button conserves fish")
	for locale: String in ["zh-CN", "en"]:
		root.get_node("I18n").set_locale(locale)
		main._on_inventory_changed()
		for viewport: Vector2i in [Vector2i(390, 844), Vector2i(844, 390), Vector2i(320, 568), Vector2i(568, 320), Vector2i(1280, 720)]:
			root.size = viewport
			for frame in 5: await process_frame
			var bounds: Rect2 = main._basket_panel.panel.get_global_rect()
			check(Rect2(Vector2.ZERO, Vector2(viewport)).encloses(bounds), "basket fits " + str(viewport) + locale)
			check(bounds.encloses(main._basket_panel.close_button.get_global_rect()), "close remains inside panel")
			var album: Rect2 = main._album_chip.get_global_rect()
			var weather: Rect2 = main._weather_chip.get_global_rect()
			var basket: Rect2 = main._basket_chip.get_global_rect()
			check(not album.intersects(weather) and not weather.intersects(basket), "HUD chips do not overlap " + str(viewport) + locale)
			check(Rect2(Vector2.ZERO, Vector2(viewport)).encloses(basket), "basket HUD stays on screen")
	root.size = Vector2i(568, 320)
	for frame in 5: await process_frame
	var start: Vector2 = main._basket_panel.scroll.get_global_rect().get_center()
	var down := InputEventScreenTouch.new()
	down.position = start
	down.pressed = true
	main._input(down)
	var drag := InputEventScreenDrag.new()
	drag.position = start - Vector2(0, 60)
	drag.relative = Vector2(0, -60)
	main._input(drag)
	var up := InputEventScreenTouch.new()
	up.position = drag.position
	main._input(up)
	check(main._basket_panel.scroll.scroll_vertical > 0, "short landscape touch scroll reaches lower rows")
	check(not main._inventory.busy(), "scroll gesture cannot withdraw a fish")
	main._basket_panel.fish_buttons[fish].pressed.emit()
	await settle()
	main._hide_basket()
	var goose = main._world.actor_named("goose")
	main._world.get_player().position = goose.position
	main._world._interact_with_target("toss_fish:goose")
	check(main._inventory.busy() and main._world._fish_carry_type == fish, "drop waits for durable transfer")
	await settle()
	check(main._inventory.view().held == "" and main._world._fish_carry_type == "", "drop clears the hand only after confirmation")
	store._load()
	check(store.get_yard_inventory().held == "" and store.get_yard_inventory().fish.is_empty() and store.get_yard_inventory().ground.size() == 1, "real reopen preserves ground fish without duplicating basket or hand")
	root.get_node("AudioDirector").release_streams()
	print("YARD_BASKET_INTEGRATION checks=%d failures=%d" % [checks, failures.size()])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
