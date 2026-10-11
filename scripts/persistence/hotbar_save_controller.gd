extends Node
## Coalesces UI choices while the shared writer confirms earlier choices.
## An uncertain write retains its identity; failure never becomes a new ledger.
signal view_changed(slots: Array)
const Slots := preload("res://scripts/persistence/hotbar_slots.gd")
var store: Node
var desired: Array = []
var active := ""
var state := "ready"

func initialize(source: Node, legacy: Array = []) -> void:
	store = source
	store.commit_confirmed.connect(_confirmed)
	store.commit_rejected.connect(_rejected)
	desired = store.get_hotbar_slots()
	if not store.has_hotbar_slots() and Slots.clean(legacy) != Slots.clean([]):
		desired = Slots.clean(legacy)
		_submit()
	view_changed.emit(desired.duplicate())

func change(slots: Array) -> void:
	desired = Slots.clean(slots)
	if active.is_empty() and state == "ready": _submit()

func retry() -> String:
	if not active.is_empty() or state != "failed": return ""
	_submit()
	return active

func _submit() -> void:
	active = store.request_hotbar_slots(desired)
	state = "pending" if not active.is_empty() else "failed"

func _confirmed(op_id: String, kind: String) -> void:
	if kind != "hotbar-slots" or op_id != active: return
	active = ""
	state = "ready"
	if desired != store.get_hotbar_slots(): _submit()

func _rejected(op_id: String, kind: String, _code: String) -> void:
	if kind != "hotbar-slots" or op_id != active: return
	active = ""
	state = "failed"
