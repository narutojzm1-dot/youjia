extends SceneTree

# Save payload capacity samples for #287. Run only through run.sh, which pins a
# disposable XDG_DATA_HOME under /tmp; this script refuses any other user:// root.
# godot --headless --path . --script res://test/save_payload_budget/generate_samples.gd -- --out DIR --host-snapshot FILE
const Codec := preload("res://scripts/persistence/save_data_codec.gd")
const SaveFilesType := preload("res://scripts/persistence/save_files.gd")
const LIMIT := 65536
const STRESS_KEY := "x_stress_extension"

var _out := ""
var _host_snapshot: Object
var _samples: Array = []
var _errors := PackedStringArray()
var _moments: Dictionary = {}
var _rule_ids: Array = []


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
	if not _disposable_user_dir():
		return _finish()
	var host_copy := "user://host_source_snapshot.gd"
	var source := FileAccess.get_file_as_string(args[host_at + 1])
	var file := FileAccess.open(host_copy, FileAccess.WRITE)
	file.store_string(source)
	file.close()
	var script: Script = load(host_copy)
	if script == null or not script.can_instantiate():
		_fail("cannot load Host source_snapshot.gd")
		return _finish()
	_host_snapshot = script.new()
	DirAccess.make_dir_recursive_absolute(_out)
	root.get_node("TuningStore").call("end_run")
	root.get_node("TuningStore").call("reset_defaults")
	_capture_all_rules()
	_natural_progression()
	_stress_samples()
	root.get_node("AudioDirector").call("release_streams")
	_finish()


func _disposable_user_dir() -> bool:
	var xdg := OS.get_environment("XDG_DATA_HOME")
	var user_dir := ProjectSettings.globalize_path("user://")
	if xdg.is_empty() or not xdg.begins_with("/tmp/") or not user_dir.begins_with(xdg):
		_fail("refusing to run outside a disposable /tmp XDG_DATA_HOME: %s" % user_dir)
		return false
	var store := root.get_node("SaveStore")
	for path: String in [store.SAVE_PATH, store.BACKUP_PATH, store.TEMP_PATH]:
		if FileAccess.file_exists(path):
			_fail("disposable user dir already contains %s" % path)
			return false
	return true


# Placements mirror test/photo_moment_render_suite.gd so every capture comes
# from a live YardWorld through the production rule/PhotoMoment path.
func _capture_all_rules() -> void:
	var index := 0
	for rule: Dictionary in ExpressionCatalog.RULES:
		if not bool(rule.get("polaroid", false)): continue
		seed(5500 + index)
		index += 1
		var world = load("res://scripts/game/yard_world.gd").new()
		root.add_child(world)
		world.setup()
		world.holiday_day = 3
		world._weather_timer = 10000.0
		var player = world.get_player()
		var rule_id: String = rule.id
		match rule_id:
			"llama_fed_gentle":
				world.debug_place_actor("llama", Vector2(365, 560))
				world.debug_place_player(Vector2(300, 562))
				player.pick_grass()
			"llama_overcast_goose_annoyed":
				world.set_weather("overcast")
				world.debug_place_actor("llama", Vector2(705, 505))
				world.debug_place_player(Vector2(660, 520))
			"llama_sun_sheep_happy":
				world.debug_place_actor("llama", Vector2(358, 525))
				world.debug_place_player(Vector2(290, 535))
			"llama_sheep_cow_smirk":
				world.debug_place_actor("llama", Vector2(528, 514))
				world.debug_place_player(Vector2(560, 532))
			"duck_pond_chorus":
				world.debug_place_player(Vector2(830, 530))
			"goose_pond_rest":
				world.debug_place_player(Vector2(755, 522))
				world.actor_named("goose").state = "rest"
				world.actor_named("goose")._idle_time = 8.0
			"goose_duck_shore":
				world.debug_place_actor("duck_a", Vector2(769, 534))
				world.debug_place_player(Vector2(739, 512))
			"sheep_pair_near":
				world.debug_place_actor("sheep_b", world.actor_named("sheep_a").position + Vector2(48, 8))
				world.debug_place_player(Vector2(343, 515))
			"cow_rare_calm":
				world.debug_place_player(Vector2(416, 535))
		if rule_id == "plant_first_bloom": world._plant_state = world.PLANT_BLOOMED
		if rule_id == "fish_first_catch":
			world._fish_state = world.FISH_CAUGHT
			world._fish_catch_type = "small"
		world.tick(1.0 / 60.0, Vector2.ZERO)
		if rule_id == "llama_fed_gentle":
			world.try_interact()
		else:
			if rule_id == "llama_overcast_goose_annoyed":
				world._leading = true
				world._update_lead_rope()
			world.debug_force_rule(rule_id)
		var moment: Dictionary = world.photo_moments.get(rule_id, {})
		var clean := PhotoMoment.sanitize(JSON.parse_string(JSON.stringify(moment)))
		if moment.is_empty() or clean.is_empty() or str(clean.rule_id) != rule_id:
			_fail("%s produced no legal PhotoMoment" % rule_id)
		else:
			_moments[rule_id] = moment
			_rule_ids.append(rule_id)
		world.free()
	if _rule_ids != Array(ExpressionCatalog.all_ids()):
		_fail("captured rules %s differ from ExpressionCatalog.all_ids() %s" % [_rule_ids, ExpressionCatalog.all_ids()])


