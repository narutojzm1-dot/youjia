class_name YardSceneFeedback
extends Node2D

const PETALS := preload("res://assets/holiday/fx/windowbox_petals.png")
const BUTTERFLY_OPEN := preload("res://assets/holiday/fx/windowbox_butterfly_open.png")
const BUTTERFLY_REST := preload("res://assets/holiday/fx/windowbox_butterfly_rest.png")
const RIPPLE_START := preload("res://assets/holiday/fx/shore_ripple_start.png")
const RIPPLE_WIDE := preload("res://assets/holiday/fx/shore_ripple_wide.png")
const DRAGONFLY_FLIGHT := preload("res://assets/holiday/fx/shore_dragonfly_flight.png")
const DRAGONFLY_REST := preload("res://assets/holiday/fx/shore_dragonfly_rest.png")
const FENCE_GRASS_STILL := preload("res://assets/holiday/fx/fence_grass_still.png")
const FENCE_GRASS_BENT := preload("res://assets/holiday/fx/fence_grass_bent.png")
const SHED_FEATHER := preload("res://assets/holiday/fx/shed_feather.png")
const PATH_SNAIL := preload("res://assets/holiday/fx/path_snail.png")
const PATH_CLOVER := preload("res://assets/holiday/fx/path_clover.png")
const PETAL_DURATION := 1.8
const BUTTERFLY_DURATION := 2.8
const RIPPLE_DURATION := 1.65
const DRAGONFLY_DURATION := 2.8
const FENCE_DURATION := 2.0
const FEATHER_DURATION := 3.2

var _petals: Sprite2D
var _butterfly: Sprite2D
var _ripple: Sprite2D
var _dragonfly: Sprite2D
var _fence_grass: Sprite2D
var _feather: Sprite2D
var _anchor := Vector2.ZERO
var _elapsed := 0.0
var _duration := 0.0
var _has_butterfly := false
var _butterfly_seen := false
var _ripple_anchor := Vector2.ZERO
var _ripple_elapsed := 0.0
var _ripple_duration := 0.0
var _dragonfly_anchor := Vector2.ZERO
var _dragonfly_elapsed := 0.0
var _dragonfly_duration := 0.0
var _dragonfly_seen := false
var _shore_was_near := false
var _fence_anchor := Vector2.ZERO
var _fence_elapsed := 0.0
var _fence_duration := 0.0
var _feather_anchor := Vector2.ZERO
var _feather_elapsed := 0.0
var _feather_duration := 0.0
var _feather_seen := false
var _fence_was_near := false
var _leaf_still := 0.0
var _leaf_wait := 0.0
var _leaf_wants := false
var _leaf_anchor := Vector2.ZERO
const LEAF_STILL_SECONDS := 2.5
const LEAF_GAP_SECONDS := 12.0
const PATH_POINT := Vector2(300, 620)
const PATH_STILL_SECONDS := 2.5
const PATH_HOLD_SECONDS := 3.2
const PATH_GAP_SECONDS := 14.0
var _snail: Sprite2D
var _clover: Sprite2D
var _path_still := 0.0
var _path_wait := 0.0
var _path_wants := false
var _path_elapsed := 0.0
var _path_duration := 0.0


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
	_ripple = Sprite2D.new()
	_ripple.name = "PaintedShoreRipple"
	_ripple.texture = RIPPLE_START
	_ripple.scale = Vector2(0.25, 0.25)
	add_child(_ripple)
	_dragonfly = Sprite2D.new()
	_dragonfly.name = "PaintedShoreDragonfly"
	_dragonfly.texture = DRAGONFLY_REST
	_dragonfly.scale = Vector2(0.18, 0.18)
	add_child(_dragonfly)
	_fence_grass = Sprite2D.new()
	_fence_grass.name = "PaintedFenceGrass"
	_fence_grass.texture = FENCE_GRASS_STILL
	_fence_grass.scale = Vector2(0.16, 0.16)
	add_child(_fence_grass)
	_feather = Sprite2D.new()
	_feather.name = "PaintedShedFeather"
	_feather.texture = SHED_FEATHER
	_feather.scale = Vector2(0.15, 0.15)
	add_child(_feather)
	_snail = Sprite2D.new()
	_snail.name = "PathSnail"
	_snail.texture = PATH_SNAIL
	_snail.scale = Vector2(0.72, 0.72)
	add_child(_snail)
	_clover = Sprite2D.new()
	_clover.name = "PathClover"
	_clover.texture = PATH_CLOVER
	_clover.scale = Vector2(0.34, 0.34)
	add_child(_clover)
	visible = false


