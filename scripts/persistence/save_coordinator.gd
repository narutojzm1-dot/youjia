class_name SaveCoordinator
extends RefCounted
## One authoritative snapshot; queued callables derive their candidate only at
## the FIFO head. Acceptance is never durability. No backend or UI autoload here.

signal confirmed(op_id: String, snapshot: Dictionary, token: String)
signal rejected(op_id: String, reason: String)
signal unknown(op_id: String, reason: String)
signal ack_failed(op_id: String, reason: String)
signal state_changed(state: String)
signal ignored_receipt(reason: String)

## Typed local refusal. Never serialized, prepared, or sent to the backend.
class IntentRejection extends RefCounted:
	const CODES := ["EXPLORATION_CLEANUP_INVALID_ARGUMENT", "EXPLORATION_CLEANUP_PRECONDITION_CHANGED", "BASKET_INVALID", "BASKET_CHANGED", "BASKET_LIMIT", "BASKET_EMPTY", "BASKET_HAND_OCCUPIED"]
	var code: String
	func _init(reason: String) -> void:
		code = reason if reason in CODES else "INVALID_LOCAL_INTENT"


const WEB_NAMESPACE := "youjia-save-host-v1"
var _namespace := WEB_NAMESPACE
var _store_id := ""
var _generation := ""
const IDENTITY_KEYS := ["namespace", "store_id", "write_id", "request_id", "candidate_token", "parent_token", "payload_sha256", "generation"]

var _state := "initializing"
var _backend: Object
var _confirmed: Dictionary = {}
var _token := ""
var _sequence := 0
var _queue: Array[Dictionary] = []
var _active: Dictionary = {}
var _call_id := ""
var _method := ""
var _starting := false
var _early_replies: Array = []
var _pump_scheduled := false


## Caller supplies the snapshot/token from a verified open/initialize result.
## No reset API: replacing this object while a write is unresolved is forbidden.
func initialize(backend: Object, trusted_snapshot: Dictionary, trusted_token: String, expected_namespace: String = WEB_NAMESPACE) -> bool:
	if _state != "initializing" or backend == null or not backend.has_method("request") or not backend.has_signal("completed"):
		return false
	if trusted_token.is_empty() or trusted_snapshot.get("version") != 5 or expected_namespace not in [WEB_NAMESPACE, "youjia-native-file-v1"]:
		return false
	_namespace = expected_namespace
	_backend = backend
	_backend.connect("completed", _on_completed)
	_confirmed = trusted_snapshot.duplicate(true)
	_token = trusted_token
	_set_state("ready")
	return true


func get_confirmed_snapshot() -> Dictionary:
	return _confirmed.duplicate(true)


func get_confirmed() -> Dictionary:
	return get_confirmed_snapshot()


func get_confirmed_token() -> String:
	return _token


func get_state() -> String:
	return _state


## Ready can occur between queued operations; transitions must wait for all work.
func is_idle() -> bool:
	return _state == "ready" and _active.is_empty() and _queue.is_empty()


## Teardown is legal only after every accepted write and acknowledgement drained.
func close_when_idle() -> bool:
	if not is_idle():
		return false
	if is_instance_valid(_backend) and _backend.is_connected("completed", _on_completed):
		_backend.disconnect("completed", _on_completed)
	_backend = null
	_set_state("closed")
	return true


func enqueue(intent: Callable) -> String:
	if _state not in ["ready", "writing", "acknowledging"] or not intent.is_valid() or _sequence == 9223372036854775807:
		return ""
	_sequence += 1
	var op_id := str(_sequence)
	_queue.append({"op_id": op_id, "intent": intent})
	_schedule_pump()
	return op_id


func retry_resolve() -> bool:
	if _state == "blocked" and _active.get("durable", false):
		return retry_ack()
	if _state != "unknown" or _active.get("prepared", {}).is_empty():
		return false
	_set_state("resolving")
	_request("resolve", _write_args(), _active.prepared)
	return true


func retry_ack() -> bool:
	if _state != "blocked" or not _active.get("durable", false):
		return false
	_set_state("acknowledging")
	_request("acknowledge", _write_args(), _active.prepared)
	return true


func _schedule_pump() -> void:
	if not _pump_scheduled:
		_pump_scheduled = true
		call_deferred("_pump")


func _pump() -> void:
	_pump_scheduled = false
	if _state != "ready" or not _active.is_empty() or _queue.is_empty():
		return
	_active = _queue.pop_front()
	_set_state("writing")
	# Deep copy protects confirmed even from a mutating intent that returns bad data.
	if not _active.intent.is_valid():
		_finish_rejected("INVALID_LOCAL_INTENT")
		return
	var candidate: Variant = _active.intent.call(_confirmed.duplicate(true))
	if candidate is IntentRejection:
		_finish_rejected(candidate.code if candidate.code in IntentRejection.CODES else "INVALID_LOCAL_INTENT")
		return
	if not candidate is Dictionary or candidate.get("version") != 5:
		_finish_rejected("INVALID_LOCAL_CANDIDATE")
		return
	_active.candidate = candidate.duplicate(true)
	_active.payload = JSON.stringify(_active.candidate)
	_active.parent_token = _token
	_active.durable = false
	_request("prepare", {"payload": _active.payload, "parent_token": _token, "write_id": _active.op_id})


