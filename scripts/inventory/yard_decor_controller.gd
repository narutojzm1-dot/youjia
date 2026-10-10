extends RefCounted
signal changed
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
	return store.get_yard_decor()

func busy() -> bool:
	return not pending.is_empty()

func request(action: String, spot: String, details: Dictionary = {}) -> bool:
	if busy() or view().is_empty(): return false
	pending = {"revision": int(view().revision), "action": action, "spot": spot, "details": details.duplicate(true)}
	_failed.clear()
	return _submit()

func _submit() -> bool:
	state = "saving"
	error = ""
	_op_id = store.request_decor_action(pending.revision, pending.action, pending.spot, pending.details)
	if _op_id.is_empty():
		state = "failed"
		error = "SAVE_UNAVAILABLE"
	elif not _failed.is_empty(): resubmitted.emit(_failed.duplicate(), _op_id)
	changed.emit()
	return not _op_id.is_empty()

func retry() -> bool:
	if state == "unknown": return store.retry_pending()
	if state != "failed" or pending.is_empty(): return false
	return _submit()

func _confirmed(op_id: String, _kind: String) -> void:
	if op_id == _op_id:
		pending.clear()
		_failed.clear()
		_op_id = ""
		state = "idle"
		error = ""
	changed.emit()

func _rejected(op_id: String, _kind: String, code: String) -> void:
	if op_id != _op_id: return
	error = code
	_failed.append(op_id)
	if code.begins_with("DECOR_"):
		# A semantic rejection never reached storage. The player may choose
		# another spot/item against the latest confirmed revision.
		state = "blocked"
		pending.clear()
		_failed.clear()
		_op_id = ""
	else:
		state = "failed"
	changed.emit()

func _unknown(op_id: String, _kind: String, code: String) -> void:
	if op_id != _op_id: return
	error = code
	state = "unknown"
	changed.emit()
