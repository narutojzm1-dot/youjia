extends Node

signal initialized(status: String, code: String)
signal commit_confirmed(op_id: String, kind: String)
## Read-only accepted exploration identity; does not change host protocol or grants.
signal exploration_intent_accepted(op_id: String, kind: String, scope: Dictionary)
signal commit_rejected(op_id: String, kind: String, code: String)
signal commit_unknown(op_id: String, kind: String, code: String)
signal persistence_state_changed(state: String)

const CoordinatorType = preload("res://scripts/persistence/save_coordinator.gd")
const WebHostType = preload("res://scripts/persistence/web_save_host.gd")
const NativeHostType = preload("res://scripts/persistence/native_save_host.gd")
var _coordinator: RefCounted
var _backend: Object
var _boot_state := "loading"
var _boot_call_id := ""
var _pending_kinds: Dictionary = {}
var _legacy_inspection: Dictionary = {}
var _legacy_review_required := false
var _legacy_call_id := ""
signal recovery_exported(status: String, bytes: PackedByteArray)

const SAVE_PATH := "user://youjia_save.json"
const TEMP_PATH := "user://youjia_save.tmp"
const BACKUP_PATH := "user://youjia_save.bak"
const SaveFilesType := preload("res://scripts/persistence/save_files.gd")
const AnimalRelationshipsType := preload("res://scripts/game/animal_relationships.gd")
const SaveDataCodec := preload("res://scripts/persistence/save_data_codec.gd")
const YardInventory := preload("res://scripts/inventory/yard_inventory.gd")
const SAVE_VERSION := SaveDataCodec.SAVE_VERSION
const TUTORIAL_VERSION := SaveDataCodec.TUTORIAL_VERSION

var _data: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_data = _default_data()
	if OS.has_feature("web"):
		_backend = WebHostType.new()
		add_child(_backend)
		_backend.completed.connect(_on_boot_reply)
		_boot_call_id = _backend.request("open", {})
		if _boot_call_id.is_empty(): call_deferred("_block_boot", "HOST_UNAVAILABLE")
	else:
		_load()



func _default_data() -> Dictionary:
	return SaveDataCodec.defaults()


func _load() -> void:
	if OS.has_feature("web"): return
	# A new read boundary requires all earlier requests to have ended.
	if _coordinator != null:
		if not _coordinator.close_when_idle(): return
		_coordinator = null
	_backend = NativeHostType.new(SAVE_PATH, TEMP_PATH, BACKUP_PATH)
	var trusted: Dictionary = _backend.get_initial_snapshot()
	if not trusted.is_empty(): _data = trusted
	if _backend.get_state() != "ready":
		_block_boot("NATIVE_SOURCE_BLOCKED")
		return
	# Snapshot and token MUST come from the same authoritative read.
	if not _connect_coordinator(_data, _backend.get_initial_token(), "youjia-native-file-v1"):
		_block_boot("COORDINATOR_INIT_FAILED")
		return
	_boot_state = "ready"


func save() -> bool:
	return _commit_candidate(_data.duplicate(true))


# One commit boundary for every setter. A failed file write must not leak a
# candidate into getters or a later unrelated save. These compatibility setters
# are native-only; Web callers use the asynchronous receipt API below.
func _commit_candidate(candidate: Dictionary) -> bool:
	if OS.has_feature("web") or _boot_state != "ready" or _coordinator == null or not _coordinator.is_idle():
		return false
	# Compatibility writes use the same native source guard and receipt logic.
	# Leave an unresolved writer attached; never create a replacement over it.
	var reply: Dictionary = _backend.commit_compat(candidate)
	if reply.get("status") != "confirmed":
		if reply.get("status") != "rejected": _block_boot("NATIVE_COMMIT_UNCERTAIN")
		return false
	if not _coordinator.close_when_idle():
		_block_boot("COORDINATOR_NOT_IDLE")
		return false
	_coordinator = null
	_data = _backend.get_initial_snapshot()
	if _backend.get_state() != "ready" or not _connect_coordinator(_data, _backend.get_initial_token(), "youjia-native-file-v1"):
		_block_boot("NATIVE_ACK_PENDING")
	return true


func get_locale() -> String:
	return str(_data.get("locale", "zh-CN"))


func set_locale(locale: String) -> void:
	if locale not in ["en", "zh-CN"]:
		return
	var candidate := _data.duplicate(true)
	candidate.locale = locale
	_commit_candidate(candidate)


