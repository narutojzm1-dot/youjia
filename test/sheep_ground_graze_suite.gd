extends SceneTree
var Art: GDScript
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func run() -> void:
	Art = load("res://scripts/game/sheep_ground_art.gd")
	var tuning := root.get_node("TuningStore")
	var world = load("res://scripts/game/yard_world.gd").new()
	root.add_child(world)
	world.setup()
	for id: String in world._actors:
		world.actor_named(id).posed = true
		world.actor_named(id).position = Vector2(1100, 450)
	world.get_player().position = Vector2(140, 650)
	for sheep_id: String in ["sheep_a", "sheep_b"]:
		var sheep = world.actor_named(sheep_id)
		sheep.posed = false
		var food := Vector2(470, 505)
		var cell: Dictionary = Art.CELLS[sheep_id]
		var anchor := Vector2(cell.metadata.ground_anchor[0],cell.metadata.ground_anchor[1])
		var mouth_anchor := Vector2(cell.metadata.mouth_anchor[0],cell.metadata.mouth_anchor[1])
		for reduced: bool in [false, true]:
			tuning.set_value("ui.reduced_motion", reduced, false)
			for visual: float in [0.75, 1.25]:
				sheep.set_meta("visual_scale", visual)
				for side: float in [-1.0, 1.0]:
					sheep.position = food - Vector2(side * 100.0, 0.0)
					sheep.state = "rest"
					sheep._idle_time = 100.0
					sheep._ack_left = 0.0
					sheep._ack_cel = ""
					sheep._velocity = Vector2.ZERO
					sheep._gait.weight = 0.0
					sheep.tick(0.05, Vector2(1280,720))
					var feet: Vector2 = world.ground_food._approach(sheep, {"kind":"grass", "x":food.x, "y":food.y})
					check(feet.is_finite(), "reachable feeding stance")
					if not feet.is_finite(): continue
					sheep.position = feet
					sheep.seek_food(feet)
					sheep.show_ground_bite("graze", food)
					sheep.tick(0.05, Vector2(1280,720))
					var mouth: Vector2 = sheep._sprite.to_global(mouth_anchor-anchor)
					check(mouth.distance_to(world.to_global(food)) < 2.0, "mouth aligned for each facing, scale and motion setting")
					check(sheep.facing == side and sheep._posture_id == "graze", "facing and complete cel retained after actor tick")
					check(sheep.position.is_equal_approx(feet), "stationary bite does not move feet")
					var snapshot := PhotoMoment.capture(world, {"id":"sheep_ground_test", "subjects":[sheep_id]})
					var restored := PhotoMoment.sanitize(JSON.parse_string(JSON.stringify(snapshot)))
					var found := false
					for item: Dictionary in restored.get("items", []):
						if item.get("kind", "") == "sprite" and item.get("subject", "") == sheep_id:
							found = item.texture.path == cell.texture and item.offset == [627.0-anchor.x,627.0-anchor.y]
					check(found, "photo JSON round trip preserves grazing texture and foot anchor")
					sheep.leave_food()
					for frame in 15: sheep.tick(0.05, Vector2(1280,720))
					check(sheep._posture_id != "graze", "bite ends after food interaction")
		sheep.posed = true
		sheep.position = Vector2(1100,450)
	world.free()
	root.get_node("AudioDirector").release_streams()
	print("SHEEP_GROUND_GRAZE checks=%d failures=%d" % [checks, failures.size()])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