func play_windowbox(anchor: Vector2) -> void:
	_anchor = anchor
	_elapsed = 0.0
	_has_butterfly = not _butterfly_seen
	_duration = BUTTERFLY_DURATION if _has_butterfly else PETAL_DURATION
	_sync_visible()
	_update_paint(bool(TuningStore.get_value("ui.reduced_motion", false)))


func play_shore_ripple(anchor: Vector2) -> void:
	# A touch on the actual bank is the only source of this response. An ambient
	# dragonfly may remain visible at the same time; neither creates a fish.
	_ripple_anchor = anchor
	_ripple_elapsed = 0.0
	_ripple_duration = RIPPLE_DURATION
	_sync_visible()
	_update_shore_paint(bool(TuningStore.get_value("ui.reduced_motion", false)))


func play_fence_grass(anchor: Vector2) -> void:
	_fence_anchor = anchor
	_fence_elapsed = 0.0
	_fence_duration = FENCE_DURATION
	_sync_visible()
	_update_fence_paint(bool(TuningStore.get_value("ui.reduced_motion", false)))


func consider_shore(world: Node2D) -> void:
	# A different discovery from the windowbox: ordinary walking near the bank,
	# without tapping a hotspot, can briefly reveal the painted dragonfly.
	var shore := YardSceneHotspots.get_hotspot(YardSceneHotspots.SHORE_STONES)
	var near := false
	if not shore.is_empty() and YardSceneHotspots.available(world) \
		and world._pending_interaction in ["", YardSceneHotspots.SHORE_STONES] \
		and world._selected_target in ["", YardSceneHotspots.SHORE_STONES]:
		var player = world.get_player()
		near = player != null and player.position.distance_to(shore.approach_points[0]) < 64.0
	if near and not _shore_was_near and not _dragonfly_seen and _dragonfly_duration <= 0.0:
		_dragonfly_anchor = shore.visual_anchor
		_dragonfly_elapsed = 0.0
		_dragonfly_duration = DRAGONFLY_DURATION
		_sync_visible()
		_update_shore_paint(bool(TuningStore.get_value("ui.reduced_motion", false)))
	_shore_was_near = near


func consider_fence(world: Node2D) -> void:
	# The feather is a separate, optional encounter while taking an ordinary
	# walk near the gate; touching the painted gate is not a prerequisite.
	var fence := YardSceneHotspots.get_hotspot(YardSceneHotspots.FENCE_GATE)
	var near := false
	var player = world.get_player()
	if not fence.is_empty() and YardSceneHotspots.available(world) \
		and world._pending_interaction in ["", YardSceneHotspots.FENCE_GATE] \
		and world._selected_target in ["", YardSceneHotspots.FENCE_GATE]:
		near = player != null and player.position.distance_to(fence.approach_points[0]) < 64.0
	if near and not _fence_was_near and not _feather_seen and _feather_duration <= 0.0:
		_feather_anchor = fence.ambient_anchor
		_feather_elapsed = 0.0
		_feather_duration = FEATHER_DURATION
		_sync_visible()
		_update_fence_paint(bool(TuningStore.get_value("ui.reduced_motion", false)))
	_fence_was_near = near
	var moving := bool(player == null or world._has_walk_goal or player._velocity.length() > 8.0)
	_leaf_wants = near and not moving and str(world._pending_interaction) != "fence_gate" and _fence_duration <= 0.0
	if _leaf_wants:
		_leaf_anchor = fence.visual_anchor


func consider_path(world: Node2D) -> void:
	var player = world.get_player()
	var near: bool = player != null and player.position.distance_to(PATH_POINT) < 70.0
	var moving: bool = player == null or world._has_walk_goal or player._velocity.length() > 8.0
	_path_wants = near and not moving and str(world._pending_interaction) == ""