func is_tutorial_completed(version: int = TUTORIAL_VERSION) -> bool:
	return int(_data.get("tutorial_version", 0)) >= version


func set_tutorial_completed(completed: bool, version: int = TUTORIAL_VERSION) -> void:
	var candidate := _data.duplicate(true)
	candidate.tutorial_version = clampi(version, 0, TUTORIAL_VERSION) if completed else 0
	_commit_candidate(candidate)


func get_album() -> Array:
	return (_data.get("album", []) as Array).duplicate()


func set_album(photos: PackedStringArray, moments: Dictionary = {}) -> bool:
	var album: Array = []
	for photo_id: String in photos:
		if photo_id not in album:
			album.append(photo_id)
	var candidate := _data.duplicate(true)
	candidate.album = album
	var combined: Dictionary = _data.get("photo_moments",{}).duplicate(true)
	for photo_id: Variant in moments: combined[photo_id] = moments[photo_id]
	candidate.photo_moments = _clean_moments(combined,album)
	return _commit_candidate(candidate)


func get_photo_moments() -> Dictionary:
	return (_data.get("photo_moments",{}) as Dictionary).duplicate(true)


func get_photo_moment(photo_id: String) -> Dictionary:
	return ((_data.get("photo_moments",{}) as Dictionary).get(photo_id,{}) as Dictionary).duplicate(true)


# ── 假期天数 ──────────────────────────────────────────────────────────────────

func get_holiday_day() -> int:
	return maxi(1, int(_data.get("holiday_day", 1)))


func get_holiday_day_elapsed() -> float:
	return maxf(0.0, float(_data.get("holiday_day_elapsed", 0.0)))


func set_holiday_progress(day: int, elapsed: float) -> void:
	var candidate := _data.duplicate(true)
	candidate.holiday_day = maxi(1, day)
	candidate.holiday_day_elapsed = maxf(0.0, elapsed)
	_commit_candidate(candidate)


# Time and plant state belong to one yard snapshot. Publish the in-memory
# snapshot only after the existing file commit succeeds (not a Web durable ack).
func set_yard_progress(day: int, elapsed: float, state: int, day_planted: int, watered_day: int) -> bool:
	var candidate: Dictionary = _data.duplicate(true)
	candidate.holiday_day = maxi(1, day)
	candidate.holiday_day_elapsed = maxf(0.0, elapsed)
	candidate.plant_state = clampi(state, 0, 3)
	candidate.plant_day_planted = maxi(0, day_planted)
	candidate.plant_watered_day = watered_day
	return _commit_candidate(candidate)


# ── 植物床 ────────────────────────────────────────────────────────────────────

func get_plant_state() -> Dictionary:
	return {
		"state": int(_data.get("plant_state", 0)),
		"day_planted": int(_data.get("plant_day_planted", 0)),
		"watered_day": int(_data.get("plant_watered_day", -1)),
	}


func set_plant_state(state: int, day_planted: int, watered_day: int) -> void:
	var candidate := _data.duplicate(true)
	candidate.plant_state = clampi(state, 0, 3)
	candidate.plant_day_planted = maxi(0, day_planted)
	candidate.plant_watered_day = watered_day
	_commit_candidate(candidate)


# ── 钓鱼记录 ──────────────────────────────────────────────────────────────────

func get_first_fish_caught() -> bool:
	return bool(_data.get("first_fish_caught", false))


func set_first_fish_caught() -> void:
	var candidate := _data.duplicate(true)
	candidate.first_fish_caught = true
	_commit_candidate(candidate)


func get_animal_relationship_memory() -> Dictionary:
	return (_data.get("animal_relationship_memory", {}) as Dictionary).duplicate(true)


func set_animal_relationship_memory(memory: Dictionary) -> bool:
	var candidate := _data.duplicate(true)
	candidate.animal_relationship_memory = AnimalRelationshipsType.sanitize(memory)
	return _commit_candidate(candidate)


# ── 探索 ──────────────────────────────────────────────────────────────────────
# 只走异步队列：返回受理编号，commit_confirmed 之后才发布到内存，被拒或未知时内存保持确认前原样。

func get_exploration_record() -> Variant:
	var record: Variant = _data.get("exploration", null)
	return record.duplicate(true) if record is Dictionary or record is Array else record


func get_exploration_committed_serial() -> int:
	return int(_data.get("exploration_committed_serial", 0))


