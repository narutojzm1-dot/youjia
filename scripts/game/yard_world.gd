class_name YardWorld
extends Node2D

signal album_updated(collected: PackedStringArray, latest_id: String)
signal weather_changed(weather: String)
signal notice_requested(key: String)
signal camera_focus_requested(world_point: Vector2, zoom: float)
signal camera_release_requested

const SUNNY := preload("res://assets/holiday/environment/yard_sunny.png")
const OVERCAST := preload("res://assets/holiday/environment/yard_overcast.png")
const GRASS := preload("res://assets/holiday/fx/grass_bundle.png")
const FeltActorType := preload("res://scripts/entities/felt_actor.gd")
const VacationerType := preload("res://scripts/entities/vacationer.gd")
const WORLD_SIZE := Vector2(1280, 720)
# 人只站在画里已经对上地面的几个位置。圆点是可以走过去的下一处。
const PICTURE_SPOTS := {
	"door": {"position": Vector2(250, 508), "depth": 1.0, "facing": 1.0, "neighbors": ["grass"]},
	"grass": {"position": Vector2(420, 548), "depth": 1.1, "facing": 1.0, "neighbors": ["door", "by_llama", "pond"]},
	"by_llama": {"position": Vector2(578, 478), "depth": 0.88, "facing": 1.0, "neighbors": ["grass", "by_cow", "by_goose"]},
	"by_cow": {"position": Vector2(545, 508), "depth": 1.02, "facing": -1.0, "neighbors": ["by_llama", "grass"]},
	"pond": {"position": Vector2(620, 575), "depth": 1.16, "facing": -1.0, "neighbors": ["grass"]},
	"by_goose": {"position": Vector2(760, 500), "depth": 0.96, "facing": -1.0, "neighbors": ["by_llama", "pen"]},
	"pen": {"position": Vector2(980, 488), "depth": 0.9, "facing": -1.0, "neighbors": ["by_goose", "shed"]},
	"shed": {"position": Vector2(1100, 536), "depth": 1.06, "facing": -1.0, "neighbors": ["pen"]},
}

var weather := "sun"
var season := "late_summer"
var collected: PackedStringArray = []
var last_photo := ""
var simulation_active := true
var input_enabled := true

var _backdrop: Sprite2D
var _player: Vacationer
var _actors: Dictionary = {}
var _zones: Dictionary = {}
var _pulse := 0.0
var _weather_timer := 0.0
var _cooldowns: Dictionary = {}
var _held: Dictionary = {}
var _focus_seconds := 0.0
var _leading := false
var _day_seconds := 0.0
var _grass_sprite: Sprite2D
var _spot := "door"
var _move_held := false
var _has_walk_goal := false
var _walk_goal := Vector2.ZERO
var _pending_interaction := ""
var _walk_path: Array[Vector2] = []


func setup(saved_photos: Array = []) -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collected = PackedStringArray()
	for item: Variant in saved_photos:
		var photo_id := str(item)
		if photo_id not in collected:
			collected.append(photo_id)
	_backdrop = Sprite2D.new()
	_backdrop.centered = false
	_backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_backdrop.z_index = -1
	add_child(_backdrop)
	_apply_weather_art()
	_define_zones()
	_spawn_grass()
	_spawn_cast()
	_bind_grounds()
	_weather_timer = randf_range(42.0, 78.0)
	queue_redraw()


func get_player() -> Vacationer:
	return _player


func get_world_size() -> Vector2:
	return WORLD_SIZE


func collected_count() -> int:
	return collected.size()


func collectible_total() -> int:
	return ExpressionCatalog.all_ids().size()


func is_mainline_complete() -> bool:
	for rule_id: String in ExpressionCatalog.llama_mainline_ids():
		if rule_id not in collected:
			return false
	return true


func set_weather(next_weather: String) -> void:
	if next_weather == weather:
		return
	weather = next_weather
	_apply_weather_art()
	TuningStore.apply_boundary("NEXT_STAGE")
	weather_changed.emit(weather)


func toggle_weather() -> void:
	set_weather("overcast" if weather == "sun" else "sun")


