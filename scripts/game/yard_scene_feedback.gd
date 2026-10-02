class_name YardSceneFeedback
extends Node2D

const PETALS := preload("res://assets/holiday/fx/windowbox_petals.png")
const BUTTERFLY_OPEN := preload("res://assets/holiday/fx/windowbox_butterfly_open.png")
const BUTTERFLY_REST := preload("res://assets/holiday/fx/windowbox_butterfly_rest.png")
const PETAL_DURATION := 1.8
const BUTTERFLY_DURATION := 2.8

var _petals: Sprite2D
var _butterfly: Sprite2D
var _anchor := Vector2.ZERO
var _elapsed := 0.0
var _duration := 0.0
var _has_butterfly := false
var _butterfly_seen := false


func setup() -> void:
	name = "PaintedSceneResponses"
	# Behind the ground-sorted characters, above the immutable painted backdrop.
	z_index = 270
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_petals = Sprite2D.new()
	_petals.name = "WindowboxPetals"
	_petals.texture = PETALS
	_petals.scale = Vector2(0.23, 0.23)
	add_child(_petals)
	_butterfly = Sprite2D.new()
	_butterfly.name = "WindowboxButterfly"
	_butterfly.texture = BUTTERFLY_REST
	_butterfly.scale = Vector2(0.22, 0.22)
	add_child(_butterfly)
	visible = false


func play_windowbox(anchor: Vector2) -> void:
	_anchor = anchor
	_elapsed = 0.0
	_has_butterfly = not _butterfly_seen
	_duration = BUTTERFLY_DURATION if _has_butterfly else PETAL_DURATION
	visible = true
	_update_paint(bool(TuningStore.get_value("ui.reduced_motion", false)))


func cancel() -> void:
	_duration = 0.0
	_elapsed = 0.0
	_has_butterfly = false
	visible = false


func active_snapshot() -> Dictionary:
	if not visible:
		return {}
	return {
		"anchor": _anchor, "remaining": _duration - _elapsed,
		"butterfly": _has_butterfly, "butterfly_seen": _butterfly_seen,
		"butterfly_position": _butterfly.position,
		"reduced_motion": bool(TuningStore.get_value("ui.reduced_motion", false)),
	}


func butterfly_seen() -> bool:
	return _butterfly_seen


func advance(delta: float) -> void:
	if not visible:
		return
	_elapsed += delta
	# A player who immediately walks away has not missed a once-per-session
	# discovery; only actual time spent viewing it completes the encounter.
	if _has_butterfly and _elapsed >= 1.3:
		_butterfly_seen = true
	if _elapsed >= _duration:
		cancel()
		return
	_update_paint(bool(TuningStore.get_value("ui.reduced_motion", false)))


func _update_paint(reduced_motion: bool) -> void:
	_petals.position = _anchor + Vector2(0.0, 12.0)
	_petals.visible = true
	_butterfly.visible = _has_butterfly
	if reduced_motion:
		_butterfly.texture = BUTTERFLY_REST
		_butterfly.position = _anchor + Vector2(14.0, 21.0)
		_petals.modulate.a = 1.0
		_butterfly.modulate.a = 1.0
		return
	var fade := clampf((_duration - _elapsed) / 0.35, 0.0, 1.0)
	_petals.position += Vector2(_elapsed * 3.0, _elapsed * 4.0)
	_petals.modulate.a = minf(1.0, 0.6 + _elapsed * 1.7) * fade
	if _has_butterfly:
		# Two complete original paintings; no wing scaling or synthetic morphing.
		_butterfly.texture = BUTTERFLY_OPEN if fmod(_elapsed, 0.38) < 0.19 and _elapsed < 1.9 else BUTTERFLY_REST
		_butterfly.position = _anchor + Vector2(10.0 + _elapsed * 3.0, 18.0 + sin(_elapsed * 5.4) * 2.5)
		_butterfly.modulate.a = fade