func get_keepsakes() -> Dictionary:
	return (_data.get("keepsakes", {}) as Dictionary).duplicate(true)


func get_yard_inventory() -> Dictionary:
	return YardInventory.read(_data)


func get_world_residents() -> Dictionary:
	return preload("res://scripts/game/world_residents.gd").read(_data)

func request_resident_action(revision: int, action: String) -> String:
	var intent := prepare_resident_intent(revision, action)
	return request_intent("residents", intent) if intent.is_valid() else ""


## Freeze a confirmed encounter at the click, so a rejected disk write can be
## retried after returning home. Never restore that old trip over current data.
func prepare_resident_intent(revision: int, action: String) -> Callable:
	var model := preload("res://scripts/game/world_residents.gd")
	var encounter: Dictionary = {}
	if action == "adopt_beibei":
		if model.transition(_data, revision, action).has("error"): return Callable()
		encounter = _data.exploration.duplicate(true)
	return func(current: Dictionary) -> Variant:
		var source := current.duplicate(true)
		if not encounter.is_empty(): source.exploration = encounter.duplicate(true)
		var result := model.transition(source, revision, action)
		if result.has("error"): return CoordinatorType.IntentRejection.new(result.error)
		if current.has("exploration"): result.candidate.exploration = current.exploration
		else: result.candidate.erase("exploration")
		return result.candidate


func request_inventory_action(revision: int, action: String, fish: String, details: Dictionary = {}) -> String:
	var frozen := details.duplicate(true)
	return request_intent("inventory", func(current: Dictionary) -> Variant:
		var result := YardInventory.transition(current, revision, action, fish, frozen)
		if result.has("error"):
			return CoordinatorType.IntentRejection.new(result.error)
		return result.candidate)


func request_exploration_record(record: Variant) -> String:
	var frozen: Variant = _copy_record(record)
	var op_id := request_intent("exploration", func(current: Dictionary) -> Dictionary:
		current.exploration = _copy_record(frozen)
		return current)
	_emit_exploration_identity(op_id, "exploration", frozen)
	return op_id


## 一次提交里同时写入带回的小物、旅程水位线与会话记录。队首求值时水位线已越过这趟就只写记录、
## 不再授予；是否授予写进 receipt.granted，确认信号到达前就已填好。
func request_exploration_trip(record: Variant, trip_serial: int, find_ids: PackedStringArray, receipt: Dictionary) -> String:
	for find_id: String in find_ids:
		if not ExplorationRoutes.is_formal_find(find_id):
			return ""
	var frozen: Variant = _copy_record(record)
	var finds := find_ids.duplicate()
	var op_id := request_intent("exploration_trip", func(current: Dictionary) -> Dictionary:
		receipt.granted = trip_serial > int(current.get("exploration_committed_serial", 0))
		if receipt.granted:
			var keepsakes: Dictionary = (current.get("keepsakes", {}) as Dictionary).duplicate(true)
			for find_id: String in finds:
				keepsakes[find_id] = mini(int(keepsakes.get(find_id, 0)) + 1, SaveDataCodec.MAX_KEEPSAKE_COUNT)
			current.keepsakes = keepsakes
			current.exploration_committed_serial = trip_serial
		current.exploration = _copy_record(frozen)
		return current)
	_emit_exploration_identity(op_id, "exploration_trip", frozen, trip_serial, finds)
	return op_id


func _emit_exploration_identity(op_id: String, kind: String, record: Variant, serial := 0, finds := PackedStringArray()) -> void:
	if op_id.is_empty() or not record is Dictionary: return
	var session: Variant = record.get("session")
	if not session is Dictionary: return # idle/quarantined records prove no active trip retry
	var trip_id: String = str(session.get("trip_id", ""))
	var trip_serial := int(session.get("trip_serial", 0))
	var revision := int(session.get("record_revision", -1))
	if trip_serial <= 0 or trip_id != "trip-%d" % trip_serial or revision < 0: return
	if kind == "exploration_trip" and serial != trip_serial: return
	exploration_intent_accepted.emit(op_id, kind, {"trip_id": trip_id, "serial": trip_serial,
		"revision": revision, "finds": Array(finds)})


