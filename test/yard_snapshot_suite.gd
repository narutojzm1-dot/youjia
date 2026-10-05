extends SceneTree

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func run() -> void:
	# This suite writes through the production singleton. Only the daily runner's
	# disposable XDG directory is accepted; never touch a normal player's files.
	var isolated := OS.get_environment("XDG_DATA_HOME")
	if not isolated.begins_with("/tmp/youjia-daily-check.") or not OS.get_user_data_dir().begins_with(isolated + "/"):
		print("REFUSED: run through tools/verify_daily_life.sh (isolated XDG required)")
		quit(2)
		return
	var store = root.get_node("SaveStore")
	store._data = store._default_data()
	store._data.album = ["legacy-snapshot-photo"]
	check(store.set_yard_progress(3, 12.5, 1, 2, 3), "seed complete old snapshot")
	var old_bytes := FileAccess.get_file_as_bytes(store.SAVE_PATH)
	var world = load("res://scripts/game/yard_world.gd").new()
	world.holiday_day = 7
	world._day_elapsed = 45.5
	world._plant_state = 2
	world._plant_day_planted = 5
	world._plant_watered_day = 6
	world._save_progress()
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(store.SAVE_PATH))
	check(saved.holiday_day == 7 and saved.holiday_day_elapsed == 45.5 and saved.plant_state == 2 and saved.plant_day_planted == 5 and saved.plant_watered_day == 6, "production world writes matching clock and plant")
	check(FileAccess.get_file_as_bytes(store.BACKUP_PATH) == old_bytes, "backup is complete prior snapshot, never new clock with old plant")
	check(saved.album == ["legacy-snapshot-photo"], "unrelated progress survives yard write")
	var good_bytes := FileAccess.get_file_as_bytes(store.SAVE_PATH)
	var good_memory: Dictionary = store._data.duplicate(true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(store.TEMP_PATH))
	var blocker := FileAccess.open(store.TEMP_PATH + "/block", FileAccess.WRITE)
	blocker.store_string("occupied")
	blocker.close()
	check(not store.set_yard_progress(9, 99.0, 3, 8, 9), "real temporary-file failure rejects whole snapshot")
	check(store._data == good_memory, "failed commit leaves acknowledged memory intact")
	check(FileAccess.get_file_as_bytes(store.SAVE_PATH) == good_bytes, "failed commit leaves disk snapshot intact")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(store.TEMP_PATH + "/block"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(store.TEMP_PATH))
	world._save_progress()
	check(store._data == good_memory, "retry retains complete live world snapshot")
	check(store.set_yard_progress(-1, -2, 99, -3, -1), "bounded snapshot can commit")
	check(store.get_holiday_day() == 1 and store.get_holiday_day_elapsed() == 0.0 and store.get_plant_state() == {"state":3,"day_planted":0,"watered_day":-1}, "legacy bounds and unwatered sentinel remain")
	world.free()
	print("yard snapshot: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
