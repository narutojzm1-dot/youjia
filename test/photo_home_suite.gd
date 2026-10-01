extends SceneTree

# Command-path integration test from the natural initial spawn. No placement,
# forced photo rules, direct lead calls, or manually assigned actor states.
# Run: godot --headless --path . --script res://test/photo_home_suite.gd
# Device/viewport dispatch is covered separately by explicit_target_suite.gd.
const FRAME_RATES := [30, 60, 120]
const RESIDENT_IDS := ["goose", "sheep_a", "sheep_b", "cow", "horse", "duck_a", "duck_b", "duck_c"]
var _checks := 0
var _failures := PackedStringArray()
var _escaped: Dictionary = {}
var _jumps: Dictionary = {}
var _bad_player_ground := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("TuningStore").call("end_run")
	root.get_node("TuningStore").call("reset_defaults")
	for fps: int in FRAME_RATES:
		_test_visits_and_release(fps)
	root.get_node("AudioDirector").call("release_streams")
	if _failures.is_empty():
		print("[photo-home-tests] PASS: %d checks" % _checks)
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[photo-home-tests] " + failure)
		print("[photo-home-tests] FAIL: %d failures across %d checks" % [_failures.size(), _checks])
		quit(1)


func _test_visits_and_release(fps: int) -> void:
	seed(1012026 + fps)
	var world_script: Script = load("res://scripts/game/yard_world.gd")
	_check(world_script != null and world_script.can_instantiate(), "yard compiles at %dHz" % fps)
	if world_script == null or not world_script.can_instantiate():
		return
	var world = world_script.new()
	root.add_child(world)
	world.setup()
	world._weather_timer = 10000.0
	_escaped.clear()
	_jumps.clear()
	_bad_player_ground = false
	var llama = world.actor_named("llama")
	var player = world.get_player()
	var label := "%dHz" % fps
	_check(not world._leading and not player.carrying_grass, "%s starts with empty hands and a free llama" % label)
	world.request_pointer_action(llama.position + Vector2(0, -48))
	for frame: int in fps * 30:
		_tick_checked(world, fps)
		if world._leading:
			break
	_check(world._leading, "%s pointer approach starts leading the real initial llama" % label)
	_check(player.position.distance_to(Vector2(260, 540)) > 100.0, "%s player walks to the llama without relocation" % label)

	# Lead toward the cottage-side sheep. Residents keep their own routines.
	var sheep_home: Rect2 = world.actor_named("sheep_a").wander_rect
	var cottage_goal := sheep_home.get_center() + Vector2(-42, 14)
	_walk_to(world, cottage_goal, fps, "cottage sheep")
	_wait_for_photo(world, "llama_sun_sheep_happy", fps)
	_check("llama_sun_sheep_happy" in world.collected, "%s visiting home sheep in sun earns the happy photo" % label)
	_check(world._leading and llama.position.distance_to(player.position) < 90.0, "%s llama follows to cottage sheep" % label)

	# Cross the same reachable lawn to the goose's pond-side home.
	world.set_weather("overcast")
	var goose_home: Rect2 = world.actor_named("goose").wander_rect
	var goose_goal := goose_home.get_center() + Vector2(48, -5)
	_walk_to(world, goose_goal, fps, "pond-side goose")
	_wait_for_photo(world, "llama_overcast_goose_annoyed", fps)
	_check("llama_overcast_goose_annoyed" in world.collected, "%s visiting home goose in overcast earns the annoyed photo" % label)
	_check(world._leading, "%s goose encounter does not lose the lead" % label)

	# Return home and release far outside the llama's configured initial area.
	# A local destination clipped to that old rectangle used to freeze here.
	world.set_weather("sun")
	_walk_to(world, Vector2(240, 550), fps, "cottage release")
	for frame: int in fps * 3:
		_tick_checked(world, fps)
	world.request_primary_action()
	_check(not world._leading and llama.state in ["rest", "graze", "wander"], "%s HUD release returns llama to daily life" % label)
	_check(not llama.wander_rect.has_point(llama.position), "%s release fixture is outside the original llama rectangle at %s" % [label, llama.position])
	var release_position: Vector2 = llama.position
	var previous: Vector2 = release_position
	var travel := 0.0
	var quiet_frames := 0
	var states: Dictionary = {}
	for frame: int in fps * 90:
		_tick_checked(world, fps)
		travel += llama.position.distance_to(previous)
		if llama._velocity.length() <= 0.3:
			quiet_frames += 1
		states[llama.state] = true
		previous = llama.position
	_check(travel > 80.0, "%s released llama keeps exploring the safe lawn (%.1fpx)" % [label, travel])
	_check(float(quiet_frames) / float(fps * 90) > 0.60, "%s released llama still spends most time resting/grazing" % label)
	_check(states.has("wander") and states.has("graze") and states.has("rest"), "%s released llama resumes all daily activities" % label)
	_check(_escaped.is_empty(), "%s residents stay home throughout visits and release: %s" % [label, _escaped])
	_check(_jumps.is_empty(), "%s player and animals never teleport during command routes: %s" % [label, _jumps])
	_check(not _bad_player_ground, "%s all player travel follows the safe lawn" % label)
	print("[photo-home-tests] %s photos=%s release=%s free_travel=%.1fpx quiet=%.1f%%" % [label, world.collected, release_position, travel, 100.0 * float(quiet_frames) / float(fps * 90)])
	world.free()


func _walk_to(world, goal: Vector2, fps: int, purpose: String) -> void:
	world.request_pointer_action(goal)
	_check(world._pending_interaction == "" and world._has_walk_goal,
		"%dHz %s is accepted as a ground walking command" % [fps, purpose])
	for frame: int in fps * 45:
		_tick_checked(world, fps)
		if not world._has_walk_goal:
			break
	_check(world.get_player().position.distance_to(goal) < 16.0,
		"%dHz walks to %s (distance %.1fpx)" % [fps, purpose, world.get_player().position.distance_to(goal)])
	_check(world._leading, "%dHz %s preserves leading" % [fps, purpose])


func _wait_for_photo(world, photo_id: String, fps: int) -> void:
	for frame: int in fps * 12:
		if photo_id in world.collected:
			return
		_tick_checked(world, fps)


func _tick_checked(world, fps: int) -> void:
	var before: Dictionary = {}
	for actor_id: String in RESIDENT_IDS + ["llama"]:
		before[actor_id] = world.actor_named(actor_id).position
	var player_before: Vector2 = world.get_player().position
	world.tick(1.0 / float(fps), Vector2.ZERO)
	for actor_id: String in RESIDENT_IDS + ["llama"]:
		var actor = world.actor_named(actor_id)
		var on_home: bool = actor._stands_on(actor.position)
		if actor.species != "llama" and actor.species != "duck":
			on_home = on_home and actor.wander_rect.grow(0.01).has_point(actor.position)
		if not on_home:
			_escaped[actor_id] = actor.position
		# A led llama has a higher speed cap than a daily wanderer.
		if actor.position.distance_to(before[actor_id]) > 100.0 / float(fps) + 0.05:
			_jumps[actor_id] = actor.position.distance_to(before[actor_id])
	var player = world.get_player()
	if player.position.distance_to(player_before) > 120.0 / float(fps) + 0.05:
		_jumps["player"] = player.position.distance_to(player_before)
	if not YardGround.allows(player.position, YardGround.lawn(), true):
		_bad_player_ground = true


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
