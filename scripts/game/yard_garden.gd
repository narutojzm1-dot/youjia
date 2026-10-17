extends RefCounted
## A first fixed flower bed. Its planting receipt is also the world/XP result.
## Original painted plants, crop plots and manual flower ownership are separate.
const FIELD := "yard_garden"
const SEEDS := ExplorationRoutes.FIND_FLOWER_SEEDS
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Materials := preload("res://scripts/game/growth_materials.gd")
const Contract := preload("res://scripts/exploration/exploration_contract.gd")

static func empty() -> Dictionary:
	return {"schema":1,"revision":0,"receipts":[]}

static func read(snapshot: Dictionary) -> Dictionary:
	var raw: Variant = snapshot.get(FIELD,empty())
	var day: Variant = Contract.as_int(snapshot.get("holiday_day",1),1,Inventory.MAX_REVISION)
	if day == null or not raw is Dictionary or raw.size() != 3 or not raw.has_all(empty().keys()): return {}
	if Contract.as_int(raw.schema,1,1) == null or Contract.as_int(raw.revision,0,1) == null: return {}
	if not raw.receipts is Array or raw.receipts.size() != raw.revision: return {}
	var result := empty()
	for receipt: Variant in raw.receipts:
		if not receipt is Dictionary or receipt.size() != 6 or not receipt.has_all(["bed","day","period","ap","seeds","experience"]): return {}
		if receipt.bed != "starter" or Contract.as_int(receipt.day,1,day) == null: return {}
		if receipt.period not in ["breakfast","lunch","dinner"] or Contract.as_int(receipt.ap,1,6) == null: return {}
		for key: String in ["seeds","experience"]:
			if Contract.as_int(receipt[key],1,Inventory.MAX_COUNT) == null: return {}
		result.receipts.append({"bed":"starter","day":int(receipt.day),"period":receipt.period,"ap":int(receipt.ap),"seeds":int(receipt.seeds),"experience":int(receipt.experience)})
	result.revision = int(raw.revision)
	return result

static func complete(snapshot: Dictionary, day: int, period: String, proposal: Dictionary, config: Dictionary) -> Dictionary:
	var value := read(snapshot)
	if value.is_empty(): return {"error":"GARDEN_INVALID"}
	if value.revision != 0: return {"error":"GARDEN_COMPLETE"}
	if day != snapshot.get("holiday_day",1) or period not in ["breakfast","lunch","dinner"]: return {"error":"GARDEN_CHANGED"}
	if config.size() != 3 or not config.has_all(["ap","seeds","experience"]): return {"error":"GARDEN_INVALID"}
	if Contract.as_int(config.ap,1,6) == null: return {"error":"GARDEN_INVALID"}
	for key: String in ["seeds","experience"]:
		if Contract.as_int(config[key],1,Inventory.MAX_COUNT) == null: return {"error":"GARDEN_INVALID"}
	if proposal.get("action_id") != "plant_flowers" or proposal.get("primary") != SEEDS or proposal.get("materials") != {SEEDS:int(config.seeds)}: return {"error":"GARDEN_INVALID"}
	var changed := Materials.consume(snapshot,proposal)
	if changed.has("error"): return changed
	value.revision = 1
	value.receipts.append({"bed":"starter","day":day,"period":period,"ap":int(config.ap),"seeds":int(config.seeds),"experience":int(config.experience)})
	changed.candidate[FIELD] = value
	return changed