func debug_force_rule(rule_id: String) -> bool:
	var rule := ExpressionCatalog.find_rule(rule_id)
	if rule.is_empty():
		return false
	_apply_rule(rule, true)
	return true


func actor_named(actor_id: String) -> FeltActor:
	return _actors.get(actor_id) as FeltActor


func debug_place_actor(actor_id: String, point: Vector2) -> void:
	var actor: FeltActor = actor_named(actor_id)
	if actor == null:
		return
	actor.position = point
	if actor._rig != null:
		actor._rig.reset_contacts()
	actor._velocity=Vector2.ZERO
	actor.current_zone = _zone_at(point)
	actor.end_lead()


func debug_place_player(point: Vector2) -> void:
	if _player == null:
		return
	_player.position = point
	_player.reset_locomotion()


func tick(delta: float, move: Vector2) -> void:
	if not simulation_active:
		return
	_day_seconds += delta
	_weather_timer -= delta
	if _weather_timer <= 0.0:
		toggle_weather()
		_weather_timer = randf_range(48.0, 90.0)
	if _player == null:
		return
	if input_enabled:
		if move.length() > 0.2:
			_has_walk_goal = false
			_pending_interaction = ""
			_walk_path.clear()
		elif _has_walk_goal:
			if _pending_interaction == "llama":
				_walk_goal = actor_named("llama").position
			if not _pending_interaction.is_empty() and _player.position.distance_to(_walk_goal) < 64.0:
				_has_walk_goal = false
				_walk_path.clear()
				_pending_interaction = ""
				try_interact()
			var destination := _walk_path[0] if not _walk_path.is_empty() else _walk_goal
			if not _walk_path.is_empty() and _player.position.distance_to(destination) < (12.0 if _walk_path.size()==1 else 4.0):
				_walk_path.pop_front()
				destination = _walk_path[0] if not _walk_path.is_empty() else _walk_goal
			var to_goal := destination - _player.position
			if not _has_walk_goal or (to_goal.length() < 12.0 and _walk_path.is_empty()):
				_has_walk_goal = false
				move = Vector2.ZERO
			else:
				move = to_goal.normalized() * minf(1.0, to_goal.length() / 44.0)
		_player.tick(delta, move, WORLD_SIZE)
	else:
		_player.tick(delta, Vector2.ZERO, WORLD_SIZE)
	var animal_scale := float(TuningStore.get_value("enemies.visual.scale", 1.0))
	var animal_speed := float(TuningStore.get_value("enemies.move.speed_multiplier", 1.0))
	for actor_id: String in _actors:
		var actor: FeltActor = _actors[actor_id]
		actor.speed = actor.get_meta("base_speed", actor.speed) * animal_speed
		actor.set_meta("visual_scale", animal_scale)
		if _leading and actor_id == "llama":
			actor.begin_lead(_player)
		elif actor.state == "lead" and actor_id == "llama":
			actor.end_lead()
		if actor_id == "goose" and weather == "overcast":
			var llama: FeltActor = _actors.get("llama")
			var nosiness := float(TuningStore.get_value("enemies.goose.nosiness", 1.0))
			if llama != null and actor.position.distance_to(llama.position) > 88.0 and randf() < 1.0 - exp(-0.24 * nosiness * delta):
				actor.nudge_toward(llama.position + (actor.position-llama.position).normalized()*72.0)
		# 晴天一只羊偶尔从羊圈走到草泥马附近，走的是同一块草地。
		if actor_id == "sheep_a" and weather == "sun" and not _leading:
			var sun_llama: FeltActor = _actors.get("llama")
			if sun_llama != null and actor.position.distance_to(sun_llama.position) > 140.0 and randf() < 1.0 - exp(-0.18 * delta):
				actor.nudge_toward(sun_llama.position + (actor.position-sun_llama.position).normalized()*76.0)
		if actor_id == "llama" and _pending_interaction == "llama" and not _leading:
			actor.state = "graze"
			actor._idle_time = maxf(actor._idle_time, 0.5)
		actor.tick(delta, WORLD_SIZE)
		actor.current_zone = _zone_at(actor.position)
	_player.player_state = _player.snapshot_state()
	for key: Variant in _cooldowns.keys():
		_cooldowns[key] = float(_cooldowns[key]) - delta
		if float(_cooldowns[key]) <= 0.0:
			_cooldowns.erase(key)
	for key: Variant in _held.keys():
		_held[key] = float(_held[key]) - delta
		if float(_held[key]) <= 0.0:
			_held.erase(key)
	_pulse += delta
	var interval := float(TuningStore.get_value("gameplay.expression.pulse", 1.6))
	if _pulse >= interval:
		_pulse = 0.0
		_evaluate_expressions()
	if _focus_seconds > 0.0:
		_focus_seconds -= delta
		if _focus_seconds <= 0.0:
			camera_release_requested.emit()
	queue_redraw()


