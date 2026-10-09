extends SceneTree
const Blink := preload("res://scripts/entities/painted_blink.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _run() -> void:
	var b := Blink.new()
	b.rng.seed = 565
	b.wait_left = 0.01
	b.advance(0.02, true)
	b.advance(0.10, true)
	check(is_equal_approx(b.amount, 1.0), "closed eyelids reached")
	b.advance(0.04, true)
	check(is_equal_approx(b.amount, 1.0), "brief closed hold")
	b.advance(0.08, true)
	check(b.amount > 0.0 and b.amount < 1.0, "soft reopening")
	b.advance(0.10, true)
	check(b.amount == 0.0 and b.wait_left >= 4.5 and b.wait_left <= 11.0, "open and rescheduled")
	var previous := b.wait_left
	b.advance(0.0, true)
	check(b.wait_left == previous, "paused clock frozen")
	b.wait_left = 0.0
	b.advance(0.02, true)
	b.advance(0.11, true)
	b.advance(0.01, false)
	check(b.amount == 0.0 and b.elapsed < 0.0, "interrupt immediately clears")
	b.wait_left = 0.0
	b.advance(9.0, true)
	check(b.amount == 0.0 and b.elapsed < 0.0, "background gap cannot replay a blink")
	var world = load("res://scripts/game/yard_world.gd").new()
	root.add_child(world)
	world.setup()
	var cow = world._actors.cow
	cow.remove_meta("shelter_rest")
	cow.state = "rest"
	cow.posed = false
	cow._idle_time = 100.0
	cow._velocity = Vector2.ZERO
	cow._gait.weight = 0.0
	cow.set_expression("idle")
	var texture = cow._sprite.texture
	var anchor = cow._ground_anchor
	var position_before = cow.position
	cow._blink.wait_left = 0.0
	for i in 8:
		cow.tick(1.0 / 60.0, Vector2(1280, 720))
	check(cow._blink.amount > 0.99, "actual resting cow closes eyes")
	check(cow._sprite.texture == texture and cow._ground_anchor == anchor and cow.position == position_before, "blink keeps canonical body and feet")
	cow.show_painted_ack("glance", 1.0)
	check(cow._blink.amount == 0.0, "interaction removes overlay synchronously")
	cow._blink.wait_left = 0.0
	cow.tick(0.10, Vector2(1280, 720))
	check(cow._blink.amount == 0.0, "interaction cannot blink wrong face")
	cow.advance_path(0.10, Vector2(2, 0), 1.0, false)
	check(cow._blink.amount == 0.0, "path adapter clears overlay")
	cow._ack_cel = ""
	cow._ack_left = 0.0
	cow._velocity = Vector2.ZERO
	cow._gait.weight = 0.0
	cow.state = "rest"
	cow.set_expression("idle")
	root.get_node("TuningStore").set_value("ui.reduced_motion", true, false)
	cow._blink.wait_left = 0.0
	for i in 30:
		cow.tick(1.0 / 60.0, Vector2(1280, 720))
	check(cow._blink.amount == 0.0, "reduced motion stays static")
	root.get_node("TuningStore").set_value("ui.reduced_motion", false, false)
	cow.set_meta("shelter_rest", true)
	cow.tick(0.1, Vector2(1280, 720))
	check(cow._blink.amount == 0.0 and cow._posture_id == "shelter_rest", "shelter cel cannot inherit standing eyes")
	check(world._actors.sheep_a._blink == null, "unsupported art has no blink player")
	world.free()
	print("PAINTED_BLINK checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
