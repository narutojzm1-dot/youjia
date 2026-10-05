extends SceneTree

# #294 bound samples. Run only through run_bounds.sh (disposable /tmp XDG).
# godot --headless --path . --script res://test/save_payload_budget/generate_bounds.gd -- --out DIR --host-snapshot FILE
const Codec := preload("res://scripts/persistence/save_data_codec.gd")
const SaveFilesType := preload("res://scripts/persistence/save_files.gd")
const Captures := preload("res://test/save_payload_budget/rule_captures.gd")
const CANDIDATE_SOURCE := 1572864
const SMALL_SOURCE := 5000
const STRESS_KEY := "x_stress_extension"
# Godot JSON.stringify writes " \ newline tab as two-byte escapes, U+0001 raw
# (one byte, not valid strict JSON), CJK/U+2028 as raw three-byte UTF-8.
const UNITS := {"ascii": "a", "quote": "\"", "backslash": "\\", "newline": "\n", "tab": "\t",
	"control": "\u0001", "cjk": "假", "u2028": "\u2028"}
const PAIRS := [["ascii", "ascii"], ["quote", "quote"], ["backslash", "backslash"], ["newline", "newline"],
	["tab", "tab"], ["cjk", "cjk"], ["u2028", "u2028"], ["control", "control"], ["quote", "ascii"],
	["ascii", "control"], ["quote", "control"]]

var _out := ""
var _host_snapshot: Object
var _samples: Array = []
var _errors := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_at := args.find("--out")
	var host_at := args.find("--host-snapshot")
	if out_at < 0 or host_at < 0 or out_at + 1 >= args.size() or host_at + 1 >= args.size():
		_fail("usage: -- --out DIR --host-snapshot FILE")
		return _finish()
	_out = args[out_at + 1]
	var xdg := OS.get_environment("XDG_DATA_HOME")
	var store := root.get_node("SaveStore")
	if xdg.is_empty() or not xdg.begins_with("/tmp/") or not ProjectSettings.globalize_path("user://").begins_with(xdg) \
			or FileAccess.file_exists(store.SAVE_PATH) or FileAccess.file_exists(store.BACKUP_PATH):
		_fail("refusing to run outside a fresh disposable /tmp XDG_DATA_HOME")
		return _finish()
	var file := FileAccess.open("user://host_source_snapshot.gd", FileAccess.WRITE)
	file.store_string(FileAccess.get_file_as_string(args[host_at + 1]))
	file.close()
	var script: Script = load("user://host_source_snapshot.gd")
	if script == null or not script.can_instantiate():
		_fail("cannot load Host source_snapshot.gd")
		return _finish()
	_host_snapshot = script.new()
	DirAccess.make_dir_recursive_absolute(_out)
	root.get_node("TuningStore").call("end_run")
	root.get_node("TuningStore").call("reset_defaults")
	var captured := Captures.capture_all(root)
	for message: String in captured.errors: _fail(message)
	if captured.errors.is_empty():
		_album("natural_full", captured.ids, captured.moments, false)
		var dense: Dictionary = {}
		for id: String in captured.ids: dense[id] = Captures.dense(captured.moments[id])
		_album("dense_full", captured.ids, dense, true)
	for pair: Array in PAIRS:
		_pair("big_%s_%s" % pair, pair[0], pair[1], CANDIDATE_SOURCE, false)
		_pair("small_%s_%s" % pair, pair[0], pair[1], SMALL_SOURCE, true)
	root.get_node("AudioDirector").call("release_streams")
	_finish()


