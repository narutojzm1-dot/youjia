extends RefCounted
## Controlled positions isolate the llama photo from competition; all food
## transfers, walking, consumption and photo saving use the production paths.
static func feed(main: Node, store: Node) -> bool:
	var world = main._world
	var player = world.get_player()
	world._leading = false
	player.leading = false
	world._stop_leading_llama()
	world._consume_pending_action()
	if not str(main._inventory.view().get("held", "")).is_empty():
		main._inventory.request("return", str(main._inventory.view().held))
		await store.flush_pending()
	world.debug_place_player(world._grass_point())
	world._interact_with_target("grass")
	await store.flush_pending()
	if not player.carrying_grass: return false
	var poses := {}
	for id: String in world._actors:
		poses[id] = world.actor_named(id).posed
		world.actor_named(id).posed = id != "llama"
	var llama = world.actor_named("llama")
	world.debug_place_actor("llama", Vector2(625, 510))
	world.ground_food.cooldowns.erase("llama")
	world.debug_place_player(Vector2(550, 510))
	world.request_primary_action()
	await store.flush_pending()
	world.debug_place_player(Vector2(510, 535))
	for frame in 1200:
		world.tick(0.05, Vector2.ZERO)
		if main._inventory.busy(): await store.flush_pending()
		if player.just_fed_seconds > 0.0: break
	await store.flush_pending()
	for id: String in poses: world.actor_named(id).posed = poses[id]
	return player.just_fed_seconds > 0.0 and not player.carrying_grass
