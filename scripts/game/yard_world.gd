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
	_backdrop.z_index = 0
	add_child(_backdrop)
	_apply_weather_art()
	_define_zones()
	_spawn_grass()
	_spawn_cast()
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
	actor.current_zone = _zone_at(point)
	actor.end_lead()


func debug_place_player(point: Vector2) -> void:
	if _player == null:
		return
	_player.position = point


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
			if llama != null and randf() < 0.012 * nosiness:
				actor.nudge_toward(llama.position)
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


func _spawn_cast() -> void:
	_player = VacationerType.new()
	add_child(_player)
	_player.setup(Vector2(210, 430))
	var configs := [
		{
			"id": "llama",
			"species": "llama",
			"position": Vector2(640, 390),
			"wander": Rect2(480, 330, 280, 140),
			"zone": "pasture",
			"speed": 26.0,
			"scale": 0.92,
			"textures": {
				"idle": "res://assets/holiday/characters/llama.png",
				"annoyed": "res://assets/holiday/characters/llama_annoyed.png",
				"happy": "res://assets/holiday/characters/llama_happy.png",
				"smirk": "res://assets/holiday/characters/llama_smirk.png",
			},
		},
		{
			"id": "goose",
			"species": "goose",
			"position": Vector2(820, 470),
			"wander": Rect2(700, 400, 220, 130),
			"zone": "pond",
			"speed": 34.0,
			"scale": 0.82,
			"textures": {"idle": "res://assets/holiday/characters/goose.png"},
		},
		{
			"id": "sheep_a",
			"species": "sheep",
			"position": Vector2(980, 360),
			"wander": Rect2(520, 310, 580, 180),
			"zone": "pen",
			"speed": 22.0,
			"scale": 0.78,
			"textures": {"idle": "res://assets/holiday/characters/sheep_clingy.png"},
		},
		{
			"id": "sheep_b",
			"species": "sheep",
			"position": Vector2(1040, 400),
			"wander": Rect2(520, 330, 560, 170),
			"zone": "pen",
			"speed": 16.0,
			"scale": 0.84,
			"textures": {"idle": "res://assets/holiday/characters/sheep_dull.png"},
		},
		{
			"id": "cow",
			"species": "cow",
			"position": Vector2(540, 470),
			"wander": Rect2(430, 400, 240, 120),
			"zone": "pasture",
			"speed": 14.0,
			"scale": 0.9,
			"textures": {"idle": "res://assets/holiday/characters/cow.png"},
		},
		{
			"id": "duck_a",
			"species": "duck",
			"position": Vector2(690, 545),
			"wander": Rect2(620, 500, 160, 70),
			"zone": "pond",
			"speed": 18.0,
			"scale": 0.7,
			"textures": {"idle": "res://assets/holiday/characters/duck.png"},
		},
		{
			"id": "duck_b",
			"species": "duck",
			"position": Vector2(740, 560),
			"wander": Rect2(640, 510, 150, 70),
			"zone": "pond",
			"speed": 17.0,
			"scale": 0.66,
			"textures": {"idle": "res://assets/holiday/characters/duck.png"},
		},
		{
			"id": "duck_c",
			"species": "duck",
			"position": Vector2(650, 555),
			"wander": Rect2(610, 505, 170, 75),
			"zone": "pond",
			"speed": 19.0,
			"scale": 0.68,
			"textures": {"idle": "res://assets/holiday/characters/duck.png"},
		},
	]
	for config: Dictionary in configs:
		var actor: FeltActor = FeltActorType.new()
		add_child(actor)
		actor.setup(config)
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


func _grass_point() -> Vector2:
	return Vector2(180, 390)


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
	_backdrop.texture = OVERCAST if weather == "overcast" else SUNNY
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
	if rule.has("same_zone"):
		var zone_name := ""
		for species: Variant in rule.same_zone:
			var group := _species_actors(str(species))
			if group.is_empty():
				return false
			var species_zone: String = group[0].current_zone
			for actor: FeltActor in group:
				if actor.current_zone != species_zone:
					return false
			if zone_name == "":
				zone_name = species_zone
			elif zone_name != species_zone:
				return false
		if rule.has("zone") and zone_name != str(rule.zone):
			return false
	return true


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
		actor.spit()
	if bool(rule.get("polaroid", false)) and rule_id not in collected:
		collected.append(rule_id)
		last_photo = rule_id
		album_updated.emit(collected, rule_id)
		_focus_seconds = 2.4
		camera_focus_requested.emit(actor.global_position + Vector2(0, -40), 1.16)


func _draw() -> void:
	var shadow := Color(0.35, 0.22, 0.38, 0.16)
	if _player != null:
		draw_circle(_player.position + Vector2(0, 18), 16.0, shadow)
	for actor_id: String in _actors:
		var actor: FeltActor = _actors[actor_id]
		draw_circle(actor.position + Vector2(0, 16), 20.0, shadow)
