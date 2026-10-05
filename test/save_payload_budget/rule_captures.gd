extends RefCounted
## Real PhotoMoment captures for every polaroid rule. Placements mirror
## test/photo_moment_render_suite.gd so each comes from a live YardWorld through
## the production rule/PhotoMoment path. Yard ticks may call SaveStore; callers
## must run inside a disposable user:// and reset the store afterwards.


static func capture_all(root: Node) -> Dictionary:
	var moments: Dictionary = {}
	var ids: Array = []
	var errors := PackedStringArray()
	var index := 0
	for rule: Dictionary in ExpressionCatalog.RULES:
		if not bool(rule.get("polaroid", false)): continue
		seed(5500 + index)
		index += 1
		var world = load("res://scripts/game/yard_world.gd").new()
		root.add_child(world)
		world.setup()
		world.holiday_day = 3
		world._weather_timer = 10000.0
		var player = world.get_player()
		var rule_id: String = rule.id
		match rule_id:
			"llama_fed_gentle":
				world.debug_place_actor("llama", Vector2(365, 560))
				world.debug_place_player(Vector2(300, 562))
				player.pick_grass()
			"llama_overcast_goose_annoyed":
				world.set_weather("overcast")
				world.debug_place_actor("llama", Vector2(705, 505))
				world.debug_place_player(Vector2(660, 520))
			"llama_sun_sheep_happy":
				world.debug_place_actor("llama", Vector2(358, 525))
				world.debug_place_player(Vector2(290, 535))
			"llama_sheep_cow_smirk":
				world.debug_place_actor("llama", Vector2(528, 514))
				world.debug_place_player(Vector2(560, 532))
			"duck_pond_chorus":
				world.debug_place_player(Vector2(830, 530))
			"goose_pond_rest":
				world.debug_place_player(Vector2(755, 522))
				world.actor_named("goose").state = "rest"
				world.actor_named("goose")._idle_time = 8.0
			"goose_duck_shore":
				world.debug_place_actor("duck_a", Vector2(769, 534))
				world.debug_place_player(Vector2(739, 512))
			"sheep_pair_near":
				world.debug_place_actor("sheep_b", world.actor_named("sheep_a").position + Vector2(48, 8))
				world.debug_place_player(Vector2(343, 515))
			"cow_rare_calm":
				world.debug_place_player(Vector2(416, 535))
		if rule_id == "plant_first_bloom": world._plant_state = world.PLANT_BLOOMED
		if rule_id == "fish_first_catch":
			world._fish_state = world.FISH_CAUGHT
			world._fish_catch_type = "small"
		world.tick(1.0 / 60.0, Vector2.ZERO)
		if rule_id == "llama_fed_gentle":
			world.try_interact()
		else:
			if rule_id == "llama_overcast_goose_annoyed":
				world._leading = true
				world._update_lead_rope()
			world.debug_force_rule(rule_id)
		var moment: Dictionary = world.photo_moments.get(rule_id, {})
		var clean := PhotoMoment.sanitize(JSON.parse_string(JSON.stringify(moment)))
		if moment.is_empty() or clean.is_empty() or str(clean.rule_id) != rule_id:
			errors.append("%s produced no legal PhotoMoment" % rule_id)
		else:
			moments[rule_id] = moment
			ids.append(rule_id)
		world.free()
	if ids != Array(ExpressionCatalog.all_ids()):
		errors.append("captured rules %s differ from ExpressionCatalog.all_ids() %s" % [ids, ExpressionCatalog.all_ids()])
	return {"ids": ids, "moments": moments, "errors": errors}


## Sanitize-legal synthetic photo: the capture padded to MAX_ITEMS by repeating
## its own recorded items. Not produced by gameplay.
static func dense(moment: Dictionary) -> Dictionary:
	var result: Dictionary = moment.duplicate(true)
	var source_items: Array = result.items.duplicate(true)
	while result.items.size() < PhotoMoment.MAX_ITEMS:
		result.items.append(source_items[result.items.size() % source_items.size()].duplicate(true))
	return result
