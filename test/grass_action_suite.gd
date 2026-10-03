extends SceneTree

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var tuning := root.get_node("TuningStore")
	tuning.reset_defaults()
	for fps: int in [30, 60, 120]:
		var player = load("res://scripts/entities/vacationer.gd").new()
		root.add_child(player)
		player.setup(Vector2(600, 550))
		player.tick(0, Vector2.ZERO, Vector2(1280, 720))
		var start: Vector2 = player.position
		player.pick_grass(0.42)
		_check(player.carrying_grass and player._sequence_walker.action_kind == &"pickup", "inventory and pickup begin immediately")
		for i: int in int(0.3 * fps):
			player.tick(1.0/fps, Vector2.ZERO, Vector2(1280, 720))
		_check(player.position == start and player._sequence_walker.frame >= 3, "pickup advances without moving feet/root")
		var walker: SequenceResident = player._sequence_walker
		var hand := walker.to_global(walker.offset + walker.action_hand())
		_check(player.grass_hand_global_position().distance_to(hand) < 0.001, "pickup uses its baked hand anchor")
		_check(player.consume_grass(player.global_position - Vector2(60, 0)) and not player.carrying_grass and not player._grass.visible, "feeding remains synchronous during pickup")
		_check(player.facing == -1 and walker.scale.x < 0, "feed faces the actual recipient even after walking away")
		_check(walker.action_kind == &"feed" and walker.frame == 0, "successful feed replaces pickup")
		player.tick(0.2, Vector2.ZERO, Vector2(1280, 720))
		var before := walker.frame
		_check(not player.consume_grass(player.global_position + Vector2(60, 0)) and walker.frame == before and player.facing == -1, "empty hands cannot restart feed or turn toward an unearned recipient")
		for i: int in fps:
			player.tick(1.0/fps, Vector2.ZERO, Vector2(1280, 720))
		_check(walker.action_kind.is_empty() and walker.animation == &"idle", "feed returns to accepted idle")
		player.pick_grass()
		player.tick(0.01, Vector2.RIGHT, Vector2(1280, 720))
		_check(walker.action_kind.is_empty(), "movement intent interrupts immediately")
		player.reset_locomotion()
		player.position.x = 1240.0
		player.pick_grass()
		player.tick(0.01, Vector2.RIGHT, Vector2(1280, 720))
		_check(walker.action_kind.is_empty() and player.position.x == 1240.0, "blocked movement intent also interrupts")
		player.reset_locomotion()
		player.pick_grass()
		player.reset_locomotion()
		_check(walker.action_kind.is_empty() and player.carrying_grass, "scene/reset cancels presentation without losing inventory")
		player.consume_grass()
		tuning.set_value("ui.reduced_motion", true, false)
		player.tick(0.01, Vector2.ZERO, Vector2(1280, 720))
		_check(walker.action_kind.is_empty(), "enabling reduced motion settles running action")
		player.pick_grass()
		_check(walker.animation == &"idle" and player.carrying_grass, "reduced pickup keeps immediate inventory without body animation")
		player.consume_grass()
		_check(walker.animation == &"idle" and not player.carrying_grass, "reduced feed clears inventory without body animation")
		tuning.set_value("ui.reduced_motion", false, false)
		player.free()
	var art := SequenceResident.ACTION_ATLAS.get_image()
	_check(art.get_size() == Vector2i(3456, 896), "atlas contains eighteen full 384x448 frames")
	for row: int in 2:
		for index: int in 9:
			var cell := art.get_region(Rect2i(index*384, row*448, 384, 448))
			_check(cell.get_used_rect().position.x > 0 and cell.get_used_rect().end.x < 384, "pose fits canvas with no clipping")
	tuning.reset_defaults()
	root.get_node("AudioDirector").call("release_streams")
	for failure: String in failures:
		push_error(failure)
	print("[grass-action-tests] %s: %d checks, %d failures" % ["PASS" if failures.is_empty() else "FAIL", checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
