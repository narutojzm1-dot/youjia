extends SceneTree
const Director := preload("res://scripts/game/balcony_morning.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return
	var events: Array[String] = []
	for block: int in 10:
		var count := 0
		for offset: int in 3:
			var day := block * 3 + offset + 1
			var kind := Director.plan(day, "sun")
			check(kind == Director.plan(day, "sun"), "reloading the same day preserves plan")
			check(Director.plan(day, "rain").is_empty(), "no balcony event in rain")
			if not kind.is_empty():
				count += 1
				events.append(kind)
		check(count == 1, "ordinary exits remain two mornings in three")
	check(events.slice(0, 5).size() == 5 and events.slice(0, 5).count("coffee") == 1, "five activity bag includes coffee once")
	for i: int in range(1, events.size()): check(events[i] != events[i-1], "successive planned mornings differ")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i: int in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	var world = main._world
	var player = world.get_player()
	var director = world.house.balcony
	var seen: Array[String] = []
	for kind: String in Director.ACTIVITIES:
		director.begin(kind)
		var stages: Array[String] = []
		var saw_keys: Array[Texture2D] = []
		for frame: int in 1000:
			var before: Vector2 = director.walker.position
			director.tick(1.0 / 60.0, false)
			if not director.stage in stages: stages.append(director.stage)
			check(before.distance_to(director.walker.position) <= 0.401, "authored balcony walk never teleports")
			if director.stage == "activity" and director.pose.texture != null:
				if not director.pose.texture in saw_keys: saw_keys.append(director.pose.texture)
			if not director.busy(): break
		check(not director.busy() and not director.visible, "event fully returns indoors: " + kind)
		check(stages == ["open", "emerge", "walk", "activity", "return", "inside", "close", ""], "ordered complete upstairs path: " + kind)
		check(saw_keys.size() == 2, "two distinct painted action keys: " + kind)
		check(director.walker.position == Director.DOOR, "return uses same upstairs threshold")
		seen.append(kind)
	# A real world pointer, action, or movement request shortens the activity;
	# it cannot redirect the hidden player through the wall or grant another day.
	for trigger: String in ["pointer", "primary", "keyboard"]:
		director.begin("coffee")
		director.stage = "activity"
		director.walker.position = Director.SPOT
		world.house.stage = "balcony"
		player.visible = false
		player.position = world.house.INSIDE
		player.walk_ground = world.house.PASSAGE
		var old_day: int = world.holiday_day
		if trigger == "pointer": world.request_pointer_action(Vector2(600, 500))
		elif trigger == "primary": world.request_primary_action()
		else: world.tick(1.0 / 60.0, Vector2.RIGHT)
		check(director.cancelled and director.stage == "return", "real input shortens event: " + trigger)
		var saw_stairs := false
		var saw_front := false
		for frame: int in 1800:
			world.tick(1.0 / 60.0, Vector2.ZERO)
			saw_stairs = saw_stairs or world.house.stage == "stairs"
			saw_front = saw_front or (world.house.stage == "out" and player.visible)
			if not world.house.busy(): break
		check(saw_stairs and saw_front and not world.house.busy(), "shortened event still descends inside and walks front porch")
		check(player.visible and player.modulate.a == 1.0 and player.walk_ground == world.player_ground(), "input and normal geometry restored")
		check(world.holiday_day == old_day, "cosmetic event never advances durable day")
	director.begin("brush")
	director.stage = "activity"
	director.tick(0.1, true)
	var still: Texture2D = director.pose.texture
	director.tick(2.0, true)
	check(still == director.pose.texture, "reduced motion holds a clear authored key")
	world.house.stage = "balcony"
	var paused_seconds: float = director.seconds
	main._toggle_pause()
	for frame: int in 90: main._process(1.0 / 30.0)
	check(director.seconds == paused_seconds, "actual pause UI stops the balcony clock")
	main._toggle_pause()
	check(not paused, "pause UI resumes the game")
	director.skip()
	for frame: int in 600: director.tick(1.0 / 60.0, true)
	check(not director.busy(), "reduced motion does not trap the traveller")
	world.house.stage = ""
	# Real durable sleep, then leave while the upstairs cosmetic is in flight.
	# Reopening must restore the confirmed morning outdoors without granting or
	# replaying it again. No new save-schema field is required for a cutscene.
	var store = root.get_node("SaveStore")
	check(await store.flush_pending(), "earlier requests settled before restart fixture")
	world.holiday_day = store.get_holiday_day()
	world._day_elapsed = 400.0
	world.weather = "sun"
	world._regional_weather.restore({"weather":"sun", "remaining":1800.0, "seed":123, "episode":0})
	world.debug_place_player(world.house.APPROACH)
	world.house.begin()
	for frame: int in 1800:
		world.tick(1.0 / 60.0, Vector2.ZERO)
		if world.house.stage == "saving": break
	check(world.house.stage == "saving" and not director.busy(), "no upstairs scene before durable morning")
	check(await store.flush_pending(), "sleep reaches native durable host")
	for frame: int in 600:
		world.tick(1.0 / 60.0, Vector2.ZERO)
		if world.house.stage == "balcony": break
	check(world.house.stage == "balcony" and not player.visible, "confirmed dawn alone starts upstairs proxy")
	var durable_day: int = store.get_holiday_day()
	main._show_title()
	await main._start_holiday()
	check(main._world.holiday_day == durable_day, "actual scene reopening retains exactly the confirmed morning")
	check(not main._world.house.busy() and main._world.get_player().visible, "reopening safely restores an outdoor controllable player")
	main.queue_free()
	await process_frame
	for failure: String in failures: printerr(failure)
	print("balcony_morning_suite checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