func cancel() -> void:
	_duration = 0.0
	_elapsed = 0.0
	_has_butterfly = false
	_ripple_duration = 0.0
	_ripple_elapsed = 0.0
	_dragonfly_duration = 0.0
	_dragonfly_elapsed = 0.0
	_fence_duration = 0.0
	_fence_elapsed = 0.0
	_feather_duration = 0.0
	_feather_elapsed = 0.0
	_leaf_still = 0.0
	_leaf_wants = false
	_path_still = 0.0
	_path_wants = false
	_path_duration = 0.0
	_path_elapsed = 0.0
	_sync_visible()


func active_snapshot() -> Dictionary:
	# Preserve the original flower-box contract even if a second scene response
	# is playing elsewhere in the yard.
	if _duration <= 0.0:
		return {}
	return {
		"anchor": _anchor, "remaining": _duration - _elapsed,
		"butterfly": _has_butterfly, "butterfly_seen": _butterfly_seen,
		"butterfly_position": _butterfly.position,
		"reduced_motion": bool(TuningStore.get_value("ui.reduced_motion", false)),
	}


func ripple_snapshot() -> Dictionary:
	if _ripple_duration <= 0.0:
		return {}
	return {
		"anchor": _ripple_anchor, "remaining": _ripple_duration - _ripple_elapsed,
		"reduced_motion": bool(TuningStore.get_value("ui.reduced_motion", false)),
	}


func dragonfly_snapshot() -> Dictionary:
	if _dragonfly_duration <= 0.0:
		return {}
	return {
		"anchor": _dragonfly_anchor, "remaining": _dragonfly_duration - _dragonfly_elapsed,
		"seen": _dragonfly_seen,
		"reduced_motion": bool(TuningStore.get_value("ui.reduced_motion", false)),
	}


func fence_snapshot() -> Dictionary:
	if _fence_duration <= 0.0:
		return {}
	return {
		"anchor": _fence_anchor, "remaining": _fence_duration - _fence_elapsed,
		"reduced_motion": bool(TuningStore.get_value("ui.reduced_motion", false)),
	}


func feather_snapshot() -> Dictionary:
	if _feather_duration <= 0.0:
		return {}
	return {
		"anchor": _feather_anchor, "remaining": _feather_duration - _feather_elapsed,
		"seen": _feather_seen,
		"reduced_motion": bool(TuningStore.get_value("ui.reduced_motion", false)),
	}


func butterfly_seen() -> bool:
	return _butterfly_seen


func dragonfly_seen() -> bool:
	return _dragonfly_seen


func feather_seen() -> bool:
	return _feather_seen


func advance(delta: float) -> void:
	if _duration > 0.0:
		_elapsed += delta
		# A player who walks away early has not missed a once-per-session view.
		if _has_butterfly and _elapsed >= 1.3:
			_butterfly_seen = true
		if _elapsed >= _duration:
			_duration = 0.0
			_has_butterfly = false
		else:
			_update_paint(bool(TuningStore.get_value("ui.reduced_motion", false)))
	if _ripple_duration > 0.0:
		_ripple_elapsed += delta
		if _ripple_elapsed >= _ripple_duration:
			_ripple_duration = 0.0
		else:
			_update_shore_paint(bool(TuningStore.get_value("ui.reduced_motion", false)))
	if _dragonfly_duration > 0.0:
		_dragonfly_elapsed += delta
		if _dragonfly_elapsed >= 1.2:
			_dragonfly_seen = true
		if _dragonfly_elapsed >= _dragonfly_duration:
			_dragonfly_duration = 0.0
		else:
			_update_shore_paint(bool(TuningStore.get_value("ui.reduced_motion", false)))
	if _fence_duration > 0.0:
		_fence_elapsed += delta
		if _fence_elapsed >= _fence_duration:
			_fence_duration = 0.0
		else:
			_update_fence_paint(bool(TuningStore.get_value("ui.reduced_motion", false)))
	if _feather_duration > 0.0:
		_feather_elapsed += delta
		if _feather_elapsed >= 1.2:
			_feather_seen = true
		if _feather_elapsed >= _feather_duration:
			_feather_duration = 0.0
		else:
			_update_fence_paint(bool(TuningStore.get_value("ui.reduced_motion", false)))
	if _leaf_wait > 0.0:
		_leaf_wait = maxf(0.0, _leaf_wait - delta)
	if _leaf_wants and _fence_duration <= 0.0 and _leaf_wait <= 0.0:
		_leaf_still += delta
		if _leaf_still >= LEAF_STILL_SECONDS:
			_leaf_still = 0.0
			_leaf_wait = LEAF_GAP_SECONDS
			play_fence_grass(_leaf_anchor)
	else:
		_leaf_still = 0.0
	if _path_wait > 0.0:
		_path_wait = maxf(0.0, _path_wait - delta)
	if not _path_wants:
		_path_duration = 0.0
		_path_still = 0.0
	elif _path_duration > 0.0:
		_path_elapsed += delta
		if _path_elapsed >= _path_duration:
			_path_duration = 0.0
			_path_wait = PATH_GAP_SECONDS
	elif _path_wait <= 0.0:
		_path_still += delta
		if _path_still >= PATH_STILL_SECONDS:
			_path_still = 0.0
			_path_elapsed = 0.0
			_path_duration = PATH_HOLD_SECONDS
			_snail.position = PATH_POINT + Vector2(-16, -8)
			_clover.position = PATH_POINT + Vector2(22, -4)
	_sync_visible()


