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
var daily_routine := false
var _routine_step := 0
var _turn_pause := 0.0

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
var body_radius := Vector2(16,8)
var body_obstacles: Array = []
var food_goal := Vector2.ZERO
var _food_path: Array[Vector2] = []
var _food_repath := 0.0
var _lead_path: Array[Vector2] = []
var _lead_repath := 0.0
var _home_path: Array[Vector2] = []
var _home_repath := 0.0
var use_ellipse := false
var ellipse_center := Vector2.ZERO
var ellipse_radius := Vector2.ZERO
var _step_phase := 0.0
var _stuck := 0.0
var _velocity := Vector2.ZERO
var _gait := GroundedGait.new()
var _rest_breath: RefCounted
var _blink: RefCounted
var _rig: PlantedGait
var _following := false
var _native_facing := 1.0
var _ground_anchor:=Vector2(-1,-1)
var _art_bounds := Rect2()
var _spit_origin:=Vector2(28,-42)
var _particle_art_scale:=1.0
var _base_texture_path:=""
var _face_region:=Rect2()
var _expression_texture: Texture2D
var _ack_cel := ""
var _ack_left := 0.0
# Transient, per-animal response spacing; repeated petting never extends a pose.
var _pet_ack_cooldown := 0.0
var _feed_ack_cooldown := 0.0
var _feed_ack_origin := Vector2.ZERO
var _feed_ack_active := false
var _posture_metadata: Dictionary = {}
var _posture_id := "idle"
var _idle_ground_anchor := Vector2(-1,-1)
var _idle_art_bounds := Rect2()
var _encounter_saved_base_scale := -1.0
var _encounter_saved_position := Vector2.ZERO
var _encounter_saved_facing := 1.0
## 生态闲置扫视：当动物静止且玩家在近旁时，偶尔短暂转向玩家
## _glance_timer > 0 时处于扫视状态；=0 时处于冷却等待
var _glance_timer := 0.0        # 正数=正在扫视中（秒），负数=冷却中
var _glance_saved_facing := 0.0 # 扫视前保存的原始朝向


func setup(config: Dictionary) -> void:
	actor_id = str(config.get("id", ""))
	daily_routine = bool(config.get("daily_routine", false))
	species = str(config.get("species", actor_id))
	body_radius = config.get("body_radius", YardBodies.radius_for(species))
	display_name_key = str(config.get("name_key", "actor.%s" % species))
	position = config.get("position", Vector2.ZERO)
	wander_rect = config.get("wander", Rect2(position - Vector2(40, 20), Vector2(80, 40)))
	preferred_zone = str(config.get("zone", "pasture"))
	speed = float(config.get("speed", 28.0))
	_base_scale = float(config.get("scale", 1.0))
	z_index = 4
	_base_texture_path=str(config.get("base_texture",""))
	_face_region=config.get("face_region",Rect2())
	_ground_anchor=config.get("ground_anchor",Vector2(-1,-1))
	_art_bounds=config.get("art_bounds",Rect2())
	_idle_ground_anchor=_ground_anchor
	_idle_art_bounds=_art_bounds
	_posture_metadata=config.get("posture_metadata",{})
	_spit_origin=config.get("spit_origin",Vector2(28,-42))
	_particle_art_scale=float(config.get("particle_art_scale",1.0))
	_textures = config.get("textures", {})
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.centered = true
	_sprite.offset = Vector2(0, -8)
	add_child(_sprite)
	set_expression("idle")
	_native_facing = float(config.get("native_facing", 1.0))
	_gait.setup(_sprite, float(config.get("leg_start",0.74 if species in ["goose", "duck"] else 0.68)))
	if species in ["cow", "horse", "llama", "goose"] or actor_id in ["sheep_a", "sheep_b"]:
		_blink = preload("res://scripts/entities/painted_blink.gd").new()
		_blink.bind(_gait._material, actor_id if species == "sheep" else species)
	_rest_breath = preload("res://scripts/entities/painted_rest_breath.gd").new()
	_rest_breath.bind(_gait._material, actor_id)
	_apply_face_override()
	if species == "llama" and bool(config.get("experimental_planted_gait", false)):
		enable_experimental_planted_gait()
	_breath = randf_range(0.0, TAU)
	_gait.phase = randf_range(0.0, TAU)
	scale = Vector2(_base_scale, _base_scale)
	_target = _random_point()
	_build_spit()
	# 给每只动物一个随机的初始扫视冷却，避免所有动物同时转头
	_glance_timer = -randf_range(8.0, 22.0)
	if daily_routine:
		_routine_step = int(abs(actor_id.hash()) % 4)
		_start_rest()
		_idle_time *= randf_range(0.35, 1.0)
	elif species != "duck":
		state = "graze"
		_idle_time = randf_range(5.0,12.0)
	_refresh_painted_posture()


