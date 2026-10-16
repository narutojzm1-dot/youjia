extends Node
## One active-world worker for pond construction and milling. The public name
## stays compatible with existing house/menu/player ownership and cancellation.
## Explicit callers can also supply a live period reader and validated recipe.
const Rest := preload("res://scripts/game/rest_context.gd")
const View := preload("res://scripts/game/pond_edging_view.gd")
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Basket := preload("res://scripts/game/physical_basket.gd")
const Schedule := preload("res://scripts/game/growth_schedule.gd")
const Stove := preload("res://scripts/game/yard_stove.gd")
const StoveView := preload("res://scripts/game/yard_stove_view.gd")
const STONE := ExplorationRoutes.FIND_STONE
signal finished(result: String)
var world: Node2D
var store: Node
var stage := ""
var pending := ""
var elapsed := 0.0
var work := 0.0
var target := Vector2.ZERO
var recipe := {}
var expected := {}
var proposal := {}
var section := ""
var period_reader: Callable
var leg_target := Vector2.ZERO
var material: Sprite2D
var autonomous_enabled := true
var idle_seconds := 0.0
var action_id := ""
var milling_station := Vector2(INF, INF)
var milling_work_point := Vector2(INF, INF)
var material_rng := RandomNumberGenerator.new()
var stove_stage := -1

func consider(delta: float, move: Vector2) -> void:
	if not autonomous_enabled or busy() or not available() or not move.is_zero_approx() \
		or world._has_walk_goal or not world._pending_interaction.is_empty() or not store.is_save_idle():
		idle_seconds = 0.0
		return
	# Only active simulation seconds count: no offline/cross-day catch-up bursts.
	idle_seconds += clampf(delta, 0.0, 0.25)
	if idle_seconds < Schedule.IDLE_SECONDS: return
	idle_seconds = 0.0
	begin_available(func(): return Schedule.period(world.tod_fraction()))

## Prerequisites are filtered before ONE cross-material draw. Multiple pond
## sections never give stone extra weight. Failed/stale plans are not redrawn.
func begin_available(current_period: Callable) -> bool:
	if not _can_start(current_period) or not store.is_save_idle(): return false
	var period: Variant = current_period.call()
	if not period is String: return false
	var budget: Dictionary = store.get_growth_budget(period)
	if budget.has("error"): return false
	var jobs := {}
	# PR801 replaces FUTURE autonomous stone work. Legacy pond receipts and
	# explicit compatibility entry points remain intact, never converted/rewarded.
	if budget.available >= Schedule.STOVE_RECIPE.ap and _stove_ready(Schedule.STOVE_RECIPE):
		jobs[STONE] = {"id":"stove","station":StoveView.APPROACH,"recipe":Schedule.STOVE_RECIPE,
			"action":{"id":"build_stove","materials":{STONE:Schedule.STOVE_RECIPE.stones}}}
	if budget.available >= Schedule.MILL_RECIPE.ap and _mill_ready(milling_station, Schedule.MILL_RECIPE):
		jobs["wheat"] = {"id":"","station":milling_station,"recipe":Schedule.MILL_RECIPE,
			"action":{"id":"mill_wheat","materials":{"wheat":Schedule.MILL_RECIPE.wheat}}}
	var catalog := {}
	for primary: String in jobs: catalog[primary] = jobs[primary].action
	if catalog.is_empty(): return false
	var chosen: Dictionary = store.plan_growth_materials(catalog, material_rng)
	if chosen.is_empty(): return false
	var job: Dictionary = jobs[chosen.primary]
	return _start(job.id, job.station, job.recipe, current_period, budget, chosen)

func _init(owner_world: Node2D, save_store: Node) -> void:
	world = owner_world
	store = save_store
	# Production uses an independent, freshly randomized stream; test fixtures
	# may seed this instance explicitly without changing the whole world's RNG.
	material_rng.randomize()

func _ready() -> void:
	material = Sprite2D.new()
	material.name = "ConstructionMaterial"
	material.set_meta("photo_player_carried", true)
	material.texture = KeepsakeArt.texture(STONE)
	material.z_as_relative = false
	material.hide()
	add_child(material)
	store.commit_confirmed.connect(_confirmed)
	store.commit_rejected.connect(_rejected)