func try_interact() -> void:
	if not input_enabled or _player == null:
		return
	TuningStore.apply_boundary("NEXT_ACTION")
	if _player.position.distance_to(_grass_point()) < 78.0 and not _player.carrying_grass:
		_player.pick_grass()
		notice_requested.emit("notice.picked_grass")
		return
	var llama: FeltActor = _actors.get("llama")
	if llama != null and _player.position.distance_to(llama.position) < 88.0:
		if _player.carrying_grass:
			_player.consume_grass()
			llama.hold_expression("happy", 4.0)
			notice_requested.emit("notice.fed_llama")
			_evaluate_expressions()
			return
		_leading = not _leading
		_player.leading = _leading
		if _leading:
			llama.begin_lead(_player)
			notice_requested.emit("notice.lead_start")
		else:
			llama.end_lead()
			notice_requested.emit("notice.lead_stop")
		return
	notice_requested.emit("notice.idle")


func primary_action_key() -> String:
	if _leading: return "action.release"
	if _player != null and _player.carrying_grass: return "action.feed"
	return "action.grass"


func request_primary_action() -> void:
	if not input_enabled: return
	if _leading:
		_leading = false
		_player.leading = false
		actor_named("llama").end_lead()
		notice_requested.emit("notice.lead_stop")
	elif _player.carrying_grass:
		request_pointer_action(actor_named("llama").position)
	else:
		request_pointer_action(_grass_point())


func request_pointer_action(point: Vector2) -> void:
	if not input_enabled or _player == null:
		return
	_pending_interaction = ""
	var goal := point
	var llama := actor_named("llama")
	if point.distance_to(_grass_point()) < 45.0:
		_pending_interaction = "grass"
		goal = _grass_point()
	elif llama != null and (point.distance_to(llama.position) < 45.0 or point.distance_to(llama.position + Vector2(0,-48)) < 50.0):
		_pending_interaction = "llama"
		goal = llama.position
	if not _pending_interaction.is_empty() and _player.position.distance_to(goal) < 64.0:
		_has_walk_goal = false
		_walk_path.clear()
		_pending_interaction = ""
		try_interact()
		return
	if not try_walk_to(goal):
		_pending_interaction = ""
		notice_requested.emit("notice.cannot_walk")



func try_walk_to(point: Vector2) -> bool:
	if not input_enabled or _player == null:
		return false
	var goal := point
	for actor_id: String in _actors:
		var actor: FeltActor = _actors[actor_id]
		var body := actor.position + Vector2(0, -36)
		if point.distance_to(actor.position) < 64.0 or point.distance_to(body) < 72.0:
			goal = actor.position
			break
	if point.distance_to(_grass_point()) < 56.0:
		goal = _grass_point()
	if not YardGround.allows(goal, YardGround.lawn(), true):
		return false
	if _player.position.distance_to(goal) < 28.0:
		return false
	_walk_path = YardGround.route(_player.position, goal)
	if _walk_path.is_empty():
		return false
	_has_walk_goal = true
	_walk_goal = goal
	return true


func try_step_to_point(point: Vector2) -> bool:
	if not input_enabled:
		return false
	var best := ""
	var best_distance := 76.0
	for spot_name: String in PICTURE_SPOTS:
		var spot: Dictionary = PICTURE_SPOTS[spot_name]
		var spot_pos: Vector2 = spot.position
		var distance := point.distance_to(spot_pos)
		if distance < best_distance:
			best_distance = distance
			best = spot_name
	if best == "" or best == _spot:
		return false
	_spot = best
	_apply_picture()
	notice_requested.emit("notice.step")
	return true


