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
	var isolated := OS.get_environment("XDG_DATA_HOME")
	if not isolated.begins_with("/tmp/youjia-daily-check.") or not OS.get_user_data_dir().begins_with(isolated + "/"):
		printerr("REFUSED: isolated daily runner required")
		quit(2)
		return
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main._on_play_pressed()
	await process_frame
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
		for case in [{"kind":"", "time":0.0}, {"kind":"small", "time":12.0}, {"kind":"odd", "time":0.0}]:
			world._fish_carry_type = case.kind
			world._fish_carry_timer = case.time
			world._fish_state = world.FISH_BITE if bite_timeout else world.FISH_CASTING
			world._fish_timer = 0.1
			world._fish_bite_nudge = 10.0
			seed(chance_seed)
			world._tick_fishing(0.2)
			var expected := "notice.fishing.miss_with_carry" if case.time > 0.0 else "notice.fishing.miss"
			check(main._notice_key == expected, "miss notice matches real carry: timeout=%s kind=%s time=%s" % [bite_timeout, case.kind, case.time])
			check(world._fish_state == world.FISH_IDLE and world._fish_carry_type == case.kind and world._fish_carry_timer == case.time, "miss preserves existing carry/state/timer: %s" % case)
	check(world._fish_caught_total == caught, "failed cast does not create a new catch")
	# Production carry expiry still clears the fish and supersedes prior text.
	world._fish_carry_type = "small"
	world._fish_carry_timer = 0.1
	main._process(0.2)
	check(world._fish_carry_type.is_empty() and world._fish_carry_timer <= 0.0 and main._notice_key == "notice.fishing.release", "expiry clears carry and says release")
	check(world.primary_action_key() != "action.toss_fish", "expired fish cannot be offered")
	main._show_title()
	root.get_node("AudioDirector").call("release_streams")
	print("[fish-miss-feedback] %d checks, %d failures: %s" % [checks, failures.size(), failures])
	quit(0 if failures.is_empty() else 1)