func _exit_tree() -> void:
	if store.commit_confirmed.is_connected(_confirmed): store.commit_confirmed.disconnect(_confirmed)
	if store.commit_rejected.is_connected(_rejected): store.commit_rejected.disconnect(_rejected)

func busy() -> bool: return not stage.is_empty()

func available() -> bool:
	var player = world.get_player()
	return player != null and world.simulation_active and world.input_enabled \
		and not world.inventory_busy and not world._leading and world._fish_state == world.FISH_IDLE \
		and not player.carrying_grass and not world._millet_held and world._grain_held.is_empty() \
		and world._fish_carry_type.is_empty() and world._goose_mount_phase < 0 \
		and (world.house == null or not world.house.owns_actor())

func begin(id: String, station: Vector2, config: Dictionary, current_period: Callable) -> bool:
	if not _can_start(current_period) or not _pond_ready(id, station, config): return false
	return _begin_explicit(id, station, config, current_period, {STONE:{"id":"pond_edging","materials":{STONE:config.stones}}})

func begin_milling(station: Vector2, config: Dictionary, current_period: Callable) -> bool:
	if not _can_start(current_period) or station != milling_station or not _mill_ready(station, config): return false
	return _begin_explicit("", station, config, current_period, {"wheat":{"id":"mill_wheat","materials":{"wheat":config.wheat}}})

func begin_stove(config: Dictionary, current_period: Callable) -> bool:
	if not _can_start(current_period) or not _stove_ready(config): return false
	return _begin_explicit("stove",StoveView.APPROACH,config,current_period,{STONE:{"id":"build_stove","materials":{STONE:config.stones}}})

func _stove_ready(config: Dictionary) -> bool:
	if not _valid_recipe(config,["ap","stones","experience"]): return false
	var value: Dictionary = store.get_yard_stove()
	return not value.is_empty() and value.revision < Stove.STAGES and YardGround.allows(StoveView.APPROACH,world.player_ground(),true) and not YardGround.route(Basket.APPROACH,StoveView.APPROACH).is_empty()

func _can_start(current_period: Callable) -> bool:
	return not busy() and available() and not world._has_walk_goal and world._pending_interaction.is_empty() and current_period.is_valid()

func _valid_recipe(config: Dictionary, quantities: Array) -> bool:
	if config.size() != quantities.size() + 1 or not config.has("seconds"): return false
	for key: String in quantities:
		if not config.has(key) or not config[key] is int or config[key] < 1 or config[key] > Inventory.MAX_COUNT: return false
	return config.ap <= 6 and (config.seconds is float or config.seconds is int) and is_finite(float(config.seconds)) and config.seconds > 0

func _pond_ready(id: String, station: Vector2, config: Dictionary) -> bool:
	if id not in View.IDS or not station.is_finite() or not YardGround.allows(station,world.player_ground(),true): return false
	var angle := deg_to_rad(float(View.IDS.find(id)) * 45.0)
	var bank := Vector2(755,615) + Vector2(cos(angle)*245,sin(angle)*73)
	if station.distance_to(bank) > 90: return false
	if not _valid_recipe(config,["ap","stones","experience"]): return false
	var edging: Dictionary = store.get_pond_edging()
	if edging.is_empty() or edging.sections.has(id): return false
	return not YardGround.route(Basket.APPROACH, station).is_empty()

func _mill_ready(station: Vector2, config: Dictionary) -> bool:
	if not station.is_finite() or not YardGround.allows(station,world.player_ground(),true): return false
	if not _valid_recipe(config,["ap","wheat","flour","experience"]): return false
	var production: Dictionary = store.get_growth_production()
	var inventory: Dictionary = store.get_yard_inventory()
	if production.is_empty() or inventory.is_empty() or production.revision >= Inventory.MAX_REVISION: return false
	if inventory.revision >= Inventory.MAX_REVISION or inventory.flour > Inventory.MAX_COUNT - config.flour: return false
	return not YardGround.route(Basket.APPROACH, station).is_empty()

