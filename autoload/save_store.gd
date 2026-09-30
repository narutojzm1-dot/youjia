extends Node

const SAVE_PATH := "user://youjia_save.json"
const TEMP_PATH := "user://youjia_save.tmp"
const SAVE_VERSION := 3
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
	}


func _load() -> void:
	_data = _default_data()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return
	var candidate: Dictionary = parsed
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


func save() -> bool:
	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(_data, "  "))
	file.close()
	var temporary := ProjectSettings.globalize_path(TEMP_PATH)
	var destination := ProjectSettings.globalize_path(SAVE_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		var remove_error := DirAccess.remove_absolute(destination)
		if remove_error != OK:
			return false
	return DirAccess.rename_absolute(temporary, destination) == OK


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


func set_album(photos: PackedStringArray) -> bool:
	var album: Array = []
	for photo_id: String in photos:
		if photo_id not in album:
			album.append(photo_id)
	_data.album = album
	return save()
