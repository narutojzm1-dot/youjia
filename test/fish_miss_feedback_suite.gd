extends SceneTree

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated + "/"):
		printerr("REFUSED: isolated daily runner required")
		quit(2)
		return
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await main._start_holiday()
	var store = root.get_node("SaveStore")
	await store.flush_pending()
	main.set_process(false)
	var world = main._world
	world.set_process(false)
	world._player.position = world._fishing_point() + Vector2(0, -50)
	# Seed a real chance-miss branch, without replacing randf or the notifier.
	var chance_seed := -1
	for value in range(100):
		seed(value)
		if randf() >= 0.75:
			chance_seed = value
			break
	check(chance_seed >= 0, "chance-miss seed available")
	var caught: int = world._fish_caught_total
	for bite_timeout in [false, true]:
		for kind: String in ["", "small", "odd"]:
			var held: String = main._inventory.view().held
			if not held.is_empty():
				main._inventory.request("return", held)
				await store.flush_pending()
			if not kind.is_empty():
				main._inventory.request("catch", kind)
				await store.flush_pending()
				main._inventory.request("withdraw", kind)
				await store.flush_pending()
			var before: Dictionary = main._inventory.view()
			world._fish_state = world.FISH_BITE if bite_timeout else world.FISH_CASTING
			world._fish_timer = 0.1
			world._fish_bite_nudge = 10.0
			seed(chance_seed)
			world._tick_fishing(0.2)
			var expected := "notice.fishing.miss_with_carry" if not kind.is_empty() else "notice.fishing.miss"
			check(main._notice_key == expected, "miss notice matches durable carry: timeout=%s kind=%s" % [bite_timeout, kind])
			check(world._fish_state == world.FISH_IDLE and world._fish_carry_type == kind and main._inventory.view() == before, "miss preserves complete inventory and hand: " + kind)
	check(world._fish_caught_total == caught, "failed cast does not create a new catch")
	# WORLD-BASKET keeps confirmed hand items instead of expiring after twenty seconds.
	main._process(21.0)
	check(world._fish_carry_type == "odd" and world._fish_carry_timer == 0.0 and main._notice_key != "notice.fishing.release", "durable fish remains without a false release notice")
	check(world.primary_action_key() == "action.drop_food", "stored fish remains available for feeding")
	await main._show_title()
	root.get_node("AudioDirector").call("release_streams")
	print("[fish-miss-feedback] %d checks, %d failures: %s" % [checks, failures.size(), failures])
	quit(0 if failures.is_empty() else 1)
