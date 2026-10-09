extends RefCounted
## The production SaveStore remains the only source of usable inventory.
signal changed
signal settled(action: String, fish: String)
signal resubmitted(failed_ops: Array, op_id: String)

var store: Object
var state := "idle"
var error := ""
var pending: Dictionary = {}
var _op_id := ""
var _failed: Array = []


func _init(save_store: Object) -> void:
	store = save_store
	store.commit_confirmed.connect(_confirmed)
	store.commit_rejected.connect(_rejected)
	store.commit_unknown.connect(_unknown)


func view() -> Dictionary:
	return store.get_yard_inventory()


func busy() -> bool:
	return not pending.is_empty()


func request(action: String, fish: String, details: Dictionary = {}) -> bool:
	if busy(): return false
	var inventory := view()
	if inventory.is_empty():
		state = "blocked"
		error = "BASKET_INVALID"
		changed.emit()
		return false
	pending = {"revision": int(inventory.revision), "action": action, "fish": fish, "details": details.duplicate(true)}
	_failed.clear()
	return _submit()


func _submit() -> bool:
	state = "saving"
	error = ""
	_op_id = store.request_inventory_action(pending.revision, pending.action, pending.fish, pending.details)
	if _op_id.is_empty():
		state = "failed"
		error = "SAVE_UNAVAILABLE"
	elif not _failed.is_empty():
		resubmitted.emit(_failed.duplicate(), _op_id)
	changed.emit()
	return not _op_id.is_empty()


func retry() -> bool:
	if state == "unknown": return store.retry_pending()
	if state != "failed" or pending.is_empty(): return false
	return _submit()


func _confirmed(op_id: String, _kind: String) -> void:
	if op_id != _op_id:
		changed.emit() # Includes freshly returned exploration keepsakes.
		return
	var completed := pending.duplicate()
	pending.clear()
	_failed.clear()
	_op_id = ""
	state = "idle"
	error = ""
	changed.emit()
	settled.emit(completed.action, completed.fish)


func _rejected(op_id: String, _kind: String, code: String) -> void:
	if op_id != _op_id: return
	if code == "BASKET_SEED_RESERVED":
		pending.clear()
		_op_id = ""
		state = "idle"
		error = code
		changed.emit()
		return
	_failed.append(op_id)
	state = "blocked" if code.begins_with("BASKET_") else "failed"
	error = code
	changed.emit()


func _unknown(op_id: String, _kind: String, code: String) -> void:
	if op_id != _op_id: return
	state = "unknown"
	error = code
	changed.emit()
