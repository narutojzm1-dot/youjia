extends RefCounted
## A request is not an acquisition. Only the store's confirmed view is usable.
signal changed
signal settled(action: String)
signal resubmitted(failed_ops: Array, op_id: String)
const Model := preload("res://scripts/game/world_residents.gd")
var store: Object
var state := "idle"
var pending: Dictionary = {}
var _op_id := ""
var _failed: Array = []
var _yard_started := false

func _init(save_store: Object) -> void:
	store = save_store
	store.commit_confirmed.connect(_confirmed)
	store.commit_rejected.connect(_rejected)
	store.commit_unknown.connect(_unknown)

func view() -> Dictionary:
	return store.get_world_residents()

func busy() -> bool:
	return not pending.is_empty()

func request(action: String) -> bool:
	if busy() or view().is_empty(): return false
	var revision := int(view().revision)
	var intent: Callable = store.prepare_resident_intent(revision, action)
	if not intent.is_valid(): return false
	pending = {"revision": revision, "action": action, "intent": intent}
	_failed.clear()
	return _submit()

func _submit() -> bool:
	state = "saving"
	_op_id = store.request_intent("residents", pending.intent)
	if _op_id.is_empty(): state = "failed"
	elif not _failed.is_empty(): resubmitted.emit(_failed.duplicate(), _op_id)
	changed.emit()
	return not _op_id.is_empty()

func retry() -> bool:
	if state == "unknown": return store.retry_pending()
	if state != "failed" or pending.is_empty(): return false
	return _submit()

func _confirmed(op_id: String, _kind: String) -> void:
	if op_id == _op_id:
		var action: String = pending.action
		pending.clear()
		_failed.clear()
		_op_id = ""
		state = "idle"
		settled.emit(action)
	changed.emit()
	_check_growth.call_deferred()

func _check_growth() -> void:
	if busy(): return
	var value := view()
	if value.is_empty(): return
	if _yard_started and value.chicken.stage == "unmet":
		request("settle_chick")
		return
	var now := {"day": store.get_holiday_day(), "elapsed": store.get_holiday_day_elapsed()}
	if value.beibei.stage == "puppy" and Model._clock_seconds(now) - Model._clock_seconds(value.beibei.adopted_clock) >= Model.GROW_SECONDS:
		request("grow_beibei")
	elif value.chicken.stage == "chick" and Model._clock_seconds(now) - Model._clock_seconds(value.chicken.settled_clock) >= Model.GROW_SECONDS:
		request("grow_chicken")

func start_yard_residents() -> void:
	_yard_started = true
	_check_growth()

func _rejected(op_id: String, _kind: String, _code: String) -> void:
	if op_id != _op_id: return
	_failed.append(op_id)
	state = "failed"
	changed.emit()

func _unknown(op_id: String, _kind: String, _code: String) -> void:
	if op_id != _op_id: return
	state = "unknown"
	changed.emit()