## Completed formal-trip cleanup only. Acceptance is not success; the CAS runs
## at the FIFO head, against the newest confirmed state. No host/schema changes.
func request_exploration_cleanup(expected_record: Variant, expected_watermark: Variant, target_idle: Variant, cleanup_id: String) -> String:
	var expected: Variant = _copy_record(expected_record)
	var target: Variant = _copy_record(target_idle)
	var valid := _valid_exploration_cleanup(expected, expected_watermark, target, cleanup_id)
	return request_intent("exploration_cleanup", func(current: Dictionary) -> Variant:
		if not valid:
			return CoordinatorType.IntentRejection.new("EXPLORATION_CLEANUP_INVALID_ARGUMENT")
		if current.get("exploration") != expected or current.get("exploration_committed_serial") != expected_watermark:
			return CoordinatorType.IntentRejection.new("EXPLORATION_CLEANUP_PRECONDITION_CHANGED")
		current.exploration = _copy_record(target)
		return current)


func _valid_exploration_cleanup(expected: Variant, watermark: Variant, target: Variant, cleanup_id: String) -> bool:
	var contract := ExplorationContract
	var serial: Variant = contract.as_int(watermark, 1, contract.MAX_INT - 1)
	if serial == null or cleanup_id.is_empty() or cleanup_id.length() > 128: return false
	if not expected is Dictionary or not target is Dictionary: return false
	var keys := ["contract_version", "next_trip_serial", "session"]
	if expected.size() != keys.size() or target.size() != keys.size(): return false
	for key in keys:
		if not expected.has(key) or not target.has(key): return false
	if contract.as_int(expected.contract_version, 1, 1) == null or contract.as_int(target.contract_version, 1, 1) == null: return false
	if not expected.session is Dictionary or target.session != null: return false
	# Restore requires explicit nullable children; never normalize missing fields.
	if not expected.session.has("proposal") or not expected.session.has("failure"): return false
	var allowed := ["trip_id", "trip_serial", "record_revision", "route_id", "catalog", "state", "started_clock", "current_stop", "visited", "offers", "carried", "taken", "rng_seed", "proposal", "failure", "companion"]
	for key in expected.session:
		if key not in allowed: return false # unsupported extensions are not discarded
	if expected.session.get("catalog") != contract.SOURCE_FORMAL: return false
	if contract.validate_session_structure(expected.session) != "": return false
	if not _cleanup_known_nested_fields(expected.session): return false
	if contract.as_int(expected.next_trip_serial, 1) == null or contract.as_int(target.next_trip_serial, 1) == null: return false
	if contract.as_int(expected.next_trip_serial, int(expected.session.trip_serial) + 1, mini(contract.MAX_INT, int(serial) + contract.NEXT_SERIAL_SLACK)) == null: return false
	if contract.record_size_bytes(expected) > contract.RECORD_BUDGET_BYTES: return false
	var restored := ExplorationSession.restore(expected, ExplorationRoutes.catalog(), int(serial))
	if restored.host_action != contract.HOST_CLOSE or restored.session.is_quarantined(): return false
	restored.session.close()
	return int(target.next_trip_serial) == int(restored.session.to_record().next_trip_serial)


func _cleanup_known_nested_fields(session: Dictionary) -> bool:
	# Shape validation already proved all scalar/map/array value types. Reject
	# extension fields in every structured child before restore can discard them.
	if not _cleanup_known_keys(session.started_clock, ["day", "elapsed"]): return false
	if session.get("proposal") != null:
		if not _cleanup_known_keys(session.proposal, ["trip_id", "route_id", "items", "reason", "revision"]): return false
		for item in session.proposal.items:
			if not _cleanup_known_keys(item, ["find_id"]): return false
	if session.get("failure") != null and not _cleanup_known_keys(session.failure, ["code", "retryable", "attempts", "deferred"]): return false
	return true


func _cleanup_known_keys(value: Dictionary, allowed: Array) -> bool:
	for key in value:
		if key not in allowed: return false
	return true


static func _copy_record(record: Variant) -> Variant:
	return record.duplicate(true) if record is Dictionary or record is Array else record


func _clean_moments(raw: Variant, album: Array) -> Dictionary:
	return SaveDataCodec.clean_moments(raw, album)


func is_initialized() -> bool:
	return _boot_state != "loading"


func can_play() -> bool:
	return _boot_state == "ready" and not _legacy_review_required


func is_save_idle() -> bool:
	return _coordinator != null and _coordinator.is_idle()


func persistence_state() -> String:
	return _coordinator.get_state() if _coordinator != null else _boot_state


