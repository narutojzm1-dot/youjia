class_name FeltActor
extends Node2D

signal proximity_changed(actor: FeltActor)

const SPIT_TEXTURE := preload("res://assets/holiday/fx/felt_spit.png")

var actor_id := ""
var species := ""
var display_name_key := ""
var wander_rect := Rect2()
var preferred_zone := "pasture"
var speed := 28.0
var facing := 1.0
var current_zone := "pasture"
var current_expression := "idle"
var nearby_ids: Dictionary = {}
var state := "wander"
var grazing := false

var _sprite: Sprite2D
var _textures: Dictionary = {}
var _target := Vector2.ZERO
var _idle_time := 0.0
var _breath := 0.0
var _hold_expression := 0.0
var _spit: CPUParticles2D
var _lead_target: Node2D
var _base_scale := 1.0


func setup(config: Dictionary) -> void:
	actor_id = str(config.get("id", ""))
	species = str(config.get("species", actor_id))
	display_name_key = str(config.get("name_key", "actor.%s" % species))
	position = config.get("position", Vector2.ZERO)
	wander_rect = config.get("wander", Rect2(position - Vector2(40, 20), Vector2(80, 40)))
	preferred_zone = str(config.get("zone", "pasture"))
	speed = float(config.get("speed", 28.0))
	_base_scale = float(config.get("scale", 1.0))
	z_index = 4
	_textures = config.get("textures", {})
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.centered = true
	_sprite.offset = Vector2(0, -8)
	add_child(_sprite)
	set_expression("idle")
	scale = Vector2(_base_scale, _base_scale)
	_target = _random_point()
	_build_spit()


func set_expression(expression_id: String) -> void:
	current_expression = expression_id
	var path := str(_textures.get(expression_id, _textures.get("idle", "")))
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	_sprite.texture = load(path) as Texture2D


func hold_expression(expression_id: String, seconds: float) -> void:
	set_expression(expression_id)
	_hold_expression = maxf(_hold_expression, seconds)


func spit() -> void:
	if _spit == null:
		return
	var density := float(TuningStore.get_value("environment.particles.density", 0.4))
	if density <= 0.0:
		return
	_spit.amount = clampi(roundi(6.0 * density), 1, 18)
	_spit.restart()
	_spit.emitting = true


func begin_lead(target: Node2D) -> void:
	state = "lead"
	_lead_target = target


func end_lead() -> void:
	state = "wander"
	_lead_target = null
	_target = _random_point()


func nudge_toward(point: Vector2) -> void:
	state = "wander"
	_target = point + Vector2(randf_range(-18.0, 18.0), randf_range(-10.0, 10.0))


func is_near(other: FeltActor, radius: float = 92.0) -> bool:
	return other != null and other != self and position.distance_to(other.position) <= radius


func tick(delta: float, world_size: Vector2) -> void:
	_breath += delta
	var reduced := bool(TuningStore.get_value("ui.reduced_motion", false))
	var breath := 1.0
	if not reduced:
		breath = 1.0 + sin(_breath * 1.6) * 0.018
		if current_expression == "annoyed":
			breath = 1.0 + sin(_breath * 3.4) * 0.012
		elif current_expression == "happy":
			breath = 1.0 + sin(_breath * 1.1) * 0.022
	var visual := _base_scale * float(get_meta("visual_scale", 1.0))
	scale = Vector2(visual * facing, visual * breath)
	if _hold_expression > 0.0:
		_hold_expression -= delta
	var motion := Vector2.ZERO
	match state:
		"lead":
			if _lead_target != null:
				var desired: Vector2 = _lead_target.position + Vector2(-70.0 * signf(facing if facing != 0.0 else 1.0), 8.0)
				motion = desired - position
		"graze":
			_idle_time -= delta
			grazing = true
			if _idle_time <= 0.0:
				state = "wander"
				grazing = false
				_target = _random_point()
		_:
			grazing = false
			motion = _target - position
			if motion.length() < 6.0:
				if randf() < 0.45:
					state = "graze"
					_idle_time = randf_range(2.2, 6.0)
				else:
					_target = _random_point()
	if motion.length() > 1.0:
		var step := motion.limit_length(speed * delta)
		position += step
		if absf(step.x) > 0.15:
			facing = 1.0 if step.x >= 0.0 else -1.0
	position.x = clampf(position.x, 48.0, world_size.x - 48.0)
	position.y = clampf(position.y, 220.0, world_size.y - 48.0)
	z_index = 4 + int(position.y / 8.0)


func _random_point() -> Vector2:
	return Vector2(
		randf_range(wander_rect.position.x, wander_rect.end.x),
		randf_range(wander_rect.position.y, wander_rect.end.y)
	)


func _build_spit() -> void:
	_spit = CPUParticles2D.new()
	_spit.texture = SPIT_TEXTURE
	_spit.one_shot = true
	_spit.emitting = false
	_spit.amount = 6
	_spit.lifetime = 0.7
	_spit.explosiveness = 0.86
	_spit.direction = Vector2(1, -0.2)
	_spit.spread = 18.0
	_spit.gravity = Vector2(0, 90)
	_spit.initial_velocity_min = 70.0
	_spit.initial_velocity_max = 110.0
	_spit.scale_amount_min = 0.45
	_spit.scale_amount_max = 0.8
	_spit.position = Vector2(28, -42)
	_spit.z_index = 20
	add_child(_spit)
