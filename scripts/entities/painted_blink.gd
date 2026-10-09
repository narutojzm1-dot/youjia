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

func bind(target: ShaderMaterial, species: String = "cow") -> void:
	material = target
	var closed: Texture2D = CLOSED
	match species:
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