func _latch_move(move: Vector2) -> void:
	if move.length() < 0.25:
		_move_held = false
		return
	if _move_held:
		return
	_move_held = true
	_step_toward(move)


func _step_toward(direction: Vector2) -> void:
	var here: Dictionary = PICTURE_SPOTS[_spot]
	var origin: Vector2 = here.position
	var best := ""
	var best_dot := 0.34
	var aim := direction.normalized()
	for next_name: String in here.neighbors:
		var next_spot: Dictionary = PICTURE_SPOTS[next_name]
		var next_pos: Vector2 = next_spot.position
		var delta := next_pos - origin
		if delta.length() < 1.0:
			continue
		var alignment := delta.normalized().dot(aim)
		if alignment > best_dot:
			best_dot = alignment
			best = next_name
	if best == "":
		return
	_spot = best
	_apply_picture()
	notice_requested.emit("notice.step")


func _apply_picture() -> void:
	_place_player_spot()
	_pose_cast()


func _place_player_spot() -> void:
	if _player == null:
		return
	var spot: Dictionary = PICTURE_SPOTS[_spot]
	_player.position = spot.position
	_player.reset_locomotion()
	_player.facing = float(spot.facing)
	_player.picture_depth = float(spot.depth)
	_player.player_state = "idle"


func _pose_cast() -> void:
	if _actors.is_empty():
		return
	var layout := _cast_layout()
	var animal_scale := float(TuningStore.get_value("enemies.visual.scale", 1.0))
	for actor_id: String in layout:
		var actor: FeltActor = _actors.get(actor_id)
		if actor == null:
			continue
		var pose: Dictionary = layout[actor_id]
		if _leading and actor_id == "llama":
			pose = _lead_pose()
		actor.set_meta("visual_scale", animal_scale)
		actor.set_pose(pose.position, float(pose.scale)*float(actor.get_meta("source_scale_ratio",1.0)), float(pose.facing))
		actor.current_zone = _zone_at(actor.position)


func _lead_pose() -> Dictionary:
	var spot: Dictionary = PICTURE_SPOTS[_spot]
	var face := float(spot.facing)
	return {
		"position": _player.position + Vector2(-58.0 * face, 10.0),
		"scale": 0.32 * float(spot.depth),
		"facing": face,
	}


func _cast_layout() -> Dictionary:
	# 晴天各就各位。阴天大鹅改站到草泥马旁边，整张画换一个构图，而不是自己滑过去。
	var goose_point := Vector2(700, 466) if weather == "overcast" else Vector2(812, 496)
	var goose_scale := 0.32 if weather == "overcast" else 0.34
	return {
		"llama": {"position": Vector2(636, 452), "scale": 0.30, "facing": -1.0},
		"cow": {"position": Vector2(400, 516), "scale": 0.40, "facing": 1.0},
		"horse": {"position": Vector2(560, 505), "scale": 0.36, "facing": -1.0},
		"goose": {"position": goose_point, "scale": goose_scale, "facing": -1.0},
		"sheep_a": {"position": Vector2(990, 448), "scale": 0.28, "facing": -1.0},
		"sheep_b": {"position": Vector2(1088, 505), "scale": 0.34, "facing": -1.0},
		"duck_a": {"position": Vector2(688, 562), "scale": 0.26, "facing": 1.0},
		"duck_b": {"position": Vector2(746, 570), "scale": 0.24, "facing": -1.0},
		"duck_c": {"position": Vector2(652, 568), "scale": 0.25, "facing": 1.0},
	}


