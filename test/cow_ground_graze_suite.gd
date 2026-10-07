extends SceneTree
var Art: GDScript
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func run() -> void:
	Art = load("res://scripts/game/cow_ground_art.gd")
	var tuning := root.get_node("TuningStore")
	var world = load("res://scripts/game/yard_world.gd").new()
	root.add_child(world)
	world.setup()
	for id: String in world._actors:
		world.actor_named(id).posed = true
		world.actor_named(id).position = Vector2(1100, 450)
	world.get_player().position = Vector2(140, 650)
	var cow = world.actor_named("cow")
	cow.posed = false
	var food := Vector2(470, 505)
	for reduced: bool in [false, true]:
		tuning.set_value("ui.reduced_motion", reduced, false)
		for visual: float in [0.75, 1.25]:
			cow.set_meta("visual_scale", visual)
			for side: float in [-1.0, 1.0]:
				cow.position = food - Vector2(side * 100.0, 0.0)
				cow.state = "rest"
				cow._idle_time = 100.0
				cow._ack_left = 0.0
				cow._ack_cel = ""
				cow._velocity = Vector2.ZERO
				cow._gait.weight = 0.0
				cow.tick(0.05, Vector2(1280,720))
				var feet: Vector2 = world.ground_food._approach(cow, {"kind":"grass", "x":food.x, "y":food.y})
				check(feet.is_finite(), "reachable feeding stance")
				if not feet.is_finite(): continue
				cow.position = feet
				cow.seek_food(feet)
				cow.show_ground_bite("graze", food)
				cow.tick(0.05, Vector2(1280,720))
				var mouth: Vector2 = cow._sprite.to_global(Vector2(223,965)-Vector2(750,990))
				check(mouth.distance_to(world.to_global(food)) < 2.0, "mouth aligned for each facing, scale and motion setting")
				check(cow.facing == side and cow._posture_id == "graze", "facing and complete cel retained after actor tick")
				check(cow.position.is_equal_approx(feet), "stationary bite does not move feet")
				var snapshot := PhotoMoment.capture(world, {"id":"cow_ground_test", "subjects":["cow"]})
				var restored := PhotoMoment.sanitize(JSON.parse_string(JSON.stringify(snapshot)))
				var found := false
				for item: Dictionary in restored.get("items", []):
					if item.get("kind", "") == "sprite" and item.get("subject", "") == "cow":
						found = item.texture.path == Art.TEXTURE and item.offset == [627.0-750.0,627.0-990.0]
				check(found, "photo JSON round trip preserves grazing texture and foot anchor")
				cow.leave_food()
				for frame in 15: cow.tick(0.05, Vector2(1280,720))
				check(cow._posture_id != "graze", "bite ends after food interaction")
	world.free()
	root.get_node("AudioDirector").release_streams()
	print("COW_GROUND_GRAZE checks=%d failures=%d" % [checks, failures.size()])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
