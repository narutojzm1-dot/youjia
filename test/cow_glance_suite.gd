extends SceneTree
# Successful pet on the cow shows the glance painting. A miss does not.

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
	var cow = world._actors["cow"]
	world.debug_place_player(cow.position + Vector2(200, 0))
	world._interact_with_target("pet:cow")
	_check(cow._posture_id != "glance" and world._just_petted_species == "", "a far pet does not raise the cow's eyes")
	var sheep = world._actors["sheep_a"]
	world.debug_place_player(sheep.position + Vector2(30, 0))
	world._interact_with_target("pet:sheep_a")
	_check(not str(sheep._sprite.texture.resource_path).ends_with("cow_glance.png"), "petting a sheep does not use the cow painting")
	_check(cow._posture_id != "glance", "the cow stays unmoved when someone else is petted")
	world.debug_place_player(cow.position + Vector2(40, 0))
	cow.state = "rest"
	cow._velocity = Vector2.ZERO
	cow._gait.weight = 0.0
	cow.posed = false
	world._interact_with_target("pet:cow")
	_check(cow._posture_id == "glance" and str(cow._sprite.texture.resource_path).ends_with("cow_glance.png"), "a close pet shows the glance painting")
	_check(world._just_petted_species == "cow", "only the successful pet is recorded")
	for _i: int in 90:
		cow.tick(1.0 / 60.0, Vector2(1280, 720))
	_check(cow._posture_id == "glance", "the glance stays while the cow is still")
	cow._velocity = Vector2(24, 0)
	cow._gait.weight = 0.2
	cow.tick(1.0 / 60.0, Vector2(1280, 720))
	_check(cow._posture_id != "glance", "walking drops the glance")
	cow.state = "rest"
	cow._velocity = Vector2.ZERO
	cow._gait.weight = 0.0
	cow.posed = false
	cow._idle_time = 30.0
	cow.show_painted_ack("glance", 0.4)
	for _i: int in 30:
		cow.tick(1.0 / 60.0, Vector2(1280, 720))
	_check(cow._posture_id == "chew", "after the glance the cow returns to the rest painting")
	world.free()
	if failures.is_empty():
		print("COW GLANCE PASS ", checks)
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
