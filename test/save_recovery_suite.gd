extends SceneTree

const Files = preload("res://scripts/persistence/save_files.gd")
const ROOT := "user://save_recovery_tests"
const PRIMARY := ROOT + "/save.json"
const TEMP := ROOT + "/save.tmp"
const BACKUP := ROOT + "/save.bak"
var checks := 0
var failures: Array[String] = []
var files = Files.new()

# Force a real OS rename failure after the old primary has been secured.
class BlockPromotion extends Files:
	func _rename(from: String, to: String) -> Error:
		var result := super._rename(from, to)
		if result == OK and to.ends_with(".bak"):
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(from))
			var blocker := FileAccess.open(from + "/block", FileAccess.WRITE)
			blocker.store_string("occupied")
			blocker.close()
		return result


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


func write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func remove_tree(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if DirAccess.dir_exists_absolute(absolute):
		var dir := DirAccess.open(path)
		for child in dir.get_files():
			DirAccess.remove_absolute(absolute.path_join(child))
		for child in dir.get_directories():
			remove_tree(path.path_join(child))
	DirAccess.remove_absolute(absolute)


func reset_files() -> void:
	remove_tree(ROOT)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT))


func run() -> void:
	reset_files()
	var old := {"version": 5, "holiday_day": 9, "album": ["legacy-id"], "plant_state": 2}
	var next := old.duplicate(true)
	next.holiday_day = 10
	check(files.commit(old, PRIMARY, TEMP, BACKUP), "first save commits a readable record")
	var old_bytes := FileAccess.get_file_as_bytes(PRIMARY)
	check(files.commit(next, PRIMARY, TEMP, BACKUP), "second save commits new progress")
	check(FileAccess.get_file_as_bytes(BACKUP) == old_bytes, "backup preserves prior exact bytes")
	check(files.recover(PRIMARY, BACKUP).data.holiday_day == 10, "valid primary wins over older backup")

	write_text(PRIMARY, "{broken")
	check(files.recover(PRIMARY, BACKUP).data.holiday_day == 9, "malformed primary recovers last complete backup")
	write_text(PRIMARY, "[]")
	check(files.recover(PRIMARY, BACKUP).data.holiday_day == 9, "non-object primary also falls back")
	check(files.commit(next, PRIMARY, TEMP, BACKUP), "save after recovery replaces invalid primary")
	check(FileAccess.get_file_as_bytes(BACKUP) == old_bytes, "invalid primary never overwrites valid backup")

	# Real failed open: the temporary target is an occupied directory.
	remove_tree(TEMP)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEMP))
	write_text(TEMP + "/block", "occupied")
	check(not files.commit(old, PRIMARY, TEMP, BACKUP), "temporary open failure returns false")
	check(files.recover(PRIMARY, BACKUP).data.holiday_day == 10, "write failure preserves primary progress")
	remove_tree(TEMP)

	# Real failed rotation: backup target is an occupied directory.
	remove_tree(BACKUP)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BACKUP))
	write_text(BACKUP + "/block", "occupied")
	check(not files.commit(old, PRIMARY, TEMP, BACKUP), "backup rotation failure returns false")
	check(files.recover(PRIMARY, BACKUP).data.holiday_day == 10, "rotation failure leaves good primary")

	reset_files()
	check(files.commit(old, PRIMARY, TEMP, BACKUP), "seed promotion failure case")
	check(not BlockPromotion.new().commit(next, PRIMARY, TEMP, BACKUP), "actual promotion rename failure returns false")
	check(files.recover(PRIMARY, BACKUP).data.holiday_day == 9, "promotion failure recovers secured old record")
	remove_tree(PRIMARY)
	check(files.commit(next, PRIMARY, TEMP, BACKUP), "retry after obstruction removed succeeds")
	check(files.recover(PRIMARY, BACKUP).data.holiday_day == 10, "retry retains latest submitted progress")

	# Construct actual files at the interruption point, then create a fresh reader.
	reset_files()
	write_text(PRIMARY, JSON.stringify(old))
	write_text(TEMP, JSON.stringify(next))
	DirAccess.rename_absolute(ProjectSettings.globalize_path(PRIMARY), ProjectSettings.globalize_path(BACKUP))
	check(Files.new().recover(PRIMARY, BACKUP).data.holiday_day == 9, "restart between rotation and promotion chooses backup, not temporary")
	remove_tree(BACKUP)
	check(Files.new().recover(PRIMARY, BACKUP).is_empty(), "uncommitted temporary alone is not promoted")
	check(FileAccess.file_exists(TEMP), "uncommitted temporary remains available for diagnostics")

	# SaveStore v5 integration using its actual paths; preserve all original files.
	var store := root.get_node("SaveStore")
	var originals := {}
	for path: String in [store.SAVE_PATH, store.TEMP_PATH, store.BACKUP_PATH]:
		if FileAccess.file_exists(path):
			originals[path] = FileAccess.get_file_as_bytes(path)
		remove_tree(path)
	var original_data: Dictionary = store._data.duplicate(true)
	var legacy: Dictionary = store._default_data()
	legacy.holiday_day = 9
	legacy.plant_state = 2
	legacy.plant_day_planted = 7
	legacy.first_fish_caught = true
	legacy.album = ["llama_fed_gentle"]
	write_text(store.BACKUP_PATH, JSON.stringify(legacy))
	write_text(store.SAVE_PATH, "bad json")
	store._load()
	check(store.get_holiday_day() == 9 and store.get_plant_state().state == 2, "SaveStore restores v5 day and plant from backup")
	check(store.get_first_fish_caught() and "llama_fed_gentle" in store.get_album(), "SaveStore restores fish and album IDs without resetting progress")
	check(store.save(), "SaveStore can save again after recovery")
	store._load()
	check(store.get_holiday_day() == 9 and store.get_first_fish_caught(), "recovered progress survives another load")
	for path: String in [store.SAVE_PATH, store.TEMP_PATH, store.BACKUP_PATH]:
		remove_tree(path)
		if originals.has(path):
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_buffer(originals[path])
			file.close()
	store._data = original_data
	remove_tree(ROOT)
	root.get_node("AudioDirector").release_streams()
	if failures.is_empty():
		print("SAVE RECOVERY PASS ", checks)
		quit(0)
		return
	print("SAVE RECOVERY FAIL ", failures)
	quit(1)