func enable_experimental_planted_gait() -> void:
	# Neutral-pose prototype only. Its limb material is not yet a visual match,
	# so the shipped yard keeps the first-pass llama until art review approves it.
	if species != "llama" or _rig != null or not _base_texture_path.is_empty():
		return
	_rig=PlantedGait.new()
	_sprite.add_child(_rig)
	_rig.setup(_sprite,"llama")


func set_expression(expression_id: String) -> void:
	if _rest_breath != null:
		_rest_breath.cancel()
	if _blink != null:
		_blink.cancel()
	current_expression = expression_id
	var posture_key := _painted_posture()
	var texture_key := posture_key if posture_key != "idle" else expression_id
	var path := str(_textures.get(texture_key, _textures.get("idle", "")))
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	_expression_texture=load(path) as Texture2D
	# Face-only expression swaps use the standing body; a whole-body resting
	# painting must replace that body as well as its face.
	_sprite.texture=load(_base_texture_path) as Texture2D if not _base_texture_path.is_empty() and posture_key == "idle" else _expression_texture
	if _posture_metadata.has(texture_key):
		_posture_id = texture_key
		var posture: Dictionary = _posture_metadata.get(texture_key,{})
		var anchor: Array=posture.ground_anchor
		var bounds: Array=posture.alpha_bbox
		if anchor.size() >= 2 and bounds.size() >= 4:
			_ground_anchor=Vector2(float(anchor[0]),float(anchor[1]))
			_art_bounds=Rect2(float(bounds[0]),float(bounds[1]),float(bounds[2]),float(bounds[3]))
	elif _posture_id != "idle":
		_posture_id = "idle"
		_ground_anchor=_idle_ground_anchor
		_art_bounds=_idle_art_bounds
	_apply_face_override()
	_anchor_feet()
	if _sprite != null:
		_sprite.scale.x = _paint_facing()


func _paint_facing() -> float:
	# A rest painting can face the other way from the standing cel. Use that cel's
	# own facing so a left-facing sheep is not mirrored backwards while resting.
	if _posture_metadata.has(_posture_id):
		var posted: Dictionary = _posture_metadata[_posture_id]
		if posted.has("native_facing"):
			return float(posted["native_facing"])
	return _native_facing


func show_painted_ack(cel: String, seconds: float) -> void:
	if posed or seconds <= 0.0 or not _textures.has(cel):
		return
	if _blink != null:
		_blink.cancel()
	_feed_ack_active = false
	_ack_cel = cel
	_ack_left = seconds
	_velocity = Vector2.ZERO
	_gait.weight = 0.0
	_refresh_painted_posture()


func show_ground_bite(cel: String, food: Vector2) -> void:
	if posed or not _textures.has(cel): return
	# Stop the final approach before the actor tick; otherwise its residual
	# food path immediately clears the stationary whole-body bite cel.
	if state == "food":
		food_goal = position
		_food_path.clear()
	if absf(food.x - position.x) > 2.0:
		facing = signf(food.x - position.x)
		_gait.face = facing
		_gait._turning = false
		_gait._next_face = facing
		_gait.turn_width = 1.0
		scale.x = absf(scale.x) * facing
	show_painted_ack(cel, 0.2)


func acknowledge_pet(observer_position: Vector2) -> void:
	if posed or _pet_ack_cooldown > 0.0:
		return
	var cel := str({"cow": "glance", "horse": "idle", "sheep": "attend", "dog": "idle"}.get(species, ""))
	if cel.is_empty() or not _textures.has(cel):
		return
	# Unreviewed tail/shake size changes are not reused as interaction poses.
	if absf(observer_position.x - position.x) > 2.0:
		facing = signf(observer_position.x - position.x)
		_gait.face = facing
		_gait._turning = false
		_gait._next_face = facing
		_gait.turn_width = 1.0
		scale.x = absf(scale.x) * facing
	_glance_timer = -5.0
	show_painted_ack(cel, 2.2)
	# Leave a real interval for normal wandering even under continuous input.
	_pet_ack_cooldown = 5.0


