extends RefCounted
## One durable fish ledger. Existing exploration keepsakes remain in their
## authoritative root field; this extension never copies or rewrites them.
const FIELD := "yard_inventory"
const FISH := ["small", "medium", "odd"]
const MAX_COUNT := 9999
const MAX_REVISION := 2147483647
const Contract := preload("res://scripts/exploration/exploration_contract.gd")


static func empty() -> Dictionary:
	return {"schema": 1, "revision": 0, "fish": {}, "held": ""}


## Absent is a legacy empty inventory; present but unknown/corrupt is blocked.
## Never normalize away future fields to make a write appear valid.
static func read(snapshot: Dictionary) -> Dictionary:
	if not snapshot.has(FIELD):
		return empty()
	var raw: Variant = snapshot[FIELD]
	if not raw is Dictionary or raw.size() != 4:
		return {}
	for key: String in ["schema", "revision", "fish", "held"]:
		if not raw.has(key): return {}
	if Contract.as_int(raw.schema, 1, 1) == null or Contract.as_int(raw.revision, 0, MAX_REVISION) == null:
		return {}
	if not raw.fish is Dictionary or not raw.held is String:
		return {}
	if not raw.held.is_empty() and raw.held not in FISH:
		return {}
	for kind: Variant in raw.fish:
		if kind not in FISH or Contract.as_int(raw.fish[kind], 1, MAX_COUNT) == null:
			return {}
	return raw.duplicate(true)


## Pure optimistic transition, evaluated at the SaveCoordinator FIFO head.
## Replaying the same expected revision cannot mint or consume a second item.
static func transition(snapshot: Dictionary, expected_revision: int, action: String, kind: String) -> Dictionary:
	var inventory := read(snapshot)
	if inventory.is_empty(): return {"error": "BASKET_INVALID"}
	if inventory.revision != expected_revision: return {"error": "BASKET_CHANGED"}
	if inventory.revision >= MAX_REVISION: return {"error": "BASKET_LIMIT"}
	if kind not in FISH: return {"error": "BASKET_INVALID"}
	var count := int(inventory.fish.get(kind, 0))
	match action:
		"catch":
			if count >= MAX_COUNT: return {"error": "BASKET_LIMIT"}
			inventory.fish[kind] = count + 1
		"withdraw":
			if not inventory.held.is_empty(): return {"error": "BASKET_HAND_OCCUPIED"}
			if count == 0: return {"error": "BASKET_EMPTY"}
			_set_count(inventory.fish, kind, count - 1)
			inventory.held = kind
		"return":
			if inventory.held != kind: return {"error": "BASKET_CHANGED"}
			if count >= MAX_COUNT: return {"error": "BASKET_LIMIT"}
			inventory.fish[kind] = count + 1
			inventory.held = ""
		"consume":
			if inventory.held != kind: return {"error": "BASKET_CHANGED"}
			inventory.held = ""
		_:
			return {"error": "BASKET_INVALID"}
	inventory.revision = int(inventory.revision) + 1
	var candidate := snapshot.duplicate(true)
	candidate[FIELD] = inventory
	return {"candidate": candidate}


static func _set_count(counts: Dictionary, kind: String, count: int) -> void:
	if count == 0: counts.erase(kind)
	else: counts[kind] = count
