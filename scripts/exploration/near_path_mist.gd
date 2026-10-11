class_name NearPathMist
extends RefCounted
## Near-scene paint only; the caller supplies the existing world's environment.

const EFFECT := preload("res://shaders/near_path_mist.gdshader")
const REGIONS := preload("res://assets/holiday/exploration/near_path_mist_mask.svg")
const PHASE_SPEED := 0.025
const FADE_SECONDS := 4.0
const BOUNDS := Rect2(480, 240, 540, 220)

var phase := 0.0
var strength := 0.12
var target_strength := 0.12
var _painting: Sprite2D
var _overlay: Sprite2D
var _material: ShaderMaterial
var _enabled := true
var _reduced := false

func bind(painting: Sprite2D, reduced: bool) -> void:
	_painting = painting
	_overlay = Sprite2D.new()
	_overlay.name = "FarMist"
	_overlay.centered = false
	_overlay.region_enabled = true
	_overlay.region_rect = BOUNDS
	_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_material = ShaderMaterial.new()
	_material.shader = EFFECT
	_material.set_shader_parameter("region_mask", REGIONS)
	_material.set_shader_parameter("region_bounds", Vector4(BOUNDS.position.x, BOUNDS.position.y, BOUNDS.size.x, BOUNDS.size.y))
	_material.set_shader_parameter("phase", phase)
	_material.set_shader_parameter("strength", strength)
	_overlay.material = _material
	painting.add_child(_overlay)
	apply(true, reduced)

func sync_environment(state: Dictionary, snap: bool = false) -> void:
	var weather := str(state.get("weather", "sun"))
	var daylight := clampf(float(state.get("daylight", 1.0)), 0.0, 1.0)
	var gain := 1.7 if weather == "rain" else 1.45 if weather == "overcast" else 1.0
	target_strength = 0.12 * gain * lerpf(0.35, 1.0, daylight)
	if snap or _reduced:
		strength = target_strength
		if _material != null: _material.set_shader_parameter("strength", strength)

func apply(enabled: bool, reduced: bool) -> void:
	_enabled = enabled
	_reduced = reduced
	if is_instance_valid(_overlay):
		_overlay.visible = enabled and not reduced
		if is_instance_valid(_painting):
			_overlay.texture = _painting.texture
			_overlay.position = _painting.get_rect().position + BOUNDS.position

func advance(delta: float, reduced: bool) -> void:
	if reduced != _reduced: apply(_enabled, reduced)
	if not _enabled or _reduced or not is_instance_valid(_painting): return
	var step := maxf(delta, 0.0)
	phase = fposmod(phase + step * PHASE_SPEED, TAU)
	strength = lerpf(strength, target_strength, 1.0 - exp(-step / FADE_SECONDS))
	_material.set_shader_parameter("phase", phase)
	_material.set_shader_parameter("strength", strength)

func release() -> void:
	apply(false, _reduced)
	if is_instance_valid(_overlay): _overlay.queue_free()
	_overlay = null
	_painting = null