# Acknowledges a successful toss by noticing the player, not a feeding mouth pose.
func acknowledge_feed(observer_position: Vector2) -> bool:
	var cel := str({"duck": "attend", "goose": "calm"}.get(species, ""))
	if cel.is_empty() or posed or _feed_ack_cooldown > 0.0 or not _textures.has(cel):
		return false
	if absf(observer_position.x - position.x) > 2.0:
		facing = signf(observer_position.x - position.x)
		_gait.face = facing
		_gait._turning = false
		_gait._next_face = facing
		_gait.turn_width = 1.0
		scale.x = absf(scale.x) * facing
	_glance_timer = -5.0
	_feed_ack_origin = position
	show_painted_ack(cel, 2.2)
	_feed_ack_active = true
	_feed_ack_cooldown = 5.0
	return true


func _exit_tree() -> void:
	_ack_cel = ""
	_feed_ack_active = false
	_ack_left = 0.0
	_feed_ack_cooldown = 0.0


func _painted_posture() -> String:
	if posed or _velocity.length() > 0.3 or _gait.weight > 0.08:
		return "idle"
	if _ack_cel != "" and _textures.has(_ack_cel):
		return _ack_cel
	if has_meta("shelter_rest") and _textures.has("shelter_rest"):
		return "shelter_rest"
	if species == "goose":
		if state == "rest":
			return "rest"
		if state == "graze":
			return "calm"
		return "idle"
	if state != "rest":
		return "idle"
	if species == "duck" and _textures.has("preen"):
		return "preen"
	if species == "horse" and _textures.has("tail"):
		return "tail"
	if species == "cow" and _textures.has("chew"):
		return "chew"
	# Each sheep keeps its own standing body at rest. The shared shake cel changes
	# both identity and silhouette; natural idle motion now lives in the eye patch.
	return "idle"


func _refresh_painted_posture() -> void:
	if posed:
		return
	if _painted_posture() != _posture_id:
		set_expression(current_expression)


func hold_expression(expression_id: String, seconds: float) -> void:
	set_expression(expression_id)
	_hold_expression = maxf(_hold_expression, seconds)


func spit(target: Vector2 = Vector2.INF) -> void:
	if _spit == null or target == Vector2.INF:
		return
	var density := float(TuningStore.get_value("environment.particles.density", 0.4))
	if density <= 0.0:
		return
	# Face the actual goose first; use a short world-space arc from the mouth.
	if absf(target.x-global_position.x) > 2.0:
		facing = signf(target.x-global_position.x)
		_gait.face = facing
		_gait._turning = false
		_gait._next_face = facing
		_gait.turn_width = 1.0
		scale.x = absf(scale.x)*facing
	var mouth := to_global(_spit_origin)
	_spit.top_level = true
	_spit.global_transform = Transform2D(0.0, mouth)
	var flight := 0.42
	var gravity := Vector2(0,260)
	var velocity := (target-mouth-0.5*gravity*flight*flight)/flight
	_spit.direction = velocity.normalized()
	_spit.gravity = gravity
	_spit.initial_velocity_min = velocity.length()
	_spit.initial_velocity_max = velocity.length()*1.03
	_spit.scale_amount_min = 0.07
	_spit.scale_amount_max = 0.11
	_spit.lifetime = flight
	_spit.spread = 3.0
	_spit.amount = clampi(roundi(4.0*density),1,4)
	state = "graze"
	_idle_time = maxf(_idle_time,1.2)
	_velocity = Vector2.ZERO
	_spit.restart()
	_spit.emitting = true


func set_pose(point: Vector2, next_scale: float, face: float) -> void:
	posed = true
	_ack_cel = ""
	_feed_ack_active = false
	_ack_left = 0.0
	pose_point = point
	_base_scale = next_scale
	state = "pose"
	# The staged photo and riding close-up must use the standing cel, not a rest
	# painting whose anchor would float or be captured by mistake.
	set_expression(current_expression)
	facing = face if face != 0.0 else facing
	position = point
	if _rig != null:
		_rig.reset_contacts()


func set_encounter_pose(point: Vector2, next_scale: float, face: float) -> void:
	if _encounter_saved_base_scale < 0.0:
		_encounter_saved_base_scale = _base_scale
		_encounter_saved_position = position
		_encounter_saved_facing = facing
	set_pose(point, next_scale, face)


func show_goose_encounter_cel(cel: String) -> void:
	if species != "goose" or not _textures.has(cel) or _sprite == null:
		return
	if _blink != null:
		_blink.cancel()
	_posture_id = cel
	_sprite.texture = load(str(_textures[cel])) as Texture2D
	var posture: Dictionary = _posture_metadata.get(cel, {})
	if posture.is_empty():
		_ground_anchor = _idle_ground_anchor
		_art_bounds = _idle_art_bounds
	else:
		var anchor: Array = posture.ground_anchor
		var bounds: Array = posture.alpha_bbox
		_ground_anchor = Vector2(float(anchor[0]), float(anchor[1]))
		_art_bounds = Rect2(float(bounds[0]), float(bounds[1]), float(bounds[2]), float(bounds[3]))
	_anchor_feet()


