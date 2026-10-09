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
	check(world._actors.goose._blink != null, "resting goose has its own blink player")
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
	for id: String in ["sheep_a", "sheep_b"]:
		_check_sheep(world, id)
	check(world._actors.sheep_a._blink.rng != world._actors.sheep_b._blink.rng, "two sheep have independent blink clocks")
	_check_llama(world)
	_check_goose(world)
	world.free()
	print("PAINTED_BLINK checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _check_goose(world) -> void:
	var goose = world.actor_named("goose")
	goose.posed = false
	goose._idle_time = 100.0
	goose._ack_cel = ""
	goose._ack_left = 0.0
	goose._velocity = Vector2.ZERO
	goose._gait.weight = 0.0
	goose.state = "rest"
	goose.set_expression("idle")
	var original = goose._sprite.texture
	var anchor = goose._ground_anchor
	check(original.resource_path == Blink.GOOSE_SOURCE and goose._posture_id == "rest", "goose blink binds lying rest art")
	goose._blink.wait_left = 0.0
	for i in 8: goose.tick(1.0 / 60.0, Vector2(1280,720))
	check(goose._blink.amount > 0.99, "actual resting goose closes its eye")
	check(goose._sprite.texture == original and goose._ground_anchor == anchor, "goose blink preserves feathers and folded feet")
	for cel: String in ["calm", "riding_up", "riding_down"]:
		goose.show_goose_encounter_cel(cel)
		check(goose._blink.amount == 0.0 and goose._posture_id == cel, "encounter cel synchronously clears resting eye: " + cel)
		goose.state = "rest"
		goose.set_expression("idle")
		goose._blink.wait_left = 0.0
		for i in 8: goose.tick(1.0 / 60.0, Vector2(1280,720))
	goose.acknowledge_feed(goose.position + Vector2(30,0))
	check(goose._blink.amount == 0.0, "food attention immediately clears resting eye")
	goose._ack_cel = ""
	goose._ack_left = 0.0
	for state: String in ["graze", "alert", "rest"]:
		goose.state = state
		goose._velocity = Vector2.ZERO
		goose._gait.weight = 0.0
		goose.set_expression("idle")
		goose._blink.wait_left = 0.0
		for i in 8: goose.tick(1.0 / 60.0, Vector2(1280,720))
		check((goose._blink.amount > 0.99) == (state == "rest"), "goose resting eye respects state " + state)
	goose.advance_path(0.1, Vector2(3,0), 1.0, false)
	check(goose._blink.amount == 0.0, "walking goose clears resting eye")
	goose.set_encounter_pose(goose.position, goose._base_scale, 1.0)
	goose._blink.wait_left = 0.0
	for i in 8: goose.tick(1.0 / 60.0, Vector2(1280,720))
	check(goose._blink.amount == 0.0, "posed goose cannot inherit resting eye")
	goose.release_encounter_pose()
	goose.state = "rest"
	goose._idle_time = 100.0
	goose._velocity = Vector2.ZERO
	goose._gait.weight = 0.0
	goose.set_expression("idle")
	goose._blink.wait_left = 0.0
	for i in 8: goose.tick(1.0 / 60.0, Vector2(1280,720))
	root.get_node("TuningStore").set_value("ui.reduced_motion", true, false)
	goose.tick(0.01, Vector2(1280,720))
	check(goose._blink.amount == 0.0, "reduced motion clears goose eye")
	root.get_node("TuningStore").set_value("ui.reduced_motion", false, false)
	check(goose._blink.rng != world._actors.llama._blink.rng, "goose owns its cosmetic clock and RNG")

func _check_llama(world) -> void:
	var llama = world.actor_named("llama")
	llama.remove_meta("shelter_rest")
	llama.posed = false
	llama._idle_time = 100.0
	llama._velocity = Vector2.ZERO
	llama._gait.weight = 0.0
	llama._ack_cel = ""
	llama.state = "rest"
	llama.set_expression("idle")
	var original = llama._sprite.texture
	var anchor = llama._ground_anchor
	check(original.resource_path == Blink.LLAMA_SOURCE, "llama keeps canonical smirk and feet")
	llama._blink.wait_left = 0.0
	for i in 8: llama.tick(1.0 / 60.0, Vector2(1280,720))
	check(llama._blink.amount > 0.99, "actual resting llama closes eyes")
	check(llama._sprite.texture == original and llama._ground_anchor == anchor, "llama blink preserves body and foot anchor")
	for state: String in ["lead", "graze", "alert", "rest"]:
		llama.state = state
		llama._velocity = Vector2.ZERO
		llama._gait.weight = 0.0
		llama._blink.wait_left = 0.0
		for i in 8: llama.tick(1.0 / 60.0, Vector2(1280,720))
		check((llama._blink.amount > 0.99) == (state == "rest"), "llama eyes respect state " + state)
	llama.set_meta("shelter_rest", true)
	llama.tick(0.01, Vector2(1280,720))
	check(llama._blink.amount == 0.0 and llama._posture_id == "shelter_rest", "lying llama cannot inherit standing eyes")
	llama.remove_meta("shelter_rest")
	llama._blink.wait_left = 0.0
	for i in 8: llama.tick(1.0 / 60.0, Vector2(1280,720))
	llama.advance_path(0.1, Vector2(3,0), 1.0, false)
	check(llama._blink.amount == 0.0, "walking llama clears eyes immediately")
	llama._velocity = Vector2.ZERO
	llama._gait.weight = 0.0
	llama._blink.wait_left = 0.0
	for i in 8: llama.tick(1.0 / 60.0, Vector2(1280,720))
	root.get_node("TuningStore").set_value("ui.reduced_motion", true, false)
	llama.tick(0.01, Vector2(1280,720))
	check(llama._blink.amount == 0.0, "reduced motion clears llama eyes")
	root.get_node("TuningStore").set_value("ui.reduced_motion", false, false)
	check(llama._blink.rng != world._actors.horse._blink.rng, "llama owns its cosmetic RNG")

func _check_sheep(world, id: String) -> void:
	var sheep = world.actor_named(id)
	sheep.remove_meta("shelter_rest")
	sheep.posed = false
	sheep._idle_time = 100.0
	sheep._velocity = Vector2.ZERO
	sheep._gait.weight = 0.0
	sheep._ack_cel = ""
	sheep._ack_left = 0.0
	sheep.state = "rest"
	sheep.set_expression("idle")
	var original = sheep._sprite.texture
	var anchor = sheep._ground_anchor
	var bounds = sheep._art_bounds
	var expected := Blink.SHEEP_A_SOURCE if id == "sheep_a" else Blink.SHEEP_B_SOURCE
	check(original.resource_path == expected and sheep._posture_id == "idle", id + " keeps its own standing body at rest")
	check(not sheep._textures.has("shake"), id + " cannot switch to the shared mismatched body")
	sheep._blink.wait_left = 0.0
	for i in 8: sheep.tick(1.0 / 60.0, Vector2(1280, 720))
	check(sheep._blink.amount > 0.99, id + " actual resting actor closes eyes")
	check(sheep._sprite.texture == original and sheep._ground_anchor == anchor, id + " blink preserves body and feet")
	sheep.show_ground_bite("graze", sheep.position + Vector2(30, 0))
	check(sheep._blink.amount == 0.0 and sheep._posture_id == "graze", id + " eating clears standing eyes immediately")
	sheep._ack_cel = ""
	sheep._ack_left = 0.0
	sheep.set_expression("idle")
	sheep._blink.wait_left = 0.0
	for i in 8: sheep.tick(1.0 / 60.0, Vector2(1280, 720))
	sheep.show_painted_ack("attend", 1.0)
	check(sheep._blink.amount == 0.0 and sheep._posture_id == "attend", id + " pet response clears eye patch")
	sheep._ack_cel = ""
	sheep._ack_left = 0.0
	sheep.set_meta("shelter_rest", true)
	sheep._blink.wait_left = 0.0
	for i in 8: sheep.tick(1.0 / 60.0, Vector2(1280, 720))
	check(sheep._blink.amount == 0.0 and sheep._posture_id == "shelter_rest", id + " lying body excludes standing eyes")
	sheep.remove_meta("shelter_rest")
	for reduced: bool in [false, true]:
		root.get_node("TuningStore").set_value("ui.reduced_motion", reduced, false)
		for face: float in [-1.0, 1.0]:
			for posture: String in ["graze", "rest", "graze", "rest"]:
				sheep.state = posture
				sheep.facing = face
				sheep._gait.face = face
				sheep.tick(0.0, Vector2(1280,720))
				check(sheep._sprite.texture == original and sheep._ground_anchor == anchor and sheep._art_bounds == bounds, id + " rest/graze transition preserves identity, size and anchor")
	var snapshot: Dictionary = PhotoMoment.capture(world, {"id":"legacy_sheep_blink", "subjects":[id]})
	for item: Dictionary in snapshot.get("items", []):
		if item.get("subject", "") == id:
			item.texture = {"path":"res://assets/holiday/characters/cast_v2/sheep_shake.png"}
	var legacy_kept := false
	for item: Dictionary in PhotoMoment.sanitize(snapshot).get("items", []):
		if item.get("subject", "") == id:
			legacy_kept = item.get("texture", {}).get("path", "").ends_with("/sheep_shake.png")
	check(legacy_kept, id + " historical shake photograph remains readable")
	sheep.state = "rest"
	sheep._blink.wait_left = 0.0
	for i in 12: sheep.tick(1.0 / 60.0, Vector2(1280,720))
	check(sheep._blink.amount == 0.0, id + " reduced motion is static")
	root.get_node("TuningStore").set_value("ui.reduced_motion", false, false)
	sheep.advance_path(0.1, Vector2(3, 0), 1.0, false)
	check(sheep._blink.amount == 0.0, id + " movement has no resting eye patch")