# Real SaveStore path: one set_album per new photo, then a yard save so the
# primary and backup both hold the whole album.
func _album(name: String, ids: Array, moments: Dictionary, synthetic: bool) -> void:
	var store := root.get_node("SaveStore")
	for path: String in [store.SAVE_PATH, store.BACKUP_PATH, store.TEMP_PATH]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	store._data = store._default_data()
	var collected := PackedStringArray()
	for id: String in ids:
		collected.append(id)
		if not store.set_album(collected, {id: moments[id]}): _fail("%s set_album failed at %s" % [name, id])
	if not store.set_yard_progress(30, 41.5, 3, 27, 30): _fail("%s set_yard_progress failed" % name)
	if not store.set_animal_relationship_memory({AnimalRelationships.GOOSE_LLAMA_SHARED_SPACE: true}):
		_fail("%s set_animal_relationship_memory failed" % name)
	store.set_first_fish_caught()
	store.set_tutorial_completed(true)
	var entry := _record(name, store.SAVE_PATH, store.BACKUP_PATH, false)
	entry.synthetic = synthetic
	entry.source = ("15 sanitize-legal photos, each a real capture padded to MAX_ITEMS=64 with its own items; not game-produced"
		if synthetic else "15 real captures through SaveStore.set_album, then set_yard_progress")
	var projection := Codec.project(JSON.parse_string(FileAccess.get_file_as_string(store.SAVE_PATH)))
	var items: Array = []
	for id: String in projection.photo_moments: items.append((projection.photo_moments[id].items as Array).size())
	entry.projection_moment_items = items
	entry.projection_compact_bytes = JSON.stringify(projection).to_utf8_buffer().size()


func _pair(name: String, primary_unit: String, backup_unit: String, target: int, capture: bool) -> void:
	var dir := "user://bounds/%s" % name
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var files := SaveFilesType.new()
	var p := dir + "/youjia_save.json"
	var b := dir + "/youjia_save.bak"
	var t := dir + "/youjia_save.tmp"
	if not files.commit(_sized(UNITS[backup_unit], target), p, t, b): _fail("%s backup commit failed" % name)
	if not files.commit(_sized(UNITS[primary_unit], target), p, t, b): _fail("%s primary commit failed" % name)
	var entry := _record(name, p, b, capture)
	entry.synthetic = true
	entry.units = {"primary": primary_unit, "backup": backup_unit}
	entry.target_bytes = target
	entry.source = "SaveFiles.commit of defaults + %s filled with %s/%s to exactly %d bytes per file" % [STRESS_KEY, primary_unit, backup_unit, target]


func _sized(unit: String, target: int) -> Dictionary:
	var data := Codec.defaults()
	data[STRESS_KEY] = ""
	var empty := _pretty_bytes(data)
	data[STRESS_KEY] = unit
	var per_unit := _pretty_bytes(data) - empty
	var count := (target - empty) / per_unit
	data[STRESS_KEY] = unit.repeat(count) + "a".repeat(target - empty - count * per_unit)
	if _pretty_bytes(data) != target: _fail("cannot size %s payload to %d bytes" % [unit.c_escape(), target])
	return data


func _pretty_bytes(data: Dictionary) -> int:
	return JSON.stringify(data, "  ").to_utf8_buffer().size()


func _record(name: String, primary: String, backup: String, capture: bool) -> Dictionary:
	var entry := {"name": name}
	for role: String in ["primary", "backup"]:
		var path := primary if role == "primary" else backup
		var raw := FileAccess.get_file_as_bytes(path)
		var copy := "%s/%s.%s.json" % [_out, name, role]
		var file := FileAccess.open(copy, FileAccess.WRITE)
		file.store_buffer(raw)
		file.close()
		var text := raw.get_string_from_utf8()
		entry[role] = {"file": copy.get_file(), "bytes": raw.size(), "chars": text.length(),
			"sha256": FileAccess.get_sha256(copy), "godot_json_parse_ok": JSON.new().parse(text) == OK}
	if capture:
		var snapshot_file := "%s/%s.snapshot.json" % [_out, name]
		var file := FileAccess.open(snapshot_file, FileAccess.WRITE)
		file.store_string(JSON.stringify(_host_snapshot.call("capture", primary, backup)))
		file.close()
		entry.snapshot = snapshot_file.get_file()
	_samples.append(entry)
	print("[save-budget-bounds] %s primary=%d backup=%d" % [name, entry.primary.bytes, entry.backup.bytes])
	return entry


func _fail(message: String) -> void:
	_errors.append(message)
	push_error("[save-budget-bounds] " + message)


func _finish() -> void:
	if not _out.is_empty() and DirAccess.dir_exists_absolute(_out):
		var file := FileAccess.open(_out + "/bounds.json", FileAccess.WRITE)
		file.store_string(JSON.stringify({"godot": Engine.get_version_info().string, "samples": _samples, "errors": _errors}, "  "))
		file.close()
	print("[save-budget-bounds] generator %s: %d samples, %d errors" % ["OK" if _errors.is_empty() else "FAIL", _samples.size(), _errors.size()])
	quit(0 if _errors.is_empty() else 1)
