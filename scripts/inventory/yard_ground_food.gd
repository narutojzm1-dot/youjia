extends Node2D
## Visuals and intentions only. SaveStore owns all food and removes it only on commit.
const Grass := preload("res://scripts/entities/grass_art.gd")
const Fish := preload("res://assets/holiday/objects/ground_fish.png")
const Millet := preload("res://assets/holiday/objects/millet.png")
const GroundShadow := preload("res://scripts/inventory/ground_food_shadow.gd")
var world: Node2D
var items: Array = []
var sprites: Dictionary = {}
## REQ-20261008-075：每份地上食物脚下的静止接触影（id → GroundShadow）
var shadows: Dictionary = {}
var targets: Dictionary = {}
var waiting: Dictionary = {}
var cooldowns: Dictionary = {}


func _init(host: Node2D) -> void:
	world = host


func held() -> String:
	if world._millet_held: return "millet"
	if world.get_player().carrying_grass: return "grass"
	return world._fish_carry_type


func find_item(id: int) -> Dictionary:
	for item: Dictionary in items:
		if int(item.id) == id: return item
	return {}


func near_item(point: Vector2, reach: float) -> Dictionary:
	var nearest: Dictionary = {}
	for item: Dictionary in items:
		var distance := point.distance_to(Vector2(item.x, item.y))
		if distance < reach:
			reach = distance
			nearest = item
	return nearest


func sync_items(confirmed: Array) -> void:
	items = confirmed.duplicate(true)
	var seen: Array = []
	for item: Dictionary in items:
		var id := int(item.id)
		seen.append(id)
		var point := Vector2(item.x, item.y)
		var depth := YardGround.depth_at(point.y)
		if not sprites.has(id):
			var shadow: Node2D = GroundShadow.new()
			shadow.z_as_relative = false
			add_child(shadow)
			shadows[id] = shadow
			var sprite := Sprite2D.new()
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			sprite.texture = Millet if item.kind == "millet" else (Grass.texture_for(Grass.LOOSE) if item.kind == "grass" else Fish)
			var width := 34.0 if item.kind == "grass" else (38.0 if item.kind == "medium" else 30.0)
			sprite.scale = Vector2.ONE * width / sprite.texture.get_width()
			sprite.z_as_relative = false
			add_child(sprite)
			sprites[id] = sprite
		var visual: Sprite2D = sprites[id]
		visual.position = point
		visual.z_index = roundi(point.y)
		var shadow_node: Node2D = shadows[id]
		shadow_node.position = point
		shadow_node.z_index = roundi(point.y) - 1
		shadow_node.configure(str(item.kind), depth)
	for id: int in sprites.keys():
		if not seen.has(id):
			sprites[id].queue_free()
			sprites.erase(id)
			if shadows.has(id):
				shadows[id].queue_free()
				shadows.erase(id)


func drop_held() -> void:
	if world.inventory_busy or held().is_empty(): return
	if items.size() >= 32:
		world.notice_requested.emit("notice.food_full")
		return
	var player = world.get_player()
	# Place nearby, fully on accessible ground. Never silently throw into water/fence.
	for offset: Vector2 in [Vector2(30 * player.facing, 8), Vector2(-30 * player.facing, 8), Vector2(0, 22), Vector2(0, -22)]:
		var point: Vector2 = player.position + offset
		if not YardGround.allows(point, YardGround.lawn(), true): continue
		if not YardBodies.clear_at(point, Vector2(12, 6), world.physical_obstacles("player")): continue
		if not near_item(point, 22.0).is_empty(): continue
		world.ground_food_requested.emit("drop", held(), {"x": point.x, "y": point.y}, "")
		return
	world.notice_requested.emit("notice.cannot_walk")


func pickup(id: int) -> void:
	var item := find_item(id)
	if item.is_empty() or world.inventory_busy or not held().is_empty(): return
	if world.get_player().position.distance_to(Vector2(item.x, item.y)) >= 48.0: return
	world.ground_food_requested.emit("pickup", str(item.kind), {"id": id}, "")


func settled(action: String, consumer: String) -> void:
	match action:
		"harvest":
			world._grass_patch.harvest(world.get_player(), true)
			world.notice_requested.emit("notice.picked_grass")
		"drop": world.notice_requested.emit("notice.food_dropped")
		"pickup": world.notice_requested.emit("notice.food_picked")
		"eat":
			var actor = world.actor_named(consumer)
			if actor != null:
				actor.leave_food()
				actor.acknowledge_feed(actor.position)
				if actor.species == "llama":
					world.get_player().just_fed_seconds = 6.0
					world.get_player().player_state = "just_fed"
					world._evaluate_expressions()
			cooldowns[consumer] = 12.0
			targets.erase(consumer)
			waiting.erase(consumer)
			world.notice_requested.emit("notice.food_eaten.%s" % actor.species if actor != null else "notice.food_eaten")


func _accepts(actor: FeltActor, item: Dictionary) -> bool:
	if item.kind == "millet": return actor.species == "chicken"
	return actor.species in ["cow", "sheep", "llama"] if item.kind == "grass" else actor.species in ["duck", "goose"]


