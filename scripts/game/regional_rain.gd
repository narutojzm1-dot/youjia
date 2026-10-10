extends Node2D
## A regional visual driven only by the caller's active game clock (never TIME).
const SHADER := preload("res://shaders/regional_rain.gdshader")
var clock := 0.0
var amount := 0.0
var reduced := false
var extent := Vector2(1280,720)
var pond := true
var layers: Array[Polygon2D] = []

func configure(area: Vector2, with_pond: bool = true) -> void:
	extent = area
	pond = with_pond
	for layer in layers: layer.queue_free()
	layers.clear()
	for kind in 2:
		var layer := Polygon2D.new()
		layer.polygon = PackedVector2Array([Vector2.ZERO,Vector2(area.x,0),area,Vector2(0,area.y)])
		layer.z_index = 1 if kind == 0 else 3000
		var shader_material := ShaderMaterial.new()
		shader_material.shader = SHADER
		shader_material.set_shader_parameter("surface_only",kind == 0)
		shader_material.set_shader_parameter("with_pond",pond)
		layer.material = shader_material
		add_child(layer)
		layers.append(layer)
	apply()

func advance(delta: float, raining: bool, low_motion: bool) -> void:
	reduced = low_motion
	amount = (1.0 if raining else 0.0) if reduced else move_toward(amount,1.0 if raining else 0.0,maxf(delta,0.0)/3.0)
	if not reduced: clock = fposmod(clock + maxf(delta,0.0),60.0)
	apply()

func apply() -> void:
	visible = amount > 0.0001
	for layer in layers:
		layer.material.set_shader_parameter("rain_clock",0.0 if reduced else clock)
		layer.material.set_shader_parameter("amount",amount)
		layer.material.set_shader_parameter("reduced_motion",reduced)

func snapshot() -> Dictionary:
	return {"clock":clock,"amount":amount,"reduced":reduced}

static func sanitize(raw: Variant) -> Dictionary:
	if not raw is Dictionary or not raw.get("reduced") is bool: return {}
	for key: String in ["clock","amount"]:
		if typeof(raw.get(key)) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(raw[key])): return {}
	if float(raw.clock) < 0.0 or float(raw.clock) >= 60.0 or float(raw.amount) < 0.0 or float(raw.amount) > 1.0: return {}
	return {"clock":float(raw.clock),"amount":float(raw.amount),"reduced":raw.reduced}

func restore(raw: Dictionary) -> void:
	var clean := sanitize(raw)
	if clean.is_empty(): return
	clock = clean.clock
	amount = clean.amount
	reduced = clean.reduced
	apply()
