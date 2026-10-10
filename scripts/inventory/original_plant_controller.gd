extends RefCounted
## Confirmed-only view for the future garden interaction; no eager art changes.
signal changed
signal completed(action: String, area: String)
var store: Object
var state := "idle"
var error := ""
var pending: Dictionary = {}
var operation := ""

func _init(save_store: Object) -> void:
	store = save_store
	store.commit_confirmed.connect(_confirmed)
	store.commit_rejected.connect(_rejected)
	store.commit_unknown.connect(_unknown)

func dispose() -> void:
	store.commit_confirmed.disconnect(_confirmed)
	store.commit_rejected.disconnect(_rejected)
	store.commit_unknown.disconnect(_unknown)

func view() -> Dictionary:
	return store.get_yard_original_plants()

func busy() -> bool:
	return not pending.is_empty()

func request(action: String, area: String) -> bool:
	if busy() or view().is_empty(): return false
	pending = {"revision": int(view().revision), "action": action, "area": area}
	return _submit()

func _submit() -> bool:
	state = "saving"
	error = ""
	operation = store.request_original_plant_action(pending.revision, pending.action, pending.area)
	if operation.is_empty():
		state = "failed"
		error = "SAVE_UNAVAILABLE"
	changed.emit()
	return not operation.is_empty()

func retry() -> bool:
	if state == "unknown": return store.retry_pending()
	if state != "failed" or pending.is_empty(): return false
	return _submit()

func _confirmed(id: String, _kind: String) -> void:
	if id == operation and not pending.is_empty():
		var finished := pending.duplicate()
		pending.clear()
		operation = ""
		state = "idle"
		error = ""
		completed.emit(finished.action, finished.area)
	changed.emit()

func _rejected(id: String, _kind: String, code: String) -> void:
	if id != operation: return
	error = code
	if code.begins_with("GARDEN_"):
		pending.clear()
		operation = ""
		state = "blocked"
	else:
		state = "failed"
	changed.emit()

func _unknown(id: String, _kind: String, code: String) -> void:
	if id != operation: return
	state = "unknown"
	error = code
	changed.emit()
