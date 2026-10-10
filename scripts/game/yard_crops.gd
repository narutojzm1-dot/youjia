extends RefCounted
## Queue-head crop transitions. Seed debit / bed creation and harvest credit /
## bed clearing each share one durable snapshot with the inventory revision.
const FIELD := "yard_crops"
const KINDS := ["grass", "wheat", "corn"]
const DAYS := {"grass": 1, "wheat": 2, "corn": 3}
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Contract := preload("res://scripts/exploration/exploration_contract.gd")

static func empty() -> Dictionary:
	return {"schema": 1, "revision": 0, "kind": "", "planted_day": 0, "watered_day": -1}

static func read(snapshot: Dictionary) -> Dictionary:
	if not snapshot.has(FIELD): return empty()
	var raw: Variant = snapshot[FIELD]
	if not raw is Dictionary or raw.size() != 5 or not raw.has_all(empty().keys()): return {}
	if Contract.as_int(raw.schema, 1, 1) == null or Contract.as_int(raw.revision, 0, Inventory.MAX_REVISION) == null: return {}
	if raw.kind not in KINDS and raw.kind != "": return {}
	if Contract.as_int(raw.planted_day, 0, Inventory.MAX_REVISION) == null or Contract.as_int(raw.watered_day, -1, Inventory.MAX_REVISION) == null: return {}
	if raw.kind == "" and (raw.planted_day != 0 or raw.watered_day != -1): return {}
	if raw.kind != "" and (raw.planted_day < 1 or (raw.watered_day != -1 and raw.watered_day < raw.planted_day)): return {}
	return {"schema": 1, "revision": int(raw.revision), "kind": raw.kind, "planted_day": int(raw.planted_day), "watered_day": int(raw.watered_day)}

static func mature(bed: Dictionary, day: int) -> bool:
	return not bed.is_empty() and bed.kind in KINDS and day >= int(bed.planted_day) + int(DAYS[bed.kind]) and int(bed.watered_day) >= int(bed.planted_day)

static func transition(snapshot: Dictionary, revision: int, inventory_revision: int, action: String, kind: String = "") -> Dictionary:
	var bed := read(snapshot)
	var inventory := Inventory.read(snapshot)
	if bed.is_empty() or inventory.is_empty(): return {"error": "CROP_INVALID"}
	if bed.revision != revision or inventory.revision != inventory_revision: return {"error": "CROP_CHANGED"}
	var candidate := snapshot.duplicate(true)
	if action == "initialize":
		# A durable field is the once-only grant marker; reload never adds seeds.
		if snapshot.has(FIELD): return {"candidate": candidate}
		if inventory.revision >= Inventory.MAX_REVISION or inventory.wheat > Inventory.MAX_COUNT - 2 or inventory.corn > Inventory.MAX_COUNT - 2: return {"error": "CROP_LIMIT"}
		inventory.wheat += 2
		inventory.corn += 2
		inventory.revision += 1
		candidate[Inventory.FIELD] = inventory
		candidate[FIELD] = bed
		return {"candidate": candidate}
	if not snapshot.has(FIELD): return {"error": "CROP_INVALID"}
	var day: Variant = Contract.as_int(snapshot.get("holiday_day", 1), 1, Inventory.MAX_REVISION)
	if day == null or bed.revision >= Inventory.MAX_REVISION or inventory.revision >= Inventory.MAX_REVISION: return {"error": "CROP_LIMIT"}
	match action:
		"plant":
			if kind not in KINDS or not bed.kind.is_empty() or int(snapshot.get("plant_state", 0)) != 0: return {"error": "CROP_OCCUPIED"}
			if kind != "grass":
				if inventory[kind] <= 0: return {"error": "CROP_EMPTY"}
				inventory[kind] -= 1
			bed.kind = kind
			bed.planted_day = day
			bed.watered_day = -1
		"water":
			if bed.kind not in KINDS or day < bed.planted_day: return {"error": "CROP_INVALID"}
			if bed.watered_day >= day: return {"error": "CROP_WATERED"}
			bed.watered_day = day
		"harvest":
			if not mature(bed, day): return {"error": "CROP_NOT_READY"}
			var crop: String = bed.kind
			if inventory[crop] > Inventory.MAX_COUNT - 3: return {"error": "CROP_LIMIT"}
			inventory[crop] += 3
			bed.kind = ""
			bed.planted_day = 0
			bed.watered_day = -1
		_:
			return {"error": "CROP_INVALID"}
	bed.revision += 1
	inventory.revision += 1
	candidate[FIELD] = bed
	candidate[Inventory.FIELD] = inventory
	return {"candidate": candidate}