func release_encounter_pose() -> void:
	if _encounter_saved_base_scale >= 0.0:
		_base_scale = _encounter_saved_base_scale
		position = _encounter_saved_position
		pose_point = position
		facing = _encounter_saved_facing
		z_index = roundi(position.y)
		_encounter_saved_base_scale = -1.0
	posed = false
	_following = false
	_lead_target = null
	_lead_path.clear()
	state = "graze"
	grazing = false
	_idle_time = randf_range(2.0, 5.0)
	_target = _random_point()
	_velocity = Vector2.ZERO
	_refresh_painted_posture()


func begin_lead(target: Node2D) -> void:
	if state != "lead":
		_following = false
	posed = false
	state = "lead"
	_lead_target = target


func end_lead() -> void:
	state = "wander"
	_following = false
	_lead_target = null
	_lead_path.clear()
	_target = _random_point()
	if daily_routine:
		_start_rest()


func nudge_toward(point: Vector2) -> void:
	if daily_routine and species != "llama" and not wander_rect.has_point(point):
		return
	if not _stands_on(point):
		return
	state = "wander"
	_target = point


func is_near(other: FeltActor, radius: float = 92.0) -> bool:
	return other != null and other != self and position.distance_to(other.position) <= radius


## 由 YardWorld.tick() 每帧调用，传入玩家位置，更新扫视状态
## 只对可抚摸动物（非草泥马、鸭、大鹅）生效
func tick_glance(delta: float, player_pos: Vector2) -> void:
	# 只有静止状态（graze/rest/pose）才做扫视，走动时不强行转头
	if state not in ["graze", "rest", "pose"]:
		# 若正在扫视途中动物开始走动，立即结束扫视
		if _glance_timer > 0.0:
			# Movement already chose its heading in tick(). Do not overwrite it
			# with the heading saved before the animal looked at the player.
			_glance_timer = -randf_range(12.0, 20.0)
		return
	if _glance_timer > 0.0:
		# 正在扫视：倒计时
		_glance_timer -= delta
		if _glance_timer <= 0.0:
			# 扫视结束，恢复原始朝向
			facing = _glance_saved_facing
			# 进入冷却
			_glance_timer = -randf_range(14.0, 26.0)
	else:
		# 冷却中：等候下一次扫视机会
		_glance_timer += delta
		if _glance_timer >= 0.0:
			# 冷却结束：检查玩家是否在附近
			var dist := position.distance_to(player_pos)
			# A nearly vertical observer provides no meaningful left/right turn.
			# signf(0) would collapse the entire actor's horizontal scale.
			if dist < 180.0 and dist > 20.0 and absf(player_pos.x - position.x) > 3.0:
				# 概率触发扫视（距离越近越容易触发）
				var chance := lerpf(0.35, 0.80, 1.0 - dist / 180.0)
				if randf() < chance:
					_glance_saved_facing = facing
					# 短暂面向玩家方向
					facing = signf(player_pos.x - position.x)
					_glance_timer = randf_range(1.2, 2.8)
				else:
					# 本次不扫，再等一会儿
					_glance_timer = -randf_range(10.0, 18.0)
			else:
				# 玩家不在附近，继续冷却
				_glance_timer = -randf_range(8.0, 15.0)


