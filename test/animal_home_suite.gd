extends SceneTree

# Outcome-based daily-life regression, independent of the controller's timers.
# Run: godot --headless --path . --script res://test/animal_home_suite.gd
# Each fixture observes three simulated minutes of sun, then three of overcast.
# Explicit pointer/feeding/leading regressions remain in explicit_target_suite.gd.
const FRAME_RATES := [30, 60, 120]
const WEATHER_SECONDS := 180
const RESIDENT_IDS := ["goose", "sheep_a", "sheep_b", "cow", "horse", "duck_a", "duck_b", "duck_c"]
const QUIET_SPEED := 0.3

var _checks := 0
var _failures := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var tuning := root.get_node("TuningStore")
	tuning.call("end_run")
	tuning.call("reset_defaults")
	for fps: int in FRAME_RATES:
		_test_daily_life(fps)
	root.get_node("AudioDirector").call("release_streams")
	if _failures.is_empty():
		print("[animal-home-tests] PASS: %d checks" % _checks)
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[animal-home-tests] " + failure)
		print("[animal-home-tests] FAIL: %d failures across %d checks" % [_failures.size(), _checks])
		quit(1)


func _test_daily_life(fps: int) -> void:
	# Different deterministic seeds make the three fixtures exercise different
	# choices, rather than requiring identical random sequences at every rate.
	seed(10012026 + fps)
	# Load after autoloads exist: --script compiles this harness before singleton
	# names are available to statically referenced gameplay scripts.
	var world_script: Script = load("res://scripts/game/yard_world.gd")
	_check(world_script != null and world_script.can_instantiate(), "yard script compiles at %d Hz" % fps)
	if world_script == null or not world_script.can_instantiate():
		return
	var world = world_script.new()
	root.add_child(world)
	world.setup()
	world.input_enabled = false
	var actors: Array = []
	for actor_id: String in RESIDENT_IDS + ["llama"]:
		var actor = world.actor_named(actor_id)
		_check(actor != null, "%s exists at %d Hz" % [actor_id, fps])
		if actor == null:
			continue
		actors.append(actor)
		_check(_at_home(actor), "%s starts on its own ground/home at %d Hz" % [actor_id, fps])
		if actor.species == "duck":
			_check(actor.use_ellipse, "%s uses its pond ellipse at %d Hz" % [actor_id, fps])
		elif actor.species != "llama":
			_check(actor.wander_rect.has_area(), "%s has a nonempty home at %d Hz" % [actor_id, fps])
	var delta := 1.0 / float(fps)
	for weather: String in ["sun", "overcast"]:
		var before_weather: Dictionary = {}
		for actor in actors:
			before_weather[actor.actor_id] = actor.position
		world.set_weather(weather)
		# Hold each weather long enough to expose drift and compulsive walking.
		# The second block also exercises a real weather change in the same yard.
		world._weather_timer = float(WEATHER_SECONDS + 10)
		var metrics: Dictionary = {}
		for actor in actors:
			_check(actor.position.distance_to(before_weather[actor.actor_id]) < 0.001,
				"%s does not relocate when weather becomes %s at %d Hz" % [actor.actor_id, weather, fps])
			metrics[actor.actor_id] = _new_metrics(actor.position)
		for frame: int in fps * WEATHER_SECONDS:
			world.tick(delta, Vector2.ZERO)
			for actor in actors:
				_observe(actor, metrics[actor.actor_id], delta)
		_check(world.weather == weather, "%s observation remains in requested weather at %d Hz" % [weather, fps])
		for actor in actors:
			_assert_rhythm(actor, metrics[actor.actor_id], weather, fps)
	world.free()


func _new_metrics(start: Vector2) -> Dictionary:
	return {
		"previous": start, "frames": 0, "quiet_frames": 0,
		"travel": 0.0, "max_step": 0.0, "discontinuous_frames": 0,
		"outside_frames": 0, "first_outside": Vector2.INF,
		"quiet_seconds": 0.0, "longest_quiet": 0.0,
		"leg_seconds": 0.0, "leg_distance": 0.0,
		"longest_leg": 0.0, "farthest_leg": 0.0, "completed_legs": 0,
		"states": {}, "invalid_frames": 0, "moving_in_pause": 0,
	}


