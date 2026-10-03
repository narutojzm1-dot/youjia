extends SceneTree

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var tuning := root.get_node("TuningStore")
	tuning.reset_defaults()
	var world = load("res://scripts/game/yard_world.gd").new()
	root.add_child(world)
	world.setup()
	for actor_id: String in world._actors:
		world.debug_place_actor(actor_id, Vector2(330, 445))
	var fence := YardSceneHotspots.get_hotspot("fence_gate")
	var approach: Vector2 = fence.approach_points[0]
	world.debug_place_player(approach + Vector2(4, 2))
	world._has_walk_goal = false
	world._pending_interaction = ""
	world._selected_target = ""
	var notices: Array[String] = []
	world.notice_requested.connect(func(key: String): notices.append(key))
	var album = world.collected.duplicate()
	for i: int in 60:
		world.tick(1.0 / 60.0, Vector2.ZERO)
	_check(world._scene_feedback.fence_snapshot().is_empty(), "standing near the gate does not paint grass in the first second")
	for i: int in 120:
		world.tick(1.0 / 60.0, Vector2.ZERO)
	var painted: Dictionary = world._scene_feedback.fence_snapshot()
	_check(not painted.is_empty() and painted.get("anchor", Vector2.INF) == fence.visual_anchor, "after a short still pause the existing gate grass painting plays")
	_check(notices.is_empty() and world.collected == album, "the breeze adds no notice and does not write the album")
	world.tick(0.05, Vector2(1, 0))
	_check(world._scene_feedback.fence_snapshot().is_empty(), "walking cancels the grass painting immediately")
	world.free()
	if failures.is_empty():
		print("QUIET STAY PASS ", checks)
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