func tick(delta: float, world_size: Vector2) -> void:
	_feed_ack_cooldown = maxf(0.0, _feed_ack_cooldown - delta)
	if _feed_ack_active and (posed or state == "lead" or _velocity.length() > 0.3 or not position.is_equal_approx(_feed_ack_origin)):
		_ack_cel = ""
		_feed_ack_active = false
		_ack_left = 0.0
		_refresh_painted_posture()
	_pet_ack_cooldown = maxf(0.0, _pet_ack_cooldown - delta)
	_breath += delta
	_lead_repath = maxf(0.0, _lead_repath-delta)
	var reduced := bool(TuningStore.get_value("ui.reduced_motion", false))
	var breath := 1.0
	if not reduced:
		breath = 1.0 + sin(_breath * 1.6) * 0.003
		if _base_texture_path.is_empty() and current_expression == "annoyed":
			breath = 1.0 + sin(_breath * 3.4) * 0.012
		elif _base_texture_path.is_empty() and current_expression == "happy":
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
		if _rest_breath != null:
			_rest_breath.cancel()
		if _blink != null:
			_blink.cancel()
		var bob := 0.0
		if species == "duck" and not reduced:
			bob = sin(_breath * 1.4) * 2.0
		position = pose_point + Vector2(0, bob)
		var depth_now := YardGround.depth_at(position.y)
		var visual := _base_scale * visual_scale * depth_now
		scale = Vector2(visual * facing, visual * breath)
		_sprite.scale.x = _native_facing
		_gait.weight = 0.0
		_gait.face = facing
		_gait.apply(_sprite, delta, facing, reduced)
		_velocity = Vector2.ZERO
		if _rig != null:
			_rig.tick(delta, Vector2.ZERO, depth_now, reduced)
		z_index = roundi(position.y)
		return
	var motion := Vector2.ZERO
	var depth := YardGround.depth_at(position.y)
	var desired := Vector2.ZERO
	match state:
		"food":
			grazing = false
			motion = food_goal - position
			_food_repath -= delta
			if use_ellipse:
				desired = motion.normalized() * minf(speed * depth, motion.length() * 1.8)
			else:
				if _food_repath <= 0.0:
					_food_path = YardBodies.route(position, food_goal, body_radius * depth, body_obstacles, walk_ground, avoid_pond)
					_food_repath = 0.7
				while not _food_path.is_empty() and position.distance_to(_food_path[0]) < 4.0:
					_food_path.pop_front()
				if not _food_path.is_empty():
					desired = position.direction_to(_food_path[0]) * minf(speed * depth, position.distance_to(_food_path[0]) * 1.8)
		"lead":
			grazing = false
			if is_instance_valid(_lead_target):
				# Follow the person's ground point, not a side chosen by our own
				# facing. That old target jumped 140px every time we turned.
				motion = _lead_target.position - position
				if motion.length() > 78.0 * depth:
					_following = true
				elif motion.length() < 60.0 * depth:
					_following = false
				if _following:
					var follow_multiplier := float(TuningStore.get_value("enemies.move.speed_multiplier", 1.0))
					var follow_speed := maxf(speed, 84.0 * follow_multiplier) * depth
					var direction := motion.normalized()
					var obstacles: Array = body_obstacles.filter(func(item: Dictionary) -> bool: return str(item.get("id","")) != "player")
					if not YardBodies.clear_segment(position,_lead_target.position,body_radius*depth,obstacles) or not YardGround._clear_segment(position,_lead_target.position):
						if _lead_repath <= 0.0:
							_lead_path = _route_to_leader(depth, obstacles)
							_lead_repath = 0.7
						while not _lead_path.is_empty() and position.distance_to(_lead_path[0]) < 5.0: _lead_path.pop_front()
						if not _lead_path.is_empty(): direction = position.direction_to(_lead_path[0])
						else: direction = Vector2.ZERO
					else:
						_lead_path.clear()
					desired = direction * minf(follow_speed, maxf(0.0, motion.length() - 56.0 * depth) * 2.5)
			else:
				end_lead()
		"graze", "rest":
			if _ack_left <= 0.0:
				_idle_time -= delta
			grazing = state == "graze"
			if _idle_time <= 0.0:
				state = "wander"
				grazing = false
				_target = _random_point()
				if daily_routine:
					_turn_pause = 0.55
		_:
			grazing = false
			motion = _target - position
			if _needs_homeward_walk():
				motion = _homeward_motion(delta)
				desired = motion.normalized() * minf(speed * depth, motion.length() * 1.8)
			elif motion.length() < 5.0:
				# A quiet pause between purposeful walks, rather than a new
				# random destination and a sudden reversal every few seconds.
				state = "graze"
				_idle_time = randf_range(7.0, 14.0)
				if daily_routine:
					_start_rest()
			else:
				desired = motion.normalized() * minf(speed * depth, motion.length() * 1.8)
	# A resident chooses its next direction while planted, then takes a few steps.
	# No reversing in motion or repeated boundary bounces.
	if daily_routine and _turn_pause > 0.0 and state == "wander" and _ack_left <= 0.0:
		_turn_pause -= delta
		desired = Vector2.ZERO
		if absf(motion.x) > 3.0:
			facing = signf(motion.x)
	if _ack_cel != "" and _ack_left > 0.0:
		desired = Vector2.ZERO
	var response := 5.0 if species == "duck" else 7.0
	_velocity = _velocity.lerp(desired, 1.0 - exp(-response * delta))
	if desired.is_zero_approx() and _velocity.length() < 0.3:
		_velocity = Vector2.ZERO
	var step := _velocity * delta
	var before := position
	if walk_ground.is_empty() and not use_ellipse:
		position += step
		position.x = clampf(position.x, 48.0, world_size.x - 48.0)
		position.y = clampf(position.y, 400.0, world_size.y - 56.0)
	else:
		position = _move_on_own_ground(step)
	if not use_ellipse and not body_obstacles.is_empty():
		position = YardBodies.move_inside(before, position-before, body_radius*depth, body_obstacles, walk_ground, avoid_pond)
	var moved := position - before
	var actual_speed := moved.length() / maxf(delta, 0.0001)
	if desired.length() > 2.0 and actual_speed < 1.0:
		_stuck += delta
		if _stuck > 0.65 and state not in ["lead", "food"]:
			_target = _random_point()
			if daily_routine: _start_rest()
			_stuck = 0.0
	else:
		_stuck = 0.0
	if absf(step.x) > 0.00001 and absf(moved.x) < 0.00001:
		_velocity.x = 0.0
	if absf(step.y) > 0.00001 and absf(moved.y) < 0.00001:
		_velocity.y = 0.0
	if absf(moved.x) / maxf(delta, 0.0001) > 2.0:
		facing = signf(moved.x)
	if _ack_left > 0.0:
		_ack_left = maxf(0.0, _ack_left - delta)
	if _ack_cel != "" and (posed or _velocity.length() > 0.3 or _gait.weight > 0.08 or _ack_left <= 0.0):
		_ack_cel = ""
		_feed_ack_active = false
		_ack_left = 0.0
	_refresh_painted_posture()
	var stride := 30.0
	if species in ["cow","horse"]:
		stride = 38.0
	elif species in ["goose", "duck"]:
		stride = 22.0
	_gait.advance(delta, moved, depth, stride)
	_step_phase = _gait.phase
	_gait.apply(_sprite, delta, facing, reduced, species == "duck" and use_ellipse)
	# Painted animal bodies stay rigid; avoid whole-cutout hops and pivot squash.
	if _ground_anchor.x >= 0.0:
		_sprite.position = Vector2.ZERO
		_sprite.rotation = 0.0
		var artwork_width := _sprite.texture.get_width() * _base_scale * visual_scale
		var artwork_height := _sprite.texture.get_height() * _base_scale * visual_scale
		_gait._material.set_shader_parameter("grounded_stride", true)
		_gait._material.set_shader_parameter("stride_uv", stride / maxf(artwork_width, 1.0))
		_gait._material.set_shader_parameter("lift_uv", 2.0 / maxf(artwork_height, 1.0))
		_gait._material.set_shader_parameter("native_walk_face", _native_facing)
		_gait._material.set_shader_parameter("amount", 0.0 if reduced or use_ellipse else minf(_gait.weight * 3.0, 1.0))
	var visual := _base_scale * visual_scale * YardGround.depth_at(position.y)
	# Breathing belongs to resting animals; don't squash a walking silhouette.
	var lying := preload("res://scripts/entities/painted_rest_breath.gd").REGIONS.has(_sprite.texture.resource_path)
	var resting_breath := 1.0 if lying else lerpf(breath, 1.0, _gait.weight)
	if _rest_breath != null:
		_rest_breath.advance(delta, not reduced and not posed and state == "rest" and _ack_cel.is_empty() and _velocity.length() <= 0.3 and _gait.weight <= 0.08, _sprite.texture.resource_path)
	scale = Vector2(visual * _gait.face * (1.0 if _ground_anchor.x >= 0.0 else _gait.turn_width), visual * resting_breath)
	_sprite.scale.x = _paint_facing()
	if _rig != null:
		scale.x = visual * _gait.face
		_sprite.position.y = 0.0
		_sprite.rotation = 0.0
		_rig.tick(delta, moved, depth, reduced)
	if _blink != null:
		if species == "cow":
			var cow_lying: bool = _sprite.texture.resource_path == _blink.COW_REST_SOURCE
			var desired_source: String = _blink.COW_REST_SOURCE if cow_lying else _blink.SOURCE
			if _blink.source_path != desired_source:
				_blink.cancel()
				_blink.bind(_gait._material, "cow_rest" if cow_lying else "cow")
		_blink.advance(delta, not reduced and not posed and state == "rest" and _ack_cel.is_empty() and _velocity.length() <= 0.3 and _gait.weight <= 0.08 and _sprite.texture.resource_path == _blink.source_path)
	z_index = roundi(position.y)


