extends RefCounted
## Inactive construction transaction component. No director, AP budget, layout
## or production cost is implied by this ledger. Compose with AP consumption
## before activating gameplay; tests use explicitly labeled fixture costs.
const FIELD := "pond_edging"
const Materials := preload("res://scripts/game/growth_materials.gd")
const Contract := preload("res://scripts/exploration/exploration_contract.gd")
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const STONE := ExplorationRoutes.FIND_STONE

static func empty() -> Dictionary:
	return {"schema":1, "revision":0, "sections":{}}

static func read(snapshot: Dictionary) -> Dictionary:
	if not snapshot.has(FIELD): return empty()
	var raw: Variant = snapshot[FIELD]
	if not raw is Dictionary or raw.size() != 3 or not raw.has_all(empty().keys()): return {}
	if Contract.as_int(raw.schema, 1, 1) == null or Contract.as_int(raw.revision) == null: return {}
	if not raw.sections is Dictionary or raw.sections.size() != raw.revision: return {}
	var day: Variant = Contract.as_int(snapshot.get("holiday_day", 1), 1)
	if day == null: return {}
	var result := empty()
	result.revision = int(raw.revision)
	for section: Variant in raw.sections:
		var receipt: Variant = raw.sections[section]
		if not Contract.is_valid_stop_id(section) or not receipt is Dictionary: return {}
		if receipt.size() != 3 or not receipt.has_all(["day", "stones", "experience"]): return {}
		if Contract.as_int(receipt.day, 1) == null or Contract.as_int(receipt.stones, 1, Inventory.MAX_COUNT) == null or Contract.as_int(receipt.experience, 1, Inventory.MAX_COUNT) == null: return {}
		if receipt.day > day: return {}
		result.sections[section] = {"day":int(receipt.day), "stones":int(receipt.stones), "experience":int(receipt.experience)}
	return result

## Each section is a stable world result, not a visual-only success flag.
## Costs/rewards are caller configuration, not approved production defaults.
static func complete(snapshot: Dictionary, revision: int, section: String, proposal: Dictionary, stones: int, experience: int) -> Dictionary:
	var edging := read(snapshot)
	if edging.is_empty() or not Contract.is_valid_stop_id(section): return {"error":"EDGING_INVALID"}
	if edging.sections.has(section): return {"error":"EDGING_ALREADY_COMPLETED"}
	if edging.revision != revision: return {"error":"EDGING_CHANGED"}
	if edging.revision >= Inventory.MAX_REVISION: return {"error":"EDGING_LIMIT"}
	if stones < 1 or stones > Inventory.MAX_COUNT or experience < 1 or experience > Inventory.MAX_COUNT: return {"error":"EDGING_INVALID"}
	if proposal.get("action_id") != "pond_edging" or proposal.get("primary") != STONE or proposal.get("materials") != {STONE:stones}: return {"error":"EDGING_INVALID"}
	var changed := Materials.consume(snapshot, proposal)
	if changed.has("error"): return changed
	var candidate: Dictionary = changed.candidate
	edging.sections[section] = {"day":int(proposal.source.day), "stones":stones, "experience":experience}
	edging.revision += 1
	candidate[FIELD] = edging
	return {"candidate":candidate}
