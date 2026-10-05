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
	var isolated := OS.get_environment("XDG_DATA_HOME")
	if not isolated.begins_with("/tmp/youjia-daily-check.") or not OS.get_user_data_dir().begins_with(isolated + "/"):
		print("REFUSED: disposable daily XDG directory required")
		quit(2)
		return
	var store = root.get_node("SaveStore")
	var memory_key := AnimalRelationships.GOOSE_LLAMA_SHARED_SPACE
	var operations: Array[Dictionary] = [
		{"method":"set_locale", "args":["en"], "expected":{"locale":"en"}},
		{"method":"set_tutorial_completed", "args":[true], "expected":{"tutorial_version":1}},
		{"method":"set_album", "args":[PackedStringArray(["photo-a", "photo-a", "photo-b"])], "expected":{"album":["photo-a", "photo-b"]}},
		{"method":"set_holiday_progress", "args":[7, 12.5], "expected":{"holiday_day":7,"holiday_day_elapsed":12.5}},
		{"method":"set_yard_progress", "args":[7,12.5,2,5,6], "expected":{"holiday_day":7,"holiday_day_elapsed":12.5,"plant_state":2,"plant_day_planted":5,"plant_watered_day":6}},
		{"method":"set_plant_state", "args":[2,5,6], "expected":{"plant_state":2,"plant_day_planted":5,"plant_watered_day":6}},
		{"method":"set_first_fish_caught", "args":[], "expected":{"first_fish_caught":true}},
		{"method":"set_animal_relationship_memory", "args":[{memory_key:true}], "expected":{"animal_relationship_memory":{memory_key:true}}},
	]
	for operation: Dictionary in operations:
		var name: String = operation.method
		store._data = store._default_data()
		# A field belonging to another module must survive every candidate copy.
		store._data.shared_owner_data = {"trip":14,"objects":["unrelated"]}
		check(store.save(), name + ": seed valid prior state")
		var before: Dictionary = store._data.duplicate(true)
		var before_bytes := FileAccess.get_file_as_bytes(store.SAVE_PATH)
		# Exercise actual FileAccess failure, not a mocked successful backend.
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(store.TEMP_PATH))
		var blocker := FileAccess.open(store.TEMP_PATH + "/occupied", FileAccess.WRITE)
		blocker.store_string("non-empty directory prevents opening the temp file")
		blocker.close()
		store.callv(name, operation.args)
		check(store._data == before, name + ": rejected candidate is not visible in memory")
		check(FileAccess.get_file_as_bytes(store.SAVE_PATH) == before_bytes, name + ": rejected candidate leaves prior file intact")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(store.TEMP_PATH + "/occupied"))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(store.TEMP_PATH))
		# A later unrelated save must not smuggle the earlier failed update onto disk.
		check(store.save(), name + ": unrelated later save succeeds")
		var disk: Variant = JSON.parse_string(FileAccess.get_file_as_string(store.SAVE_PATH))
		check(disk == JSON.parse_string(JSON.stringify(before)), name + ": later save does not commit rejected fields")
		store.callv(name, operation.args)
		var expected := before.duplicate(true)
		for field: Variant in operation.expected:
			expected[field] = operation.expected[field]
		check(store._data == expected, name + ": successful candidate publishes complete state")
		check(JSON.parse_string(FileAccess.get_file_as_string(store.SAVE_PATH)) == JSON.parse_string(JSON.stringify(expected)), name + ": successful file matches confirmed memory")
		check(JSON.parse_string(FileAccess.get_file_as_string(store.BACKUP_PATH)) == JSON.parse_string(JSON.stringify(before)), name + ": backup preserves complete prior state")
		store._load()
		var known_expected: Dictionary = store.SaveDataCodec.project(expected)
		check(store._data == known_expected, name + ": accepted gameplay values survive real reload")
	print("save candidate: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
