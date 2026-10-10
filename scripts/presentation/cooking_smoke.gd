class_name CookingSmoke
extends Node2D
## GROK #705: local chimney watercolor smoke while cooking is active.
## Leaf presentation only. Leader supplies real cooking start/end + roof anchor.
## Does not infer mealtime, does not touch house door / sleep / brush directors.

## Default near painted cottage roof above the house_door hotspot (YardWorld 1280×720).
## Override with set_chimney_anchor once Leader publishes the authentic roof point.
const DEFAULT_CHIMNEY_ANCHOR := Vector2(292.0, 218.0)

## Soft warm gray wash — light watercolor puff, not a screen fog.
const SMOKE_DAY := Color(0.82, 0.78, 0.72, 0.30)
const SMOKE_NIGHT := Color(0.68, 0.66, 0.64, 0.22)

var _emitter: CPUParticles2D
var _cooking := false
var _paused := false
var _built := false
var _night_tint := false


func _ready() -> void:
	_ensure_emitter()
	if position == Vector2.ZERO:
		position = DEFAULT_CHIMNEY_ANCHOR
	_apply_emission()


## World-space chimney mouth. Safe to call before or after set_cooking.
func set_chimney_anchor(world_pos: Vector2) -> void:
	position = world_pos


## Optional day/night tint hint from Leader (does not own the weather/night systems).
func set_night_tint(night: bool) -> void:
	if _night_tint == night:
		return
	_night_tint = night
	if _emitter != null:
		_emitter.color = SMOKE_NIGHT if _night_tint else SMOKE_DAY


## Start or stop cooking smoke. Same value is a no-op (no restart, no extra nodes).
func set_cooking(active: bool) -> void:
	if _cooking == active:
		return
	_cooking = active
	_apply_emission()


## Pause freezes new emission; existing wisps fade out. Cooking flag is unchanged.
func set_paused(paused: bool) -> void:
	if _paused == paused:
		return
	_paused = paused
	_apply_emission()


func is_cooking() -> bool:
	return _cooking


func is_paused() -> bool:
	return _paused


func is_emitting() -> bool:
	return _emitter != null and _emitter.emitting


func debug_snapshot() -> Dictionary:
	return {
		"cooking": _cooking,
		"paused": _paused,
		"emitting": is_emitting(),
		"child_count": get_child_count(),
		"anchor": position,
		"night_tint": _night_tint,
		"reduced_motion": _reduced_motion(),
	}


func _ensure_emitter() -> void:
	if _built and _emitter != null and is_instance_valid(_emitter):
		return
	# Tear down any accidental extras so repeated ensure never accumulates.
	for child in get_children():
		if child is CPUParticles2D:
			child.queue_free()
	_emitter = CPUParticles2D.new()
	_emitter.name = "ChimneyWisp"
	_emitter.emitting = false
	_emitter.one_shot = false
	_emitter.explosiveness = 0.0
	_emitter.randomness = 0.55
	_emitter.lifetime = 2.8
	_emitter.preprocess = 0.0
	_emitter.amount = 10
	_emitter.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_emitter.emission_sphere_radius = 6.0
	_emitter.direction = Vector2(0.0, -1.0)
	_emitter.spread = 18.0
	_emitter.gravity = Vector2(4.0, -12.0)
	_emitter.initial_velocity_min = 8.0
	_emitter.initial_velocity_max = 18.0
	_emitter.angular_velocity_min = -12.0
	_emitter.angular_velocity_max = 12.0
	_emitter.scale_amount_min = 0.55
	_emitter.scale_amount_max = 1.35
	_emitter.color = SMOKE_DAY
	# Local roof puff sits above yard props but below HUD/UI.
	_emitter.z_index = 6
	_emitter.local_coords = true
	add_child(_emitter)
	_built = true


func _apply_emission() -> void:
	_ensure_emitter()
	var reduced := _reduced_motion()
	var should_emit := _cooking and not _paused and not reduced
	if should_emit:
		_emitter.amount = 6 if reduced else 10
		_emitter.lifetime = 1.6 if reduced else 2.8
		_emitter.color = SMOKE_NIGHT if _night_tint else SMOKE_DAY
		# Do not restart() while already emitting — that would pop a new burst.
		if not _emitter.emitting:
			_emitter.emitting = true
	else:
		# Stop spawning; living particles keep rising and fade (natural dissipate).
		_emitter.emitting = false


func _reduced_motion() -> bool:
	if typeof(TuningStore) == TYPE_NIL:
		return false
	return bool(TuningStore.get_value("ui.reduced_motion", false))
