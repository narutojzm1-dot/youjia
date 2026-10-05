extends SceneTree

var failures: Array[String] = []
var checks := 0

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
		print("REFUSED: isolated daily runner required")
		quit(2)
		return
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main._on_play_pressed()
	await process_frame
	var world = main._world
	main.set_process(false)
	world.set_process(false)
	world._player.position = world._fishing_point() + Vector2(0, -50)
	world._selected_target = "fishing"
	world._pending_interaction = ""
	world._fish_carry_type = "small"
	world._fish_carry_timer = 12.0
	world._fish_state = world.FISH_IDLE
	world._start_fishing()
	check(world.primary_action_key() == "action.fish_waiting", "old fish cannot hide active waiting label")
	world.request_primary_action()
	check(world._fish_state == world.FISH_CASTING and world._fish_carry_type == "small" and world._fish_carry_timer == 12.0, "waiting primary does not toss old fish or reset expiry")
	world._fish_state = world.FISH_BITE
	world._fish_timer = 0.1
	check(world.primary_action_key() == "action.reel", "old fish cannot hide reel label")
	world._tick_fishing(0.2)
	check(world._fish_state == world.FISH_IDLE and world._fish_carry_type == "small" and world._fish_carry_timer == 12.0, "miss retains legitimate old fish and its original expiry")
	check(world.primary_action_key() == "action.toss_fish", "after miss default returns to old fish")
	world._start_fishing()
	world._fish_state = world.FISH_BITE
	var previous: int = world._fish_caught_total
	world.request_primary_action()
	check(world._fish_caught_total == previous + 1 and world._fish_state == world.FISH_IDLE, "production primary actually reels second catch")
	check(not world._fish_carry_type.is_empty() and world._fish_carry_timer == 20.0, "successful catch keeps existing carry behavior")
	world._fish_state = world.FISH_CASTING
	world._selected_target = "toss_fish:goose"
	check(world.primary_action().target == "toss_fish:goose", "explicit animal choice still wins")
	world._selected_target = ""
	world._player.position = world._fishing_point() + Vector2(0, -120)
	check(world.primary_action_key() == "action.toss_fish", "walking away restores carried fish action")
	world._fish_carry_type = ""
	world._player.position = world._fishing_point() + Vector2(0, -50)
	world._fish_state = world.FISH_BITE
	check(world.primary_action_key() == "action.reel", "empty-handed fishing unchanged")
	main.queue_free()
	await process_frame
	print("fishing active HUD: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
