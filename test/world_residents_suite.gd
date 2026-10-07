extends SceneTree
const Residents := preload("res://scripts/game/world_residents.gd")
const Controller := preload("res://scripts/game/world_residents_controller.gd")
class DeferredStore extends RefCounted:
	signal commit_confirmed(op_id: String, kind: String)
	signal commit_rejected(op_id: String, kind: String, code: String)
	signal commit_unknown(op_id: String, kind: String, code: String)
	var snapshot: Dictionary = {}
	var submissions := 0
	var resolutions := 0
	var active: Callable
	func get_world_residents() -> Dictionary: return Residents.read(snapshot)
	func get_holiday_day() -> int: return 1
	func get_holiday_day_elapsed() -> float: return 0.0
	func prepare_resident_intent(revision: int, action: String) -> Callable:
		return func(current: Dictionary) -> Dictionary: return Residents.transition(current, revision, action).candidate
	func request_intent(_kind: String, intent: Callable) -> String:
		submissions += 1
		active = intent
		return "resident-%d" % submissions
	func retry_pending() -> bool:
		resolutions += 1
		return true
var checks := 0
var failures := 0
func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(why)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var old := {"version": 5, "holiday_day": 2, "holiday_day_elapsed": 250.0, "future_root": {"untouched": [1, 2]}, "keepsakes": {ExplorationRoutes.FIND_PINE_CONE: 2}}
	check(Residents.read(old).beibei.stage == "unmet", "legacy absence is not adopted")
	check(Residents.transition(old, 0, "adopt_beibei").error == "RESIDENT_NOT_PRESENT", "cannot adopt from yard")
	var routes := ExplorationRoutes.routes()
	var session := ExplorationSession.new(ExplorationCatalog.new("formal", routes), 0)
	session.begin(ExplorationRoutes.NEAR_PATH, {"day": 2, "elapsed": 250.0}, 7)
	session.visit(Residents.STRAY_STOP)
	old.exploration = session.to_record()
	var before := old.duplicate(true)
	var rescued: Dictionary = Residents.transition(old, 0, "adopt_beibei").candidate
	check(old == before, "candidate does not mutate the source")
	check(rescued.keepsakes == old.keepsakes and rescued.future_root == old.future_root, "resident is not an inventory item and unknown root data survives")
	check(Residents.read(rescued).beibei.stage == "puppy", "confirmed candidate has one puppy")
	check(Residents.transition(rescued, 0, "adopt_beibei").error == "RESIDENT_STALE", "double click cannot reuse a stale revision")
	check(Residents.transition(rescued, 1, "adopt_beibei").error == "RESIDENT_ALREADY_HOME", "return visit cannot create a duplicate")
	check(Residents.read(JSON.parse_string(JSON.stringify(rescued))) == Residents.read(rescued), "JSON round trip preserves resident identity")
	for stage: String in ["pending_commit", "committed", "recoverable_failure", "idle"]:
		var wrong := before.duplicate(true)
		wrong.exploration.session.state = stage
		check(Residents.transition(wrong, 0, "adopt_beibei").error == "RESIDENT_NOT_PRESENT", "rescue only during a confirmed active trip")
	var future_trip := before.duplicate(true)
	future_trip.exploration.contract_version = 2
	check(Residents.transition(future_trip, 0, "adopt_beibei").error == "RESIDENT_NOT_PRESENT", "future exploration contracts cannot authorize a rescue")
	var broken_trip := before.duplicate(true)
	broken_trip.exploration.session.erase("trip_id")
	check(Residents.transition(broken_trip, 0, "adopt_beibei").error == "RESIDENT_NOT_PRESENT", "broken exploration identity cannot authorize a rescue")
	var corrupt := rescued.duplicate(true)
	corrupt.world_residents.extra = true
	check(Residents.read(corrupt).is_empty(), "unknown resident fields cannot be discarded")
	check(Residents.transition(corrupt, 1, "grow_beibei").error == "RESIDENT_SOURCE_UNSUPPORTED", "unknown resident data blocks writes")
	corrupt = rescued.duplicate(true)
	corrupt.world_residents.schema = 4
	check(Residents.read(corrupt).is_empty(), "future schema is preserved by refusing to write")
	corrupt = rescued.duplicate(true)
	corrupt.world_residents.beibei.adopted_clock.elapsed = NAN
	check(Residents.read(corrupt).is_empty(), "nonfinite adoption time is invalid")
	for elapsed: float in [-1.0, 600.0, INF, NAN]:
		var clock_bad := rescued.duplicate(true)
		clock_bad.holiday_day_elapsed = elapsed
		check(Residents.transition(clock_bad, 1, "grow_beibei").error == "RESIDENT_CLOCK_INVALID", "invalid game clock cannot force growth")
	var growing := rescued.duplicate(true)
	growing.holiday_day = 5
	growing.holiday_day_elapsed = 249.99
	check(Residents.transition(growing, 1, "grow_beibei").error == "RESIDENT_NOT_READY", "three complete play days required")
	growing.holiday_day_elapsed = 250.0
	var grown: Dictionary = Residents.transition(growing, 1, "grow_beibei").candidate
	check(Residents.read(grown).beibei.stage == "grown", "exact growth boundary succeeds")
	check(Residents.read(grown).beibei.adopted_clock == Residents.read(rescued).beibei.adopted_clock, "growth preserves the original adoption identity")
	grown.holiday_day = 1
	check(Residents.read(grown).beibei.stage == "grown", "reading an older clock never shrinks the dog")
	check(Residents.transition(grown, 2, "grow_beibei").error == "RESIDENT_NOT_PUPPY", "growth cannot grant twice")
	controller_receipts(before)
	await native_roundtrip(before.exploration)
	print("WORLD_RESIDENTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func controller_receipts(source: Dictionary) -> void:
	var fake := DeferredStore.new()
	fake.snapshot = source.duplicate(true)
	var controller := Controller.new(fake)
	check(controller.request("adopt_beibei"), "controller accepts frozen encounter")
	fake.commit_unknown.emit("resident-1", "residents", "WRITE_OUTCOME_UNKNOWN")
	check(controller.state == "unknown" and controller.view().beibei.stage == "unmet", "unknown result never grants puppy")
	check(controller.retry() and fake.resolutions == 1 and fake.submissions == 1, "unknown retry resolves original operation instead of duplicating")
	check(not controller.request("adopt_beibei"), "unknown operation blocks duplicate clicks")
	fake.commit_rejected.emit("resident-1", "residents", "WRITE_REJECTED")
	check(controller.state == "failed" and controller.view().beibei.stage == "unmet", "definite rejection leaves village puppy unacquired")
	check(controller.retry() and fake.submissions == 2, "definite rejection can resubmit frozen intent")
	fake.commit_confirmed.emit("unrelated", "yard")
	check(controller.busy(), "unrelated acknowledgement cannot finish rescue")
	fake.snapshot = fake.active.call(fake.snapshot)
	fake.commit_confirmed.emit("resident-2", "residents")
	check(not controller.busy() and controller.view().beibei.stage == "puppy", "matching durable receipt grants puppy once")

func native_roundtrip(record: Dictionary) -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		check(false, "native resident checks require an isolated profile")
		return
	var store := root.get_node("SaveStore")
	store.request_patch("resident-fixture", {"exploration": record, "holiday_day": 2, "holiday_day_elapsed": 250.0})
	check(await store.flush_pending(), "fixture reaches the real native file")
	store.request_intent("resident", func(current: Dictionary) -> Dictionary:
		return Residents.transition(current, 0, "adopt_beibei").candidate)
	check(Residents.read(store._data).beibei.stage == "unmet", "accepted adoption is not published before commit")
	check(await store.flush_pending(), "adoption commits through the production queue")
	store._load()
	check(Residents.read(store._data).beibei.stage == "puppy", "native reopen retains the same puppy")
	store.request_patch("yard", {"holiday_day": 5, "holiday_day_elapsed": 250.0})
	store.request_intent("resident", func(current: Dictionary) -> Dictionary:
		return Residents.transition(current, 1, "grow_beibei").candidate)
	check(Residents.read(store._data).beibei.stage == "puppy", "queued growth leaves confirmed puppy visible")
	check(await store.flush_pending(), "growth observes the clock at the FIFO queue head")
	store._load()
	check(Residents.read(store._data).beibei.stage == "grown", "native reopen retains mature identity")
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(store.SAVE_PATH))
	check(raw is Dictionary and raw.world_residents.beibei.stage == "grown" and raw.world_residents.revision == 2, "actual save bytes contain one grown beibei")
