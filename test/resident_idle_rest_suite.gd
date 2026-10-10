extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated): quit(2); return
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i: int in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	var world = main._world
	var player = world.get_player()
	var rest = player.idle_rest
	player.position = Vector2(400,510)
	player.body_obstacles = []
	player.rest_allowed = true
	for i: int in 2699: player.tick(1.0/60.0, Vector2.ZERO, world.WORLD_SIZE)
	check(not rest.active(), "does not sit before45s")
	for i: int in 50: player.tick(1.0/60.0, Vector2.ZERO, world.WORLD_SIZE)
	check(rest.stage == "sit", "lower transitions into seated pose")
	check(player.snapshot_state() == "sitting" and not player._sequence_walker.visible, "photo state and unique visible body")
	var before: Vector2 = player.position
	player.tick(1.0/60.0,Vector2.RIGHT,world.WORLD_SIZE)
	check(rest.getting_up(), "one-frame input requests rise")
	for i: int in 55: player.tick(1.0/60.0,Vector2.ZERO,world.WORLD_SIZE)
	check(player.position.x > before.x + 1.0, "released one-frame key is replayed after getup")
	check(not rest.active(), "returns to normal locomotion")
	player.clear_idle_rest()
	for i: int in 8300: player.tick(1.0/60.0,Vector2.ZERO,world.WORLD_SIZE)
	check(rest.stage == "nap" and rest.cel == 6, "full sit lean recline then eyesclosed")
	var day: int = world.holiday_day
	var clock: float = world._day_elapsed
	world.tick(0.1,Vector2.ZERO)
	check(day == world.holiday_day and absf(world._day_elapsed-clock-0.1) < 0.001, "outdoor nap follows ordinary clock without day skip")
	world.input_enabled = false
	check(not rest.active() and rest.idle_seconds == 0.0, "all menu input locks immediately clear rest")
	world.input_enabled = true
	player.rest_allowed = false
	for i: int in 8400: player.tick(1.0/60.0,Vector2.ZERO,world.WORLD_SIZE)
	check(not rest.active() and rest.idle_seconds == 0.0, "ineligible time never accumulates")
	player.rest_allowed = true
	player.carrying_grass = true
	player.tick(200,Vector2.ZERO,world.WORLD_SIZE)
	check(not rest.active(), "held grass excludes rest")
	player.carrying_grass = false
	player.leading = true
	player.tick(200,Vector2.ZERO,world.WORLD_SIZE)
	check(not rest.active(), "leading excludes rest")
	player.leading = false
	# Authored pose bounds remain isolated and contact points inside each crop.
	for index: int in rest.REGIONS.size():
		check(rest.REGIONS[index].has_point(rest.CONTACTS[index]), "contact inside cel" + str(index))
		for other: int in range(index + 1,rest.REGIONS.size()): check(not rest.REGIONS[index].intersects(rest.REGIONS[other]), "atlas regions never overlap")
	# Real world eligibility must reject banks, actors, fishing, grain and scenes.
	player.position = Vector2(400,510)
	player.body_obstacles = []
	world._goose_mount_wait = 0.0
	world._goose_mount_phase = -1
	world._focus_seconds = 0.0
	check(world._outdoor_rest_allowed(Vector2.ZERO), "open ground eligible")
	player.position = Vector2(500,545)
	check(not world._outdoor_rest_allowed(Vector2.ZERO), "bank/ground edge rejects horizontal body")
	player.position = Vector2(400,510)
	player.body_obstacles = [{"position":Vector2(425,510),"radius":Vector2(20,10)}]
	check(not world._outdoor_rest_allowed(Vector2.ZERO), "animal clearance wider than standing body")
	player.body_obstacles = []
	for field: String in ["_grain_held","_fish_carry_type"]:
		world.set(field,"wheat")
		check(not world._outdoor_rest_allowed(Vector2.ZERO), "held item excludes:" + field)
		world.set(field,"")
	world._fish_state = world.FISH_CASTING
	check(not world._outdoor_rest_allowed(Vector2.ZERO), "fishing excludes rest")
	world._fish_state = world.FISH_IDLE
	world._has_walk_goal = true
	check(not world._outdoor_rest_allowed(Vector2.ZERO), "pending path excludes rest")
	world._has_walk_goal = false
	rest.stage = "nap"
	rest.visible = true
	world.request_pointer_action(Vector2(430,510))
	check(rest.getting_up() and world._has_walk_goal, "pointer wakes without swallowing destination")
	world.cancel_scene_feedback()
	check(not rest.active(), "scene/menu cancellation clears rest")
	rest.stage = "nap"
	rest.advance(0.01,false,1,-1,true,1)
	check(not rest.active(), "reduced motion wakes immediately")
	rest.advance(45.1,true,1,-1,true,1)
	check(rest.stage == "sit" and rest.pose.scale.x < 0, "reduced motion keeps seated key and facing")
	rest.advance(90.1,true,0.82,1,true,1)
	check(rest.stage == "nap" and is_equal_approx(rest.pose.scale.x,0.18*0.82), "reduced motion nap respects depth")
	print("resident_idle_rest_suite checks=%d failures=%d" % [checks,failures.size()])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