func _on_boot_reply(call_id: String, method: String, reply: Dictionary) -> void:
	if call_id == _legacy_call_id and method == "exportRecovery":
		_legacy_call_id = ""
		if reply.get("status") in ["same", "changed", "absent", "unavailable"]:
			recovery_exported.emit(reply.status, JSON.stringify(reply.wire, "  ").to_utf8_buffer())
		else:
			recovery_exported.emit("unavailable", PackedByteArray())
		return
	if call_id != _boot_call_id or method not in ["open", "initialize", "inspectLegacy"]:
		return
	_boot_call_id = ""
	if method == "inspectLegacy":
		_legacy_inspection = reply.get("wire", {}).duplicate(true)
		var status := str(reply.get("status", "unavailable"))
		var changed: bool = status == "changed" or (status == "absent" and _legacy_inspection.get("baseline") == "sealed")
		_legacy_review_required = status not in ["same", "absent", "changed"] or (changed and str(_data.get("legacy_observed_sha256", "")) != _legacy_fingerprint())
		_boot_state = "ready"
		initialized.emit("review" if _legacy_review_required else "ready", "")
		return
	if reply.get("status") == "empty":
		_boot_call_id = _backend.request("initialize", {
			"payload": JSON.stringify(_default_data()),
			"paths": _legacy_paths(),
		})
		return
	var wire: Dictionary = reply.get("wire", {})
	if reply.get("status") != "ready":
		var code := str(reply.get("code", "STORE_UNAVAILABLE"))
		# Only the exact, already decoded open error denotes another page's lock.
		# Storage corruption, permissions, malformed replies and other failures keep
		# their original error; this classification never changes Host ownership.
		if method == "open" and reply.get("status") == "blocked" and code == "OPEN_FAILED" \
				and wire.size() == 3 and wire.get("schema") == "youjia.save-error/v1" \
				and wire.get("code") == "OPEN_FAILED" and wire.get("cause") == "Error: writer_owned_by_another_page":
			code = "SAVE_WRITER_OWNED"
		_block_boot(code)
		return
	var parsed: Variant = JSON.parse_string(str(wire.get("current_payload", "")))
	if parsed is Dictionary and parsed.get("schema") == "youjia.legacy-v5-import/v1":
		var selected: String = str(parsed.get("selected", ""))
		parsed = JSON.parse_string(str(parsed.get("sources", {}).get(selected, {}).get("text", "")))
	if not parsed is Dictionary or parsed.get("version") != SAVE_VERSION:
		_block_boot("UNSUPPORTED_GAME_SAVE")
		return
	# Keep unrelated owners' fields in ordinary snapshots. Raw legacy originals
	# remain separately sealed by the Host, including numbers beyond JSON precision.
	_data = parsed.duplicate(true)
	_data.merge(SaveDataCodec.project(parsed), true)
	if not _connect_coordinator(_data, str(wire.get("current_token", "")), "youjia-save-host-v1"):
		_block_boot("COORDINATOR_INIT_FAILED")
		return
	_boot_call_id = _backend.request("inspectLegacy", {"paths": _legacy_paths()})
	if _boot_call_id.is_empty():
		_legacy_review_required = true
		_boot_state = "ready"
		initialized.emit("review", "")


func _legacy_paths() -> Dictionary:
	return {"primaryPath": ProjectSettings.globalize_path(SAVE_PATH), "backupPath": ProjectSettings.globalize_path(BACKUP_PATH)}


func _legacy_fingerprint() -> String:
	return JSON.stringify(_legacy_inspection.get("sources", {})).sha256_text()


func needs_legacy_review() -> bool:
	return _legacy_review_required


func continue_current_save() -> bool:
	if _boot_state != "ready" or not await flush_pending(): return false
	# A player choice acknowledges only these observed bytes. It never merges or
	# deletes an old database, and cannot acknowledge an unreadable observation.
	if _legacy_inspection.get("status") in ["changed", "absent"]:
		var operation := request_patch("legacy-choice", {"legacy_observed_sha256": _legacy_fingerprint()})
		if operation.is_empty() or not await flush_pending(): return false
		if _data.get("legacy_observed_sha256") != _legacy_fingerprint(): return false
	_legacy_review_required = false
	return true


func export_recovery() -> bool:
	if not OS.has_feature("web") or _coordinator == null or not _coordinator.is_idle() or not _legacy_call_id.is_empty(): return false
	_legacy_call_id = _backend.request("exportRecovery", {"paths": _legacy_paths()})
	return not _legacy_call_id.is_empty()


