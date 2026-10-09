extends "res://scripts/game/house_lights.gd"
## A narrow authored porch, never part of the general roaming ground.
const State := preload("res://scripts/game/house_sleep_state.gd")
const Daylight := preload("res://scripts/game/world_daylight.gd")
const OPEN := preload("res://assets/holiday/environment/house_open.png")
const APPROACH := Vector2(263, 472)
const PORCH := Vector2(263, 450)
const INSIDE := Vector2(263, 434)
const HIT := Rect2(233, 337, 63, 113)
static var PASSAGE := PackedVector2Array([Vector2(239,422),Vector2(287,422),Vector2(287,493),Vector2(239,493)])
var world: Node2D
var store: Node
var stage := ""
var seconds := 0.0
var pending := ""
var failed := false
var night: Dictionary = {}
var door: Sprite2D
var _night_elapsed := 0.0

func _init(owner_world: Node2D, save_store: Node) -> void:
	world = owner_world
	store = save_store
	store.commit_confirmed.connect(_confirmed)
	store.commit_rejected.connect(_rejected)
	door = Sprite2D.new()
	door.texture = OPEN
	door.centered = false
	door.position = Vector2(216.0,327.0)
	door.scale = Vector2(0.083,0.083)
	door.z_index = 0
	door.visible = false
	add_child(door)
	z_index = 1

func busy() -> bool: return not stage.is_empty()

func available() -> bool:
	return not busy() and not world.is_leading() and world._fish_state == world.FISH_IDLE and not world.inventory_busy

func begin() -> void:
	if not available(): return
	if Daylight.phase(world.tod_fraction()) != "night":
		world.notice_requested.emit("notice.house.day")
		return
	if not store.is_save_idle():
		world.notice_requested.emit("notice.gate_save_wait")
		return
	world._consume_pending_action()
	world.cancel_scene_feedback()
	world._cancel_quiet_sky_look()
	world.camera_release_requested.emit()
	world.get_player().walk_ground = PASSAGE
	night = {"holiday_day":world.holiday_day,"holiday_day_elapsed":world._day_elapsed,
		"plant_state":world._plant_state,"plant_day_planted":world._plant_day_planted,
		"plant_watered_day":world._plant_watered_day,"world_weather":world._regional_weather.snapshot()}
	_night_elapsed = world._day_elapsed
	_enter("porch")
	world.notice_requested.emit("notice.house.enter")

func _enter(next: String) -> void:
	stage = next
	seconds = 0.0

func inside_room() -> bool:
	return stage in ["close", "saving", "sleep", "wake"]

func window_light_target() -> float:
	return 1.0 if wants_light(world.tod_fraction(), inside_room()) else 0.0

func tick(delta: float) -> void:
	var target := window_light_target()
	lights = move_toward(lights,target,delta * 0.7)
	queue_redraw()
	if not busy(): return
	seconds += delta
	var player = world.get_player()
	player.body_obstacles = world.physical_obstacles("player")
	match stage:
		"porch":
			if _walk(delta,PORCH): _enter("open")
		"open":
			door.visible = true
			door.modulate.a = minf(seconds / 0.6,1.0)
			if seconds >= 1.6: _enter("in")
		"in":
			player.modulate.a = clampf((player.position.y - INSIDE.y) / 12.0,0.0,1.0)
			if _walk(delta,INSIDE):
				player.visible = false
				_enter("close")
		"close":
			door.modulate.a = maxf(0.0,1.0 - seconds / 0.8)
			if seconds >= 1.1:
				door.visible = false
				_enter("saving")
				retry()
		"sleep":
			# Only a confirmed durable morning may start this visual fast-forward.
			world._day_elapsed = lerpf(_night_elapsed,599.99,clampf(seconds / 5.0,0.0,1.0))
			if seconds >= 5.0:
				_apply_morning()
				_enter("wake")
		"wake":
			door.visible = true
			door.modulate.a = minf(seconds / 0.6,1.0)
			if seconds >= 1.0:
				player.visible = true
				_enter("out")
		"out":
			player.modulate.a = clampf((player.position.y - INSIDE.y) / 12.0,0.0,1.0)
			if _walk(delta,APPROACH):
				player.modulate.a = 1.0
				player.walk_ground = world.player_ground()
				door.visible = false
				stage = ""
				world.notice_requested.emit("notice.house.morning")
				world._save_interval = 60.0

func _walk(delta: float, point: Vector2) -> bool:
	var player = world.get_player()
	var offset: Vector2 = point - player.position
	if offset.length() < 1.5:
		player._velocity = Vector2.ZERO
		return true
	player.tick(delta,offset.normalized() * minf(0.55,offset.length()/20.0),world.WORLD_SIZE)
	return false

func retry() -> String:
	if stage != "saving" or not pending.is_empty(): return ""
	failed = false
	pending = store.request_house_sleep(night)
	if pending.is_empty(): failed = true
	return pending

func _confirmed(op_id: String, _kind: String) -> void:
	if op_id != pending or pending.is_empty(): return
	pending = ""
	failed = false
	_enter("sleep")
	world.notice_requested.emit("notice.house.sleep")

func _rejected(op_id: String, _kind: String, _code: String) -> void:
	if op_id != pending or pending.is_empty(): return
	pending = ""
	failed = true

func _apply_morning() -> void:
	world.holiday_day = store.get_holiday_day()
	world._day_elapsed = store.get_holiday_day_elapsed()
	var plant: Dictionary = store.get_plant_state()
	world._plant_state = int(plant.state)
	world._plant_day_planted = int(plant.day_planted)
	world._plant_watered_day = int(plant.watered_day)
	world._regional_weather.restore(store.get_world_weather())
	world.weather = str(world._regional_weather.state.weather)
	world._apply_weather_art()
	world.weather_changed.emit(world.weather)
	world.day_advanced.emit(world.holiday_day)
	world._refresh_prop_visuals()


# Live light is drawn after the shared night tint; PhotoMoment uses the same panes.
func _draw() -> void: pass
