class_name Vacationer
extends Node2D

const TEXTURE := preload("res://assets/holiday/characters/player.png")
const GRASS := preload("res://assets/holiday/fx/grass_bundle.png")
# 原图按近景画的，缩进院子全景里才像站在草地上的人。
const DISPLAY_SCALE := 0.4

var carrying_grass := false
var player_state := "idle"
var facing := 1.0
var just_fed_seconds := 0.0
var leading := false
# 当前落点的远近。越远越小，和画的透视一起用。
var picture_depth := 1.0

var _sprite: Sprite2D
var _grass: Sprite2D
var _velocity := Vector2.ZERO
var _idle_timer := 0.0
var _step_phase := 0.0
var walk_ground: PackedVector2Array = PackedVector2Array()
var avoid_pond := false


func setup(start: Vector2) -> void:
	position = start
	z_index = 8
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.centered = true
	# 锚到脚底，和动物同一套站位。
	_sprite.offset = Vector2(0, -TEXTURE.get_height() * 0.5)
	add_child(_sprite)
	_grass = Sprite2D.new()
	_grass.texture = GRASS
	_grass.visible = false
	_grass.position = Vector2(18, -28)
	_grass.scale = Vector2(0.55, 0.55)
	add_child(_grass)


func tick(delta: float, input_vector: Vector2, world_size: Vector2) -> void:
	var depth := YardGround.depth_at(position.y)
	picture_depth = depth
	var speed := float(TuningStore.get_value("player.move.max_speed", 96.0)) * depth
	if leading:
		speed *= float(TuningStore.get_value("player.lead.speed_multiplier", 0.72))
	var desired := input_vector.limit_length(1.0) * speed
	# 起步和停步有一点惯性，不像在画上被拖动。
	_velocity = _velocity.lerp(desired, 1.0 - exp(-delta * 7.5))
	var moving := _velocity.length() > 6.0
	if moving:
		var before := position
		var step := _velocity * delta
		if walk_ground.is_empty():
			position += step
			position.x = clampf(position.x, 40.0, world_size.x - 40.0)
			# 上半幅是山和屋檐，人只在草坪和池边走。
			position.y = clampf(position.y, 390.0, world_size.y - 36.0)
		else:
			position = YardGround.move_inside(position, step, walk_ground, avoid_pond)
		var moved := position - before
		if absf(moved.x) < 0.2:
			_velocity.x = 0.0
		if absf(moved.y) < 0.2:
			_velocity.y = 0.0
		if absf(moved.x) > 0.12:
			facing = 1.0 if moved.x >= 0.0 else -1.0
		player_state = "walking"
		_idle_timer = 0.0
		_step_phase += delta * 8.6
		_sprite.position.y = -absf(sin(_step_phase * PI)) * 3.6 * depth
	else:
		_idle_timer += delta
		player_state = "idle" if _idle_timer < 2.4 else "watching"
		_sprite.position.y = lerpf(_sprite.position.y, 0.0, 1.0 - exp(-delta * 8.0))
	if just_fed_seconds > 0.0:
		just_fed_seconds -= delta
		if just_fed_seconds <= 0.0 and player_state != "walking":
			player_state = "idle"
	var visual := float(TuningStore.get_value("player.visual.scale", 1.0)) * DISPLAY_SCALE * depth
	var squash := 1.0 if not moving else 1.0 - 0.045 * absf(sin(_step_phase * PI))
	_sprite.scale = Vector2(facing * visual, visual * squash)
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
