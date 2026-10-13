extends SceneTree
const Model := preload("res://scripts/inventory/yard_original_plants.gd")
var checks := 0
var failures: Array[String] = []
var store: Node
var rejected := {}

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return
	store = root.get_node("SaveStore")
	store.commit_rejected.connect(func(id: String, _kind: String, code: String): rejected[id] = code)
	pure_contract()
	await durable()
	await failure_retry()
	await controller_receipts()
	await unknown_record()
	print("YARD_ORIGINAL_PLANTS checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func pure_contract() -> void:
	var legacy := {"album": ["old"], "yard_decor": {"old_offset": 16}, "future_extension": {"x": 9}}
	check(Model.read(legacy) == Model.original(), "missing extension means untouched original painting")
	check(not legacy.has(Model.FIELD) and Model.available(legacy).is_empty(), "read neither writes migration nor gifts basket plants")
	for area: String in Model.AREAS:
		var edit: Dictionary = Model.transition(legacy, 0, "remove", area)
		check(not edit.has("error") and Model.available(edit.candidate) == [area], "original group becomes available exactly once: " + area)
		check(edit.candidate.album == legacy.album and edit.candidate.yard_decor == legacy.yard_decor and edit.candidate.future_extension == legacy.future_extension, "unrelated legacy/photo/offset fields retained: " + area)
		check(not legacy.has(Model.FIELD), "transition does not mutate source: " + area)
		check(Model.transition(edit.candidate, 0, "remove", area).error == "GARDEN_CHANGED", "replayed identity cannot remove twice: " + area)
		check(Model.transition(edit.candidate, 1, "remove", area).error == "GARDEN_EMPTY", "already empty cannot grant again: " + area)
		var restored: Dictionary = Model.transition(edit.candidate, 1, "restore", area)
		check(Model.available(restored.candidate).is_empty() and Model.read(restored.candidate).revision == 2, "restore reserves the same original: " + area)
		check(Model.transition(restored.candidate, 2, "restore", area).error == "GARDEN_OCCUPIED", "cannot restore an extra original: " + area)
	for record: Variant in [null, {}, {"schema": 2, "revision": 0, "removed": []}, {"schema": 1, "revision": 0, "removed": ["left_cluster", "left_cluster"]}, {"schema": 1, "revision": 0, "removed": ["unknown"]}, {"schema": 1, "revision": 0.5, "removed": []}, {"schema": 1, "revision": 0, "removed": [], "future": true}]:
		var source := {Model.FIELD: record}
		check(Model.read(source).is_empty(), "malformed/future source is blocked")
		check(Model.transition(source, 0, "remove", "left_cluster").error == "GARDEN_INVALID", "invalid source is never normalized into writable defaults")
	check(Model.transition(legacy, 0, "remove", "house_edge").error == "GARDEN_INVALID", "old keepsake spot is not a flower area")
	check(Model.transition(legacy, 0, "plant_new_species", "left_cluster").error == "GARDEN_INVALID", "no unapproved species/capacity behavior")
	check(Model.transition({Model.FIELD: {"schema": 1, "revision": Model.MAX_REVISION, "removed": []}}, Model.MAX_REVISION, "remove", "left_cluster").error == "GARDEN_LIMIT", "revision never wraps")

func durable() -> void:
	var protected := {"keepsakes": {"formal.find.pine_cone": 2}, "exploration_committed_serial": 9, "exploration": {"unrelated_checkpoint": true}, "plant_state": 2, "plant_day_planted": 2, "yard_decor": {"schema": 1, "revision": 5, "places": {"house_edge": {"find_id": "formal.find.pine_cone", "dx": 1, "dy": -1}}}, "album": ["legacy"], "future_field": {"retain": true}}
	store.request_patch("original_fixture", protected)
	check(await store.flush_pending(), "native protected fixture committed")
	var op: String = store.request_original_plant_action(0, "remove", "left_cluster")
	check(not op.is_empty() and store.get_yard_original_plants().removed.is_empty(), "acceptance is not successful removal")
	var duplicate: String = store.request_original_plant_action(0, "remove", "left_cluster")
	check(await store.flush_pending(), "queued edits drain")
	check(rejected.get(duplicate) == "GARDEN_CHANGED", "FIFO second edit sees first committed revision")
	check(store.get_yard_original_plants().removed == ["left_cluster"], "one removed group, not a duplicated inventory grant")
	store._load()
	check(store.get_yard_original_plants().removed == ["left_cluster"], "explicit removed area stays empty on actual native reopen")
	for area: String in ["door_pots", "pond_cluster"]:
		store.request_original_plant_action(int(store.get_yard_original_plants().revision), "remove", area)
		check(await store.flush_pending(), "remove next original group")
	store._load()
	check(store.get_yard_original_plants().removed.size() == 3, "all three remain removed after reopen")
	for key: String in protected:
		check(JSON.parse_string(JSON.stringify(store._data.get(key))) == JSON.parse_string(JSON.stringify(protected[key])), "edit preserves root field " + key)
	for area: String in Model.AREAS:
		store.request_original_plant_action(int(store.get_yard_original_plants().revision), "restore", area)
		check(await store.flush_pending(), "restore one original durably")
	store._load()
	check(store.get_yard_original_plants().removed.is_empty() and store.get_yard_original_plants().revision == 6, "restored painting and revision survive restart without another gift")

func failure_retry() -> void:
	var before := FileAccess.get_file_as_bytes(store.SAVE_PATH)
	var revision: int = store.get_yard_original_plants().revision
	var temporary: String = store._backend._temporary
	store._backend._temporary = "user://missing-original-plants-dir/write.tmp"
	var op: String = store.request_original_plant_action(revision, "remove", "door_pots")
	check(not await store.flush_pending(), "actual native temporary-file failure is unresolved, not a success")
	check(store.get_yard_original_plants().removed.is_empty() and FileAccess.get_file_as_bytes(store.SAVE_PATH) == before, "failed removal keeps confirmed painting and primary bytes")
	check(store.retry_pending(), "resolve same native write identity")
	check(await store.flush_pending() and rejected.has(op), "resolution rejects failed candidate before any new operation")
	store._backend._temporary = temporary
	store.request_original_plant_action(revision, "remove", "door_pots")
	check(await store.flush_pending(), "retry after repairing path commits")
	store._load()
	check(store.get_yard_original_plants().removed == ["door_pots"], "failed edit retry creates exactly one removed original")
	# The inverse operation must also remain unconfirmed during a real I/O failure.
	before = FileAccess.get_file_as_bytes(store.SAVE_PATH)
	revision = store.get_yard_original_plants().revision
	store._backend._temporary = "user://missing-original-plants-dir/write.tmp"
	store.request_original_plant_action(revision, "restore", "door_pots")
	check(not await store.flush_pending() and store.get_yard_original_plants().removed == ["door_pots"], "failed restoration does not consume the available original")
	check(FileAccess.get_file_as_bytes(store.SAVE_PATH) == before and store.retry_pending(), "restore failure preserves disk and resolves same identity")
	await store.flush_pending()
	store._backend._temporary = temporary
	store.request_original_plant_action(revision, "restore", "door_pots")
	check(await store.flush_pending(), "restoration safely retries")

func unknown_record() -> void:
	var future := {"schema": 99, "revision": 5, "removed": [], "future_payload": [1, 2]}
	store.request_patch("future_fixture", {Model.FIELD: future})
	check(await store.flush_pending(), "future extension fixture committed without projection loss")
	store._load()
	var before := FileAccess.get_file_as_bytes(store.SAVE_PATH)
	var op: String = store.request_original_plant_action(5, "remove", "left_cluster")
	check(await store.flush_pending() and rejected.get(op) == "GARDEN_INVALID", "future schema has typed refusal at production coordinator")
	check(JSON.parse_string(JSON.stringify(store._data[Model.FIELD])) == JSON.parse_string(JSON.stringify(future)) and FileAccess.get_file_as_bytes(store.SAVE_PATH) == before, "refusal retains exact future record and source bytes")

func controller_receipts() -> void:
	var client = preload("res://scripts/inventory/original_plant_controller.gd").new(store)
	var completed: Array = []
	client.completed.connect(func(action: String, area: String): completed.append([action, area]))
	check(client.request("remove", "pond_cluster") and client.busy(), "controller accepts one operation")
	check(client.view().removed.is_empty() and completed.is_empty(), "controller shows confirmed painting, no early done notice")
	check(not client.request("remove", "left_cluster"), "double click cannot enqueue another edit while pending")
	await store.flush_pending()
	check(not client.busy() and client.view().removed == ["pond_cluster"] and completed == [["remove", "pond_cluster"]], "matching confirmed receipt alone updates view and emits success")
	client._confirmed("unrelated-old-operation", "original-plants")
	check(completed.size() == 1, "late unrelated receipt cannot emit another success")
	check(client.request("remove", "pond_cluster"), "already-empty request reaches semantic validation")
	await store.flush_pending()
	check(client.error == "GARDEN_EMPTY" and not client.busy() and not client.retry(), "semantic refusal releases stale selection instead of infinite retry")
	var temporary: String = store._backend._temporary
	store._backend._temporary = "user://missing-original-plants-dir/write.tmp"
	check(client.request("restore", "pond_cluster"), "controller accepts restoration intent")
	await store.flush_pending()
	check(client.state == "unknown" and client.busy() and client.view().removed == ["pond_cluster"] and completed.size() == 1, "unresolved I/O keeps original available and freezes edit")
	var same_operation: String = client.operation
	check(client.retry() and client.operation == same_operation, "unknown retry resolves same identity rather than new mutation")
	await store.flush_pending()
	check(client.state == "failed" and client.busy(), "proven failed write retains retry proposal")
	store._backend._temporary = temporary
	check(client.retry(), "explicit retry submits proven uncommitted proposal")
	await store.flush_pending()
	check(client.state == "idle" and not client.busy() and client.view().removed.is_empty() and completed.size() == 2, "successful retry restores exactly once")
	client.dispose()
