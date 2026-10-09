extends RefCounted
## Optional durable feeding credit. Inventory revision owns exactly-once consumption.
const FIELD := "chick_care"
const PORTION_SECONDS := 300
const MAX_BONUS := 1200
const GROW_SECONDS := 1800.0

static func read(snapshot: Dictionary) -> Dictionary:
	if not snapshot.has(FIELD): return {"schema": 1, "bonus_seconds": 0}
	var raw: Variant = snapshot[FIELD]
	if not raw is Dictionary or raw.size() != 2 or not raw.has_all(["schema", "bonus_seconds"]): return {}
	var contract = preload("res://scripts/exploration/exploration_contract.gd")
	if contract.as_int(raw.schema, 1, 1) == null: return {}
	var bonus: Variant = contract.as_int(raw.bonus_seconds, 0, MAX_BONUS)
	if bonus == null or int(bonus) % PORTION_SECONDS != 0: return {}
	return {"schema": 1, "bonus_seconds": int(bonus)}

## Called only after the authoritative inventory transition succeeds, in the same candidate.
static func credit(candidate: Dictionary, action: String, kind: String, consumer: String) -> Dictionary:
	if action != "eat" or consumer != "chicken" or kind not in ["millet", "wheat", "corn"]:
		return {"candidate": candidate}
	var care := read(candidate)
	if care.is_empty(): return {"error": "BASKET_CHICK_CARE_UNSUPPORTED"}
	# Resolve at runtime to avoid a cyclic preload with the growth predicate.
	var residents: Dictionary = load("res://scripts/game/world_residents.gd").read(candidate)
	if residents.is_empty(): return {"error": "BASKET_CHICK_CARE_UNSUPPORTED"}
	var chicken: Dictionary = residents.chicken
	if chicken.get("stage", "") != "chick": return {"candidate": candidate}
	var result := candidate.duplicate(true)
	care.bonus_seconds = mini(MAX_BONUS, int(care.bonus_seconds) + PORTION_SECONDS)
	result[FIELD] = care
	return {"candidate": result}

static func age(snapshot: Dictionary, settled_seconds: float, now_seconds: float) -> float:
	var care := read(snapshot)
	if care.is_empty() or settled_seconds < 0.0 or now_seconds < settled_seconds: return -1.0
	return minf(GROW_SECONDS, now_seconds - settled_seconds + float(care.bonus_seconds))
