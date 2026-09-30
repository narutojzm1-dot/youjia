class_name GroundedGait
extends RefCounted

# One cycle is two steps. Advance from ground distance, never a wall-clock timer:
# slow movement gets slow feet and a blocked actor cannot run in place.
const WALK_SHADER := preload("res://shaders/felt_walk.gdshader")
var phase := 0.0
var weight := 0.0
var face := 1.0
var turn_width := 1.0
var _material: ShaderMaterial
var _turning := false
var _next_face := 1.0

func setup(sprite: Sprite2D, hip: float, split: float = 0.5) -> void:
	_material = ShaderMaterial.new()
	_material.shader = WALK_SHADER
	_material.set_shader_parameter("hip", hip)
	_material.set_shader_parameter("foot_split", split)
	sprite.material = _material

func advance(delta: float, moved: Vector2, depth: float, stride: float) -> void:
	var distance := moved.length() / maxf(depth, 0.1)
	phase = fmod(phase + distance / stride * TAU, TAU)
	var speed := distance / maxf(delta, 0.0001)
	weight = move_toward(weight, clampf(speed / 18.0, 0.0, 1.0), delta * 8.0)

func apply(sprite: Sprite2D, delta: float, desired_face: float, reduced: bool, swimming: bool = false) -> void:
	if reduced:
		face = desired_face
		turn_width = 1.0
		_turning = false
	if _turning and desired_face == face:
		_turning = false
	# A small pivot before swapping direction avoids a one-frame mirror snap.
	if desired_face != face and not _turning:
		_turning = true
		_next_face = desired_face
	if _turning:
		turn_width = move_toward(turn_width, 0.82, delta * 2.4)
		if turn_width <= 0.82:
			face = _next_face
			_turning = false
	else:
		turn_width = move_toward(turn_width, 1.0, delta * 1.8)
	var amount := 0.0 if reduced or swimming else weight
	_material.set_shader_parameter("phase", phase)
	_material.set_shader_parameter("amount", amount)
	# Feet lift individually in the shader. Keep the body nearly grounded rather
	# than bouncing the entire cutout several pixels eight times a second.
	sprite.position.y = -0.65 * (1.0 - cos(phase * 2.0)) * amount
	sprite.rotation = sin(phase) * amount * 0.008
	if swimming and not reduced:
		sprite.rotation = sin(phase) * weight * 0.012