## Road adapters own movement and depth; reuse the same anchored painted gait.
func advance_path(delta: float, moved: Vector2, depth: float, reduced: bool) -> void:
	if _rest_breath != null:
		_rest_breath.cancel()
	if _blink != null:
		_blink.cancel()
	state = "path"
	grazing = false
	if absf(moved.x) > 0.01: facing = signf(moved.x)
	_velocity = moved / maxf(delta, 0.0001)
	var stride := 38.0 if species in ["cow", "horse"] else (22.0 if species == "goose" else 30.0)
	_gait.advance(delta, moved, depth, stride)
	_gait.apply(_sprite, delta, facing, reduced)
	_sprite.position = Vector2.ZERO
	_sprite.rotation = 0.0
	_gait._material.set_shader_parameter("grounded_stride", true)
	_gait._material.set_shader_parameter("stride_uv", stride / maxf(_sprite.texture.get_width() * _base_scale, 1.0))
	_gait._material.set_shader_parameter("lift_uv", 2.0 / maxf(_sprite.texture.get_height() * _base_scale, 1.0))
	_gait._material.set_shader_parameter("native_walk_face", _native_facing)
	_gait._material.set_shader_parameter("amount", 0.0 if reduced else minf(_gait.weight * 3.0, 1.0))
	scale = Vector2(_gait.face, 1.0) * _base_scale * depth
	_sprite.scale.x = _paint_facing()
	z_index = roundi(position.y)


