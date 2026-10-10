extends SceneTree
const Meals := preload("res://scripts/game/meal_ledger.gd")
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Coordinator := preload("res://scripts/persistence/save_coordinator.gd")
const Backend := preload("res://test/save_coordinator_suite.gd").Backend
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func fixture() -> Dictionary:
	var inventory := Inventory.empty()
	inventory.wheat = 12
	inventory.fish = {"small": 1}
	return {"version": 5, "holiday_day": 1, Inventory.FIELD: inventory, "album": ["old"], "unknown_owner": {"keep": [1, 2]}}
func step(s: Dictionary, meal: String = "breakfast", tired: bool = false, cost: Dictionary = {"wheat": 1}) -> Dictionary:
	return Meals.complete(s, int(Meals.read(s).revision), int(Inventory.read(s).revision), int(s.holiday_day), meal, cost, tired)
func intent() -> Callable:
	return func(s: Dictionary) -> Variant:
		var result := Meals.complete(s, 0, 0, 1, "breakfast", {"wheat": 1}, false)
		return Coordinator.IntentRejection.new(result.error) if result.has("error") else result.candidate
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return
	var original := fixture()
	check(Meals.read(original) == Meals.empty() and not original.has(Meals.FIELD), "legacy read does not grant points or mutate save")
	for tired: bool in [false, true]:
		var state := original.duplicate(true)
		var expected: Array = [0, 1, 1] if tired else [1, 3, 2]
		for index in 3:
			var meal: String = Meals.GRANTS.keys()[index]
			state = step(state, meal, tired).candidate
			check(state.meal_ledger.receipts[index].earned == expected[index], "grant " + meal + str(tired))
			check(state.yard_inventory.wheat == 11-index, "exactly one cost per meal")
			check(step(state, meal, tired).error == "MEAL_ALREADY_COMPLETED", "repeat cannot grant or debit " + meal)
		var reopened: Dictionary = JSON.parse_string(JSON.stringify(state))
		check(Meals.read(reopened) == Meals.read(state), "JSON roundtrip preserves zero-point breakfast too")
		check(state.album == original.album and state.unknown_owner == original.unknown_owner, "other owners preserved")
		state.holiday_day = 2
		var next := step(state, "breakfast", not tired).candidate as Dictionary
		check(next.meal_ledger.receipts.size() == 4 and next.meal_ledger.receipts.slice(0,3) == state.meal_ledger.receipts, "new day preserves receipts without inventing AP expiry")
	check(not original.has(Meals.FIELD) and original.yard_inventory.wheat == 12, "input snapshot never mutated")
	check(Meals.complete(original, 1, 0, 1, "breakfast", {"wheat":1}, false).error == "MEAL_CHANGED", "stale meal revision")
	check(Meals.complete(original, 0, 1, 1, "breakfast", {"wheat":1}, false).error == "MEAL_CHANGED", "stale inventory revision")
	check(Meals.complete(original, 0, 0, 2, "breakfast", {"wheat":1}, false).error == "MEAL_CHANGED", "late director cannot charge a different day")
	var breakfast := step(original).candidate as Dictionary
	check(step(breakfast, "lunch", true).error == "MEAL_CHANGED", "same-day fatigue cannot change between meals")
	for cost: Dictionary in [{}, {"grass":1}, {"wheat":0}, {"wheat":-1}, {"wheat":1.5}, {"wheat":true}, {"feather":1}]:
		check(step(original,"breakfast",false,cost).error == "MEAL_INVALID", "invalid cost rejected " + str(cost))
	check(step(original,"breakfast",false,{"wheat":12}).error == "BASKET_SEED_RESERVED", "last seed protected")
	check(step(original,"breakfast",false,{"wheat":1,"medium":1}).error == "MEAL_EMPTY", "missing ingredient rejects whole cost")
	check(original.yard_inventory.wheat == 12, "partial recipe never consumes available part")
	var fish := step(original,"breakfast",false,{"small":1}).candidate as Dictionary
	check(not Inventory.read(fish).is_empty() and fish.yard_inventory.fish.is_empty(), "last fish key removed to retain valid inventory")
	for raw: Variant in [null, [], {"schema":2,"revision":0,"receipts":[]}, {"schema":1,"revision":1,"receipts":[]}, {"schema":1,"revision":1,"receipts":[{}]}]:
		var invalid := original.duplicate(true)
		invalid[Meals.FIELD] = raw
		check(Meals.read(invalid).is_empty(), "invalid/future ledger blocked")
		check(Meals.complete(invalid,0,0,1,"breakfast",{"wheat":1},false).error == "MEAL_INVALID", "invalid ledger not overwritten")
	var duplicate := breakfast.duplicate(true)
	duplicate.meal_ledger.receipts.append(duplicate.meal_ledger.receipts[0].duplicate(true))
	duplicate.meal_ledger.revision = 2
	check(Meals.read(duplicate).is_empty(), "duplicate stored identity rejected")
	# Fault injection uses the real coordinator, not a substitute meal writer.
	for landed: bool in [false, true]:
		var backend := Backend.new()
		var coordinator := Coordinator.new()
		check(coordinator.initialize(backend, original, "root-token"), "fault writer initialized")
		coordinator.enqueue(intent())
		check(coordinator.get_confirmed() == original, "acceptance reveals neither debit nor points")
		await process_frame
		backend.prepare_ok()
		backend.send("unknown", {}, "TIMEOUT")
		check(coordinator.get_confirmed() == original and coordinator.enqueue(intent()).is_empty(), "unknown blocks replacement and retains old snapshot")
		coordinator.retry_resolve()
		backend.receipt("confirmed" if landed else "rejected")
		backend.ack()
		check(coordinator.get_confirmed() == (breakfast if landed else original), "resolve publishes both or neither")
		backend.sync = true
		coordinator.enqueue(intent())
		await process_frame
		check(coordinator.get_confirmed() == breakfast, "retry after either resolution cannot double-charge")
		check(coordinator.close_when_idle(), "all acknowledgements drain")
	# Real SaveStore + native file, followed by a fresh on-disk read.
	var store = root.get_node("SaveStore")
	store.request_patch("meal-fixture", original)
	check(await store.flush_pending(), "native fixture persisted")
	var cost := {"wheat": 1}
	var one: String = store.request_meal_completion(0,0,1,"breakfast",cost)
	cost.wheat = 9
	store.request_meal_completion(0,0,1,"breakfast",{"wheat":1})
	check(not one.is_empty() and store.get_meal_ledger().receipts.is_empty(), "native acceptance is not confirmation")
	check(await store.flush_pending(), "native duplicate queue drained")
	check(store.get_yard_inventory().wheat == 11 and store.get_meal_ledger().receipts.size() == 1, "captured cost and duplicate callback cannot double debit")
	var disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(store.SAVE_PATH))
	check(disk.yard_inventory.wheat == 11 and disk.meal_ledger.receipts[0].earned == 1, "real file contains cost and entitlement")
	store._load()
	check(store.get_meal_ledger().receipts.size() == 1 and store.get_yard_inventory().wheat == 11, "native reopen preserves receipt and cost")
	store.request_meal_completion(1,1,1,"breakfast",{"wheat":1})
	check(await store.flush_pending(), "reopened replay rejected without a write")
	check(store.get_meal_ledger().receipts.size() == 1 and store.get_yard_inventory().wheat == 11, "reopen cannot farm meal grants")
	for failure in failures: push_error(failure)
	print("MEAL_LEDGER checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
