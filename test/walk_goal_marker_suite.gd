extends SceneTree
# REQ-20261008-074: the tap-to-walk destination ring lies on the ground as a
# flattened, depth-scaled, anti-aliased ellipse and fades in over 0.15s instead
# of popping in as a full upright circle. Reduced motion shows it at once.
# Walk logic (accept, arrive, clear) is unchanged.

const STEP := 1.0 / 60.0
const MARKER_PATH := "res://scripts/game/walk_goal_marker.gd"

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_sources()
	var marker = load(MARKER_PATH)
	_check(marker != null, "walk goal marker script loads")
	if marker != null:
		_check_pose(marker)
		_check_points(marker)
	var tuning := root.get_node("TuningStore")
	for reduced: bool in [false, true]:
		tuning.reset_defaults()
		tuning.set_value("ui.reduced_motion", reduced)
		var world = load("res://scripts/game/yard_world.gd").new()
		root.add_child(world)
		world.setup([])
		if marker != null:
			_check_world(world, marker, reduced)
		world.free()
	tuning.reset_defaults()
	# A script error inside a helper aborts it silently; never call that a pass.
	_check(checks >= 40, "suite ran all its checks (%d)" % checks)
	if failures.is_empty():
		print("WALK GOAL MARKER PASS ", checks)
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _check_sources() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/game/yard_world.gd")
	_check(not source.contains("draw_arc(_walk_goal"), "yard no longer draws the goal as an upright arc")
	_check(source.contains("WalkGoalMarker.pose(_walk_goal_age"), "yard draw reads the marker pose from the tick-owned age")
	_check(source.contains("WalkGoalMarker.points(_walk_goal"), "yard draw uses the flattened ground ellipse")
	_check(source.contains("YardGround.depth_at(_walk_goal.y)"), "marker scales with ground depth at the goal")
	_check(not source.contains("Time.get_ticks"), "marker timing does not read the wall clock")


func _check_pose(marker) -> void:
	var first: Dictionary = marker.pose(0.0, false, 1.0)
	_check(float(first.alpha) < 0.05, "tap frame starts transparent (%.2f)" % float(first.alpha))
	var previous := -1.0
	var rising := true
	for i: int in 10:
		var a := float(marker.pose(float(i) * 0.015, false, 1.0).alpha)
		if a < previous - 0.0001:
			rising = false
		previous = a
	_check(rising, "fade in rises monotonically")
	_check(is_equal_approx(float(marker.pose(0.15, false, 1.0).alpha), 0.85), "full 0.85 alpha after 0.15s")
	_check(is_equal_approx(float(marker.pose(5.0, false, 1.0).alpha), 0.85), "stays at 0.85 while walking")
	_check(float(marker.pose(0.075, false, 1.0).alpha) > 0.3 and float(marker.pose(0.075, false, 1.0).alpha) < 0.6, "half way through the fade is half alpha")
	_check(is_equal_approx(float(marker.pose(0.0, true, 1.0).alpha), 0.85), "reduced motion shows full alpha on the tap frame")
	_check(is_equal_approx(float(marker.pose(-1.0, false, 1.0).alpha), 0.0), "negative age clamps to transparent")
	var mid: Vector2 = marker.pose(1.0, false, 1.0).radius
	_check(is_equal_approx(mid.x, 10.0), "mid-depth width keeps the old radius 10")
	_check(mid.y < mid.x * 0.6 and mid.y > mid.x * 0.3, "ring is flattened onto the ground (%.1f x %.1f)" % [mid.x, mid.y])
	var far: Vector2 = marker.pose(1.0, false, YardGround.depth_at(YardGround.FAR_Y)).radius
	var near: Vector2 = marker.pose(1.0, false, YardGround.depth_at(YardGround.NEAR_Y)).radius
	_check(far.x < mid.x and near.x > mid.x, "far ring is smaller and near ring larger (%.1f / %.1f)" % [far.x, near.x])
	_check(is_equal_approx(far.y / far.x, near.y / near.x), "flatten ratio is the same near and far")
	var reduced_radius: Vector2 = marker.pose(0.0, true, 1.0).radius
	_check(reduced_radius.is_equal_approx(mid), "reduced motion keeps the same fixed size")


func _check_points(marker) -> void:
	var center := Vector2(500, 520)
	var radius := Vector2(10.0, 4.5)
	var pts: PackedVector2Array = marker.points(center, radius)
	_check(pts.size() >= 25, "ellipse has enough segments to read smooth (%d)" % pts.size())
	_check(pts[0].is_equal_approx(pts[pts.size() - 1]), "ellipse polyline is closed")
	var min_p := Vector2(INF, INF)
	var max_p := Vector2(-INF, -INF)
	for p: Vector2 in pts:
		min_p = min_p.min(p)
		max_p = max_p.max(p)
	_check(is_equal_approx(max_p.x - min_p.x, 20.0), "ellipse spans 2x radius wide")
	_check(absf((max_p.y - min_p.y) - 9.0) < 0.05, "ellipse spans 2x flattened radius tall")
	_check(((min_p + max_p) * 0.5).is_equal_approx(center), "ellipse is centred on the goal")


func _check_world(world, marker, reduced: bool) -> void:
	var tag := " (reduced=%s)" % reduced
	world.debug_place_player(Vector2(400, 500))
	_check(not world._has_walk_goal, "no marker before a tap" + tag)
	_check(world.try_walk_to(Vector2(580, 480)), "lawn goal still accepted" + tag)
	_check(world._has_walk_goal, "marker shows after a tap" + tag)
	_check(is_zero_approx(world._walk_goal_age), "new goal starts at age 0" + tag)
	var tap_alpha := float(marker.pose(world._walk_goal_age, reduced, YardGround.depth_at(world._walk_goal.y)).alpha)
	if reduced:
		_check(is_equal_approx(tap_alpha, 0.85), "reduced motion: full ring on the tap frame" + tag)
	else:
		_check(tap_alpha < 0.05, "tap frame ring is transparent" + tag)
	for _i: int in 6:
		world.tick(STEP, Vector2.ZERO)
	_check(absf(world._walk_goal_age - 6.0 * STEP) < 0.001, "tick advances marker age" + tag)
	for _i: int in 6:
		world.tick(STEP, Vector2.ZERO)
	var shown := float(marker.pose(world._walk_goal_age, reduced, YardGround.depth_at(world._walk_goal.y)).alpha)
	_check(is_equal_approx(shown, 0.85), "ring fully shown by 0.2s" + tag)
	# A second tap to a new spot restarts the fade.
	_check(world.try_walk_to(Vector2(450, 500)), "second lawn goal accepted" + tag)
	_check(is_zero_approx(world._walk_goal_age), "new goal restarts the fade" + tag)
	var goal: Vector2 = world._walk_goal
	for _i: int in 60 * 6:
		world.tick(STEP, Vector2.ZERO)
	_check(world.get_player().position.distance_to(goal) < 14.0, "player still arrives at the goal" + tag)
	_check(not world._has_walk_goal, "marker clears on arrival" + tag)
	var age_after := float(world._walk_goal_age)
	world.tick(STEP, Vector2.ZERO)
	_check(is_equal_approx(world._walk_goal_age, age_after), "age does not run without a goal" + tag)
	# Moving with keys clears the goal at once, as before.
	_check(world.try_walk_to(Vector2(560, 480)), "third goal accepted" + tag)
	world.tick(STEP, Vector2(1, 0))
	_check(not world._has_walk_goal, "key movement clears the marker at once" + tag)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