func _spawn_cast() -> void:
	_player = VacationerType.new()
	add_child(_player)
	_player.setup(Vector2(260, 540))
	var configs := [
		{
			"id": "llama",
			"species": "llama",
			"position": Vector2(560, 470),
			"wander": Rect2(500, 445, 240, 80),
			"zone": "pasture",
			"speed": 26.0,
			"scale": 0.36,
			"textures": {
				"idle": "res://assets/holiday/characters/llama.png",
				"annoyed": "res://assets/holiday/characters/llama_annoyed.png",
				"happy": "res://assets/holiday/characters/llama_happy.png",
				"smirk": "res://assets/holiday/characters/llama_smirk.png",
			},
		},
		{
			"id": "goose",
			"native_facing": -1.0,
			"species": "goose",
			"position": Vector2(800, 490),
			"wander": Rect2(720, 455, 150, 75),
			"zone": "pond",
			"speed": 34.0,
			"scale": 0.38,
			"textures": {"idle": "res://assets/holiday/characters/goose.png"},
		},
		{
			"id": "sheep_a",
			"species": "sheep",
			"position": Vector2(1020, 505),
			"wander": Rect2(970, 485, 150, 60),
			"zone": "pen",
			"speed": 22.0,
			"scale": 0.36,
			"textures": {"idle": "res://assets/holiday/characters/sheep_clingy.png"},
		},
		{
			"id": "sheep_b",
			"native_facing": -1.0,
			"species": "sheep",
			"position": Vector2(1120, 530),
			"wander": Rect2(1040, 500, 130, 55),
			"zone": "pen",
			"speed": 16.0,
			"scale": 0.34,
			"textures": {"idle": "res://assets/holiday/characters/sheep_dull.png"},
		},
		{
			"id": "cow",
			"native_facing": -1.0,
			"species": "cow",
			"position": Vector2(430, 510),
			"wander": Rect2(370, 470, 170, 80),
			"zone": "pasture",
			"speed": 14.0,
			"scale": 0.36,
			"textures": {"idle": "res://assets/holiday/characters/cow.png"},
		},
		{
			"id": "horse",
			"native_facing": -1.0,
			"species": "horse",
			"position": Vector2(650, 480),
			"wander": Rect2(570, 455, 155, 62),
			"zone": "pasture",
			"speed": 15.0,
			"scale": 0.36,
			"textures": {"idle": "res://assets/holiday/characters/cast_v2/horse.png"},
		},
		{
			"id": "duck_a",
			"species": "duck",
			"position": Vector2(680, 582),
			"wander": Rect2(620, 500, 160, 70),
			"zone": "pond",
			"speed": 18.0,
			"scale": 0.32,
			"textures": {"idle": "res://assets/holiday/characters/duck.png"},
		},
		{
			"id": "duck_b",
			"species": "duck",
			"position": Vector2(740, 594),
			"wander": Rect2(640, 510, 150, 70),
			"zone": "pond",
			"speed": 17.0,
			"scale": 0.30,
			"textures": {"idle": "res://assets/holiday/characters/duck.png"},
		},
		{
			"id": "duck_c",
			"species": "duck",
			"position": Vector2(650, 590),
			"wander": Rect2(610, 505, 170, 75),
			"zone": "pond",
			"speed": 19.0,
			"scale": 0.31,
			"textures": {"idle": "res://assets/holiday/characters/duck.png"},
		},
	]
	for original: Dictionary in configs:
		var config:=CastArt.configure(original)
		var actor: FeltActor = FeltActorType.new()
		add_child(actor)
		actor.setup(config)
		actor.set_meta("source_scale_ratio",float(config.get("source_scale_ratio",1.0)))
		actor.set_meta("base_speed", float(config.get("speed", 28.0)))
		_actors[str(config.id)] = actor


func _define_zones() -> void:
	_zones = {
		"door": Rect2(40, 250, 280, 250),
		"pasture": Rect2(320, 300, 430, 220),
		"pond": Rect2(520, 470, 360, 180),
		"pen": Rect2(860, 280, 360, 250),
	}


func _zone_at(point: Vector2) -> String:
	for zone_name: String in _zones:
		var rect: Rect2 = _zones[zone_name]
		if rect.has_point(point):
			return zone_name
	return "pasture"


func _bind_grounds() -> void:
	_player.walk_ground = YardGround.lawn()
	_player.avoid_pond = true
	if not YardGround.allows(_player.position, YardGround.lawn(), true):
		_player.position = Vector2(260, 540)
	for actor_id: String in _actors:
		var actor: FeltActor = _actors[actor_id]
		if actor_id.begins_with("duck"):
			actor.adopt_ellipse(YardGround.POND_CENTER, Vector2(96, 28))
		elif actor_id.begins_with("sheep"):
			actor.adopt_ground(YardGround.pen_and_lawn(), true)
		else:
			actor.adopt_ground(YardGround.lawn(), true)


