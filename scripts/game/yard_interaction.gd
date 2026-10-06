class_name YardInteraction
extends RefCounted

# The label, target and reach belong to one decision, shared by every input.
const PET_REACH := 85.0
const FEED_REACH := 110.0
const PATH_OUT_STANDING := 20.0
const PLANT_CORE := 60.0

static func action(target: String, point: Vector2, label: String, reach: float) -> Dictionary:
	return {"target": target, "point": point, "label": label, "reach": reach}

static func primary(world: Node2D) -> Dictionary:
	var player = world.get_player()
	if player == null:
		return {}
	if world.is_leading():
		if world.inventory_enabled:
			var exit_action := YardSceneHotspots.resolve(world, YardSceneHotspots.PATH_OUT)
			if not exit_action.is_empty() and (world._pending_interaction == YardSceneHotspots.PATH_OUT or player.position.distance_to(exit_action.point) <= PATH_OUT_STANDING):
				return exit_action
		return action("release", player.position, "action.release", INF)
	if world._fish_state != world.FISH_IDLE and player.position.distance_to(world._fishing_point()) < 110.0:
		return fishing(world)
	if world.inventory_enabled and world.ground_food != null and not world.ground_food.held().is_empty():
		if world._pending_interaction == "plant" or not YardSceneHotspots.get_hotspot(world._pending_interaction).is_empty():
			var pending := selected(world, world._pending_interaction)
			if not pending.is_empty(): return pending
		return action("drop_food", player.position, "action.drop_food", INF)
	# HUD, keyboard and pointer share the clicked/approached actor even while it wanders.
	for target: String in [world._pending_interaction, world._selected_target]:
		if not target.is_empty():
			var chosen := selected(world, target)
			if not chosen.is_empty():
				return chosen
	if not world._fish_carry_type.is_empty():
		var bird = nearest(world, ["duck", "goose"])
		if bird != null:
			return action("toss_fish:" + bird.actor_id, bird.position, "action.toss_fish", FEED_REACH)
	if player.carrying_grass:
		var llama = world.actor_named("llama")
		return action("llama", llama.position, "action.feed", 88.0)
	if player.position.distance_to(world._grass_point()) < 78.0:
		return action("grass", world._grass_point(), "action.grass", 78.0)
	var plant_action := plant(world)
	var candidates: Array[Dictionary] = [plant_action, fishing(world)]
	var scene_action := YardSceneHotspots.near_player(world)
	# Leaving the yard is a scene change: inside the plant bed's reach it only wins
	# right at the path end, never in the plant's core reach.
	if scene_action.get("target", "") == YardSceneHotspots.PATH_OUT \
			and player.position.distance_to(plant_action.point) < plant_action.reach \
			and (player.position.distance_to(scene_action.point) > PATH_OUT_STANDING \
				or player.position.distance_to(plant_action.point) < PLANT_CORE):
		scene_action = {}
	if not scene_action.is_empty():
		candidates.append(scene_action)
	for id: String in world._actors:
		var actor = world.actor_named(id)
		if actor.species == "llama":
			candidates.append(action("llama", actor.position, "action.lead", 88.0))
		elif actor.species in ["cow", "sheep", "horse", "dog"]:
			candidates.append(action("pet:" + id, actor.position, "action.pet", PET_REACH))
	var selected: Dictionary = {}
	var distance := INF
	for candidate: Dictionary in candidates:
		var gap: float = player.position.distance_to(candidate.point)
		if gap < candidate.reach and gap < distance:
			distance = gap
			selected = candidate
	return selected if not selected.is_empty() else action("grass", world._grass_point(), "action.grass", 78.0)

static func selected(world: Node2D, target: String) -> Dictionary:
	var player = world.get_player()
	if player == null:
		return {}
	if target.begins_with("ground_food:") and world.ground_food != null:
		var item: Dictionary = world.ground_food.find_item(int(target.get_slice(":", 1)))
		if item.is_empty() or not world.ground_food.held().is_empty(): return {}
		return action(target, Vector2(item.x, item.y), "action.pickup_food", 48.0)
	if target.begins_with("pet:") or target.begins_with("toss_fish:"):
		var actor = world.actor_named(target.get_slice(":", 1))
		if actor == null:
			return {}
		if target.begins_with("pet:") and actor.species in ["cow", "sheep", "horse", "dog"]:
			return action(target, actor.position, "action.pet", PET_REACH)
		if target.begins_with("toss_fish:") and actor.species in ["duck", "goose"] and not world._fish_carry_type.is_empty():
			return action(target, actor.position, "action.toss_fish", FEED_REACH)
		return {}
	if target == "llama":
		var llama = world.actor_named("llama")
		if llama != null:
			return action(target, llama.position, "action.feed" if player.carrying_grass else "action.lead", 88.0)
	if target == "grass" and not player.carrying_grass:
		return action(target, world._grass_point(), "action.grass", 78.0)
	if target == "plant":
		return plant(world)
	if target == "fishing" and world._fish_carry_type.is_empty():
		return fishing(world)
	var scene_action := YardSceneHotspots.resolve(world, target)
	if not scene_action.is_empty():
		return scene_action
	return {}

