## Calibration-only model. Never consumes fish or decides business success.
extends RefCounted
const SETTLE_END := 0.2
const ARRIVE := 0.5
const CONTACT_END := 0.7
const END := 2.2
const INTERVAL := 5.0
var active := false
var elapsed := 0.0
var cooldown := 0.0
var origin := Vector2.ZERO
var source := Vector2.ZERO
var mouth := Vector2.ZERO
var reduced := false

static func pixel_world(sprite: Sprite2D, pixel: Vector2) -> Vector2:
	# Mirrors and parent/camera transforms are not approximated with fixed pixels.
	var size := sprite.texture.get_size()
	var mirrored := Vector2(size.x - pixel.x if sprite.flip_h else pixel.x, size.y - pixel.y if sprite.flip_v else pixel.y)
	var local := mirrored + sprite.offset
	if sprite.centered:
		local -= size * 0.5
	return sprite.to_global(local)

func begin(foot: Vector2, start: Vector2, end: Vector2, low_motion := false) -> bool:
	if active or cooldown > 0.0:
		return false
	origin = foot
	source = start
	mouth = end
	reduced = low_motion
	elapsed = 0.0
	cooldown = INTERVAL
	active = true
	return true

func advance(delta: float, foot: Vector2, posed := false, attached := true) -> void:
	if not is_finite(delta) or delta < 0.0:
		return
	cooldown = maxf(0.0, cooldown - delta)
	if not active:
		return
	# Match the response lifetime: never move the bird to preserve an effect.
	if not attached or posed or foot.distance_to(origin) > 0.01:
		active = false
		return
	elapsed += delta
	if elapsed >= END:
		active = false

func sample() -> Dictionary:
	if not active:
		return {"phase": "off", "visible": false}
	if elapsed < SETTLE_END:
		return {"phase": "settle", "visible": false}
	if elapsed >= CONTACT_END:
		return {"phase": "attention", "visible": false}
	if reduced or elapsed >= ARRIVE:
		return {"phase": "contact", "visible": true, "point": mouth}
	var t := clampf((elapsed - SETTLE_END) / (ARRIVE - SETTLE_END), 0.0, 1.0)
	# A low arc, capped relative to the actual flight distance, not character size.
	var lift := minf(4.0, source.distance_to(mouth) * 0.08)
	return {"phase": "flight", "visible": true, "point": source.lerp(mouth, t) + Vector2.UP * sin(PI * t) * lift}
