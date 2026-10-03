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

func begin_write() -> Dictionary:
	if not _flight.is_empty() or not dirty():
		return {}
	_flight = {"write_id": _next_id, "revision": _revision, "payload": _working.duplicate(true)}
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

func resolve_verified(write_id: int, succeeded: bool) -> bool:
	# Trusted adapter only: candidate match, or proven terminated + parent match.
	# No timeout, watermark or memory-file heuristic is implemented here.
	if not _unknown or not _matches(write_id):
		return false
	_complete(succeeded)
	return true

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
