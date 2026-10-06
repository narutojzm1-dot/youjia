extends SceneTree

# Headless data/render-node contract, plus an optional native six-card fixture:
# godot --headless --path . --script res://test/photo_moment_render_suite.gd
# godot --path . --script res://test/photo_moment_render_suite.gd -- --preview
# Fixture only: creates temporary worlds, never loads/writes the player's save.
const Moment := preload("res://scripts/ui/photo_moment.gd")
var _checks := 0
var _failures := PackedStringArray()
var _preview := false
var _completed_events := 0
var _gallery: Control


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_preview = "--preview" in OS.get_cmdline_user_args()
	root.get_node("TuningStore").call("end_run")
	root.get_node("TuningStore").call("reset_defaults")
	_gallery = Control.new()
	_gallery.size = Vector2(1280, 720)
	root.add_child(_gallery)
	_test_invalid()
	_test_weather_layer()
	var index := 0
	for rule: Dictionary in ExpressionCatalog.RULES:
		if not bool(rule.get("polaroid", false)): continue
		_test_event(rule, index)
		index += 1
	_check(_completed_events == ExpressionCatalog.all_ids().size(), "all current event fixtures completed without runtime errors")
	await process_frame
	await process_frame
	root.get_node("AudioDirector").call("release_streams")
	if _failures.is_empty():
		print("[photo-moment-tests] PASS: %d checks" % _checks)
	else:
		for failure: String in _failures:
			push_error("[photo-moment-tests] " + failure)
		print("[photo-moment-tests] FAIL: %d failures across %d checks" % [_failures.size(), _checks])
	if not _preview: quit(0 if _failures.is_empty() else 1)


func _test_weather_layer() -> void:
	var world_script: Script = load("res://scripts/game/yard_world.gd")
	_check(world_script != null and world_script.can_instantiate(), "weather fixture yard compiles")
	if world_script == null or not world_script.can_instantiate(): return
	var world = world_script.new()
	root.add_child(world)
	world.setup()
	var layer := world.get_node_or_null("WeatherBackdropBlend") as Sprite2D
	if layer == null:
		layer = Sprite2D.new()
		layer.name = "WeatherBackdropBlend"
		world.add_child(layer)
	layer.texture = load("res://assets/holiday/environment/yard_overcast.png")
	layer.centered = false
	layer.scale = world._backdrop.scale
	layer.modulate = Color(0.96, 0.95, 0.98, 0.375)
	layer.visible = true
	layer.z_index = -1
	var snapshot := Moment.capture(world, ExpressionCatalog.find_rule("llama_fed_gentle"))
	_check(not snapshot.is_empty(), "weather transition captures using version-one fields")
	var recorded: Dictionary = {}
	for item: Dictionary in snapshot.get("items", []):
		if item.subject == "weather_background": recorded = item
	_check(not recorded.is_empty(), "named live weather layer is captured separately")
	if recorded.is_empty():
		world.free()
		return
	_check(is_equal_approx(float(recorded.modulate[3]), 0.375), "capture retains exact transition alpha")
	layer.modulate.a = 0.9
	var restored := Moment.sanitize(JSON.parse_string(JSON.stringify(snapshot)))
	var card := Moment.new()
	card.setup(restored)
	var found := false
	for visual: Node in card._stage.get_children():
		if visual.get_meta("subject", "") == "weather_background":
			found = true
			_check(visual.get_index() > card._ground.get_index() and visual.get_index() < card._shadows.get_index(), "weather paint replays after base but before contact shadows")
			_check(is_equal_approx(visual.modulate.a, 0.375), "replayed weather alpha is frozen despite live layer changing")
		elif visual.get_meta("subject", "") == "weather_cloud":
			_check(visual.get_index() > card._ground.get_index() and visual.get_index() < card._shadows.get_index(), "captured weather clouds stay below contact shadows")
		elif visual.has_meta("subject"):
			_check(visual.get_index() > card._shadows.get_index(), "ordinary and legacy negative-depth items retain their placement after shadows")
	_check(found, "weather layer survives JSON restoration and card creation")
	card.free()
	layer.hide()
	var legacy := Moment.capture(world, ExpressionCatalog.find_rule("llama_fed_gentle"))
	_check(not legacy.is_empty() and not _has_subject(legacy, "weather_background"), "hidden weather layer preserves ordinary legacy capture")
	world.free()


