extends RefCounted
signal completed(call_id: String, method: String, reply: Dictionary)
const Files = preload("res://scripts/persistence/save_files.gd")
const Codec = preload("res://scripts/persistence/save_data_codec.gd")
const SOURCE_KEY := "_youjia_native_legacy_sha256"
const NAMESPACE := "youjia-native-file-v1"
var _files: RefCounted
var _primary: String
var _temporary: String
var _backup: String
var _store_id: String
var _token := ""
var _snapshot: Dictionary = {}
var _raw := ""
var _seal_hash := ""
var _generation := 0
var _calls := 0
var _state := "blocked"
var _active: Dictionary = {}

func _init(primary: String = "user://youjia_save.json", temporary: String = "user://youjia_save.tmp", backup: String = "user://youjia_save.bak", files: RefCounted = null) -> void:
	_primary = primary
	_temporary = temporary
	_backup = backup
	_files = files if files != null else Files.new()
	_store_id = Crypto.new().generate_random_bytes(16).hex_encode()
	var initial := _read()
	if initial.get("writable", false) and (FileAccess.file_exists(_primary) or FileAccess.file_exists(_backup)):
		if not _ensure_sources():
			initial.writable = false
		else:
			initial = _read()
	if initial.get("trusted", false):
		_token = initial.token
		_snapshot = initial.data.duplicate(true)
		_raw = initial.raw
		_state = "ready" if initial.writable else "blocked"

func get_initial_snapshot() -> Dictionary:
	return _snapshot.duplicate(true)
func get_initial_token() -> String:
	return _token
func get_state() -> String:
	return _state
func request(method: String, args: Dictionary, expected: Dictionary = {}) -> String:
	_calls += 1
	var id := str(_calls)
	call_deferred("_dispatch", id, method, args.duplicate(true), expected.duplicate(true))
	return id
func _error(code: String) -> Dictionary:
	return {"status":"unknown", "code":code, "wire":{}}
func _read() -> Dictionary:
	var unsafe := false
	for path: String in [_primary, _backup]:
		var record: Dictionary = _files.read_record(path)
		if FileAccess.file_exists(path) and (record.is_empty() or not _supported(record.data.get("version")) or str(record.text).to_utf8_buffer() != FileAccess.get_file_as_bytes(path)):
			unsafe = true
	var recovered: Dictionary = _files.recover(_primary, _backup)
	if not recovered.is_empty() and _supported(recovered.data.get("version")):
		var projected: Dictionary = recovered.data.duplicate(true)
		projected.merge(Codec.project(recovered.data), true)
		var seal := _load_seal()
		if recovered.data.has(SOURCE_KEY):
			unsafe = unsafe or seal.is_empty() or recovered.data[SOURCE_KEY] != seal.get("sha256")
		elif not seal.is_empty():
			unsafe = unsafe or seal.sources != _source_pair()
		if FileAccess.file_exists(_primary + ".legacy-sources.json") and seal.is_empty():
			unsafe = true
		return {"trusted":true,"writable":not unsafe,"token":str(recovered.text).sha256_text(),"data":projected,"raw":str(recovered.text)}
	if not FileAccess.file_exists(_primary) and not FileAccess.file_exists(_backup):
		return {"trusted":true,"writable":true,"token":"youjia-native-file-v1:both-sources-absent".sha256_text(),"data":Codec.defaults(),"raw":JSON.stringify(Codec.defaults())}
	return {"trusted":false,"writable":false}
func _dispatch(id: String, method: String, args: Dictionary, expected: Dictionary) -> void:
	var reply := _error("INVALID_REQUEST")
	if method == "open":
		var status := "ready" if _state == "ready" else "blocked"
		var wire := {"schema":"youjia.host-open/v1","status":status,"code":"" if status == "ready" else "NATIVE_SOURCE_BLOCKED","current_payload":_raw,"current_token":_token,"current_envelope":null}
		reply = {"status":status,"code":wire.code,"wire":wire}
	elif method == "prepare":
		reply = _prepare(args)
	elif method in ["submit", "resolve", "acknowledge"]:
		if not _active.is_empty() and args.get("request_id") == _active.wire.request_id and args.get("write_id") == _active.wire.write_id and expected == _active.wire:
			if method == "submit": reply = _submit()
			elif method == "resolve": reply = _resolve()
			else: reply = _ack()
	completed.emit(id, method, reply)
func _prepare(args: Dictionary) -> Dictionary:
	if _state != "ready" or not _active.is_empty() or _generation == 9223372036854775807:
		return _error("NOT_READY")
	var read := _read()
	if not read.get("trusted", false) or not read.get("writable", false) or read.token != _token or args.get("parent_token") != _token:
		_state = "blocked"
		return _error("PARENT_CHANGED")
	if not args.get("payload") is String or not args.get("write_id") is String or not str(args.write_id).is_valid_int() or str(args.write_id).to_int() <= 0 or str(str(args.write_id).to_int()) != args.write_id:
		return _error("INVALID_PREPARE")
	var data: Variant = JSON.parse_string(args.payload)
	if not data is Dictionary or data.get("version") != 5:
		return _error("INVALID_PAYLOAD")
	if not _seal_hash.is_empty():
		data[SOURCE_KEY] = _seal_hash
	var wire := {"schema":"youjia.save-prepared/v1","namespace":NAMESPACE,"store_id":_store_id,"write_id":args.write_id,"request_id":Crypto.new().generate_random_bytes(16).hex_encode(),"candidate_token":JSON.stringify(data, "  ").sha256_text(),"parent_token":_token,"payload_sha256":str(args.payload).sha256_text(),"generation":str(_generation + 1)}
	_active = {"wire":wire,"data":data.duplicate(true),"started":false,"confirmed":false}
	_state = "prepared"
	return {"status":"prepared","code":"","wire":wire.duplicate(true)}
