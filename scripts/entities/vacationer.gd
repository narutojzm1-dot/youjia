class_name Vacationer
extends Node2D

const TEXTURE := preload("res://assets/holiday/characters/player.png")
const GRASS := preload("res://assets/holiday/fx/grass_bundle.png")

var carrying_grass := false
var player_state := "idle"
var facing := 1.0
var just_fed_seconds := 0.0
var leading := false

var _sprite: Sprite2D
var _grass: Sprite2D
var _velocity := Vector2.ZERO
var _idle_timer := 0.0


func setup(start: Vector2) -> void:
	position = start
	z_index = 8
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.centered = true
	_sprite.offset = Vector2(0, -6)
	add_child(_sprite)
	_grass = Sprite2D.new()
	_grass.texture = GRASS
	_grass.visible = false
	_grass.position = Vector2(18, -28)
	_grass.scale = Vector2(0.55, 0.55)
	add_child(_grass)


func tick(delta: float, input_vector: Vector2, world_size: Vector2) -> void:
	var speed := float(TuningStore.get_value("player.move.max_speed", 96.0))
	if leading:
		speed *= float(TuningStore.get_value("player.lead.speed_multiplier", 0.72))
	_velocity = input_vector.limit_length(1.0) * speed
	if _velocity.length() > 4.0:
		position += _velocity * delta
		facing = 1.0 if _velocity.x >= 0.0 else -1.0
		player_state = "walking"
		_idle_timer = 0.0
	else:
		_idle_timer += delta
		player_state = "idle" if _idle_timer < 2.4 else "watching"
	if just_fed_seconds > 0.0:
		just_fed_seconds -= delta
		if just_fed_seconds <= 0.0 and player_state != "walking":
			player_state = "idle"
	position.x = clampf(position.x, 40.0, world_size.x - 40.0)
	position.y = clampf(position.y, 250.0, world_size.y - 36.0)
	var visual := float(TuningStore.get_value("player.visual.scale", 1.0))
	_sprite.scale = Vector2(facing * visual, visual)
	_grass.visible = carrying_grass
	_grass.position.x = 18.0 * facing
	z_index = 8 + int(position.y / 8.0)


func pick_grass() -> void:
	carrying_grass = true


func consume_grass() -> bool:
	if not carrying_grass:
		return false
	carrying_grass = false
	just_fed_seconds = 6.0
	player_state = "just_fed"
	return true


func snapshot_state() -> String:
	if just_fed_seconds > 0.0:
		return "just_fed"
	if leading:
		return "leading"
	return player_state