func _test_event(rule: Dictionary, index: int) -> void:
	seed(5500 + index)
	var world_script: Script = load("res://scripts/game/yard_world.gd")
	_check(world_script != null and world_script.can_instantiate(), "yard compiles")
	if world_script == null or not world_script.can_instantiate(): return
	var world = world_script.new()
	root.add_child(world)
	world.setup()
	world.holiday_day = 3
	world._weather_timer = 10000.0
	var llama = world.actor_named("llama")
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
		# First record a real visible bundle, then prove the fed snapshot lacks it.
		var carrying := Moment.capture(world, rule)
		_check(not carrying.is_empty(), "carrying scene captures")
		_check(_count_atlases(carrying) >= 3, "grass patch and held bundle retain atlas regions")
		world.try_interact()
	else:
		if rule_id == "llama_overcast_goose_annoyed":
			world._leading = true
			world._update_lead_rope()
		world.debug_force_rule(rule_id)
	var positions: Dictionary = {}
	for id: String in world._actors:
		positions[id] = world.actor_named(id).position
	var player_position: Vector2 = player.position
	var collection: PackedStringArray = world.collected.duplicate()
	var snapshot: Dictionary = world.photo_moments.get(rule_id,{})
	_check(not snapshot.is_empty(), "%s creates a snapshot" % rule_id)
	if snapshot.is_empty():
		world.free()
		return
	_check(snapshot.version == 1 and snapshot.rule_id == rule_id, "%s version and keyed identity" % rule_id)
	_check(snapshot.weather == world.weather, "%s preserves light" % rule_id)
	_check(snapshot.has("caption_variant") and int(snapshot.caption_variant) >= 0 and int(snapshot.caption_variant) < int(rule.get("caption_variants", 1)), "%s saves exactly one permitted caption variant" % rule_id)
	var crop_focus := Vector2(float(snapshot.focus[0]), float(snapshot.focus[1]))
	var crop_extent := Vector2.ONE * float(snapshot.span)
	var crop_bounds := Rect2(crop_focus - crop_extent * 0.5, crop_extent)
	_check(Rect2(Vector2.ZERO, world.get_world_size()).encloses(crop_bounds), "%s square crop stays inside the painted backdrop" % rule_id)
	var json := JSON.stringify(snapshot)
	var restored := Moment.sanitize(JSON.parse_string(json))
	_check(not restored.is_empty(), "%s survives a JSON save roundtrip" % rule_id)
	_check(_same_json_value(restored, snapshot), "%s roundtrip retains scene values" % rule_id)
	_check(json.length() < 24000, "%s bounded metadata size (%d bytes)" % [rule_id, json.length()])
	_check(player.position == player_position and world.collected == collection, "%s capture never mutates player or progress" % rule_id)
	for id: String in positions:
		_check(world.actor_named(id).position == positions[id], "%s capture leaves %s in place" % [rule_id, id])
	var found_hero := false
	var found_llama := false
	var found_rope := false
	var previous_depth := -100000
	for item: Dictionary in snapshot.items:
		_check(int(item.depth) >= previous_depth, "%s sorted depth" % rule_id)
		previous_depth = int(item.depth)
		if item.kind == "line":
			found_rope = true
			_check(item.points.size() == 17, "all actual lead curve points retained")
		if item.subject == "player" and item.kind == "sprite" and (item.texture.get("path", "").contains("resident_walk_authored_v1") or str(item.texture.get("atlas", "")).contains("resident_grass_actions_v1")):
			found_hero = true
			_check(item.texture == Moment._texture_data(player._sequence_walker.sprite_frames.get_frame_texture(player._sequence_walker.animation, player._sequence_walker.frame)), "exact accepted hero frame retained")
		if item.subject == "llama" and item.kind == "sprite":
			found_llama = true
			_check(item.gait.face_override, "llama canonical body keeps face override")
			_check(item.gait.expression.path == llama._expression_texture.resource_path, "live expression texture retained")
			_check(item.transform == Moment._matrix(world.global_transform.affine_inverse() * llama._sprite.global_transform), "actual llama transform retained")
	var traveler_expected: bool = rule_id in ["llama_fed_gentle", "fish_first_catch"] or (rule_id == "llama_overcast_goose_annoyed" and bool(world._leading))
	_check(found_hero == traveler_expected, "%s only includes the traveler when their action belongs in the photograph" % rule_id)
	_check(found_llama, "%s retains the actual llama painting" % rule_id)
	_check(found_rope == (world._lead_rope.visible and traveler_expected), "%s captures the rope only when its traveler is in the photograph" % rule_id)
	if rule_id == "llama_fed_gentle":
		_check(not player.carrying_grass, "feeding fixture actually consumes the bundle")
		_check(_count_atlases(snapshot) == 2, "feeding record does not invent a consumed bundle")
	if rule_id == "duck_pond_chorus":
		var focus := Vector2(snapshot.focus[0], snapshot.focus[1])
		var crop := Rect2(focus - Vector2.ONE * float(snapshot.span) * 0.5, Vector2.ONE * float(snapshot.span))
		_check(crop.encloses(Rect2(YardGround.POND_CENTER - YardGround.POND_RADIUS, YardGround.POND_RADIUS * 2)), "duck composition contains the real pond")
	if rule_id == "goose_pond_rest":
		_check(world.actor_named("goose")._posture_id == "rest" and _has_subject(snapshot, "goose"), "the goose photo contains the actually painted resting pose")
	if rule_id == "goose_duck_shore":
		_check(_has_subject(snapshot, "goose") and _has_subject(snapshot, "duck_a"), "pond-side snapshot contains the real goose and nearby duck")
	if rule_id == "sheep_pair_near":
		_check(_has_subject(snapshot, "sheep_a") and _has_subject(snapshot, "sheep_b"), "sheep pair snapshot contains both real sheep")
	var card := Moment.new()
	card.position = Vector2(30 + (index % 3) * 405, 30 + (index / 3) * 335)
	card.setup(restored)
	card.size = Vector2(260, 260) if _preview else Vector2(184, 184)
	_gallery.add_child(card)
	_check(card.clip_contents, "card clips contents")
	_check(card._stage.process_mode == Node.PROCESS_MODE_DISABLED, "card has no active simulation")
	_check(card._stage.get_child_count() == snapshot.items.size() + 2, "one static primitive per recorded item plus background and shadows")
	for child: CanvasItem in card._stage.get_children():
		_check(child.z_index == 0 and child.z_as_relative, "yard z ordering cannot escape the card")
		_check(not child is AnimatedSprite2D, "hero is a static selected frame")
	var old_transform: Transform2D = card._stage.transform
	card.size = Vector2(280, 190)
	_check(card._stage.transform != old_transform, "resize refits the scene")
	card.size = Vector2(260, 260) if _preview else Vector2(184, 184)
	card.setup(snapshot)
	_check(card.get_child_count() == 1, "repeated setup retires the previous scene immediately")
	var original_scene := JSON.stringify(card._snapshot)
	world.tick(0.25, Vector2.RIGHT)
	_check(JSON.stringify(card._snapshot) == original_scene, "later live simulation cannot change a saved photo")
	_test_corruptions(snapshot)
	if _preview:
		var label := Label.new()
		label.text = rule_id.replace("_", " ")
		label.position = card.position + Vector2(0, 270)
		label.add_theme_color_override("font_color", Color(0.24, 0.20, 0.15))
		label.add_theme_font_size_override("font_size", 15)
		_gallery.add_child(label)
	print("[photo-moment-tests] %s: %d items, span %.1f, %d JSON bytes" % [rule_id, snapshot.items.size(), snapshot.span, json.length()])
	world.free()
	_completed_events += 1