func _submit() -> Dictionary:
	if _active.started or _state != "prepared": return _error("ALREADY_SUBMITTED")
	_active.started = true
	_state = "unknown"
	var before := _read()
	if not before.get("trusted",false) or not before.get("writable",false) or before.token != _active.wire.parent_token: return _error("PARENT_CHANGED")
	var committed: bool = _files.commit(_active.data, _primary, _temporary, _backup)
	var after := _read()
	if not committed or not after.get("trusted",false) or not after.get("writable",false) or after.token != _active.wire.candidate_token: return _error("COMMIT_UNCERTAIN")
	return _confirm(after)
func _confirm(read: Dictionary) -> Dictionary:
	_token = read.token
	_snapshot = _active.data.duplicate(true)
	_raw = read.raw
	_generation = str(_active.wire.generation).to_int()
	_active.confirmed = true
	_state = "confirmed"
	return _receipt("confirmed", _token, "complete")
func _resolve() -> Dictionary:
	if not _active.started: return _error("NOT_SUBMITTED")
	var read := _read()
	if not read.get("trusted",false) or not read.get("writable",false): return _error("RECOVERY_BLOCKED")
	if read.token == _active.wire.candidate_token: return _confirm(read)
	if read.token == _active.wire.parent_token and not _active.confirmed:
		var reply := _receipt("rejected", read.token, "terminated")
		_active.clear()
		_state = "ready"
		return reply
	return _error("UNRELATED_CURRENT")
func _receipt(status: String, observed: String, transaction: String) -> Dictionary:
	var wire: Dictionary = _active.wire.duplicate(true)
	wire.schema = "youjia.save-receipt/v2"
	wire.merge({"outcome":status,"observed_token":observed,"transaction_state":transaction,"readback_verified":true,"old_write_terminated":true})
	return {"status":status,"code":"","wire":wire}
func _ack() -> Dictionary:
	if not _active.confirmed: return _error("NOT_CONFIRMED")
	var read := _read()
	if not read.get("trusted",false) or not read.get("writable",false) or read.token != _active.wire.candidate_token:
		_state = "blocked"
		return _error("ACK_CURRENT_CHANGED")
	var wire := {"schema":"youjia.save-ack/v1","namespace":NAMESPACE,"request_id":_active.wire.request_id,"write_id":_active.wire.write_id,"status":"cleared"}
	_active.clear()
	_state = "ready"
	return {"status":"acknowledged","code":"","wire":wire}


func _supported(version: Variant) -> bool:
	return (version is int or version is float) and is_finite(float(version)) and float(version) == floor(float(version)) and float(version) >= 1.0 and float(version) <= 5.0

func _source_pair() -> Dictionary:
	var pair := {}
	for label: String in ["primary", "backup"]:
		var path := _primary if label == "primary" else _backup
		if not FileAccess.file_exists(path):
			pair[label] = {"status":"absent"}
			continue
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null: return {}
		var bytes := f.get_buffer(f.get_length())
		var err := f.get_error()
		f.close()
		if err not in [OK, ERR_FILE_EOF]: return {}
		pair[label] = {"status":"present", "base64":Marshalls.raw_to_base64(bytes)}
	return pair

func _load_seal() -> Dictionary:
	var record: Dictionary = _files.read_record(_primary + ".legacy-sources.json")
	if record.is_empty(): return {}
	var seal: Dictionary = record.data
	if seal.size() != 3 or seal.get("schema") != "youjia.native-legacy-sources/v1" or not seal.get("sources") is Dictionary or not seal.get("sha256") is String: return {}
	if seal.sources.size() != 2 or not seal.sources.has("primary") or not seal.sources.has("backup"): return {}
	for label: String in ["primary", "backup"]:
		var source: Variant = seal.sources[label]
		if not source is Dictionary: return {}
		if source.get("status") == "absent" and source.size() == 1: continue
		if source.get("status") != "present" or source.size() != 2 or not source.get("base64") is String: return {}
		if Marshalls.raw_to_base64(Marshalls.base64_to_raw(source.base64)) != source.base64: return {}
	if JSON.stringify(seal.sources).sha256_text() != seal.sha256: return {}
	return seal

func _ensure_sources() -> bool:
	var path := _primary + ".legacy-sources.json"
	if FileAccess.file_exists(path):
		var existing := _load_seal()
		if existing.is_empty(): return false
		_seal_hash = existing.sha256
		return true
	# A linked file without its evidence must never manufacture replacement evidence.
	for source_path: String in [_primary, _backup]:
		var source: Dictionary = _files.read_record(source_path)
		if not source.is_empty() and source.data.has(SOURCE_KEY): return false
	var pair := _source_pair()
	if pair.is_empty(): return false
	var seal := {"schema":"youjia.native-legacy-sources/v1", "sources":pair, "sha256":JSON.stringify(pair).sha256_text()}
	var text := JSON.stringify(seal)
	var temp := path + ".tmp"
	var f := FileAccess.open(temp, FileAccess.WRITE)
	if f == null: return false
	f.store_string(text)
	f.flush()
	var err := f.get_error()
	f.close()
	if err != OK or FileAccess.get_file_as_string(temp) != text: return false
	if FileAccess.file_exists(path): return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(path)) != OK: return false
	var saved := _load_seal()
	if saved.is_empty() or saved.sources != pair: return false
	_seal_hash = saved.sha256
	return true