func _block_boot(code: String) -> void:
	_boot_state = "blocked"
	initialized.emit("blocked", code)
	persistence_state_changed.emit("blocked")
	if OS.has_feature("web"):
		# The loading shell owns the visible startup error; never start a blank save.
		JavaScriptBridge.eval("window.dispatchEvent(new CustomEvent('youjia:save-blocked',{detail:" + JSON.stringify(code) + "}));", true)


func _connect_coordinator(snapshot: Dictionary, token: String, expected_namespace: String) -> bool:
	_coordinator = CoordinatorType.new()
	_coordinator.confirmed.connect(_on_commit_confirmed)
	_coordinator.rejected.connect(_on_commit_rejected)
	_coordinator.unknown.connect(_on_commit_unknown)
	_coordinator.ack_failed.connect(_on_commit_unknown)
	_coordinator.state_changed.connect(func(value: String): persistence_state_changed.emit(value))
	return _coordinator.initialize(_backend, snapshot, token, expected_namespace)


func _ensure_native_coordinator() -> bool:
	return _coordinator != null and _boot_state == "ready"


## Returns acceptance identity only. Consumers must wait for commit_confirmed.
func request_intent(kind: String, intent: Callable) -> String:
	if _boot_state != "ready" or not _ensure_native_coordinator():
		return ""
	var op_id: String = _coordinator.enqueue(intent)
	if not op_id.is_empty():
		_pending_kinds[op_id] = kind
	return op_id


func request_patch(kind: String, patch: Dictionary) -> String:
	var frozen := patch.duplicate(true)
	return request_intent(kind, func(current: Dictionary) -> Dictionary:
		current.merge(frozen, true)
		return current)


func request_album(photos: PackedStringArray, moments: Dictionary = {}) -> String:
	var frozen_photos := photos.duplicate()
	var frozen_moments := moments.duplicate(true)
	return request_intent("album", func(current: Dictionary) -> Dictionary:
		var album: Array = current.get("album", []).duplicate()
		for photo_id: String in frozen_photos:
			if not photo_id.is_empty() and photo_id not in album: album.append(photo_id)
		var combined: Dictionary = current.get("photo_moments", {}).duplicate(true)
		combined.merge(frozen_moments, true)
		current.album = album
		current.photo_moments = _clean_moments(combined, album)
		return current)


func request_yard_progress(day: int, elapsed: float, state: int, day_planted: int, watered_day: int) -> String:
	return request_patch("yard", {"holiday_day": maxi(1, day), "holiday_day_elapsed": maxf(0.0, elapsed), "plant_state": clampi(state, 0, 3), "plant_day_planted": maxi(0, day_planted), "plant_watered_day": watered_day})


func request_plant_state(state: int, day_planted: int, watered_day: int) -> String:
	return request_patch("plant", {"plant_state": clampi(state, 0, 3), "plant_day_planted": maxi(0, day_planted), "plant_watered_day": watered_day})


func request_first_fish_caught() -> String:
	return request_patch("fish", {"first_fish_caught": true})


func request_animal_relationship_memory(memory: Dictionary) -> String:
	var clean := AnimalRelationshipsType.sanitize(memory)
	return request_intent("relationship", func(current: Dictionary) -> Dictionary:
		var combined: Dictionary = current.get("animal_relationship_memory", {}).duplicate(true)
		combined.merge(clean, true)
		current.animal_relationship_memory = AnimalRelationshipsType.sanitize(combined)
		return current)


func _on_commit_confirmed(op_id: String, snapshot: Dictionary, _token: String) -> void:
	_data = snapshot.duplicate(true)
	var kind: String = str(_pending_kinds.get(op_id, ""))
	_pending_kinds.erase(op_id)
	commit_confirmed.emit(op_id, kind)


func _on_commit_rejected(op_id: String, code: String) -> void:
	var kind: String = str(_pending_kinds.get(op_id, ""))
	_pending_kinds.erase(op_id)
	commit_rejected.emit(op_id, kind, code)


func _on_commit_unknown(op_id: String, code: String) -> void:
	commit_unknown.emit(op_id, str(_pending_kinds.get(op_id, "")), code)


func retry_pending() -> bool:
	return _coordinator != null and _coordinator.retry_resolve()


func flush_pending() -> bool:
	if _coordinator == null: return _boot_state == "ready"
	while not _coordinator.is_idle():
		if _coordinator.get_state() in ["blocked", "unknown", "initializing"]: return false
		await get_tree().process_frame
	return true
