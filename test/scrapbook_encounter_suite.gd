extends SceneTree

# Genuine YardWorld predicates and captured subjects; no force_rule bypass.
var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


func has_subject(moment: Dictionary, id: String) -> bool:
	for item: Dictionary in moment.get("items", []):
		if item.get("kind", "") == "sprite" and item.get("subject", "") == id:
			return true
	return false


func matches(world, id: String) -> bool:
	return world._rule_matches(ExpressionCatalog.find_rule(id), world._world_snapshot())


func _run() -> void:
	seed(12012)
	root.get_node("TuningStore").call("reset_defaults")
	var script: Script = load("res://scripts/game/yard_world.gd")
	var world = script.new()
	root.add_child(world)
	world.setup()
	world.set_weather("sun")
	world._weather_timer = 10000.0
	world.debug_place_actor("goose", Vector2(766, 508))
	world.debug_place_player(Vector2(741, 524))
	var goose = world.actor_named("goose")
	goose.state = "graze"
	goose._idle_time = 10.0
	goose._velocity = Vector2.ZERO
	goose._gait.weight = 0.0
	world.tick(1.0 / 60.0, Vector2.ZERO)
	check(not matches(world, "goose_pond_rest"), "goose is not recorded on day one")
	world.holiday_day = 2
	check(not matches(world, "goose_pond_rest"), "standing goose is not called resting")
	goose.state = "rest"
	goose._idle_time = 10.0
	world.tick(1.0 / 60.0, Vector2.ZERO)
	check(goose._posture_id == "rest" and matches(world, "goose_pond_rest"), "painted resting goose near the traveler is eligible")
	world.debug_place_actor("goose", Vector2(425, 504))
	world.debug_place_player(Vector2(410, 530))
	check(not matches(world, "goose_pond_rest"), "a real resting goose on grass cannot be captioned as resting by the pond")
	world.debug_place_actor("goose", Vector2(766, 508))
	world.debug_place_player(Vector2(270, 515))
	check(not matches(world, "goose_pond_rest"), "distant resting goose cannot be photographed")
	world.debug_place_player(Vector2(741, 524))
	world._evaluate_expressions()
	var rest: Dictionary = world.photo_moments.get("goose_pond_rest", {})
	check("goose_pond_rest" in world.collected and has_subject(rest, "goose"), "genuine resting goose is saved with its painted body")
	var third_sentence := rest.duplicate(true)
	third_sentence.caption_variant = 2
	check(not PhotoMoment.sanitize(third_sentence).is_empty(), "a three-sentence photo still accepts its valid third caption")
	var goose_art := str(goose._sprite.texture.resource_path)
	var recorded_art := false
	for item: Dictionary in rest.get("items", []):
		if item.get("kind", "") == "sprite" and item.get("subject", "") == "goose":
			recorded_art = item.get("texture", {}).get("path", "") == goose_art
	check(recorded_art and goose_art.contains("rest"), "record includes the actual full resting painting, not a standing-body substitute")

	world.debug_place_player(Vector2(323, 512))
	world.debug_place_actor("sheep_a", Vector2(303, 506))
	world.debug_place_actor("sheep_b", Vector2(480, 507))
	check(not matches(world, "sheep_pair_near"), "two distant sheep cannot become a pair photo")
	world.debug_place_actor("sheep_b", Vector2(352, 506))
	check(matches(world, "sheep_pair_near"), "two actually close sheep can be observed")
	world._evaluate_expressions()
	var pair: Dictionary = world.photo_moments.get("sheep_pair_near", {})
	check(has_subject(pair, "sheep_a") and has_subject(pair, "sheep_b"), "both actual sheep are in the captured scene")

	world.debug_place_actor("duck_a", Vector2(642, 580))
	world.debug_place_actor("duck_b", Vector2(650, 580))
	world.debug_place_actor("duck_c", Vector2(660, 580))
	world.debug_place_player(Vector2(752, 510))
	goose.state = "graze"
	goose._idle_time = 10.0
	goose._velocity = Vector2.ZERO
	goose._gait.weight = 0.0
	world.tick(1.0 / 60.0, Vector2.ZERO)
	check(not matches(world, "goose_duck_shore"), "a faraway duck never becomes the goose's nearby companion")
	world.debug_place_actor("duck_a", Vector2(771, 533))
	check(not matches(world, "goose_duck_shore"), "shore companionship does not unlock before day three")
	world.holiday_day = 3
	world.debug_place_actor("goose", Vector2(430, 505))
	world.debug_place_actor("duck_a", Vector2(475, 534))
	world.debug_place_player(Vector2(418, 521))
	check(not matches(world, "goose_duck_shore"), "grassland goose and duck cannot become a pond-side photograph")
	world.debug_place_actor("goose", Vector2(766, 508))
	world.debug_place_actor("duck_a", Vector2(848, 534))
	world.debug_place_actor("duck_b", Vector2(640, 574))
	world.debug_place_player(Vector2(568, 520))
	check(not matches(world, "goose_duck_shore"), "seeing another duck does not justify photographing the closest duck hidden from the traveler")
	world.debug_place_actor("duck_a", Vector2(771, 533))
	world.debug_place_actor("duck_b", Vector2(650, 580))
	world.debug_place_player(Vector2(200, 520))
	check(not matches(world, "goose_duck_shore"), "unseen duck and goose cannot be photographed")
	world.debug_place_player(Vector2(748, 523))
	check(matches(world, "goose_duck_shore"), "visible close duck and goose are a genuine encounter")
	world._evaluate_expressions()
	var companions: Dictionary = world.photo_moments.get("goose_duck_shore", {})
	check(has_subject(companions, "goose") and has_subject(companions, "duck_a"), "scene contains the nearest real duck and goose")
	var incomplete := companions.duplicate(true)
	var without_duck: Array = []
	for item: Dictionary in incomplete.get("items", []):
		if not str(item.get("subject", "")).begins_with("duck_"): without_duck.append(item)
	incomplete.items = without_duck
	check(not PhotoMoment.has_event_subject(incomplete, "goose_duck_shore"), "a missing duck cannot masquerade as a genuine paired photograph")
	var before: int = world.collected.size()
	world._evaluate_expressions()
	check(world.collected.size() == before, "repeated encounters do not mint duplicate photo entries")
	root.get_node("AudioDirector").call("release_streams")
	print("[scrapbook-encounters] ", "PASS" if failures.is_empty() else "FAIL", ": ", checks, " checks ", failures)
	quit(0 if failures.is_empty() else 1)