func _grass_point() -> Vector2:
	# 草堆在门前小路边，人可以走过去拿。
	return Vector2(340, 600)


func _spawn_grass() -> void:
	_grass_sprite = Sprite2D.new()
	_grass_sprite.texture = GRASS
	_grass_sprite.position = _grass_point()
	_grass_sprite.z_index = 3
	_grass_sprite.scale = Vector2(0.9, 0.9)
	add_child(_grass_sprite)


func _apply_weather_art() -> void:
	if _backdrop == null:
		return
	# Weather changes light, never the ground layout under the actors.
	_backdrop.texture = SUNNY
	if _backdrop.texture != null:
		var tex_size := _backdrop.texture.get_size()
		_backdrop.scale = Vector2(WORLD_SIZE.x / tex_size.x, WORLD_SIZE.y / tex_size.y)
	var filter_on := bool(TuningStore.get_value("environment.filter.enabled", true))
	var intensity := float(TuningStore.get_value("environment.filter.intensity", 0.12))
	if not filter_on:
		_backdrop.modulate = Color.WHITE
		return
	if weather == "overcast":
		_backdrop.modulate = Color(0.92, 0.90, 0.96).lerp(Color.WHITE, 1.0 - intensity)
	else:
		_backdrop.modulate = Color(1.0, 0.97, 0.90).lerp(Color.WHITE, 1.0 - intensity)


func _evaluate_expressions() -> void:
	var snapshot := _world_snapshot()
	var ranked: Array = ExpressionCatalog.RULES.duplicate()
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("priority", 0)) > int(b.get("priority", 0)))
	var used_owners: Dictionary = {}
	for rule: Dictionary in ranked:
		var owner := str(rule.get("owner", ""))
		if used_owners.has(owner):
			continue
		if not _rule_matches(rule, snapshot):
			continue
		used_owners[owner] = true
		_apply_rule(rule, false)


func _world_snapshot() -> Dictionary:
	var nearby: Dictionary = {}
	for actor_id: String in _actors:
		var actor: FeltActor = _actors[actor_id]
		var near_list: Array = []
		for other_id: String in _actors:
			if other_id == actor_id:
				continue
			var other: FeltActor = _actors[other_id]
			if actor.is_near(other, float(TuningStore.get_value("gameplay.proximity.radius", 92.0))):
				near_list.append(other.species)
		nearby[actor_id] = near_list
	return {
		"weather": weather,
		"season": season,
		"player": _player.snapshot_state() if _player != null else "idle",
		"nearby": nearby,
		"actors": _actors,
	}


func _species_actors(species: String) -> Array:
	var matches: Array = []
	for actor_id: String in _actors:
		var actor: FeltActor = _actors[actor_id]
		if actor.species == species:
			matches.append(actor)
	return matches


func _rule_matches(rule: Dictionary, snapshot: Dictionary) -> bool:
	var owner := str(rule.get("owner", ""))
	var actors := _species_actors(owner)
	if actors.is_empty():
		return false
	if bool(rule.get("observe_nearby",false)):
		var close := false
		for subject in actors:
			if _player != null and _player.position.distance_to(subject.position) < 205.0:
				close = true
		if not close: return false
	if rule.has("weather") and str(rule.weather) != str(snapshot.weather):
		return false
	if rule.has("player") and str(rule.player) != str(snapshot.player):
		return false
	if rule.has("zone"):
		var wanted := str(rule.zone)
		var any_in_zone := false
		for actor: FeltActor in actors:
			if actor.current_zone == wanted:
				any_in_zone = true
		if not any_in_zone:
			return false
	if rule.has("nearby"):
		var ok := false
		for actor: FeltActor in actors:
			var near: Array = snapshot.nearby.get(actor.actor_id, [])
			if _contains_all(near, rule.nearby):
				ok = true
		if not ok:
			return false
	if rule.has("not_nearby"):
		for actor: FeltActor in actors:
			var near: Array = snapshot.nearby.get(actor.actor_id, [])
			for blocked: Variant in rule.not_nearby:
				if str(blocked) in near:
					return false
	if rule.has("same_zone") and not _species_share_zone(rule):
		return false
	# sees 表示玩家得站在近处，这张表情才算被看见。
	if bool(rule.get("sees", false)) and not _player_sees(actors):
		return false
	return true