func _test_invalid() -> void:
	for value: Variant in [null, "llama_fed_gentle", [], {}, {"version": 0}, {"version": 2}, {"version": true}]:
		_check(Moment.sanitize(value).is_empty(), "legacy or invalid root is empty")
	_check(not Moment._valid_path("res://assets/holiday/../holiday/characters/player.png"), "path traversal rejected")
	_check(not Moment._valid_path("res://scripts/main.gd"), "non-texture resources rejected")
	_check(not Moment._valid_path("user://photo.png"), "user paths rejected")
	var card := Moment.new()
	card.setup({})
	_check(card._snapshot.is_empty() and card._stage.get_child_count() == 0, "legacy fallback does not fabricate a moment")
	card.free()


func _test_corruptions(snapshot: Dictionary) -> void:
	var bad := snapshot.duplicate(true)
	bad.focus[0] = NAN
	_check(Moment.sanitize(bad).is_empty(), "NaN focus rejected")
	bad = snapshot.duplicate(true)
	bad.items[0].transform[0] = INF
	_check(Moment.sanitize(bad).is_empty(), "infinite transform rejected")
	bad = snapshot.duplicate(true)
	bad.items[0].transform = [1, 2]
	_check(Moment.sanitize(bad).is_empty(), "short transform rejected")
	bad = snapshot.duplicate(true)
	bad.background.texture = {"path": "res://autoload/save_store.gd"}
	_check(Moment.sanitize(bad).is_empty(), "arbitrary resource injection rejected")
	bad = snapshot.duplicate(true)
	bad.shadows = [[1, 1, -1, 2]]
	_check(Moment.sanitize(bad).is_empty(), "negative shadow size rejected")
	bad = snapshot.duplicate(true)
	for i in 65: bad.items.append(snapshot.items[0].duplicate(true))
	_check(Moment.sanitize(bad).is_empty(), "excess item count rejected")
	bad = snapshot.duplicate(true)
	bad.background.frames = [1.5, 1, 0]
	_check(Moment.sanitize(bad).is_empty(), "fractional frame grid rejected")
	bad = snapshot.duplicate(true)
	bad.items[0].unexpected = "discard me"
	bad.unexpected = "discard me"
	var clean := Moment.sanitize(bad)
	_check(not clean.has("unexpected") and not clean.items[0].has("unexpected"), "unknown data never persists")


func _count_atlases(snapshot: Dictionary) -> int:
	var count := 0
	for item: Dictionary in snapshot.get("items", []):
		if item.kind == "sprite" and item.texture.has("atlas") and not str(item.texture.atlas).contains("resident_grass_actions_v1"): count += 1
	return count


func _has_subject(snapshot: Dictionary, subject: String) -> bool:
	for item: Dictionary in snapshot.get("items", []):
		if item.get("subject", "") == subject and item.get("kind", "") == "sprite":
			return true
	return false


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)


# JSON writes real numbers with decimal rounding; compare their values, not
# the incidental choice of integer/float spelling after parsing.
func _same_json_value(a: Variant, b: Variant) -> bool:
	if (a is int or a is float) and (b is int or b is float):
		return is_equal_approx(float(a), float(b))
	if a is Array and b is Array:
		if a.size() != b.size(): return false
		for index: int in a.size():
			if not _same_json_value(a[index], b[index]): return false
		return true
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not _same_json_value(a[key], b[key]): return false
		return true
	return a == b
