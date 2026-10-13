extends Node
## Active-world autonomous construction; producer tuning lives in GrowthSchedule.
## Explicit callers can also supply a live period reader and validated recipe.
const Rest := preload("res://scripts/game/rest_context.gd")
const View := preload("res://scripts/game/pond_edging_view.gd")
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Basket := preload("res://scripts/game/physical_basket.gd")
const Schedule := preload("res://scripts/game/growth_schedule.gd")
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

func consider(delta: float, move: Vector2) -> void:
	if not autonomous_enabled or busy() or not available() or not move.is_zero_approx() \
		or world._has_walk_goal or not world._pending_interaction.is_empty() or not store.is_save_idle():
		idle_seconds = 0.0
		return
	# Only active simulation seconds count: no offline/cross-day catch-up bursts.
	idle_seconds += clampf(delta, 0.0, 0.25)
	if idle_seconds < Schedule.IDLE_SECONDS: return
	idle_seconds = 0.0
	var current := Schedule.period(world.tod_fraction())
	var budget: Dictionary = store.get_growth_budget(current)
	if budget.has("error") or budget.get("available",0) < Schedule.POND_RECIPE.ap: return
	for id: String in Schedule.ORDER:
		if store.get_pond_edging().get("sections",{}).has(id): continue
		if begin(id, Schedule.station(id), Schedule.POND_RECIPE, func(): return Schedule.period(world.tod_fraction())):
			return

func _init(owner_world: Node2D, save_store: Node) -> void:
	world = owner_world
	store = save_store

func _ready() -> void:
	material = Sprite2D.new()
	material.name = "ConstructionMaterial"
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
	if busy() or not available() or world._has_walk_goal or not current_period.is_valid(): return false
	if id not in View.IDS or not station.is_finite() or not YardGround.allows(station,world.player_ground(),true): return false
	var angle := deg_to_rad(float(View.IDS.find(id)) * 45.0)
	var bank := Vector2(755,615) + Vector2(cos(angle)*245,sin(angle)*73)
	if station.distance_to(bank) > 90: return false
	if config.size() != 4 or not config.has_all(["ap","stones","experience","seconds"]): return false
	for key in ["ap","stones","experience"]:
		if not config[key] is int or config[key] < 1: return false
	if config.ap > 6 or config.stones > Inventory.MAX_COUNT or config.experience > Inventory.MAX_COUNT: return false
	if not (config.seconds is float or config.seconds is int) or not is_finite(float(config.seconds)) or config.seconds <= 0: return false
	var edging: Dictionary = store.get_pond_edging()
	if edging.is_empty() or edging.sections.has(id): return false
	var period: Variant = current_period.call()
	if not period is String: return false
	expected = store.get_growth_budget(period)
	if expected.has("error") or expected.available < config.ap: return false
	proposal = store.plan_growth_materials({STONE:{"id":"pond_edging","materials":{STONE:config.stones}}},RandomNumberGenerator.new())
	if proposal.is_empty() or store.get_rest_context().is_empty(): return false
	target = station
	leg_target = Basket.APPROACH
	if world.get_player().position.distance_to(leg_target) >= 14 and not world.try_walk_to(leg_target): return false
	if world.pond_story != null: world.pond_story.cancel()
	world._cancel_quiet_sky_look()
	world.get_player().clear_idle_rest()
	recipe = config.duplicate(true)
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
			var fresh: Dictionary = store.plan_growth_materials({STONE:{"id":"pond_edging","materials":{STONE:recipe.stones}}},RandomNumberGenerator.new())
			if fresh != proposal:
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
	pending = store.request_pond_growth(expected,section,proposal,recipe.ap,recipe.stones,recipe.experience)
	if pending.is_empty():
		stage = ""
		finished.emit("rejected")

func _pose_work() -> void:
	var walker = world.get_player()._sequence_walker
	if bool(TuningStore.get_value("ui.reduced_motion", false)):
		walker.reset_motion()
		return
	var progress := clampf(work / float(recipe.seconds), 0.0, 1.0)
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
	if not material.visible: return
	material.global_position = player.grass_hand_global_position()
	if stage == "working" and not bool(TuningStore.get_value("ui.reduced_motion", false)):
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
