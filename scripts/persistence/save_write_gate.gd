extends RefCounted
## Candidate H1 primitive. No disk, browser, inventory or game integration.
## Backend must establish durable outcome; this class cannot establish it.
var _working: Dictionary
var _confirmed: Dictionary
var _revision: int = 0
var _confirmed_revision: int = 0
var _next_id: int = 1
var _flight: Dictionary = {}
var _unknown: bool = false

func _init(initial: Dictionary = {}) -> void:
	_working = initial.duplicate(true)
	_confirmed = initial.duplicate(true)

func replace_working(value: Dictionary) -> void:
	_working = value.duplicate(true)
	_revision += 1

func working() -> Dictionary:
	return _working.duplicate(true)

func confirmed() -> Dictionary:
	return _confirmed.duplicate(true)

func dirty() -> bool:
	return _revision != _confirmed_revision

func begin_write(candidate_token: String, parent_token: String) -> Dictionary:
	if candidate_token.is_empty() or parent_token.is_empty() or candidate_token == parent_token:
		return {}
	if not _flight.is_empty() or not dirty():
		return {}
	_flight = {"write_id": _next_id, "revision": _revision, "payload": _working.duplicate(true), "candidate_token": candidate_token, "parent_token": parent_token}
	_next_id += 1
	_unknown = false
	return _flight.duplicate(true)

func mark_unknown(write_id: int) -> bool:
	if not _matches(write_id):
		return false
	_unknown = true
	return true

func finish(write_id: int, succeeded: bool) -> bool:
	# An ordinary callback must not accidentally resolve an uncertain operation.
	if _unknown or not _matches(write_id):
		return false
	_complete(succeeded)
	return true

func resolve_verified(receipt: Dictionary) -> bool:
	# Tokens are stable envelope identities supplied by the trusted adapter.
	# This comparison rejects mismatched receipts; it cannot prove I/O quiescence.
	if not _unknown or not receipt.get("write_id") is int:
		return false
	if not _matches(receipt.write_id):
		return false
	if receipt.get("candidate_token") != _flight.candidate_token or receipt.get("parent_token") != _flight.parent_token:
		return false
	var observed: Variant = receipt.get("observed_token")
	if observed == _flight.candidate_token:
		_complete(true)
		return true
	if observed == _flight.parent_token and receipt.get("old_write_terminated") is bool and receipt.old_write_terminated:
		_complete(false)
		return true
	return false

func blocked() -> bool:
	return not _flight.is_empty()

func uncertain() -> bool:
	return _unknown

func _matches(write_id: int) -> bool:
	return not _flight.is_empty() and int(_flight.write_id) == write_id

func _complete(succeeded: bool) -> void:
	if succeeded:
		_confirmed = _flight.payload.duplicate(true)
		_confirmed_revision = int(_flight.revision)
	# Never replace working with the older candidate.
	_flight = {}
	_unknown = false