func _observe(actor, metric: Dictionary, delta: float) -> void:
	var distance: float = actor.position.distance_to(metric.previous)
	var actual_speed := distance / delta
	var quiet: bool = actual_speed <= QUIET_SPEED and actor._velocity.length() <= QUIET_SPEED
	metric.frames += 1
	metric.travel += distance
	metric.max_step = maxf(metric.max_step, distance)
	# Movement may be eased or collision-limited, but cannot jump farther than
	# the maximum perspective-scaled speed permits during this one frame.
	if distance > actor.speed * 1.18 * delta + 0.02:
		metric.discontinuous_frames += 1
	if not actor.position.is_finite() or not actor._velocity.is_finite():
		metric.invalid_frames += 1
	if not _at_home(actor):
		metric.outside_frames += 1
		if metric.first_outside == Vector2.INF:
			metric.first_outside = actor.position
	metric.states[actor.state] = int(metric.states.get(actor.state, 0)) + 1
	if quiet:
		metric.quiet_frames += 1
		metric.quiet_seconds += delta
		metric.longest_quiet = maxf(metric.longest_quiet, metric.quiet_seconds)
		if metric.leg_distance > 2.0:
			metric.completed_legs += 1
		metric.leg_seconds = 0.0
		metric.leg_distance = 0.0
	else:
		metric.quiet_seconds = 0.0
		metric.leg_seconds += delta
		metric.leg_distance += distance
		metric.longest_leg = maxf(metric.longest_leg, metric.leg_seconds)
		metric.farthest_leg = maxf(metric.farthest_leg, metric.leg_distance)
	# Brief deceleration after reaching grass is allowed. Persistent movement
	# labelled rest/graze would hide the exact skating this suite should catch.
	if actor.state in ["rest", "graze"] and actual_speed > 1.0:
		metric.moving_in_pause += 1
	metric.previous = actor.position


func _at_home(actor) -> bool:
	if not actor._stands_on(actor.position):
		return false
	if actor.species == "duck":
		return actor.use_ellipse and YardGround.in_ellipse(actor.position, actor.ellipse_center, actor.ellipse_radius)
	if actor.species == "llama":
		# The interactive llama may explore the shared lawn or follow the player.
		return true
	# A tiny tolerance includes exact rectangle edges; it is not room to roam.
	return actor.wander_rect.grow(0.01).has_point(actor.position)


func _assert_rhythm(actor, metric: Dictionary, weather: String, fps: int) -> void:
	var label := "%s %s %dHz" % [actor.actor_id, weather, fps]
	var quiet_ratio := float(metric.quiet_frames) / float(metric.frames)
	var minimum_quiet := 0.35 if actor.species == "duck" else 0.60
	print("[animal-home-tests] %s quiet=%.1f%% travel=%.1fpx longest_leg=%.2fs/%.1fpx legs=%d max_step=%.3f outside=%d states=%s" % [
		label, quiet_ratio * 100.0, metric.travel, metric.longest_leg,
		metric.farthest_leg, metric.completed_legs, metric.max_step, metric.outside_frames, metric.states,
	])
	_check(metric.outside_frames == 0, "%s stays home every frame (outside=%d first=%s)" % [label, metric.outside_frames, metric.first_outside])
	_check(metric.invalid_frames == 0, "%s has finite positions and velocities" % label)
	_check(metric.discontinuous_frames == 0, "%s moves continuously without per-frame jumps (violations=%d)" % [label, metric.discontinuous_frames])
	_check(quiet_ratio > minimum_quiet, "%s is genuinely stationary >%.0f%% of frames (%.1f%%)" % [label, minimum_quiet * 100.0, quiet_ratio * 100.0])
	_check(metric.travel > 20.0, "%s takes real walks instead of freezing (%.1fpx)" % [label, metric.travel])
	_check(metric.completed_legs >= 3, "%s repeatedly walks and settles (legs=%d)" % [label, metric.completed_legs])
	_check(metric.longest_quiet >= 2.0, "%s has sustained quiet pauses (longest=%.2fs)" % [label, metric.longest_quiet])
	_check(metric.longest_leg < 12.0, "%s interrupts its walking within 12s (longest=%.2fs)" % [label, metric.longest_leg])
	_check(metric.farthest_leg < 90.0, "%s takes short local legs below 90px (longest=%.1fpx)" % [label, metric.farthest_leg])
	_check(float(metric.moving_in_pause) / float(metric.frames) < 0.05,
		"%s resting/grazing states do not conceal continuous motion" % label)
	for state: String in metric.states:
		_check(state in ["rest", "graze", "wander"], "%s exposes a recognized daily behavior: %s" % [label, state])
	_check(metric.states.has("rest"), "%s spends time resting" % label)
	_check(metric.states.has("wander"), "%s spends time moving between activities" % label)
	if actor.species != "duck":
		_check(metric.states.has("graze"), "%s spends time grazing" % label)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
