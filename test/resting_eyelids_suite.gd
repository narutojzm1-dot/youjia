extends SceneTree
const Blink := preload("res://scripts/entities/painted_blink.gd")
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
	for id in ["sheep_a", "sheep_b"]:
		var a = world.actor_named(id)
		a.set_meta("shelter_rest", true)
		a.state = "rest"
		a._idle_time = 100.0
		a._velocity = Vector2.ZERO
		a._gait.weight = 0.0
		a.set_expression("idle")
		a.tick(0.01,Vector2(1280,720))
		var texture: Texture2D = a._sprite.texture
		var anchor: Vector2 = a._ground_anchor
		var position_before: Vector2 = a.position
		a._blink.wait_left = 0.0
		for i in 8: a.tick(1.0/60.0, Vector2(1280,720))
		check(a._blink.source_path == texture.resource_path and a._blink.amount > 0.99, id+" own lying eyelids close")
		check(a.position == position_before and a._ground_anchor == anchor and a._sprite.texture == texture, id+" face action keeps body and feet")
		var data := PhotoMoment._sanitize_gait(JSON.parse_string(JSON.stringify({"blink_amount":a._blink.amount})))
		var frozen := PhotoMoment._load_gait(data, texture.resource_path)
		check(is_equal_approx(frozen.get_shader_parameter("blink_amount"), a._blink.amount), id+" photograph retains eyelid closure")
		check(frozen.get_shader_parameter("blink_eye_a") == a._gait._material.get_shader_parameter("blink_eye_a"), id+" photograph binds correct lying eyes")
		a.advance_path(0.1,Vector2(3,0),1.0,false)
		check(a._blink.amount == 0.0, id+" path clears eyes")
		a._velocity = Vector2.ZERO
		a._gait.weight = 0.0
		a.state = "rest"
		a.remove_meta("shelter_rest")
		a.set_expression("idle")
		a.tick(0.01,Vector2(1280,720))
		check(a._blink.source_path == (Blink.SHEEP_A_SOURCE if id == "sheep_a" else Blink.SHEEP_B_SOURCE), id+" standing profile restored")
	for path: String in Blink.SOURCE_PROFILES:
		var photo := PhotoMoment._load_gait(PhotoMoment._sanitize_gait({"blink_amount":0.8}),path)
		var b := Blink.new()
		var target := ShaderMaterial.new()
		target.shader = preload("res://shaders/felt_walk.gdshader")
		b.bind(target,Blink.profile_for_source(path))
		check(photo.get_shader_parameter("blink_texture") == b.material.get_shader_parameter("blink_texture"), path+" frozen original eye texture")
		check(photo.get_shader_parameter("blink_amount") == 0.8, path+" frozen amount")
	check(PhotoMoment._sanitize_gait({}).blink_amount == 0.0, "legacy default open")
	for bad in [-0.1,1.1,NAN,INF,"wrong"]: check(PhotoMoment._sanitize_gait({"blink_amount":bad}).is_empty(), "bad eyelid amount rejected")
	var unknown := PhotoMoment._load_gait(PhotoMoment._sanitize_gait({"blink_amount":1.0}), "res://assets/holiday/characters/shelter/horse-rest.png")
	check(unknown.get_shader_parameter("blink_amount") == 0.0, "already sleeping artwork cannot inherit standing eye patch")
	world.queue_free()
	await process_frame
	print("RESTING_EYELIDS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
