extends SceneTree
const Breath := preload("res://scripts/entities/painted_rest_breath.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func run() -> void:
	var world = load("res://scripts/game/yard_world.gd").new()
	root.add_child(world)
	world.setup()
	var phases: Array[float] = []
	for id in ["cow", "horse", "llama", "sheep_a", "sheep_b"]:
		var actor = world.actor_named(id)
		actor.set_meta("shelter_rest", true)
		actor.state = "rest"
		actor.posed = false
		actor._idle_time = 100.0
		actor._velocity = Vector2.ZERO
		actor._gait.weight = 0.0
		actor.set_expression("idle")
		var location: Vector2 = actor.position
		var anchor: Vector2 = actor._ground_anchor
		var low := 1.0
		var high := 0.0
		for frame in 600:
			actor.tick(1.0/60.0, Vector2(1280,720))
			var shift := float(actor._gait._material.get_shader_parameter("rest_breath_shift"))
			low = minf(low, shift)
			high = maxf(high, shift)
			check(shift >= 0.0 and shift <= Breath.MAX_SHIFT, id+" bounded deformation")
			check(is_equal_approx(absf(actor.scale.x), actor.scale.y), id+" no whole-body squash")
		check(high-low > 0.005, id+" completes breathing cycles")
		check(actor.position == location and actor._ground_anchor == anchor, id+" planted feet and anchor")
		phases.append(actor._rest_breath.phase)
		var before: float = actor._rest_breath.phase
		var shift_before: float = actor._gait._material.get_shader_parameter("rest_breath_shift")
		actor._rest_breath.advance(0.0, true, actor._sprite.texture.resource_path)
		check(actor._rest_breath.phase == before and actor._gait._material.get_shader_parameter("rest_breath_shift") == shift_before, id+" paused clock")
		var data := PhotoMoment._sanitize_gait({"rest_breath_shift":shift_before})
		var photo := PhotoMoment._load_gait(data, actor._sprite.texture.resource_path)
		check(photo.get_shader_parameter("rest_breath_shift") == shift_before and photo.get_shader_parameter("rest_breath_region") == Breath.REGIONS[actor._sprite.texture.resource_path], id+" photo freezes exact deformation")
		actor.advance_path(0.1, Vector2(2,0), 1.0, false)
		check(actor._gait._material.get_shader_parameter("rest_breath_shift") == 0.0, id+" path cancels synchronously")
		actor.state = "rest"
		actor._velocity = Vector2.ZERO
		actor._gait.weight = 0.0
		actor.tick(0.1, Vector2(1280,720))
		root.get_node("TuningStore").set_value("ui.reduced_motion", true, false)
		actor.tick(0.1, Vector2(1280,720))
		check(actor._gait._material.get_shader_parameter("rest_breath_shift") == 0.0, id+" reduced motion clears")
		root.get_node("TuningStore").set_value("ui.reduced_motion", false, false)
		actor.remove_meta("shelter_rest")
		actor.state = "wander"
		actor.set_expression("idle")
		check(actor._gait._material.get_shader_parameter("rest_breath_shift") == 0.0, id+" standing clears old warp")
	for i in phases.size():
		for j in range(i+1, phases.size()): check(not is_equal_approx(phases[i], phases[j]), "independent animal phases")
	check(PhotoMoment._sanitize_gait({}).rest_breath_shift == 0.0, "legacy photograph defaults static")
	for value in [-0.001, 0.007, NAN, INF, "bad"]:
		check(PhotoMoment._sanitize_gait({"rest_breath_shift":value}).is_empty(), "invalid photo deformation rejected")
	var unsupported := PhotoMoment._load_gait(PhotoMoment._sanitize_gait({"rest_breath_shift":0.006}), "res://assets/holiday/characters/cast_v2/horse.png")
	check(unsupported.get_shader_parameter("rest_breath_shift") == 0.0, "foreign artwork cannot inherit chest region")
	world.queue_free()
	await process_frame
	print("PAINTED_REST_BREATH checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
