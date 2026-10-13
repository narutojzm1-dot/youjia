extends "res://scripts/game/house_lights.gd"
## A narrow authored porch, never part of the general roaming ground.
const Basket := preload("res://scripts/game/physical_basket.gd")
const Meals := preload("res://scripts/game/meal_schedule.gd")
const State := preload("res://scripts/game/house_sleep_state.gd")
const Daylight := preload("res://scripts/game/world_daylight.gd")
const OPEN := preload("res://assets/holiday/environment/house_open.png")
const APPROACH := Vector2(263, 472)
const PORCH := Vector2(263, 450)
const INSIDE := Vector2(263, 434)
const HIT := Rect2(233, 337, 63, 113)
const MEAL_ROUTE_TIMEOUT := 90.0
const MEAL_ROUTE_STALL := 10.0
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
var balcony: Node2D
var cooking_plan: Dictionary = {}
var smoke: Node2D
var meal_idle := 0.0
var meal_cooldown := 0.0
var meal_rng := RandomNumberGenerator.new()
var meal_succeeded := false
var meal_ingredient: Sprite2D
# A walking intention, never a stock reservation or durable meal receipt.
var meal_route: Dictionary = {}
# One latest player intent, never a queue of stale clicks. Not persistent.
var player_intent: Dictionary = {}


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
	balcony = preload("res://scripts/game/balcony_morning.gd").new(world)
	add_child(balcony)
	meal_rng.randomize()
	meal_ingredient = Sprite2D.new()
	meal_ingredient.name = "MealIngredient"
	meal_ingredient.set_meta("photo_player_carried", true)
	meal_ingredient.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	meal_ingredient.z_as_relative = false
	meal_ingredient.visible = false
	add_child(meal_ingredient)


func busy() -> bool: return not stage.is_empty()

func owns_actor() -> bool:
	# Walking to the basket/house already reserves the actor, before animation.
	return busy() or not cooking_plan.is_empty() or world._pending_interaction in ["meal_basket", "house_meal"]

func available() -> bool:
	return not busy() and not world.is_leading() and world._fish_state == world.FISH_IDLE and not world.inventory_busy \
		and (world.pond_growth == null or not world.pond_growth.busy())

func begin(meal_only: bool = false) -> void:
	if not available(): return
	var meal := Meals.meal_at(world.tod_fraction())
	var hands_free: bool = not world.get_player().carrying_grass and (world.ground_food == null or world.ground_food.held().is_empty())
	if hands_free and not meal.is_empty() and store.has_method("plan_meal") and store.is_save_idle():
		if not cooking_plan.is_empty():
			if _prepared_meal_valid():
				meal_succeeded = false
				_start_entry()
				_sync_meal_ingredient()
				world.notice_requested.emit("notice.meal.enter")
				return
			cancel_preparation()
			return
		var plan: Dictionary = store.plan_meal(meal, Meals.recipes_for(meal), meal_rng)
		if not plan.is_empty():
			# A door click also fetches food from the physical basket first.
			_request_meal_route("meal_basket", Basket.APPROACH, meal)
			return
	if not cooking_plan.is_empty():
		cancel_preparation()
		return
	# Arrival revalidates food/time, but an autonomous meal never becomes sleep.
	if meal_only:
		meal_cooldown = 30.0
		return
	if Daylight.phase(world.tod_fraction()) != "night":
		world.notice_requested.emit("notice.house.day")
		return
	if not store.is_save_idle():
		world.notice_requested.emit("notice.gate_save_wait")
		return
	_start_entry()
	world.notice_requested.emit("notice.house.enter")

func take_from_basket() -> void:
	if not available() or not store.is_save_idle(): return
	if world.get_player().position.distance_to(Basket.APPROACH) >= 18.0: return
	if world.get_player().carrying_grass or (world.ground_food != null and not world.ground_food.held().is_empty()): return
	var meal := Meals.meal_at(world.tod_fraction())
	if meal.is_empty():
		cancel_preparation()
		return
	cooking_plan = store.plan_meal(meal, Meals.recipes_for(meal), meal_rng)
	if cooking_plan.is_empty():
		cancel_preparation()
		return
	world._consume_pending_action()
	meal_route = {}
	meal_succeeded = false
	_enter("take")
	_sync_meal_ingredient()

