extends RefCounted
## The three original painted compositions, not a capacity for collected flowers.
## Missing field means the untouched legacy painting. An explicit empty area
## must survive reopening. Ownership is never minted by removal/restoration.
const FIELD := "yard_original_plants"
const AREAS := ["left_cluster", "door_pots", "pond_cluster"]
const Contract := preload("res://scripts/exploration/exploration_contract.gd")
const MAX_REVISION := 2147483647

static func original() -> Dictionary:
	return {"schema": 1, "revision": 0, "removed": []}

static func read(snapshot: Dictionary) -> Dictionary:
	if not snapshot.has(FIELD): return original()
	var raw: Variant = snapshot[FIELD]
	if not raw is Dictionary or raw.size() != 3 or not raw.has_all(["schema", "revision", "removed"]): return {}
	if Contract.as_int(raw.schema, 1, 1) == null or Contract.as_int(raw.revision, 0, MAX_REVISION) == null: return {}
	if not raw.removed is Array or raw.removed.size() > AREAS.size(): return {}
	var removed: Array = []
	for area: Variant in raw.removed:
		if not area is String or area not in AREAS or area in removed: return {}
		removed.append(area)
	removed.sort()
	return {"schema": 1, "revision": int(raw.revision), "removed": removed}

## A returned original group remains owned once, reserved when in the painting.
## This projection does not add it to nearpath drops or the food inventory.
static func available(snapshot: Dictionary) -> Array:
	var record := read(snapshot)
	return [] if record.is_empty() else record.removed.duplicate()

static func transition(snapshot: Dictionary, revision: int, action: String, area: String) -> Dictionary:
	var record := read(snapshot)
	if record.is_empty(): return {"error": "GARDEN_INVALID"}
	if record.revision != revision: return {"error": "GARDEN_CHANGED"}
	if revision >= MAX_REVISION: return {"error": "GARDEN_LIMIT"}
	if area not in AREAS: return {"error": "GARDEN_INVALID"}
	match action:
		"remove":
			if area in record.removed: return {"error": "GARDEN_EMPTY"}
			record.removed.append(area)
		"restore":
			if area not in record.removed: return {"error": "GARDEN_OCCUPIED"}
			record.removed.erase(area)
		_: return {"error": "GARDEN_INVALID"}
	# First edit and legacy initialization are a single durable transaction.
	# No eager default patch can reset an already edited area.
	record.removed.sort()
	record.revision += 1
	var candidate := snapshot.duplicate(true)
	candidate[FIELD] = record
	return {"candidate": candidate}