func _approach(actor: FeltActor, item: Dictionary) -> Vector2:
	var point := Vector2(item.x, item.y)
	if actor.species in ["cow", "sheep"]:
		var grazing = preload("res://scripts/game/cow_ground_art.gd") if actor.species == "cow" else preload("res://scripts/game/sheep_ground_art.gd")
		var mouth: Vector2 = grazing.mouth_offset(actor, point)
		# Another animal may occupy the near-side stance. Walk around to the
		# mirrored stance when clear; do not enlarge bite reach or move the food.
		for side: float in [1.0, -1.0]:
			var feet := point - Vector2(mouth.x * side, mouth.y)
			if not YardGround.allows(feet, actor.walk_ground, actor.avoid_pond): continue
			var radius := actor.body_radius * YardGround.depth_at(feet.y)
			if YardBodies.clear_at(feet, radius, world.physical_obstacles(actor.actor_id)): return feet
		return Vector2.INF
	if actor.species == "chicken":
		var side := signf(point.x - actor.position.x)
		if side == 0.0: side = actor.facing
		var beak := (21.0 if actor.get_meta("resident_stage", "") == "hen" else 10.0) * YardGround.depth_at(point.y)
		return point - Vector2(side * beak, -3.0)
	if not actor.use_ellipse:
		var radius: Vector2 = actor.body_radius * YardGround.depth_at(point.y)
		var obstacles: Array = world.physical_obstacles(actor.actor_id)
		if YardBodies.clear_at(point, radius, obstacles): return point
		# Another animal can occupy the food's centre while its edge remains
		# reachable. Approach a clear nearby point without enlarging eating reach.
		var approach := Vector2.INF
		var nearest := INF
		for step in 16:
			var angle := TAU * float(step) / 16.0
			var candidate := point + Vector2(cos(angle), sin(angle)) * 14.0
			if not YardGround.allows(candidate, actor.walk_ground, actor.avoid_pond): continue
			if not YardBodies.clear_at(candidate, radius, obstacles): continue
			var distance := actor.position.distance_squared_to(candidate)
			if distance < nearest:
				nearest = distance
				approach = candidate
		return approach
	# Ducks stay in their own water. Only a reachable bank morsel is considered.
	var relative := (point - actor.ellipse_center) / actor.ellipse_radius
	var bank := actor.ellipse_center + relative.limit_length(0.98) * actor.ellipse_radius
	return bank if bank.distance_to(point) <= 40.0 else Vector2.INF


func attraction_radius(actor: FeltActor, item: Dictionary) -> float:
	if actor.species != "cow" or item.kind != "grass": return 175.0
	var bunches := 0
	var point := Vector2(item.x, item.y)
	for other: Dictionary in items:
		if other.kind == "grass" and point.distance_to(Vector2(other.x, other.y)) < 100.0:
			bunches += 1
	# One nearby snack does not create following. Several bundles in one place
	# can interest the cow across the yard, including beside the gate.
	return 175.0 + 70.0 * mini(5, maxi(0, bunches - 1))


func tick(delta: float) -> void:
	for id: String in cooldowns.keys():
		cooldowns[id] = maxf(0.0, float(cooldowns[id]) - delta)
	if not world.input_enabled or world.inventory_busy: return
	var ready: Array = []
	for id: String in world._actors:
		var actor: FeltActor = world.actor_named(id)
		if actor.posed or actor.state == "lead" or float(cooldowns.get(id, 0.0)) > 0.0: continue
		var item := find_item(int(targets.get(id, -1)))
		if item.is_empty():
			waiting.erase(id)
			var best := INF
			for candidate: Dictionary in items:
				if not _accepts(actor, candidate): continue
				var point := _approach(actor, candidate)
				if not point.is_finite(): continue
				var distance := actor.position.distance_to(point)
				if distance > attraction_radius(actor, candidate): continue
				if distance < best:
					best = distance
					item = candidate
			if item.is_empty():
				actor.leave_food()
				targets.erase(id)
				continue
			targets[id] = int(item.id)
		var goal := _approach(actor, item)
		if not goal.is_finite():
			actor.leave_food()
			waiting.erase(id)
			continue
		actor.seek_food(goal)
		var eating_point := goal if actor.use_ellipse or actor.species in ["chicken", "cow", "sheep"] else Vector2(item.x, item.y)
		var distance := actor.position.distance_to(eating_point)
		if distance < (5.0 if actor.species in ["chicken", "cow", "sheep"] else 18.0):
			if actor.species == "chicken": actor.show_painted_ack("peck", 0.2)
			if actor.species in ["cow", "sheep"]: actor.show_ground_bite("graze", Vector2(item.x, item.y))
			waiting[id] = float(waiting.get(id, 0.0)) + delta
			if float(waiting[id]) >= 1.2: ready.append({"actor": id, "item": item, "distance": distance})
		else: waiting[id] = 0.0
	# All arrivals compete before one durable consume is submitted. Ties aren't
	# decided by the fixed actor insertion order; the loser must find another item.
	if not ready.is_empty():
		ready.shuffle()
		ready.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.distance) < float(b.distance))
		var winner: Dictionary = ready[0]
		world.ground_food_requested.emit("eat", str(winner.item.kind), {"id": int(winner.item.id)}, str(winner.actor))
