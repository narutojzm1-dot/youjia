extends RefCounted
## Read-only migration source candidate. Caller must stop ALL legacy writers
## before calling and hold that ownership through target durable readback.
## This is NOT a lock, UTF-8/JSON validation, or a production migration entry.

const MAX_BYTES := 65536 # Isolated fixture budget, not the production save limit.

func read_source(path: String) -> Dictionary:
	var parent := DirAccess.open(path.get_base_dir())
	if parent == null:
		return {"status": "read_error", "reason": "parent_unreadable"}
	var leaf := path.get_file()
	if leaf.is_empty() or parent.dir_exists(leaf):
		return {"status": "read_error", "reason": "not_regular_file"}
	if not parent.file_exists(leaf):
		return {"status": "absent"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"status": "read_error", "reason": "open_failed"}
	var length := file.get_length()
	if length > MAX_BYTES:
		file.close()
		return {"status": "read_error", "reason": "too_large"}
	var raw := file.get_buffer(length)
	var error := file.get_error()
	var end_length := file.get_length()
	file.close()
	if raw.size() != length or end_length != length or (error != OK and error != ERR_FILE_EOF):
		return {"status": "read_error", "reason": "incomplete_read"}
	# Preserve bytes before ANY decoding or sanitization, including malformed UTF-8.
	# Base64 is transport encoding; it is not evidence that the file is valid v5.
	return {"status": "present", "base64": ("" if raw.is_empty() else Marshalls.raw_to_base64(raw))}

func capture(primary: String, backup: String) -> Dictionary:
	# Never call recover(): it discards the failed source and collapses read errors.
	return {"primary": read_source(primary), "backup": read_source(backup)}