func visual_hit_rect() -> Rect2:
	var bounds := _art_bounds if _art_bounds.has_area() else Rect2(Vector2.ZERO, _sprite.texture.get_size())
	var origin := _sprite.offset - _sprite.texture.get_size() * 0.5
	return get_parent().global_transform.affine_inverse() * _sprite.global_transform * Rect2(origin + bounds.position, bounds.size)


func _anchor_feet() -> void:
	if _sprite == null or _sprite.texture == null:
		return
	# 贴图默认以中心为锚点，脚会悬在逻辑坐标上方。收到脚底，影子和站位才对齐院子。
	if _ground_anchor.x>=0.0:
		_sprite.offset=_sprite.texture.get_size()*0.5-_ground_anchor
	else:
		_sprite.offset = Vector2(0, -_sprite.texture.get_height() * 0.5)


## 脚底锚点到精灵冠顶的世界像素高度（用于 WorldEffectsOverlay 把弧/箭头画在头顶上方）
func marker_crown_lift() -> float:
	var visual := absf(scale.y)
	if visual < 0.01:
		visual = _base_scale * float(get_meta("visual_scale", 1.0)) * YardGround.depth_at(position.y)
	if _ground_anchor.x >= 0.0 and _ground_anchor.y > 0.0:
		return maxf(48.0, _ground_anchor.y * visual)
	if _sprite != null and _sprite.texture != null:
		return maxf(48.0, _sprite.texture.get_height() * visual * 0.92)
	return 64.0


func _start_rest() -> void:
	_routine_step += 1
	# The goose settles every other pause so folded wings and lying down can both
	# be observed naturally; the other species keep their established rhythm.
	state = "rest" if _routine_step % (2 if species == "goose" else 3) == 0 else "graze"
	var durations := {"cow": Vector2(18, 26), "horse": Vector2(16, 23), "sheep": Vector2(13, 21), "goose": Vector2(10, 17), "duck": Vector2(8, 14), "llama": Vector2(6, 11)}
	var span: Vector2 = durations.get(species, Vector2(12, 20))
	_idle_time = randf_range(span.x, span.y)
	if species == "goose":
		_idle_time /= maxf(0.5, float(TuningStore.get_value("enemies.goose.nosiness", 1.0)))
	_turn_pause = 0.0
	# Natural foraging is a quiet painted peck, never a free inventory grant.
	if species == "chicken" and _routine_step % 3 == 1:
		show_painted_ack("peck", 0.9)


func _local_destination() -> Vector2:
	# Nearby reachable feeding spots only. Trying a new heading happens while
	# resting, never by clamping a distant point and sliding along a boundary.
	var distance_span := Vector2(14, 29)
	if species == "llama": distance_span = Vector2(40, 90)
	elif species == "duck": distance_span = Vector2(20, 38)
	for attempt in 32:
		var angle := randf() * TAU
		var point := position + Vector2(cos(angle), sin(angle)*0.42) * randf_range(distance_span.x, distance_span.y)
		if species != "llama" and not use_ellipse and not wander_rect.has_point(point): continue
		if not _stands_on(point): continue
		if not YardBodies.clear_segment(position,point,body_radius*YardGround.depth_at(position.y),body_obstacles): continue
		var reachable := true
		for i in range(1, 9):
			if not _stands_on(position.lerp(point, float(i)/8.0)):
				reachable = false
				break
		if reachable: return point
	return position