func _species_share_zone(rule: Dictionary) -> bool:
	# 每种动物只要有一只在同一片区域即可。两只羊不必同时离开羊圈。
	var shared := str(rule.get("zone", ""))
	var species_list: Array = rule.same_zone
	if shared != "":
		for species: Variant in species_list:
			if not _species_in_zone(str(species), shared):
				return false
		return true
	var zones: Dictionary = {}
	for species: Variant in species_list:
		var group := _species_actors(str(species))
		if group.is_empty():
			return false
		for actor: FeltActor in group:
			zones[actor.current_zone] = true
	for zone_name: String in zones:
		var all_present := true
		for species: Variant in species_list:
			if not _species_in_zone(str(species), zone_name):
				all_present = false
				break
		if all_present:
			return true
	return false


func _species_in_zone(species: String, zone_name: String) -> bool:
	for actor: FeltActor in _species_actors(species):
		if actor.current_zone == zone_name:
			return true
	return false


func _player_sees(actors: Array) -> bool:
	if _player == null:
		return false
	var radius := float(TuningStore.get_value("gameplay.proximity.radius", 92.0)) * 2.2
	for actor: FeltActor in actors:
		if _player.position.distance_to(actor.position) <= radius:
			return true
	return false


func _contains_all(haystack: Array, needles: Array) -> bool:
	for needle: Variant in needles:
		if str(needle) not in haystack:
			return false
	return true


func _apply_rule(rule: Dictionary, force: bool) -> void:
	var rule_id := str(rule.get("id", ""))
	if not force and float(_cooldowns.get(rule_id, 0.0)) > 0.0:
		return
	var owner := str(rule.get("owner", ""))
	var actors := _species_actors(owner)
	if actors.is_empty():
		return
	var actor: FeltActor = actors[0]
	if owner == "llama":
		actor = _actors.get("llama")
	if actor == null:
		return
	var expression := str(rule.get("expression", "idle"))
	var hold := float(rule.get("hold", 4.0))
	actor.hold_expression(expression, hold)
	_held[rule_id] = hold
	_cooldowns[rule_id] = hold + float(TuningStore.get_value("gameplay.expression.cooldown", 16.0))
	if bool(rule.get("spit", false)):
		var goose := actor_named("goose")
		if goose != null:
			actor.spit(goose.global_position + Vector2(0,-30))
	if bool(rule.get("polaroid", false)) and rule_id not in collected:
		collected.append(rule_id)
		last_photo = rule_id
		album_updated.emit(collected, rule_id)
		_focus_seconds = 2.4
		camera_focus_requested.emit(actor.global_position + Vector2(0, -40), 1.16)


func _draw() -> void:
	if _leading and _player != null:
		var llama := actor_named("llama")
		if llama != null:
			var hand := _player.position + Vector2(12.0*_player.facing,-32.0)
			var collar := llama.position + Vector2(18.0*llama.facing,-55.0*YardGround.depth_at(llama.position.y))
			var midpoint := (hand+collar)*0.5+Vector2(0,13)
			var cord := PackedVector2Array()
			for i in 13:
				var t := float(i)/12.0
				cord.append(hand.lerp(midpoint,t).lerp(midpoint.lerp(collar,t),t))
			draw_polyline(cord,Color(0.48,0.34,0.22,0.75),1.5,true)
	if _has_walk_goal:
		draw_arc(_walk_goal, 10.0, 0.0, TAU, 24, Color(1.0,0.92,0.65,0.85), 2.0)
	var shadow := Color(0.35, 0.22, 0.38, 0.16)
	if _player != null:
		draw_set_transform(_player.position + Vector2(0, 2), 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, 11.0 * YardGround.depth_at(_player.position.y), shadow)
	for actor_id: String in _actors:
		var actor: FeltActor = _actors[actor_id]
		draw_set_transform(actor.position + Vector2(0, 2), 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, 14.0 * YardGround.depth_at(actor.position.y), shadow)
	draw_set_transform(Vector2.ZERO)
