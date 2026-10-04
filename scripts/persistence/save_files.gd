extends RefCounted
## File-level recovery only. A successful Web write is to Godot's user:// FS;
## browser durable acknowledgement remains a separate host protocol.

func read_record(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	var error := file.get_error()
	file.close()
	if error != OK and error != ERR_FILE_EOF:
		return {}
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return {}
	var parsed: Variant = parser.data
	if not parsed is Dictionary:
		return {}
	return {"data": parsed, "text": text}


func recover(primary: String, backup: String) -> Dictionary:
	var record := read_record(primary)
	if not record.is_empty():
		return record
	# A temporary file has not reached the commit point. Never promote it on load.
	return read_record(backup)


func commit(data: Dictionary, primary: String, temporary: String, backup: String) -> bool:
	var text := JSON.stringify(data, "  ")
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return false
	var candidate := read_record(temporary)
	if candidate.is_empty() or candidate.text != text:
		return false

	var previous := read_record(primary)
	if not previous.is_empty():
		# Only replace a backup while a complete primary still exists. If either
		# operation fails, the primary remains the last known good copy.
		if FileAccess.file_exists(backup) and _remove(backup) != OK:
			return false
		if _rename(primary, backup) != OK:
			return false
	elif FileAccess.file_exists(primary):
		# Invalid primary must not overwrite the only valid recovery copy.
		if _remove(primary) != OK:
			return false

	# There is deliberately no deletion of the good backup after this point.
	# A failure/interruption here loads that backup next time.
	if _rename(temporary, primary) != OK:
		return false
	var committed := read_record(primary)
	return not committed.is_empty() and committed.text == text


func _rename(from: String, to: String) -> Error:
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(from), ProjectSettings.globalize_path(to))


func _remove(path: String) -> Error:
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