func _needs_homeward_walk() -> bool:
	# Llamas may settle wherever released. Swimmers keep their pond ellipse.
	return daily_routine and species != "llama" and not use_ellipse and wander_rect.has_area() and not wander_rect.has_point(position)


func _homeward_motion(delta: float) -> Vector2:
	_home_repath -= delta
	if _home_repath <= 0.0:
		_home_repath = 0.7
		_home_path.clear()
		# Home is an activity area, not a mandatory occupied centre point.
		# Retry clear interior locations when another resident blocks the centre.
		for fraction: Vector2 in [Vector2(0.5, 0.5), Vector2(0.25, 0.5), Vector2(0.75, 0.5), Vector2(0.5, 0.25), Vector2(0.5, 0.75)]:
			var goal := wander_rect.position + wander_rect.size * fraction
			if not _stands_on(goal): continue
			var radius := body_radius * YardGround.depth_at(position.y)
			if not YardBodies.clear_at(goal, radius, body_obstacles): continue
			_home_path = YardBodies.route(position, goal, radius, body_obstacles, walk_ground, avoid_pond)
			if not _home_path.is_empty(): break
	while not _home_path.is_empty() and position.distance_to(_home_path[0]) < 4.0:
		_home_path.pop_front()
	return _home_path[0] - position if not _home_path.is_empty() else Vector2.ZERO


func _random_point() -> Vector2:
	if daily_routine: return _local_destination()
	if use_ellipse:
		var angle := randf() * TAU
		var radius := sqrt(randf())
		return ellipse_center + Vector2(cos(angle) * ellipse_radius.x * radius, sin(angle) * ellipse_radius.y * radius)
	for _try: int in 24:
		# Grazers move to the next patch, not a random point across the whole yard.
		var angle := randf()*TAU
		var point := position + Vector2(cos(angle),sin(angle)*0.45)*randf_range(18.0,48.0)
		point.x = clampf(point.x,wander_rect.position.x,wander_rect.end.x)
		point.y = clampf(point.y,wander_rect.position.y,wander_rect.end.y)
		if _stands_on(point): return point
	return position


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
	_spit.gravity = Vector2(0, 90)*_particle_art_scale
	_spit.initial_velocity_min = 70.0*_particle_art_scale
	_spit.initial_velocity_max = 110.0*_particle_art_scale
	_spit.scale_amount_min = 0.45*_particle_art_scale
	_spit.scale_amount_max = 0.8*_particle_art_scale
	_spit.position = _spit_origin
	_spit.z_index = 20
	add_child(_spit)


func _apply_face_override() -> void:
	if _gait._material==null or _sprite==null or _sprite.texture==null:
		return
	var enabled:=not _base_texture_path.is_empty() and _expression_texture!=null and _posture_id == "idle"
	_gait._material.set_shader_parameter("face_override",enabled)
	if enabled:
		var size:=_sprite.texture.get_size()
		_gait._material.set_shader_parameter("expression_texture",_expression_texture)
		_gait._material.set_shader_parameter("face_region",Vector4(_face_region.position.x/size.x,_face_region.position.y/size.y,_face_region.size.x/size.x,_face_region.size.y/size.y))


func seek_food(point: Vector2) -> void:
	if posed or state == "lead": return
	_home_path.clear()
	_home_repath = 0.0
	if state != "food" or food_goal.distance_to(point) > 2.0:
		_food_repath = 0.0
		_food_path.clear()
	food_goal = point
	state = "food"


func leave_food() -> void:
	if state != "food": return
	state = "rest"
	_idle_time = 3.0
	_food_path.clear()


func _route_to_leader(depth: float, obstacles: Array) -> Array[Vector2]:
	var path := YardBodies.route(position,_lead_target.position,body_radius*depth,obstacles,walk_ground,avoid_pond)
	if not path.is_empty(): return path
	# A person can fit beside a resident where the larger llama cannot. The
	# companion only needs a safe trailing spot, not the person's exact footprint.
	var toward_us := _lead_target.position.direction_to(position)
	for offset: float in [0.0, PI/8, -PI/8, PI/4, -PI/4, 3*PI/8, -3*PI/8, PI/2, -PI/2, 5*PI/8, -5*PI/8, 3*PI/4, -3*PI/4, 7*PI/8, -7*PI/8, PI]:
		var goal := _lead_target.position + toward_us.rotated(offset) * 56.0 * depth
		path = YardBodies.route(position,goal,body_radius*depth,obstacles,walk_ground,avoid_pond)
		if not path.is_empty(): return path
	return []