func _prepared_meal_valid() -> bool:
	return not cooking_plan.is_empty() and cooking_plan.day == world.holiday_day \
		and cooking_plan.meal == Meals.meal_at(world.tod_fraction()) \
		and cooking_plan.revision == store.get_meal_ledger().get("revision", -1) \
		and cooking_plan.inventory_revision == store.get_yard_inventory().get("revision", -1)

func cancel_preparation() -> void:
	# Nothing is debited before the confirmed cooking transaction.
	cooking_plan = {}
	meal_route = {}
	meal_ingredient.visible = false
	meal_idle = 0.0
	meal_cooldown = 30.0
	if stage == "take": stage = ""
	if world._pending_interaction in ["meal_basket", "house_meal"]:
		world._consume_pending_action()

func _start_entry() -> void:
	world._consume_pending_action()
	meal_route = {}
	world.cancel_scene_feedback()
	world._cancel_quiet_sky_look()
	world.camera_release_requested.emit()
	world.get_player().walk_ground = PASSAGE
	night = {"holiday_day":world.holiday_day,"holiday_day_elapsed":world._day_elapsed,
		"plant_state":world._plant_state,"plant_day_planted":world._plant_day_planted,
		"plant_watered_day":world._plant_watered_day,"world_weather":world._regional_weather.snapshot()}
	_night_elapsed = world._day_elapsed
	_enter("porch")

func _enter(next: String) -> void:
	stage = next
	seconds = 0.0
	if not cooking_plan.is_empty():
		var hint: String = {"take":"notice.meal.take", "cook":_cooking_hint(), "balcony":"notice.meal.brush"}.get(next, "")
		if not hint.is_empty(): world.notice_requested.emit(hint)

func inside_room() -> bool:
	return stage in ["close", "saving", "cook", "sleep", "balcony", "stairs", "wake"]

func skip_balcony() -> void:
	if stage == "take":
		cancel_preparation()
		return
	if stage == "balcony":
		world.camera_release_requested.emit()
		balcony.skip()
	elif not cooking_plan.is_empty() and pending.is_empty() and stage in ["porch", "open", "in", "close", "cook"]:
		# A player's input can interrupt uncommitted cooking without losing food.
		_set_cooking_smoke(false)
		meal_ingredient.visible = false
		meal_cooldown = 30.0
		if stage in ["porch", "open", "in"]:
			_enter("out")
		else:
			_enter("wake")

func player_activity() -> void:
	meal_idle = 0.0

func request_player_intent(intent: Dictionary) -> bool:
	player_activity()
	if not busy():
		if world._pending_interaction in ["meal_basket", "house_meal"] or not cooking_plan.is_empty():
			cancel_preparation()
		return false
	player_intent = intent.duplicate()
	skip_balcony()
	if not busy():
		# Taking food is wholly outside; caller can execute this input now.
		player_intent = {}
		return false
	return true

func _resume_player_intent() -> void:
	var intent := player_intent
	player_intent = {}
	match str(intent.get("kind", "")):
		"pointer": world.request_pointer_action(intent.point)
		"basket": world.basket_requested.emit()

func meal_hint() -> String:
	if cooking_plan.is_empty(): return ""
	if stage == "take" or (stage.is_empty() and world._pending_interaction == "house_meal"): return "notice.meal.take"
	if stage in ["porch", "open", "in"]: return "notice.meal.enter"
	if stage in ["cook", "close", "saving"]: return _cooking_hint()
	if stage == "balcony": return "notice.meal.brush"
	return ""

func action_label() -> String:
	if cooking_plan.is_empty(): return "action.house_resting"
	if stage == "saving": return "action.meal_saving"
	if stage in ["take", "porch", "open", "in"]: return "action.meal_cancel"
	return "action.meal_return"

func window_light_target() -> float:
	return 1.0 if wants_light(world.tod_fraction(), inside_room()) else 0.0