func _write_args() -> Dictionary:
	return {"request_id": _active.prepared.request_id, "write_id": _active.op_id}


func _request(method: String, args: Dictionary, expected: Dictionary = {}) -> void:
	_method = method
	_call_id = ""
	_starting = true
	_early_replies.clear()
	var returned: Variant = _backend.request(method, args.duplicate(true), expected.duplicate(true))
	_starting = false
	if not returned is String or returned.is_empty():
		_early_replies.clear()
		_request_failure("REQUEST_NOT_STARTED")
		return
	_call_id = returned
	# Native adapters may emit before returning their ID. Process their result
	# only after it is known, never losing a synchronous completion.
	var replies := _early_replies.duplicate(true)
	_early_replies.clear()
	for item in replies:
		_on_completed(item[0], item[1], item[2])


func _on_completed(request_id: String, method: String, reply: Dictionary) -> void:
	if _starting:
		_early_replies.append([request_id, method, reply.duplicate(true)])
		return
	if _call_id.is_empty() or request_id != _call_id or method != _method:
		ignored_receipt.emit("STALE_OR_MISMATCHED_CALL")
		return
	_call_id = ""
	var status: String = str(reply.get("status", ""))
	var code: String = str(reply.get("code", "INVALID_REPLY"))
	var wire: Variant = reply.get("wire")
	if method == "prepare":
		if status != "prepared" or not wire is Dictionary or not _valid_prepared(wire):
			_request_failure(code)
			return
		_store_id = wire.store_id
		_active.prepared = wire.duplicate(true)
		_request("submit", _write_args(), _active.prepared)
	elif method in ["submit", "resolve"]:
		if status not in ["confirmed", "rejected"] or not wire is Dictionary or not _valid_receipt(wire, status, method):
			_request_failure(code)
			return
		if status == "rejected":
			_finish_rejected("RESOLVED_PARENT")
			return
		_confirmed = _active.candidate.duplicate(true)
		_token = _active.prepared.candidate_token
		_generation = _active.prepared.generation
		_active.durable = true
		_set_state("acknowledging")
		confirmed.emit(_active.op_id, _confirmed.duplicate(true), _token)
		_request("acknowledge", _write_args(), _active.prepared)
	elif method == "acknowledge":
		if status != "acknowledged" or not wire is Dictionary or not _valid_ack(wire):
			_request_failure(code)
			return
		_active.clear()
		_set_state("ready")
		_schedule_pump()


func _valid_prepared(wire: Dictionary) -> bool:
	if wire.get("schema") != "youjia.save-prepared/v1" or wire.get("namespace") != _namespace:
		return false
	for key in IDENTITY_KEYS:
		if not wire.get(key) is String or wire[key].is_empty():
			return false
	if not _store_id.is_empty() and wire.store_id != _store_id:
		return false
	var generation: String = wire.generation
	if not generation.is_valid_int() or str(generation.to_int()) != generation or generation.to_int() <= 0:
		return false
	if not _generation.is_empty() and (_generation.to_int() == 9223372036854775807 or generation.to_int() != _generation.to_int() + 1):
		return false
	return wire.write_id == _active.op_id and wire.parent_token == _active.parent_token \
		and (_namespace == "youjia-native-file-v1" or wire.candidate_token != wire.parent_token) and wire.payload_sha256 == str(_active.payload).sha256_text()


func _valid_receipt(wire: Dictionary, status: String, method: String) -> bool:
	if wire.get("schema") != "youjia.save-receipt/v2" or wire.get("outcome") != status:
		return false
	for key in IDENTITY_KEYS:
		if wire.get(key) != _active.prepared[key]:
			return false
	if not wire.get("readback_verified") is bool or not wire.get("old_write_terminated") is bool or wire.readback_verified != true or wire.old_write_terminated != true:
		return false
	if status == "confirmed":
		return wire.get("observed_token") == _active.prepared.candidate_token and wire.get("transaction_state") == "complete"
	# A submit error is never a rejection: only recovery can prove the old write
	# terminated with the trusted parent current and no surviving intent.
	return method == "resolve" and wire.get("observed_token") == _active.prepared.parent_token and wire.get("transaction_state") == "terminated"


func _valid_ack(wire: Dictionary) -> bool:
	return wire.get("schema") == "youjia.save-ack/v1" and wire.get("namespace") == _namespace \
		and wire.get("request_id") == _active.prepared.request_id and wire.get("write_id") == _active.op_id \
		and wire.get("status") in ["cleared", "already_clear"]


func _request_failure(reason: String) -> void:
	if _method == "acknowledge":
		_set_state("blocked")
		ack_failed.emit(_active.op_id, reason)
	elif _method == "prepare":
		_set_state("blocked")
		unknown.emit(_active.op_id, reason)
	else:
		_set_state("unknown")
		unknown.emit(_active.op_id, reason)


func _finish_rejected(reason: String) -> void:
	var id: String = _active.op_id
	_active.clear()
	_set_state("ready")
	rejected.emit(id, reason)
	_schedule_pump()


func _set_state(value: String) -> void:
	_state = value
	state_changed.emit(value)