func _sync_visible() -> void:
	visible = _duration > 0.0 or _ripple_duration > 0.0 or _dragonfly_duration > 0.0 \
		or _fence_duration > 0.0 or _feather_duration > 0.0 or _path_duration > 0.0
	if _petals != null:
		_petals.visible = _duration > 0.0
		_butterfly.visible = _duration > 0.0 and _has_butterfly
		_ripple.visible = _ripple_duration > 0.0
		_dragonfly.visible = _dragonfly_duration > 0.0
		_fence_grass.visible = _fence_duration > 0.0
		_feather.visible = _feather_duration > 0.0
		_snail.visible = _path_duration > 0.0
		_clover.visible = _path_duration > 0.0


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


func _update_shore_paint(reduced_motion: bool) -> void:
	if _ripple_duration > 0.0:
		# Replace the entire painted water cel; do not stretch one geometric ring.
		_ripple.texture = RIPPLE_WIDE if reduced_motion or _ripple_elapsed >= 0.72 else RIPPLE_START
		_ripple.position = _ripple_anchor
		_ripple.modulate.a = 1.0 if reduced_motion else clampf((_ripple_duration - _ripple_elapsed) / 0.38, 0.0, 1.0)
	if _dragonfly_duration > 0.0:
		_dragonfly.texture = DRAGONFLY_REST if reduced_motion or fmod(_dragonfly_elapsed, 0.44) >= 0.22 else DRAGONFLY_FLIGHT
		_dragonfly.position = _dragonfly_anchor + (Vector2(19.0, -24.0) if reduced_motion else Vector2(18.0 + _dragonfly_elapsed * 1.8, -24.0 + sin(_dragonfly_elapsed * 5.0) * 2.2))
		_dragonfly.modulate.a = 1.0 if reduced_motion else clampf((_dragonfly_duration - _dragonfly_elapsed) / 0.4, 0.0, 1.0)


func _update_fence_paint(reduced_motion: bool) -> void:
	if _fence_duration > 0.0:
		# Alternate complete painted leaf poses, never deform a single cel.
		_fence_grass.texture = FENCE_GRASS_BENT if reduced_motion or fmod(_fence_elapsed, 0.64) >= 0.32 else FENCE_GRASS_STILL
		_fence_grass.position = _fence_anchor + Vector2(0.0, -13.0)
		_fence_grass.modulate.a = 1.0 if reduced_motion else clampf((_fence_duration - _fence_elapsed) / 0.42, 0.0, 1.0)
	if _feather_duration > 0.0:
		# A single intact watercolor feather drifts; low-motion keeps it still.
		_feather.texture = SHED_FEATHER
		_feather.position = _feather_anchor + (Vector2.ZERO if reduced_motion else Vector2(-_feather_elapsed * 8.0, _feather_elapsed * 4.0 + sin(_feather_elapsed * 4.3) * 2.0))
		_feather.modulate.a = 1.0 if reduced_motion else clampf((_feather_duration - _feather_elapsed) / 0.46, 0.0, 1.0)
