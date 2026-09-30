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
# 画中站位。posed 时不再沿矩形游荡，只在落点上呼吸。
var posed := false
var pose_point := Vector2.ZERO
# 各自的地面。空多边形表示还没绑地，沿用原来的矩形夹取。
var walk_ground: PackedVector2Array = PackedVector2Array()
var avoid_pond := false
var use_ellipse := false
var ellipse_center := Vector2.ZERO
var ellipse_radius := Vector2.ZERO
var _step_phase := 0.0
var _stuck := 0.0


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
	_anchor_feet()


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


func set_pose(point: Vector2, next_scale: float, face: float) -> void:
	posed = true
	pose_point = point
	_base_scale = next_scale
	state = "pose"
	facing = face if face != 0.0 else facing
	position = point


func begin_lead(target: Node2D) -> void:
	posed = false
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
	var visual_scale := float(get_meta("visual_scale", 1.0))
	if _hold_expression > 0.0:
		_hold_expression -= delta
		# 表情只停留一小会儿，过后回到平时的脸，避免第一张表情黏住不放。
		if _hold_expression <= 0.0:
			_hold_expression = 0.0
			set_expression("idle")
	# 活的画：脚钉在落点上。鸭子只在水面轻轻起伏，不横着滑过院子。
	if posed and state == "pose":
		var bob := 0.0
		if species == "duck" and not reduced:
			bob = sin(_breath * 1.4) * 2.0
		position = pose_point + Vector2(0, bob)
		var depth_now := YardGround.depth_at(position.y)
		var visual := _base_scale * visual_scale * depth_now
		scale = Vector2(visual * facing, visual * breath)
		z_index = 4 + int(position.y / 8.0)
		return
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
		var depth := YardGround.depth_at(position.y)
		var ease := clampf(motion.length() / 36.0, 0.42, 1.0)
		var step := motion.limit_length(speed * depth * ease * delta)
		var before := position
		if walk_ground.is_empty() and not use_ellipse:
			position += step
			position.x = clampf(position.x, 48.0, world_size.x - 48.0)
			# 上半幅是山脉和屋顶，动物留在草坪、池边和羊圈。
			position.y = clampf(position.y, 400.0, world_size.y - 56.0)
		else:
			position = _move_on_own_ground(step)
		if position.distance_to(before) < 0.35:
			_stuck += delta
			if _stuck > 0.65:
				_target = _random_point()
				_stuck = 0.0
		else:
			_stuck = 0.0
		if absf(position.x - before.x) > 0.12:
			facing = 1.0 if position.x >= before.x else -1.0
		if not reduced:
			_step_phase += delta * 8.2
			# 抬脚留在贴图上，脚的逻辑坐标还在地面，影子不跟着跳。
			_sprite.position.y = -absf(sin(_step_phase * PI)) * 3.4 * depth
	else:
		_stuck = 0.0
		_sprite.position.y = lerpf(_sprite.position.y, 0.0, 1.0 - exp(-delta * 8.0))
	var depth_now := YardGround.depth_at(position.y)
	var visual := _base_scale * visual_scale * depth_now
	var squash := 1.0
	if motion.length() > 1.0 and not reduced:
		squash = 1.0 - 0.04 * absf(sin(_step_phase * PI))
	scale = Vector2(visual * facing, visual * breath * squash)
	z_index = 4 + int(position.y / 8.0)


func _anchor_feet() -> void:
	if _sprite == null or _sprite.texture == null:
		return
	# 贴图默认以中心为锚点，脚会悬在逻辑坐标上方。收到脚底，影子和站位才对齐院子。
	_sprite.offset = Vector2(0, -_sprite.texture.get_height() * 0.5)


func _random_point() -> Vector2:
	if use_ellipse:
		var angle := randf() * TAU
		var radius := sqrt(randf())
		return ellipse_center + Vector2(cos(angle) * ellipse_radius.x * radius, sin(angle) * ellipse_radius.y * radius)
	for _try: int in 16:
		var point := Vector2(
			randf_range(wander_rect.position.x, wander_rect.end.x),
			randf_range(wander_rect.position.y, wander_rect.end.y)
		)
		if _stands_on(point):
			return point
	if not walk_ground.is_empty():
		return walk_ground[0]
	return wander_rect.get_center()


func adopt_ground(poly: PackedVector2Array, hole_pond: bool) -> void:
	walk_ground = poly
	avoid_pond = hole_pond
	use_ellipse = false
	if not _stands_on(position):
		position = _random_point()
	_target = _random_point()


func adopt_ellipse(center: Vector2, radius: Vector2) -> void:
	use_ellipse = true
	ellipse_center = center
	ellipse_radius = radius
	avoid_pond = false
	if not _stands_on(position):
		position = center
	_target = _random_point()


func _stands_on(point: Vector2) -> bool:
	if use_ellipse:
		return YardGround.in_ellipse(point, ellipse_center, ellipse_radius)
	if walk_ground.is_empty():
		return true
	return YardGround.allows(point, walk_ground, avoid_pond)


func _move_on_own_ground(step: Vector2) -> Vector2:
	if use_ellipse:
		var next := position + step
		if YardGround.in_ellipse(next, ellipse_center, ellipse_radius):
			return next
		var along_x := Vector2(next.x, position.y)
		if YardGround.in_ellipse(along_x, ellipse_center, ellipse_radius):
			return along_x
		var along_y := Vector2(position.x, next.y)
		if YardGround.in_ellipse(along_y, ellipse_center, ellipse_radius):
			return along_y
		return position
	return YardGround.move_inside(position, step, walk_ground, avoid_pond)


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
