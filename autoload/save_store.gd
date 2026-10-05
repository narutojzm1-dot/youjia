extends Node

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
	_load()


func _default_data() -> Dictionary:
	return SaveDataCodec.defaults()


func _load() -> void:
	_data = _default_data()
	var record: Dictionary = SaveFilesType.new().recover(SAVE_PATH, BACKUP_PATH)
	if record.is_empty():
		return
	_data = SaveDataCodec.project(record.data)


func save() -> bool:
	return _commit_candidate(_data.duplicate(true))


# One commit boundary for every setter. A failed file write must not leak a
# candidate into getters or a later unrelated save. On Web this confirms only
# Godot's user:// file commit; it is not an IndexedDB durable receipt.
func _commit_candidate(candidate: Dictionary) -> bool:
	if not SaveFilesType.new().commit(candidate, SAVE_PATH, TEMP_PATH, BACKUP_PATH):
		return false
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


# ── 探索 ──────────────────────────────────────────────────────────────────────
# 同 set_yard_progress：候选提交成功后才发布到内存，失败时内存保持写入前原样。

func get_exploration_record() -> Variant:
	var record: Variant = _data.get("exploration", null)
	return record.duplicate(true) if record is Dictionary or record is Array else record


func get_exploration_committed_serial() -> int:
	return int(_data.get("exploration_committed_serial", 0))


func get_keepsakes() -> Dictionary:
	return (_data.get("keepsakes", {}) as Dictionary).duplicate(true)


func save_exploration_record(record: Variant) -> bool:
	var candidate: Dictionary = _data.duplicate(true)
	candidate.exploration = record.duplicate(true) if record is Dictionary or record is Array else record
	return _commit_candidate(candidate)


## 一次文件提交里同时写入带回的小物、旅程水位线与会话记录，避免重复授予。
func commit_exploration_trip(record: Variant, trip_serial: int, find_ids: PackedStringArray) -> bool:
	if trip_serial <= get_exploration_committed_serial():
		return false
	var candidate: Dictionary = _data.duplicate(true)
	var keepsakes: Dictionary = (candidate.get("keepsakes", {}) as Dictionary).duplicate(true)
	for find_id: String in find_ids:
		if not ExplorationRoutes.is_formal_find(find_id):
			return false
		keepsakes[find_id] = mini(int(keepsakes.get(find_id, 0)) + 1, SaveDataCodec.MAX_KEEPSAKE_COUNT)
	candidate.keepsakes = keepsakes
	candidate.exploration_committed_serial = trip_serial
	candidate.exploration = record.duplicate(true) if record is Dictionary or record is Array else record
	return _commit_candidate(candidate)


func _clean_moments(raw: Variant, album: Array) -> Dictionary:
	return SaveDataCodec.clean_moments(raw, album)