# Real SaveStore calls in the order the game makes them: each new photo commits
# the whole album (main.gd set_album), so primary=k photos and backup=k-1.
func _natural_progression() -> void:
	var store := root.get_node("SaveStore")
	# Yard ticks during capture may already save; start the progression clean.
	for path: String in [store.SAVE_PATH, store.BACKUP_PATH, store.TEMP_PATH]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	store._data = store._default_data()
	if not store.save(): _fail("empty first save failed")
	_record("natural_00_empty", "natural", store.SAVE_PATH, store.BACKUP_PATH,
		"SaveStore.save() on SaveDataCodec.defaults()", [])
	var collected := PackedStringArray()
	for rule_id: String in _rule_ids:
		collected.append(rule_id)
		if not store.set_album(collected, {rule_id: _moments[rule_id]}):
			_fail("set_album failed at %s" % rule_id)
		_record("natural_%02d_%s" % [collected.size(), rule_id], "natural", store.SAVE_PATH, store.BACKUP_PATH,
			"SaveStore.set_album(first %d catalog rules, real capture of %s)" % [collected.size(), rule_id], Array(collected))
	if not store.set_yard_progress(30, 41.5, 3, 27, 30): _fail("set_yard_progress failed")
	if not store.set_animal_relationship_memory({AnimalRelationships.GOOSE_LLAMA_SHARED_SPACE: true}):
		_fail("set_animal_relationship_memory failed")
	store.set_first_fish_caught()
	store.set_tutorial_completed(true)
	_record("natural_full_steady", "natural", store.SAVE_PATH, store.BACKUP_PATH,
		"full album, then set_yard_progress/relationship/fish/tutorial saves (primary and backup both full)", Array(collected))


func _stress_samples() -> void:
	var base := Codec.defaults()
	_stress_pair("stress_single_at_limit", _sized(base, LIMIT, "a"), {}, "ASCII extension so the primary file is exactly 65536 bytes; no backup")
	_stress_pair("stress_single_over_limit", _sized(base, LIMIT + 1, "a"), {}, "ASCII extension so the primary file is 65537 bytes; no backup")
	_stress_pair("stress_dual_each_under_combined_over", _sized(base, 40000, "a"), _sized(base, 40000, "a"),
		"two 40000-byte files: each under 64KiB, raw sum and combined envelope over")
	_stress_pair("stress_dual_fits", _sized(base, 30000, "a"), _sized(base, 30000, "a"),
		"two 30000-byte ASCII files: combined envelope expected under 64KiB")
	_stress_pair("stress_nonascii_single_chars_under_bytes_over", _sized(base, LIMIT + 2, "假"), {},
		"CJK extension: under 65536 characters but over 65536 UTF-8 bytes")
	_stress_pair("stress_nonascii_dual", _sized(base, 34000, "假"), _sized(base, 34000, "假"),
		"two 34000-byte CJK files: character sum under, UTF-8 byte sum over 65536")
	var future := base.duplicate(true)
	var first: String = _rule_ids[0]
	for i in 2:
		var id := "future_rule_%02d" % i
		var copy: Dictionary = _moments[first].duplicate(true)
		copy.rule_id = id
		future.album.append(id)
		future.photo_moments[id] = copy
	_stress_pair("stress_future_rules_growth", future, future,
		"two unknown future-rule photos (copies of a real capture, renamed); projection discards them")
	var dense := base.duplicate(true)
	var biggest := first
	for id: String in _rule_ids:
		if JSON.stringify(_moments[id]).length() > JSON.stringify(_moments[biggest]).length(): biggest = id
	var moment: Dictionary = _moments[biggest].duplicate(true)
	var source_items: Array = moment.items.duplicate(true)
	while moment.items.size() < PhotoMoment.MAX_ITEMS:
		moment.items.append(source_items[moment.items.size() % source_items.size()].duplicate(true))
	if PhotoMoment.sanitize(JSON.parse_string(JSON.stringify(moment))).is_empty():
		_fail("dense PhotoMoment is not sanitize-legal")
	dense.album = [biggest]
	dense.photo_moments = {biggest: moment}
	_stress_pair("stress_photomoment_dense_single", dense, dense,
		"one sanitize-legal %s photo padded to MAX_ITEMS=64 by repeating its own items; not game-produced" % biggest)


