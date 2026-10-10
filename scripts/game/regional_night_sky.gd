extends Sprite2D
## One regional clock, no shader TIME and no extra saved state.
const Daylight := preload("res://scripts/game/world_daylight.gd")
var amount := 0.0

func configure(painting: Sprite2D, nearby: bool = false) -> void:
	name = "RegionalNightSky"
	texture = painting.texture
	centered = false
	transform = painting.transform
	z_index = painting.z_index
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var ink := ShaderMaterial.new()
	ink.shader = preload("res://shaders/regional_night_sky.gdshader")
	ink.set_shader_parameter("sky_bounds", Vector4(0.22, 0.015, 0.84, 0.145) if not nearby else Vector4(0.16, 0.025, 0.57, 0.13))
	ink.set_shader_parameter("moon_position", Vector2(0.50, 0.12) if not nearby else Vector2(0.37, 0.055))
	ink.set_shader_parameter("mountain_step_x", 0.58 if not nearby else 1.0)
	material = ink

static func night_strength(fraction: float) -> float:
	var h := Daylight.hour(fraction)
	if h >= 20.0: return smoothstep(20.0, 21.0, h)
	if h < 5.0: return 1.0
	return 1.0 - smoothstep(5.0, 5.8, h)

func sync(fraction: float, weather: String, delta: float, reduced: bool) -> void:
	var target := night_strength(fraction) if weather == "sun" else 0.0
	amount = target if delta <= 0.0 or reduced else lerpf(amount, target, 1.0 - exp(-maxf(delta, 0.0)))
	visible = amount > 0.001
	material.set_shader_parameter("amount", amount)
	# Saved time freezes with the game and recovers exactly after reload.
	material.set_shader_parameter("phase", 0.0 if reduced else Daylight.hour(fraction) / 24.0 * TAU * 8.0)

func snapshot() -> Dictionary:
	return {"amount": amount, "phase": float(material.get_shader_parameter("phase"))}

static func sanitize(data: Variant) -> Dictionary:
	if not data is Dictionary: return {}
	for key in ["amount", "phase"]:
		if not (data.get(key) is float or data.get(key) is int) or not is_finite(float(data[key])): return {}
	if float(data.amount) < 0.0 or float(data.amount) > 1.0 or float(data.phase) < 0.0 or float(data.phase) > TAU * 8.0: return {}
	return {"amount": float(data.amount), "phase": float(data.phase)}

func restore(data: Dictionary) -> void:
	var clean := sanitize(data)
	if clean.is_empty(): return
	amount = clean.amount
	visible = amount > 0.001
	material.set_shader_parameter("amount", amount)
	material.set_shader_parameter("phase", clean.phase)
