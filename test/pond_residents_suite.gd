extends SceneTree
const Model := preload("res://scripts/game/world_residents.gd")
const Controller := preload("res://scripts/game/world_residents_controller.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(why)
func fixture(serial: int = 5) -> Dictionary:
	var session := ExplorationSession.new(ExplorationCatalog.new("formal", ExplorationRoutes.routes()), serial - 1)
	session.begin(ExplorationRoutes.NEAR_PATH, {"day": 4, "elapsed": 100.0}, 7)
	session.visit(Model.TURTLE_STOP)
	var record: Dictionary = session.to_record()
	record.session.companion = {"actor_id": "beibei", "mode": "nearby"}
	return {"holiday_day": 4, "holiday_day_elapsed": 100.0, "exploration": record,
		"world_residents": {"schema": 1, "revision": 2, "beibei": {"stage": "grown", "adopted_clock": {"day": 1, "elapsed": 0.0}}},
		"keepsakes": {ExplorationRoutes.FIND_PINE_CONE: 2}, "unrelated": {"value": 17}}
func run() -> void:
	var source := fixture()
	var before := source.duplicate(true)
	var migrated := Model.read(source)
	check(migrated.schema == 3 and migrated.turtle.stage == "unmet", "schema1 adds no acquired turtle")
	check(migrated.beibei == source.world_residents.beibei and migrated.revision == 2, "migration preserves E dog and revision")
	check(source == before, "migration read does not rewrite caller data")
	check(Model.transition(source, 2, "adopt_turtle").error == "RESIDENT_NOT_FOUND", "cannot take before discovery")
	for partner: Dictionary in [{}, {"actor_id": "llama", "mode": "rope"}, {"actor_id": "sheep_shy", "mode": "nearby"}]:
		var wrong := source.duplicate(true)
		wrong.exploration.session.companion = partner
		check(Model.transition(wrong, 2, "find_turtle").error == "RESIDENT_NOT_PRESENT", "only accompanying beibei discovers turtle")
	for stage: String in ["unmet", "puppy"]:
		var wrong := source.duplicate(true)
		wrong.world_residents.beibei.stage = stage
		if stage == "unmet": wrong.world_residents.beibei.adopted_clock = null
		check(Model.transition(wrong, 2, "find_turtle").error == "RESIDENT_NOT_PRESENT", "only mature dog qualifies")
	var wrong_stop := source.duplicate(true)
	wrong_stop.exploration.session.current_stop = Model.STRAY_STOP
	check(Model.transition(wrong_stop, 2, "find_turtle").error == "RESIDENT_NOT_PRESENT", "village arrival is not water encounter")
	var found: Dictionary = Model.transition(source, 2, "find_turtle").candidate
	check(found.world_residents.turtle.stage == "found", "discovery is persistent before adoption")
	check(found.world_residents.turtle.found_trip == source.exploration.session.trip_id, "discovery belongs to actual trip")
	check(found.keepsakes == source.keepsakes and found.unrelated == source.unrelated, "discovery preserves inventory and root data")
	check(Model.transition(found, 3, "find_turtle").error == "RESIDENT_ALREADY_FOUND", "same trip cannot discover twice")
	check(Model.transition(found, 2, "adopt_turtle").error == "RESIDENT_STALE", "old revision cannot adopt")
	var later := fixture(6)
	later.world_residents = found.world_residents.duplicate(true)
	check(Model.transition(later, 3, "adopt_turtle").error == "RESIDENT_NOT_FOUND", "new trip must actually rediscover an unclaimed turtle")
	check(Model.transition(later, 3, "find_turtle").candidate.world_residents.turtle.found_trip == later.exploration.session.trip_id, "missed encounter may recur with dog")
	var adopted: Dictionary = Model.transition(found, 3, "adopt_turtle").candidate
	check(adopted.world_residents.turtle.stage == "pond", "confirmed adoption places one pond resident")
	check(adopted.world_residents.beibei == source.world_residents.beibei, "turtle cannot erase mature dog")
	for action: String in ["find_turtle", "adopt_turtle"]:
		check(Model.transition(adopted, 4, action).error == "RESIDENT_ALREADY_HOME", "old encounter cannot clone pond turtle")
	check(Model.read(JSON.parse_string(JSON.stringify(adopted))) == Model.read(adopted), "full JSON roundtrip preserves identity")
	for bad: Dictionary in [{"stage": "unmet", "found_trip": "trip-5"}, {"stage": "found", "found_trip": ""}, {"stage": "pond", "found_trip": 5}, {"stage": "lost", "found_trip": "trip-5"}, {"stage": "pond", "found_trip": "trip-5", "extra": true}]:
		var corrupt := adopted.duplicate(true)
		corrupt.world_residents.turtle = bad
		check(Model.read(corrupt).is_empty(), "unknown turtle data is refused without reset")
	await native_roundtrip(source)
	print("POND_RESIDENTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
func native_roundtrip(source: Dictionary) -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		check(false, "isolated native profile required"); return
	var store := root.get_node("SaveStore")
	if not store.is_initialized(): await store.initialized
	store.request_patch("pond-fixture", source)
	check(await store.flush_pending(), "legacy dog and actual encounter persist")
	var controller := Controller.new(store)
	check(controller.request("find_turtle"), "production controller accepts qualified discovery")
	check(controller.view().turtle.stage == "unmet", "queue acceptance never reveals unconfirmed turtle")
	check(not controller.request("find_turtle"), "duplicate discovery blocked in flight")
	check(await store.flush_pending(), "discovery writes real file")
	store._load()
	check(controller.view().turtle.stage == "found", "reopened discovery identity retained")
	var retry: Callable = store.prepare_resident_intent(3, "adopt_turtle")
	check(retry.is_valid(), "confirmed water encounter freezes adoption资格")
	var yard: Dictionary = store._data.duplicate(true)
	yard.erase("exploration")
	yard.unrelated.value = 99
	var retry_result: Variant = retry.call(yard)
	check(retry_result is Dictionary and retry_result.world_residents.turtle.stage == "pond", "definite rejection can retry after return cleanup")
	check(not retry_result.has("exploration") and retry_result.unrelated.value == 99, "retry preserves cleanup and newer root state")
	check(controller.request("adopt_turtle"), "production adoption accepted")
	check(controller.view().turtle.stage == "found", "acceptance is not pond placement")
	check(await store.flush_pending(), "adoption commits")
	store._load()
	check(controller.view().turtle.stage == "pond", "native reopen retains pond turtle")
	check(retry.call(store._data) is SaveCoordinator.IntentRejection, "old intent cannot clone confirmed turtle")
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(store.SAVE_PATH))
	check(raw.world_residents.schema == 3 and raw.world_residents.turtle.stage == "pond" and raw.keepsakes.size() == 1 and raw.keepsakes[ExplorationRoutes.FIND_PINE_CONE] == 2, "real save bytes preserve animal and inventory")