func _sized(base: Dictionary, target: int, unit: String) -> Dictionary:
	var data := base.duplicate(true)
	data[STRESS_KEY] = ""
	var empty := _pretty_bytes(data)
	var unit_bytes := unit.to_utf8_buffer().size()
	var count := (target - empty) / unit_bytes
	data[STRESS_KEY] = unit.repeat(count) + "a".repeat(target - empty - count * unit_bytes)
	if _pretty_bytes(data) != target:
		_fail("cannot size stress payload to %d bytes (got %d)" % [target, _pretty_bytes(data)])
	return data


func _pretty_bytes(data: Dictionary) -> int:
	return JSON.stringify(data, "  ").to_utf8_buffer().size()


func _stress_pair(name: String, primary: Dictionary, backup: Dictionary, source: String) -> void:
	var dir := "user://stress/%s" % name
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var files := SaveFilesType.new()
	var p := dir + "/youjia_save.json"
	var b := dir + "/youjia_save.bak"
	var t := dir + "/youjia_save.tmp"
	if not backup.is_empty() and not files.commit(backup, p, t, b): _fail("%s backup commit failed" % name)
	if not files.commit(primary, p, t, b): _fail("%s primary commit failed" % name)
	var album: Array = primary.get("album", [])
	_record(name, "stress", p, b, source, album)


func _record(name: String, kind: String, primary: String, backup: String, source: String, album: Array) -> void:
	var entry := {"name": name, "kind": kind, "source": source, "album": album, "photo_count": album.size()}
	for role: String in ["primary", "backup"]:
		var path := primary if role == "primary" else backup
		if not FileAccess.file_exists(path):
			entry[role] = {"status": "absent"}
			continue
		var raw := FileAccess.get_file_as_bytes(path)
		var copy := "%s/%s.%s.json" % [_out, name, role]
		var file := FileAccess.open(copy, FileAccess.WRITE)
		file.store_buffer(raw)
		file.close()
		var text := raw.get_string_from_utf8()
		var parsed: Variant = JSON.parse_string(text)
		var info := {"status": "present", "file": copy.get_file(), "bytes": raw.size(),
			"chars": text.length(), "sha256": FileAccess.get_sha256(copy)}
		if parsed is Dictionary:
			var projection := Codec.project(parsed)
			info["projection_compact_bytes"] = JSON.stringify(projection).to_utf8_buffer().size()
			info["projection_pretty_bytes"] = _pretty_bytes(projection)
			info["projection_photo_count"] = (projection.album as Array).size()
			info["projection_moment_count"] = (projection.photo_moments as Dictionary).size()
			info["raw_compact_bytes"] = JSON.stringify(parsed).to_utf8_buffer().size()
		entry[role] = info
	var snapshot: Dictionary = _host_snapshot.call("capture", primary, backup)
	var snapshot_file := "%s/%s.snapshot.json" % [_out, name]
	var file := FileAccess.open(snapshot_file, FileAccess.WRITE)
	file.store_string(JSON.stringify(snapshot))
	file.close()
	entry["host_godot_capture"] = {
		"primary": str(snapshot.primary.status) + ("" if not snapshot.primary.has("reason") else ":" + str(snapshot.primary.reason)),
		"backup": str(snapshot.backup.status) + ("" if not snapshot.backup.has("reason") else ":" + str(snapshot.backup.reason)),
		"file": snapshot_file.get_file(),
	}
	_samples.append(entry)
	print("[save-payload-budget] %s primary=%s backup=%s capture=%s/%s" % [name,
		entry.primary.get("bytes", "absent"), entry.backup.get("bytes", "absent"),
		entry.host_godot_capture.primary, entry.host_godot_capture.backup])


func _fail(message: String) -> void:
	_errors.append(message)
	push_error("[save-payload-budget] " + message)


func _finish() -> void:
	if not _out.is_empty() and DirAccess.dir_exists_absolute(_out):
		var file := FileAccess.open(_out + "/samples.json", FileAccess.WRITE)
		file.store_string(JSON.stringify({"godot": Engine.get_version_info().string, "rules": _rule_ids,
			"samples": _samples, "errors": _errors}, "  "))
		file.close()
	print("[save-payload-budget] generator %s: %d samples, %d errors" % ["OK" if _errors.is_empty() else "FAIL", _samples.size(), _errors.size()])
	quit(0 if _errors.is_empty() else 1)
