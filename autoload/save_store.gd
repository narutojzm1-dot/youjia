extends Node

signal initialized(status: String, code: String)
signal commit_confirmed(op_id: String, kind: String)
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
		# Keep the existing synchronous file API for native compatibility/tests.
		# New gameplay requests lazily initialize the same FIFO protocol.
		_boot_state = "ready"



func _default_data() -> Dictionary:
	return SaveDataCodec.defaults()


func _load() -> void:
	# Native reload is a new read boundary only after every request has ended.
	# Never detach a writer with an unknown outcome.
	if _coordinator != null:
		if OS.has_feature("web") or not _coordinator.close_when_idle():
			return
		_coordinator = null
		_backend = null
	_data = _default_data()
	var record: Dictionary = SaveFilesType.new().recover(SAVE_PATH, BACKUP_PATH)
	if record.is_empty():
		return
	_data = record.data.duplicate(true)
	_data.merge(SaveDataCodec.project(record.data), true)


func save() -> bool:
	return _commit_candidate(_data.duplicate(true))


# One commit boundary for every setter. A failed file write must not leak a
# candidate into getters or a later unrelated save. These compatibility setters
# are native-only; Web callers use the asynchronous receipt API below.
func _commit_candidate(candidate: Dictionary) -> bool:
	# Web callers must use request_* and wait for an authoritative receipt.
	if OS.has_feature("web") or (_coordinator != null and not _coordinator.is_idle()):
		return false
	if not SaveFilesType.new().commit(candidate, SAVE_PATH, TEMP_PATH, BACKUP_PATH):
		return false
	if _coordinator != null:
		_coordinator.close_when_idle()
		_coordinator = null
		_backend = null
	_data = candidate
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


func _clean_moments(raw: Variant, album: Array) -> Dictionary:
	return SaveDataCodec.clean_moments(raw, album)


func is_initialized() -> bool:
	return _boot_state != "loading"


func can_play() -> bool:
	return _boot_state == "ready" and not _legacy_review_required


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
		_block_boot(str(reply.get("code", "STORE_UNAVAILABLE")))
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
	if _coordinator != null:
		return true
	if OS.has_feature("web"):
		return false
	_backend = NativeHostType.new(SAVE_PATH, TEMP_PATH, BACKUP_PATH)
	if _backend.get_state() != "ready":
		_block_boot("NATIVE_SOURCE_BLOCKED")
		return false
	return _connect_coordinator(_data, _backend.get_initial_token(), "youjia-native-file-v1")


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
