extends SceneTree
var checks := 0
var failures: Array[String] = []
const L := preload("res://scripts/exploration/near_path_layout.gd")

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		push_error(label)

func run() -> void:
	var road := L.geometry()
	check(road.free_walk(), "near path has road surface movement")
	check(not VillagePathLayout.geometry().free_walk(), "village retains its existing navigation contract")
	var origin := road.point("lane", 300.0)
	for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(1, 1).normalized()]:
		var next := road.step_input(road.nearest(origin), direction, 10.0)
		check(road.position(next).distance_to(origin + direction * 10.0) < 0.1, "road interior follows actual input vector %s" % direction)
	var north_end := road.point("north", road.arm_length("north"))
	check(north_end.y < 590.0 and road.depth(north_end.y) < road.depth(origin.y) * 0.65, "north route reaches distant road with smaller perspective")
	var from := road.START.duplicate()
	var to := road.nearest(north_end)
	var steps := 0
	while road.position(from).distance_to(north_end) > 0.5 and steps < 500:
		var before := road.position(from)
		from = road.step_toward(from, to, 4.0)
		check(road.position(from).distance_to(before) <= 4.01, "tap route never teleports at the fork")
		check(road._corridor.contains(road.position(from)), "tap route stays on painted road")
		steps += 1
	check(steps < 500 and road.position(from).distance_to(north_end) < 0.5, "tap walking reaches north endpoint")
	for stop: Dictionary in road.STOPS:
		var visitor := to.duplicate()
		var walk_frames := 0
		while road.position(visitor).distance_to(road.position(stop)) > 0.5 and walk_frames < 800:
			visitor = road.step_toward(visitor, stop, 1.4)
			walk_frames += 1
		check(walk_frames < 800, "north returns to %s; final=%s goal=%s" % [stop.id, road.position(visitor), road.position(stop)])
	var return_point := road.nearest(road.point(road.HOME_ARM, road.arm_length(road.HOME_ARM)))
	steps = 0
	while not road.at_home(from) and steps < 500:
		from = road.step_toward(from, return_point, 5.0)
		steps += 1
	check(road.at_home(from), "north route can return to the original home gate")
	for forbidden: Vector2 in [Vector2(250, 650), Vector2(480, 700), Vector2(30, 900), Vector2(1590, 860)]:
		check(not road._corridor.contains(forbidden), "water rocks and paper are not walkable %s" % forbidden)
		check(road._corridor.contains(road.position(road.nearest(forbidden))), "off-road tap chooses a reachable road edge")
	for arm: String in road.ARMS:
		for i in 15:
			var at := road.nearest(road.point(arm, road.arm_length(arm) * i / 14.0))
			for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
				var edge := road.step_input(at, direction, 120.0)
				check(road._corridor.contains(road.position(edge)), "long keyboard movement remains inside road")
	print("ROAD_FREEDOM checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
