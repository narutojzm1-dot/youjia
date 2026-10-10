extends RefCounted
## Local chest expansion of authored lying paintings; feet and head stay rigid.
## A per-actor cosmetic clock never consumes gameplay RNG or shader TIME.
const ROOT := "res://assets/holiday/characters/shelter/"
const REGIONS := {
	"res://assets/holiday/characters/cast_v2/goose_rest.png": Vector4(0.15, 0.43, 0.63, 0.34),
	ROOT+"cow-rest.png": Vector4(0.50, 0.40, 0.35, 0.32),
	ROOT+"horse-rest.png": Vector4(0.53, 0.40, 0.27, 0.29),
	ROOT+"llama-rest.png": Vector4(0.12, 0.50, 0.46, 0.35),
	ROOT+"sheep-clingy-rest.png": Vector4(0.10, 0.43, 0.38, 0.31),
	ROOT+"sheep-dull-rest.png": Vector4(0.53, 0.25, 0.38, 0.43),
}
const MAX_SHIFT := 0.006
var phase := 0.0
var rate := 1.4
var strength := 0.0
var material: ShaderMaterial
var source_path := ""

func bind(target: ShaderMaterial, identity: String) -> void:
	material = target
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = identity.hash()
	phase = local_rng.randf_range(0.0, TAU)
	rate = local_rng.randf_range(1.15, 1.65)
	cancel()

static func configure(target: ShaderMaterial, path: String) -> bool:
	var supported := REGIONS.has(path)
	target.set_shader_parameter("rest_breath_region", REGIONS.get(path, Vector4(0, 0, 1, 1)))
	if not supported: target.set_shader_parameter("rest_breath_shift", 0.0)
	return supported

func advance(delta: float, allowed: bool, path: String) -> void:
	if material == null: return
	if path != source_path:
		cancel()
		source_path = path
		configure(material, path)
	if not allowed or not REGIONS.has(path) or not is_finite(delta) or delta < 0.0 or delta > 0.25:
		cancel()
		return
	if delta == 0.0: return
	phase = fposmod(phase + delta * rate, TAU)
	strength = move_toward(strength, 1.0, delta * 1.5)
	# Expand upwards only; never move the body's support point or entire cutout.
	material.set_shader_parameter("rest_breath_shift", MAX_SHIFT * (0.5 + 0.5 * sin(phase)) * strength)

func cancel() -> void:
	strength = 0.0
	if material != null: material.set_shader_parameter("rest_breath_shift", 0.0)