func tick(delta: float) -> void:
	_sync_meal_ingredient()
	var target := window_light_target()
	lights = move_toward(lights,target,delta * 0.7)
	queue_redraw()
	if smoke != null: smoke.set_night_tint(Daylight.phase(world.tod_fraction()) == "night")
	if not busy(): return
	seconds += delta
	var player = world.get_player()
	player.body_obstacles = world.physical_obstacles("player")
	match stage:
		"take":
			if seconds >= 1.0:
				stage = ""
				_request_meal_route("house_meal", APPROACH, str(cooking_plan.meal))
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
				meal_ingredient.visible = false
				_enter("close")
		"close":
			door.modulate.a = maxf(0.0,1.0 - seconds / 0.8)
			if seconds >= 1.1:
				door.visible = false
				if cooking_plan.is_empty():
					_enter("saving")
					retry()
				else:
					_enter("cook")
					_set_cooking_smoke(true)
		"cook":
			if seconds >= Meals.COOK_SECONDS:
				_set_cooking_smoke(false)
				_enter("saving")
				retry()
		"sleep":
			# Only a confirmed durable morning may start this visual fast-forward.
			world._day_elapsed = lerpf(_night_elapsed,599.99,clampf(seconds / 5.0,0.0,1.0))
			if seconds >= 5.0:
				_apply_morning()
				var kind: String = balcony.plan(world.holiday_day, world.weather)
				if kind.is_empty():
					_enter("wake")
				else:
					balcony.begin(kind)
					_enter("balcony")
					world.camera_focus_requested.emit(Vector2(278, 300), 1.0 if bool(TuningStore.get_value("ui.reduced_motion", false)) else 1.25)
		"balcony":
			balcony.tick(delta, bool(TuningStore.get_value("ui.reduced_motion", false)))
			if not balcony.busy():
				world.camera_release_requested.emit()
				_enter("stairs")
		"stairs":
			# The traveller is hidden inside the house throughout the descent.
			if seconds >= 1.2: _enter("wake")
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
				if cooking_plan.is_empty():
					world.notice_requested.emit("notice.house.morning")
				else:
					world.notice_requested.emit("notice.meal.done" if meal_succeeded else "notice.meal.cancel")
					cooking_plan = {}
					meal_cooldown = 30.0
					meal_idle = 0.0
				world._save_interval = 60.0
				_resume_player_intent.call_deferred()

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
	if cooking_plan.is_empty():
		pending = store.request_house_sleep(night)
	else:
		pending = store.request_meal_completion(cooking_plan.revision, cooking_plan.inventory_revision,
			cooking_plan.day, cooking_plan.meal, cooking_plan.ingredients,
			{"elapsed":night.holiday_day_elapsed, "weather":night.world_weather})
	if pending.is_empty(): failed = true
	return pending

func _confirmed(op_id: String, _kind: String) -> void:
	if op_id != pending or pending.is_empty(): return
	pending = ""
	failed = false
	if cooking_plan.is_empty():
		_enter("sleep")
		world.notice_requested.emit("notice.house.sleep")
	else:
		meal_succeeded = true
		if not player_intent.is_empty():
			_enter("wake")
		elif meal_rng.randf() < 0.8:
			balcony.begin("brush")
			_enter("balcony")
			world.camera_focus_requested.emit(Vector2(278, 300), 1.0 if bool(TuningStore.get_value("ui.reduced_motion", false)) else 1.25)
		else:
			_enter("wake")

func _rejected(op_id: String, _kind: String, _code: String) -> void:
	if op_id != pending or pending.is_empty(): return
	pending = ""
	failed = true
	# Definitive rejection does not award a meal. Unknown writes stay pending
	# until the existing save-problem flow resolves that same operation.
	if not cooking_plan.is_empty() and _code.begins_with("MEAL_"):
		failed = false
		_enter("wake")

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

