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
	var horse = world._actors.horse
	horse.remove_meta("shelter_rest")
	horse.state = "rest"
	horse.posed = false
	horse._idle_time = 100.0
	horse._velocity = Vector2.ZERO
	horse._gait.weight = 0.0
	horse.set_expression("idle")
	var horse_texture = horse._sprite.texture
	var horse_anchor = horse._ground_anchor
	check(horse._blink.source_path == Blink.HORSE_SOURCE and horse._posture_id == "idle", "horse binds its own resting cel")
	horse._blink.wait_left = 0.0
	for i in 8:
		horse.tick(1.0 / 60.0, Vector2(1280, 720))
	check(horse._blink.amount > 0.99, "actual resting horse closes eyes: %s %s %s %s %s" % [horse._blink.amount, horse._posture_id, horse._sprite.texture.resource_path, horse._gait.weight, horse.position])
	check(horse._sprite.texture == horse_texture and horse._ground_anchor == horse_anchor, "horse blink preserves original body and feet")
	horse.show_painted_ack("idle", 1.0)
	check(horse._blink.amount == 0.0, "horse response clears eyes immediately")
	horse._ack_cel = ""
	horse._ack_left = 0.0
	horse.set_meta("shelter_rest", true)
	horse._blink.wait_left = 0.0
	for i in 8:
		horse.tick(1.0 / 60.0, Vector2(1280, 720))
	check(horse._blink.amount == 0.0 and horse._posture_id == "shelter_rest", "lying horse cannot inherit standing eyes")
	horse.remove_meta("shelter_rest")
	horse.set_expression("idle")
	horse._blink.wait_left = 0.0
	horse.advance_path(0.1, Vector2(3, 0), 1.0, false)
	check(horse._blink.amount == 0.0, "moving horse clears eyes")
	check(horse._blink.rng != cow._blink.rng, "animals do not share a blink clock or RNG")
	world.free()
	print("PAINTED_BLINK checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