func _begin_explicit(id: String, station: Vector2, config: Dictionary, current_period: Callable, catalog: Dictionary) -> bool:
	var period: Variant = current_period.call()
	if not period is String: return false
	var budget: Dictionary = store.get_growth_budget(period)
	if budget.has("error") or budget.available < config.ap: return false
	var chosen: Dictionary = store.plan_growth_materials(catalog, material_rng)
	if chosen.is_empty(): return false
	return _start(id, station, config, current_period, budget, chosen)

func _start(id: String, station: Vector2, config: Dictionary, current_period: Callable, budget: Dictionary, chosen: Dictionary) -> bool:
	if not store.validate_growth_materials(chosen).is_empty() or store.get_rest_context().is_empty(): return false
	target = station
	leg_target = Basket.APPROACH
	if world.get_player().position.distance_to(leg_target) >= 14 and not world.try_walk_to(leg_target): return false
	if world.pond_story != null: world.pond_story.cancel()
	world._cancel_quiet_sky_look()
	world.get_player().clear_idle_rest()
	recipe = config.duplicate(true)
	expected = budget.duplicate(true)
	proposal = chosen.duplicate(true)
	action_id = str(proposal.action_id)
	stove_stage = int(store.get_yard_stove().get("revision",-1)) if action_id == "build_stove" else -1
	material.texture = preload("res://scripts/game/crop_art.gd").texture("wheat") if action_id == "mill_wheat" else KeepsakeArt.texture(STONE)
	period_reader = current_period
	section = id
	elapsed = 0.0
	work = 0.0
	stage = "fetching"
	return true

func cancel() -> void:
	idle_seconds = 0.0
	# An accepted write can no longer be cancelled. Release actor ownership but
	# retain the identity until its durable result; never submit a replacement.
	if stage in ["fetching","taking","walking","working"]:
		if world._has_walk_goal and world._walk_goal == leg_target: world._consume_pending_action()
		world.get_player().clear_idle_rest()
		if is_instance_valid(world.get_player()._sequence_walker): world.get_player()._sequence_walker.reset_motion()
		stage = ""
		material.hide()
		finished.emit("cancelled")

func tick(delta: float, move: Vector2) -> void:
	if stage.is_empty() or stage == "saving": return
	if not available() or not move.is_zero_approx() or not period_reader.is_valid():
		cancel()
		return
	if period_reader.call() != expected.period or store.get_holiday_day() != expected.day:
		cancel()
		return
	if world._has_walk_goal and world._walk_goal != leg_target:
		cancel()
		return
	elapsed += maxf(0,delta)
	if stage == "fetching":
		if elapsed > 90:
			cancel()
		elif not world._has_walk_goal and world.get_player().position.distance_to(Basket.APPROACH) < 16:
			# Revalidate at the basket; never carry a visual for unavailable stock.
			if not _plan_valid():
				cancel()
				return
			stage = "taking"
			elapsed = 0
			world.get_player()._play_grass_action(&"pickup")
		return
	if stage == "taking":
		if world.get_player().position.distance_to(Basket.APPROACH) >= 16:
			cancel()
			return
		# Presentation timing only; fatigue does not slow material retrieval.
		if elapsed < 0.8: return
		leg_target = target
		if world.get_player().position.distance_to(target) >= 14 and not world.try_walk_to(target):
			cancel()
			return
		stage = "walking"
		elapsed = 0
		return
	if stage == "walking":
		if elapsed > 90:
			cancel()
		elif not world._has_walk_goal and world.get_player().position.distance_to(target) < 16:
			if not _plan_valid():
				cancel()
				return
			stage = "working"
			elapsed = 0
			world.get_player().reset_locomotion()
			_pose_work()
		return
	if world.get_player().position.distance_to(target) >= 16:
		cancel()
		return
	# Only production work is slowed. Existing movement and animation clocks,
	# earned AP, material/result quantities and experience stay unchanged.
	work += maxf(0,delta) * Rest.work_speed(store.get_rest_context())
	if work < float(recipe.seconds):
		_pose_work()
		return
	stage = "saving"
	world.get_player()._sequence_walker.reset_motion()
	material.hide()
	if action_id == "mill_wheat":
		pending = store.request_milling(expected,proposal,{"ap":recipe.ap,"wheat":recipe.wheat,"flour":recipe.flour,"experience":recipe.experience})
	elif action_id == "build_stove":
		pending = store.request_stove_growth(expected,stove_stage,proposal,{"ap":recipe.ap,"stones":recipe.stones,"experience":recipe.experience})
	else:
		pending = store.request_pond_growth(expected,section,proposal,recipe.ap,recipe.stones,recipe.experience)
	if pending.is_empty():
		stage = ""
		finished.emit("rejected")

