class_name NearPathMotion
extends RefCounted
## Cosmetic phase only. World time/weather and exploration state remain with their owners.
## A single masked paint pass; reduced motion removes the material altogether.

const EFFECT := preload("res://shaders/near_path_motion.gdshader")
const REGIONS := preload("res://assets/holiday/exploration/near_path_motion_mask.svg")

var phase := 0.0
var _painting: Sprite2D
var _material: ShaderMaterial
var _enabled := true
var _reduced := false

func bind(painting: Sprite2D, reduced: bool) -> void:
	_painting = painting
	_material = ShaderMaterial.new()
	_material.shader = EFFECT
	_material.set_shader_parameter("region_mask", REGIONS)
	_material.set_shader_parameter("phase", phase)
	apply(true, reduced)

func apply(enabled: bool, reduced: bool) -> void:
	_enabled = enabled
	_reduced = reduced
	if is_instance_valid(_painting):
		_painting.material = _material if enabled and not reduced else null

func advance(delta: float, reduced: bool) -> void:
	if reduced != _reduced:
		apply(_enabled, reduced)
	if not _enabled or _reduced or not is_instance_valid(_painting): return
	phase = fposmod(phase + maxf(delta, 0.0) * 0.42, TAU)
	_material.set_shader_parameter("phase", phase)

func release() -> void:
	apply(false, _reduced)
	_painting = null
