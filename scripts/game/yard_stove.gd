extends RefCounted
## Durable staged construction, separate from legacy pond results. The receipt
## IS the stage result and XP; no second world flag can get ahead of a write.
const FIELD := "yard_stove"
const STAGES := 3
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Materials := preload("res://scripts/game/growth_materials.gd")
const Contract := preload("res://scripts/exploration/exploration_contract.gd")
const STONE := ExplorationRoutes.FIND_STONE

static func empty() -> Dictionary:
	return {"schema":1,"revision":0,"receipts":[]}

static func read(snapshot: Dictionary) -> Dictionary:
	var raw: Variant = snapshot.get(FIELD,empty())
	var day: Variant = Contract.as_int(snapshot.get("holiday_day",1),1,Inventory.MAX_REVISION)
	if day == null or not raw is Dictionary or raw.size() != 3 or not raw.has_all(empty().keys()): return {}
	if Contract.as_int(raw.schema,1,1) == null or Contract.as_int(raw.revision,0,STAGES) == null: return {}
	if not raw.receipts is Array or raw.receipts.size() != raw.revision: return {}
	var result := empty()
	var last_day := 0
	for index: int in raw.receipts.size():
		var receipt: Variant = raw.receipts[index]
		if not receipt is Dictionary or receipt.size() != 6 or not receipt.has_all(["stage","day","period","ap","stones","experience"]): return {}
		if Contract.as_int(receipt.stage,index+1,index+1) == null: return {}
		var date: Variant = Contract.as_int(receipt.day,1,day)
		if date == null or date < last_day or receipt.period not in ["breakfast","lunch","dinner"]: return {}
		if Contract.as_int(receipt.ap,1,6) == null: return {}
		for key: String in ["stones","experience"]:
			if Contract.as_int(receipt[key],1,Inventory.MAX_COUNT) == null: return {}
		result.receipts.append({"stage":index+1,"day":int(date),"period":receipt.period,"ap":int(receipt.ap),"stones":int(receipt.stones),"experience":int(receipt.experience)})
		last_day = int(date)
	result.revision = int(raw.revision)
	return result

## Only GrowthBudget supplies validated meal AP. Stage is optimistic identity,
## not a caller-selected visual. Explicit costs are producer configuration.
static func complete(snapshot: Dictionary, expected_stage: int, day: int, period: String, proposal: Dictionary, config: Dictionary) -> Dictionary:
	var value := read(snapshot)
	if value.is_empty(): return {"error":"STOVE_INVALID"}
	if value.revision >= STAGES: return {"error":"STOVE_COMPLETE"}
	if value.revision != expected_stage: return {"error":"STOVE_CHANGED"}
	if day != snapshot.get("holiday_day",1) or period not in ["breakfast","lunch","dinner"]: return {"error":"STOVE_CHANGED"}
	if config.size() != 3 or not config.has_all(["ap","stones","experience"]): return {"error":"STOVE_INVALID"}
	if Contract.as_int(config.ap,1,6) == null: return {"error":"STOVE_INVALID"}
	for key: String in ["stones","experience"]:
		if Contract.as_int(config[key],1,Inventory.MAX_COUNT) == null: return {"error":"STOVE_INVALID"}
	if proposal.get("action_id") != "build_stove" or proposal.get("primary") != STONE or proposal.get("materials") != {STONE:int(config.stones)}: return {"error":"STOVE_INVALID"}
	var changed := Materials.consume(snapshot,proposal)
	if changed.has("error"): return changed
	value.revision += 1
	value.receipts.append({"stage":value.revision,"day":day,"period":period,"ap":int(config.ap),"stones":int(config.stones),"experience":int(config.experience)})
	changed.candidate[FIELD] = value
	return changed