func _plan_valid() -> bool:
	return store.validate_growth_materials(proposal).is_empty() and store.get_growth_budget(expected.period) == expected

func _pose_work() -> void:
	var walker = world.get_player()._sequence_walker
	if bool(TuningStore.get_value("ui.reduced_motion", false)):
		walker.reset_motion()
		return
	var progress := clampf(work / float(recipe.seconds), 0.0, 1.0)
	if action_id == "build_stove":
		var player = world.get_player()
		player.facing = -1.0
		player._gait.face = -1.0
		# First course uses grounded crouch; raised courses use the authored
		# reaching cels. Contact is toward the real work surface, no body shake.
		walker.hold_action_frame(&"pickup" if stove_stage == 0 else &"feed",4 if int(work/0.8)%2 == 0 else 3)
		return
	if action_id == "mill_wheat":
		# Reuse the authored reaching sequence for the handle; the character and
		# stone are never stretched or spun as a whole cutout.
		if milling_work_point.is_finite():
			var player = world.get_player()
			player.facing = 1.0 if milling_work_point.x >= player.position.x else -1.0
			player._gait.face = player.facing
		var reach_frame := mini(4, int(progress / 0.2 * 5.0)) if progress < 0.2 else 4 + int(work / 0.75) % 2
		walker.hold_action_frame(&"feed", reach_frame)
		return
	var frame: int
	if progress < 0.2:
		frame = mini(4, int(progress / 0.2 * 5.0))
	elif progress < 0.8:
		# Reuse authored crouch poses to settle the stone, without deforming art.
		frame = 4 if int(work / 0.75) % 2 == 0 else 3
	else:
		frame = mini(8, 4 + int((progress - 0.8) / 0.2 * 5.0))
	walker.hold_action_frame(&"pickup", frame)

func sync_presentation() -> void:
	# Called after the actor tick so the stone uses this frame's hand/depth,
	# including the first frame after arriving or cancelling.
	# Presentation of this plan only, not a second inventory/held-item ledger.
	# The existing atomic completion is still the sole material debit.
	var player = world.get_player()
	material.visible = stage in ["walking","working"] and player.visible
	if action_id == "mill_wheat" and stage == "working" and work >= float(recipe.seconds) * 0.2:
		material.visible = false
	if not material.visible: return
	material.global_position = player.grass_hand_global_position()
	if stage == "working" and action_id == "build_stove":
		var point := StoveView.WORK_POINT + Vector2(0,18 if stove_stage == 0 else 0)
		material.global_position = material.global_position.lerp(world.to_global(point),clampf(work / float(recipe.seconds) / 0.2,0.0,1.0))
	elif stage == "working" and action_id == "mill_wheat" and milling_work_point.is_finite():
		material.global_position = material.global_position.lerp(world.to_global(milling_work_point),clampf(work / float(recipe.seconds) / 0.2,0.0,1.0))
	elif stage == "working" and not bool(TuningStore.get_value("ui.reduced_motion", false)):
		var ground: Vector2 = player.global_position + Vector2(14.0 * player.grass_hand_facing(), -4.0) * player.picture_depth
		var placing := clampf(work / float(recipe.seconds) / 0.2, 0.0, 1.0)
		material.global_position = material.global_position.lerp(ground, placing)
	material.scale = Vector2(player.grass_hand_facing(),1) * 22.0 * player.picture_depth / material.texture.get_width()
	material.modulate = player.modulate
	material.z_index = player.z_index + 1

func _confirmed(id: String, kind: String) -> void:
	if pending.is_empty() or id != pending or kind != "growth": return
	pending = ""
	stage = ""
	finished.emit("confirmed")

func _rejected(id: String, kind: String, _code: String) -> void:
	if pending.is_empty() or id != pending or kind != "growth": return
	pending = ""
	stage = ""
	finished.emit("rejected")