# Called only by the live yard tick; no real-time/offline catch-up.
func consider_meal(delta: float, move: Vector2) -> void:
	if move.length() > 0.2:
		request_player_intent({"kind":"move"})
	if not busy() and not meal_route.is_empty():
		# In particular, the first leg has no cooking_plan yet. Validate its
		# original meal before the generic pending-action early return below.
		if not _meal_route_valid(delta):
			cancel_preparation()
			return
	if not busy() and not cooking_plan.is_empty():
		if move.length() > 0.2 or world._pending_interaction != "house_meal" or not _prepared_meal_valid():
			cancel_preparation()
		return
	meal_cooldown = maxf(0.0, meal_cooldown - delta)
	if busy() or meal_cooldown > 0.0 or not world.input_enabled or not available():
		meal_idle = 0.0
		return
	if move.length() > 0.2 or world._has_walk_goal or not world._pending_interaction.is_empty():
		meal_idle = 0.0
		return
	if world.get_player().carrying_grass or (world.ground_food != null and not world.ground_food.held().is_empty()):
		meal_idle = 0.0
		return
	meal_idle += delta
	if meal_idle < Meals.IDLE_SECONDS or not store.has_method("plan_meal") or not store.is_save_idle(): return
	meal_idle = 0.0
	var meal := Meals.meal_at(world.tod_fraction())
	if meal.is_empty(): return
	var plan: Dictionary = store.plan_meal(meal, Meals.recipes_for(meal), meal_rng)
	if plan.is_empty(): return
	# Use the normal walk route to the porch; never clamp/teleport from the yard
	# into the narrow indoor passage. Input can replace this unreserved route.
	world.notice_requested.emit("notice.meal.hungry")
	_request_meal_route("meal_basket", Basket.APPROACH, meal)

func _request_meal_route(target: String, point: Vector2, meal: String) -> void:
	meal_route = {"day":world.holiday_day, "meal":meal, "target":target,
		"seconds":0.0, "still":0.0, "position":world.get_player().position}
	world._request_action(target, point)
	if not busy() and world._pending_interaction != target:
		cancel_preparation()

func _meal_route_valid(delta: float) -> bool:
	if meal_route.day != world.holiday_day or meal_route.meal != Meals.meal_at(world.tod_fraction()) \
			or world._pending_interaction != meal_route.target or not world._has_walk_goal:
		return false
	meal_route.seconds += maxf(0.0, delta)
	meal_route.still += maxf(0.0, delta)
	var point: Vector2 = world.get_player().position
	if point.distance_to(meal_route.position) >= 1.0:
		meal_route.position = point
		meal_route.still = 0.0
	# Fully blocked destinations may clear, but must not own the actor forever.
	return meal_route.seconds < MEAL_ROUTE_TIMEOUT and meal_route.still < MEAL_ROUTE_STALL

func _set_cooking_smoke(active: bool) -> void:
	# Do not allocate a particle emitter for a house that has never cooked.
	if smoke == null and active:
		smoke = preload("res://scripts/presentation/cooking_smoke.gd").new()
		smoke.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(smoke)
		smoke.set_chimney_anchor(Vector2(286, 122))
		smoke.set_night_tint(Daylight.phase(world.tod_fraction()) == "night")
	if smoke != null: smoke.set_cooking(active)

func _cooking_hint() -> String:
	match str(cooking_plan.get("recipe_id", "")):
		"steamed_bun": return "notice.meal.buns"
		"wheat_noodles": return "notice.meal.noodles"
	return "notice.meal.cook"

func _sync_meal_ingredient() -> void:
	# Presentation of the chosen basket ingredient, never a second held ledger.
	# Cancellation and hidden-room stages must not leave a floating item behind.
	var player = world.get_player()
	meal_ingredient.visible = not cooking_plan.is_empty() and (stage in ["take", "porch", "open", "in"] or (stage.is_empty() and world._pending_interaction == "house_meal")) and player.visible
	if not meal_ingredient.visible: return
	var ingredients: Dictionary = cooking_plan.get("ingredients", {})
	if ingredients.size() != 1:
		meal_ingredient.visible = false
		return
	var kind := str(ingredients.keys()[0])
	if kind not in ["millet", "small", "medium", "flour"]:
		meal_ingredient.visible = false
		return
	meal_ingredient.texture = preload("res://assets/holiday/objects/flour-pouch-v1.png") if kind == "flour" else preload("res://assets/holiday/objects/millet.png") if kind == "millet" else preload("res://assets/holiday/objects/ground_fish.png")
	var width := 30.0 if kind == "flour" else 25.0 if kind == "millet" else 32.0 if kind == "medium" else 26.0
	var size: float = width * player.picture_depth * float(TuningStore.get_value("player.visual.scale", 1.0)) / meal_ingredient.texture.get_width()
	meal_ingredient.global_position = player.grass_hand_global_position()
	meal_ingredient.scale = Vector2(player.grass_hand_facing(), 1.0) * size
	meal_ingredient.modulate.a = player.modulate.a
	meal_ingredient.z_index = player.z_index + 1
