extends RefCounted
## Cosmetic only: one local clock/RNG, no gameplay random draws or saved state.
const CLOSED := preload("res://assets/holiday/characters/cast_v2/cow_chew_blink.png")
const SOURCE := "res://assets/holiday/characters/cast_v2/cow_chew.png"
const DURATION := 0.30
var rng := RandomNumberGenerator.new()
var wait_left := 0.0
var elapsed := -1.0
var amount := 0.0
var material: ShaderMaterial

func _init() -> void:
	rng.randomize()
	_schedule()

func bind(target: ShaderMaterial) -> void:
	material = target
	material.set_shader_parameter("blink_texture", CLOSED)
	# Two small feathered regions, in canonical 1280px chew-cel coordinates.
	material.set_shader_parameter("blink_eye_a", Vector4(165, 390, 65, 58) / 1280.0)
	material.set_shader_parameter("blink_eye_b", Vector4(290, 412, 113, 70) / 1280.0)
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
