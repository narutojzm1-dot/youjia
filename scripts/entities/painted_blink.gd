extends RefCounted
## Cosmetic only: one local clock/RNG, no gameplay random draws or saved state.
const CLOSED := preload("res://assets/holiday/characters/cast_v2/cow_chew_blink.png")
const SOURCE := "res://assets/holiday/characters/cast_v2/cow_chew.png"
const HORSE_CLOSED := preload("res://assets/holiday/characters/cast_v2/horse_blink.png")
const HORSE_SOURCE := "res://assets/holiday/characters/cast_v2/horse.png"
const SHEEP_A_SOURCE := "res://assets/holiday/characters/cast_v2/sheep_clingy.png"
const SHEEP_B_SOURCE := "res://assets/holiday/characters/cast_v2/sheep_dull.png"
const SHEEP_A_CLOSED := preload("res://assets/holiday/characters/cast_v2/sheep_clingy_blink.png")
const SHEEP_B_CLOSED := preload("res://assets/holiday/characters/cast_v2/sheep_dull_blink.png")
const LLAMA_SOURCE := "res://assets/holiday/characters/cast_v2/llama_smirk.png"
const LLAMA_CLOSED := preload("res://assets/holiday/characters/cast_v2/llama_smirk_blink.png")
const GOOSE_SOURCE := "res://assets/holiday/characters/cast_v2/goose_rest.png"
const GOOSE_CLOSED := preload("res://assets/holiday/characters/cast_v2/goose_rest_blink.png")
const COW_REST_SOURCE := "res://assets/holiday/characters/shelter/cow-rest.png"
const COW_REST_CLOSED := preload("res://assets/holiday/characters/shelter/cow-rest-blink.png")
const SHEEP_A_REST_SOURCE := "res://assets/holiday/characters/shelter/sheep-clingy-rest.png"
const SHEEP_B_REST_SOURCE := "res://assets/holiday/characters/shelter/sheep-dull-rest.png"
const SHEEP_A_REST_CLOSED := preload("res://assets/holiday/characters/shelter/sheep-clingy-rest-blink.png")
const SHEEP_B_REST_CLOSED := preload("res://assets/holiday/characters/shelter/sheep-dull-rest-blink.png")
const SOURCE_PROFILES := {SOURCE:"cow", COW_REST_SOURCE:"cow_rest", HORSE_SOURCE:"horse", LLAMA_SOURCE:"llama", GOOSE_SOURCE:"goose", SHEEP_A_SOURCE:"sheep_a", SHEEP_B_SOURCE:"sheep_b", SHEEP_A_REST_SOURCE:"sheep_a_rest", SHEEP_B_REST_SOURCE:"sheep_b_rest"}
const DURATION := 0.30
var rng := RandomNumberGenerator.new()
var wait_left := 0.0
var elapsed := -1.0
var amount := 0.0
var material: ShaderMaterial
var source_path := SOURCE
var eye_a := Vector4(165, 390, 65, 58)
var eye_b := Vector4(290, 412, 113, 70)

func _init() -> void:
	rng.randomize()
	_schedule()

static func profile_for_source(path: String) -> String:
	return str(SOURCE_PROFILES.get(path, ""))

func bind(target: ShaderMaterial, species: String = "cow") -> void:
	material = target
	source_path = SOURCE
	eye_a = Vector4(165, 390, 65, 58)
	eye_b = Vector4(290, 412, 113, 70)
	var closed: Texture2D = CLOSED
	match species:
		"cow_rest":
			source_path = COW_REST_SOURCE
			closed = COW_REST_CLOSED
			eye_a = Vector4(181, 435, 60, 51)
			eye_b = Vector4(321, 465, 115, 72)
		"sheep_a_rest":
			source_path = SHEEP_A_REST_SOURCE
			closed = SHEEP_A_REST_CLOSED
			eye_a = Vector4(838, 442, 151, 112)
			eye_b = Vector4(1030, 391, 91, 67)
		"sheep_b_rest":
			source_path = SHEEP_B_REST_SOURCE
			closed = SHEEP_B_REST_CLOSED
			eye_a = Vector4(282, 510, 125, 81)
			eye_b = Vector4(132, 514, 57, 64)
		"goose":
			source_path = GOOSE_SOURCE
			closed = GOOSE_CLOSED
			eye_a = Vector4(960, 328, 125, 77)
			eye_b = eye_a # Profile view has only one visible eye.
		"llama":
			source_path = LLAMA_SOURCE
			closed = LLAMA_CLOSED
			eye_a = Vector4(852, 240, 98, 68)
			eye_b = Vector4(986, 275, 52, 43)
		"horse":
			source_path = HORSE_SOURCE
			closed = HORSE_CLOSED
			eye_a = Vector4(191, 272, 88, 64)
			eye_b = Vector4(111, 312, 39, 43)
		"sheep_a":
			source_path = SHEEP_A_SOURCE
			closed = SHEEP_A_CLOSED
			eye_a = Vector4(885, 306, 90, 87)
			eye_b = Vector4(1038, 253, 61, 58)
		"sheep_b":
			source_path = SHEEP_B_SOURCE
			closed = SHEEP_B_CLOSED
			eye_a = Vector4(290, 455, 110, 69)
			eye_b = Vector4(137, 451, 58, 53)
	# Two small feathered regions, normalized from each canonical 1280px display.
	material.set_shader_parameter("blink_texture", closed)
	material.set_shader_parameter("blink_eye_a", eye_a / 1280.0)
	material.set_shader_parameter("blink_eye_b", eye_b / 1280.0)
	_write(0.0)

func cancel() -> void:
	if elapsed >= 0.0:
		_schedule()
	elapsed = -1.0
	_write(0.0)

func advance(delta: float, allowed: bool) -> void:
	if not allowed or delta > 0.25:
		cancel()
		return
	if delta <= 0.0:
		return
	if elapsed < 0.0:
		wait_left -= delta
		if wait_left > 0.0:
			return
		elapsed = 0.0
	else:
		elapsed += delta
	if elapsed >= DURATION:
		cancel()
		return
	# Close quickly, hold briefly, then open softly; never swap the whole body.
	var value := smoothstep(0.0, 0.10, elapsed)
	if elapsed > 0.16:
		value = 1.0 - smoothstep(0.16, DURATION, elapsed)
	_write(value)

func _schedule() -> void:
	wait_left = rng.randf_range(4.5, 11.0)

func _write(value: float) -> void:
	amount = value
	if material != null:
		material.set_shader_parameter("blink_amount", amount)
