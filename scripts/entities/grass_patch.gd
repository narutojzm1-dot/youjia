class_name GrassPatch
extends Node2D

const Art := preload("res://scripts/entities/grass_art.gd")
const PICKUP_SECONDS := 0.42
const REGROW_SECONDS := 14.0
const CLIPPED_SECONDS := 1.2
var growth: Array[float] = [1.0, 1.0]
var _clipped: Array[float] = [0.0, 0.0]
var _roots: Array[Sprite2D] = []
var _stubble: Array[Sprite2D] = []
var _loose: Sprite2D
var _carrier: Node2D
var _transfer_left := 0.0
var _transfer_start := Vector2.ZERO
var _transfer_revision := -1
var _harvest_count := 0

func setup(point: Vector2) -> void:
	position = point
	z_index = roundi(point.y)
	for index: int in 2:
		var width := 18.0 if index == 0 else 16.0
		var origin := Vector2(-10, 0) if index == 0 else Vector2(10, -3)
		var clipped := Art.rooted_sprite(Art.STUBBLE, width * Art.STUBBLE.size.x / Art.ROOTED.size.x)
		clipped.position = origin
		add_child(clipped)
		_stubble.append(clipped)
		var rooted := Art.rooted_sprite(Art.ROOTED, width)
		rooted.position = origin
		add_child(rooted)
		_roots.append(rooted)
	_loose = Sprite2D.new()
	Art.configure_bundle(_loose)
	_loose.visible = false
	_loose.z_as_relative = false
	add_child(_loose)
	_update_roots()

func harvest(player: Node2D, committed: bool = false) -> bool:
	if not is_instance_valid(player) or (player.carrying_grass and not committed):
		return false
	var index := _harvest_count % 2
	if growth[1 - index] > growth[index]:
		index = 1 - index
	_harvest_count += 1
	growth[index] = 0.0
	_clipped[index] = CLIPPED_SECONDS
	_update_roots()
	var reduced := bool(TuningStore.get_value("ui.reduced_motion", false))
	# Inventory is immediate. This short animation never adds a wait or click.
	player.pick_grass(0.0 if reduced else PICKUP_SECONDS)
	_carrier = player
	_transfer_revision = player.grass_visual_revision
	_transfer_left = 0.0 if reduced else PICKUP_SECONDS
	_transfer_start = global_position + _roots[index].position + Vector2(-7, -5)
	_loose.visible = not reduced
	if not reduced:
		_update_transfer()
	return true

func tick(delta: float) -> void:
	for index: int in 2:
		_clipped[index] = maxf(0.0, _clipped[index] - delta)
		if _clipped[index] <= 0.0:
			growth[index] = minf(1.0, growth[index] + delta / REGROW_SECONDS)
	_update_roots()
	if _transfer_left <= 0.0:
		return
	# Feeding or a newer pickup invalidates this exact bundle. Never resurrect it.
	if not is_instance_valid(_carrier) or not _carrier.carrying_grass or _carrier.grass_visual_revision != _transfer_revision:
		_cancel_transfer()
		return
	if bool(TuningStore.get_value("ui.reduced_motion", false)):
		_cancel_transfer()
		return
	_transfer_left = maxf(0.0, _transfer_left - delta)
	_update_transfer()
	if _transfer_left <= 0.0:
		_cancel_transfer()

func _update_roots() -> void:
	for index: int in _roots.size():
		var amount := smoothstep(0.0, 1.0, growth[index])
		_roots[index].modulate.a = amount
		_stubble[index].modulate.a = 1.0 - amount
		# An unclipped neighboring tuft stays rooted while the selected one grows.
		var width := 18.0 if index == 0 else 16.0
		_roots[index].scale = Vector2.ONE * (width / Art.ROOTED.size.x) * lerpf(0.65, 1.0, amount)

func _update_transfer() -> void:
	if not is_instance_valid(_carrier):
		_cancel_transfer()
		return
	var elapsed := PICKUP_SECONDS - _transfer_left
	var amount := smoothstep(0.0, 1.0, clampf((elapsed - 0.12) / (PICKUP_SECONDS - 0.12), 0.0, 1.0))
	var destination: Vector2 = _carrier.grass_hand_global_position()
	_loose.global_position = _transfer_start.lerp(destination, amount) + Vector2(0, -sin(amount * PI) * 8.0)
	var face: float = _carrier.grass_hand_facing()
	var size: float = _carrier.grass_hand_scale()
	_loose.scale = Vector2(face, 1.0) * lerpf(0.055, size, amount)
	_loose.rotation = lerpf(0.08, Art.HELD_ROTATION * face, amount)
	_loose.z_index = _carrier.z_index + 1

func _cancel_transfer() -> void:
	_transfer_left = 0.0
	_loose.visible = false
	_carrier = null
