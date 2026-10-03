extends Node

const SAVE_PATH := "user://youjia_save.json"
const TEMP_PATH := "user://youjia_save.tmp"
const BACKUP_PATH := "user://youjia_save.bak"
const SaveFilesType := preload("res://scripts/persistence/save_files.gd")
const AnimalRelationshipsType := preload("res://scripts/game/animal_relationships.gd")
const SAVE_VERSION := 5
const TUTORIAL_VERSION := 1

var _data: Dictionary = {}


func _ready() -> void:
	_load()


func _default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"locale": "zh-CN",
		"tutorial_version": 0,
		"album": [],
		"photo_moments": {},
		# 假期天数系统（v4 兼容新增字段）
		"holiday_day": 1,
		"holiday_day_elapsed": 0.0,
		# 植物床状态（0=空, 1=已种, 2=发芽, 3=开花）
		"plant_state": 0,
		"plant_day_planted": 0,
		"plant_watered_day": -1,
		# 钓鱼记录
		"first_fish_caught": false,
		"animal_relationship_memory": {},
	}


func _load() -> void:
	_data = _default_data()
	var record: Dictionary = SaveFilesType.new().recover(SAVE_PATH, BACKUP_PATH)
	if record.is_empty():
		return
	var candidate: Dictionary = record.data
	var locale := str(candidate.get("locale", "zh-CN"))
	_data.locale = locale if locale in ["en", "zh-CN"] else "zh-CN"
	_data.tutorial_version = clampi(int(candidate.get("tutorial_version", 0)), 0, TUTORIAL_VERSION)
	var album: Array = []
	var raw: Variant = candidate.get("album", [])
	if raw is Array:
		for item: Variant in raw:
			var photo_id := str(item)
			if not photo_id.is_empty() and photo_id not in album:
				album.append(photo_id)
	_data.album = album
	_data.photo_moments = _clean_moments(candidate.get("photo_moments",{}),album)
	# 读取假期进度（旧存档没有这些字段时用默认值）
	_data.holiday_day = maxi(1, int(candidate.get("holiday_day", 1)))
	_data.holiday_day_elapsed = maxf(0.0, float(candidate.get("holiday_day_elapsed", 0.0)))
	_data.plant_state = clampi(int(candidate.get("plant_state", 0)), 0, 3)
	_data.plant_day_planted = maxi(0, int(candidate.get("plant_day_planted", 0)))
	_data.plant_watered_day = int(candidate.get("plant_watered_day", -1))
	_data.first_fish_caught = bool(candidate.get("first_fish_caught", false))
	_data.animal_relationship_memory = AnimalRelationshipsType.sanitize(candidate.get("animal_relationship_memory", {}))


func save() -> bool:
	return SaveFilesType.new().commit(_data, SAVE_PATH, TEMP_PATH, BACKUP_PATH)


func get_locale() -> String:
	return str(_data.get("locale", "zh-CN"))


func set_locale(locale: String) -> void:
	if locale not in ["en", "zh-CN"]:
		return
	_data.locale = locale
	save()


func is_tutorial_completed(version: int = TUTORIAL_VERSION) -> bool:
	return int(_data.get("tutorial_version", 0)) >= version


func set_tutorial_completed(completed: bool, version: int = TUTORIAL_VERSION) -> void:
	_data.tutorial_version = clampi(version, 0, TUTORIAL_VERSION) if completed else 0
	save()


func get_album() -> Array:
	return (_data.get("album", []) as Array).duplicate()


func set_album(photos: PackedStringArray, moments: Dictionary = {}) -> bool:
	var album: Array = []
	for photo_id: String in photos:
		if photo_id not in album:
			album.append(photo_id)
	_data.album = album
	var combined: Dictionary = _data.get("photo_moments",{}).duplicate(true)
	for photo_id: Variant in moments: combined[photo_id] = moments[photo_id]
	_data.photo_moments = _clean_moments(combined,album)
	return save()


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
	_data.holiday_day = maxi(1, day)
	_data.holiday_day_elapsed = maxf(0.0, elapsed)
	save()


# ── 植物床 ────────────────────────────────────────────────────────────────────

func get_plant_state() -> Dictionary:
	return {
		"state": int(_data.get("plant_state", 0)),
		"day_planted": int(_data.get("plant_day_planted", 0)),
		"watered_day": int(_data.get("plant_watered_day", -1)),
	}


func set_plant_state(state: int, day_planted: int, watered_day: int) -> void:
	_data.plant_state = clampi(state, 0, 3)
	_data.plant_day_planted = maxi(0, day_planted)
	_data.plant_watered_day = watered_day
	save()


# ── 钓鱼记录 ──────────────────────────────────────────────────────────────────

func get_first_fish_caught() -> bool:
	return bool(_data.get("first_fish_caught", false))


func set_first_fish_caught() -> void:
	_data.first_fish_caught = true
	save()


func get_animal_relationship_memory() -> Dictionary:
	return (_data.get("animal_relationship_memory", {}) as Dictionary).duplicate(true)


func set_animal_relationship_memory(memory: Dictionary) -> bool:
	_data.animal_relationship_memory = AnimalRelationshipsType.sanitize(memory)
	return save()


func _clean_moments(raw: Variant, album: Array) -> Dictionary:
	var result: Dictionary = {}
	if not raw is Dictionary: return result
	for photo_id: Variant in raw:
		if not photo_id is String or photo_id not in album or photo_id not in ExpressionCatalog.all_ids(): continue
		var moment := PhotoMoment.sanitize(raw[photo_id])
		if not moment.is_empty() and str(moment.get("rule_id","")) == photo_id:
			result[photo_id] = moment
	return result
