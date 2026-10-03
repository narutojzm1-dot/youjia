extends SceneTree
# REQ-20261003-022: reduced motion holds pet/plant/bird object feedback still and readable.

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var overlay = load("res://scripts/game/world_effects_overlay.gd")
	var still_pet_a: Dictionary = overlay.object_feedback_pose("pet", 0.1, 1.4, true)
	var still_pet_b: Dictionary = overlay.object_feedback_pose("pet", 0.9, 0.12, true)
	var live_pet_a: Dictionary = overlay.object_feedback_pose("pet", 0.1, 1.4, false)
	var live_pet_b: Dictionary = overlay.object_feedback_pose("pet", 0.9, 0.12, false)
	_check(is_equal_approx(float(still_pet_a.opacity), 1.0), "reduced motion holds the pet heart at full readable opacity")
	_check(is_equal_approx(float(still_pet_a.opacity), float(still_pet_b.opacity)), "reduced motion keeps the pet heart from fading mid-cue")
	_check(is_equal_approx(float(still_pet_a.rise), 0.0) and is_equal_approx(float(still_pet_b.rise), 0.0), "reduced motion keeps the pet heart from floating upward")
	_check(float(live_pet_b.rise) > float(live_pet_a.rise), "ordinary pet heart still rises")
	_check(float(live_pet_a.opacity) > float(live_pet_b.opacity), "ordinary pet heart still fades near the end")

	var still_plant_a: Dictionary = overlay.object_feedback_pose("plant", 0.15, 1.3, true)
	var still_plant_b: Dictionary = overlay.object_feedback_pose("plant", 0.85, 0.15, true)
	var live_plant_a: Dictionary = overlay.object_feedback_pose("plant", 0.15, 1.3, false)
	var live_plant_b: Dictionary = overlay.object_feedback_pose("plant", 0.85, 0.15, false)
	_check(is_equal_approx(float(still_plant_a.opacity), float(still_plant_b.opacity)) and is_equal_approx(float(still_plant_a.opacity), 1.0), "reduced motion holds the water splash still and readable")
	_check(is_equal_approx(float(still_plant_a.rise), 0.0), "reduced motion keeps the water splash from floating")
	_check(float(live_plant_b.rise) > float(live_plant_a.rise), "ordinary water splash still rises a little")
	_check(float(live_plant_a.opacity) > float(live_plant_b.opacity), "ordinary water splash still fades")

	var still_bird_a: Dictionary = overlay.object_feedback_pose("bird", 0.1, 1.6, true)
	var still_bird_b: Dictionary = overlay.object_feedback_pose("bird", 0.85, 0.2, true)
	var live_bird_a: Dictionary = overlay.object_feedback_pose("bird", 0.1, 1.6, false)
	var live_bird_b: Dictionary = overlay.object_feedback_pose("bird", 0.85, 0.2, false)
	_check(is_equal_approx(float(still_bird_a.ring_radius), 18.0) and is_equal_approx(float(still_bird_a.ring_radius), float(still_bird_b.ring_radius)), "reduced motion holds the bird feed ring radius fixed")
	_check(is_equal_approx(float(still_bird_a.ring_alpha), float(still_bird_b.ring_alpha)) and is_equal_approx(float(still_bird_a.heart_alpha), float(still_bird_b.heart_alpha)), "reduced motion keeps bird feed brightness from fading mid-cue")
	_check(is_equal_approx(float(still_bird_a.rise), 0.0), "reduced motion keeps bird feed hearts from rising")
	_check(float(live_bird_b.ring_radius) > float(live_bird_a.ring_radius), "ordinary bird feed ring still expands")
	_check(float(live_bird_a.heart_alpha) > float(live_bird_b.heart_alpha), "ordinary bird feed hearts still fade")

	if failures.is_empty():
		print("STILL OBJECT FEEDBACK PASS ", checks)
		quit(0)
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