static func pointer(world: Node2D, point: Vector2) -> Dictionary:
	if world.inventory_enabled and world.is_leading():
		var exit_action := YardSceneHotspots.at_point(world, point)
		if exit_action.get("target", "") == YardSceneHotspots.PATH_OUT: return exit_action
	if world.inventory_enabled and world.ground_food != null:
		var item: Dictionary = world.ground_food.near_item(point, 22.0)
		if not item.is_empty() and world.ground_food.held().is_empty():
			return action("ground_food:%d" % int(item.id), Vector2(item.x, item.y), "action.pickup_food", 48.0)
		# While carrying, ground taps remain walking targets; the action button drops.
		if not world.ground_food.held().is_empty():
			if not world._fish_carry_type.is_empty() and (YardGround.in_pond(point) or point.distance_to(world._fishing_point()) < 38.0):
				return fishing(world)
			var scene := YardSceneHotspots.at_point(world, point)
			if not scene.is_empty(): return scene
			if Rect2(world._plant_point() - Vector2(36, 28), Vector2(72, 48)).has_point(point): return plant(world)
			return action("", point, "", 12.0)
	var selected = null
	var score := INF
	for id: String in world._actors:
		var actor = world.actor_named(id)
		var can_feed: bool = not world._fish_carry_type.is_empty() and actor.species in ["duck", "goose"]
		if not can_feed and actor.species not in ["llama", "cow", "sheep", "horse", "dog"]:
			continue
		var bounds: Rect2 = actor.visual_hit_rect().grow(5.0)
		if not bounds.has_point(point):
			continue
		var candidate: float = point.distance_to(bounds.get_center()) / maxf(bounds.size.y, 1.0)
		if candidate < score:
			score = candidate
			selected = actor
	if selected != null:
		if selected.species in ["duck", "goose"]:
			return action("toss_fish:" + selected.actor_id, selected.position, "action.toss_fish", FEED_REACH)
		if selected.species == "llama":
			return action("llama", selected.position, "action.feed" if world.get_player().carrying_grass else "action.lead", 88.0)
		return action("pet:" + selected.actor_id, selected.position, "action.pet", PET_REACH)
	if point.distance_to(world._grass_point()) < 35.0:
		return action("grass", world._grass_point(), "action.grass", 78.0)
	if Rect2(world._plant_point() - Vector2(36, 28), Vector2(72, 48)).has_point(point):
		return plant(world)
	if YardGround.in_pond(point) or point.distance_to(world._fishing_point()) < 38.0:
		return fishing(world)
	var scene_action := YardSceneHotspots.at_point(world, point)
	if not scene_action.is_empty():
		return scene_action
	return action("", point, "", 12.0)

static func nearest(world: Node2D, species: Array):
	var best = null
	var distance := INF
	for id: String in world._actors:
		var actor = world.actor_named(id)
		var gap: float = world.get_player().position.distance_to(actor.position)
		if actor.species in species and gap < distance:
			distance = gap
			best = actor
	return best

static func plant(world: Node2D) -> Dictionary:
	var label: String = ["action.plant", "action.water", "action.water", "action.harvest"][world._plant_state]
	return action("plant", world._plant_point(), label, 75.0)

static func fishing(world: Node2D) -> Dictionary:
	var label := "action.fish"
	if world._fish_state == world.FISH_CASTING: label = "action.fish_waiting"
	if world._fish_state == world.FISH_BITE: label = "action.reel"
	return action("fishing", world._fishing_point(), label, 85.0)

static func reach(target: String) -> float:
	if target == "drop_food": return INF
	if target.begins_with("ground_food:"): return 48.0
	if target == "llama": return 88.0
	if target == "grass": return 78.0
	if target == "plant": return 75.0
	if target == "fishing": return 85.0
	if target.begins_with("pet:"): return PET_REACH
	if target.begins_with("toss_fish:"): return FEED_REACH
	return YardSceneHotspots.reach(target)
