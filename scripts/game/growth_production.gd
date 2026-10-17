extends RefCounted
## Additional production receipts, NOT another AP balance. Legacy pond receipts
## retain their paired revisions; GrowthBudget combines all spend ledgers.
const FIELD := "growth_production"
const PERIODS := ["breakfast", "lunch", "dinner"]
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Materials := preload("res://scripts/game/growth_materials.gd")
const Contract := preload("res://scripts/exploration/exploration_contract.gd")
const Stove := preload("res://scripts/game/yard_stove.gd")
const Garden := preload("res://scripts/game/yard_garden.gd")

static func empty() -> Dictionary:
	return {"schema":1, "revision":0, "receipts":[]}

static func read(snapshot: Dictionary) -> Dictionary:
	var raw: Variant = snapshot.get(FIELD, empty())
	var inventory := Inventory.read(snapshot)
	var today: Variant = Contract.as_int(snapshot.get("holiday_day",1),1,Inventory.MAX_REVISION)
	if today == null or not raw is Dictionary or raw.size() != 3 or not raw.has_all(empty().keys()): return {}
	var scope: Variant = Contract.as_int(raw.schema,1,3)
	if scope == null or Contract.as_int(raw.revision,0,Inventory.MAX_REVISION) == null: return {}
	# Schema 2 fences AP work in pre-stove clients, whose strict schema-1
	# reader cannot count stove spends. Both directions of the link must exist:
	# never downgrade a fence or silently lose construction receipts.
	var stove := Stove.read(snapshot)
	var garden := Garden.read(snapshot)
	if stove.is_empty() or garden.is_empty(): return {}
	if (scope == 1 and stove.revision > 0) or (scope == 2 and stove.revision == 0): return {}
	# Schema 3 prevents pre-garden clients from re-spending unseen garden AP.
	if (scope < 3 and garden.revision > 0) or (scope == 3 and garden.revision == 0): return {}
	if inventory.is_empty() or inventory.production_revision != raw.revision: return {}
	if not raw.receipts is Array or raw.receipts.size() != raw.revision: return {}
	var result := empty()
	result.schema = int(scope)
	var last_day := 0
	for index: int in raw.receipts.size():
		var receipt: Variant = raw.receipts[index]
		if not receipt is Dictionary or receipt.size() != 8 or not receipt.has_all(["id","action","day","period","ap","ingredients","products","experience"]): return {}
		if Contract.as_int(receipt.id,index+1,index+1) == null or receipt.action != "mill_wheat": return {}
		var day: Variant = Contract.as_int(receipt.day,1,today)
		if day == null or day < last_day or receipt.period not in PERIODS or Contract.as_int(receipt.ap,1,6) == null: return {}
		if not _one_count(receipt.ingredients,"wheat") or not _one_count(receipt.products,"flour") or not _one_count(receipt.experience,"cooking"): return {}
		result.receipts.append({"id":index+1,"action":"mill_wheat","day":int(day),"period":receipt.period,"ap":int(receipt.ap),"ingredients":{"wheat":int(receipt.ingredients.wheat)},"products":{"flour":int(receipt.products.flour)},"experience":{"cooking":int(receipt.experience.cooking)}})
		last_day = int(day)
	result.revision = int(raw.revision)
	return result

static func _one_count(value: Variant, key: String) -> bool:
	return value is Dictionary and value.size() == 1 and value.has(key) and Contract.as_int(value[key],1,Inventory.MAX_COUNT) != null

## Pure subtransition. Only GrowthBudget.complete_milling supplies validated AP.
## Quantities are caller configuration, not a default recipe or progression rule.
static func complete_milling(snapshot: Dictionary, day: int, period: String, proposal: Dictionary, config: Dictionary) -> Dictionary:
	if config.size() != 4 or not config.has_all(["ap","wheat","flour","experience"]): return {"error":"PRODUCTION_INVALID"}
	if Contract.as_int(config.ap,1,6) == null: return {"error":"PRODUCTION_INVALID"}
	for key: String in ["wheat","flour","experience"]:
		if Contract.as_int(config[key],1,Inventory.MAX_COUNT) == null: return {"error":"PRODUCTION_INVALID"}
	if day != snapshot.get("holiday_day",1) or period not in PERIODS: return {"error":"PRODUCTION_CHANGED"}
	var ledger := read(snapshot)
	var inventory := Inventory.read(snapshot)
	if ledger.is_empty() or inventory.is_empty(): return {"error":"PRODUCTION_INVALID"}
	if ledger.revision >= Inventory.MAX_REVISION or inventory.flour > Inventory.MAX_COUNT - int(config.flour): return {"error":"PRODUCTION_LIMIT"}
	if proposal.get("action_id") != "mill_wheat" or proposal.get("primary") != "wheat" or proposal.get("materials") != {"wheat":int(config.wheat)}: return {"error":"PRODUCTION_INVALID"}
	var changed := Materials.consume(snapshot,proposal)
	if changed.has("error"): return changed
	# consume already increments inventory.revision once. Credit the output in
	# that same candidate; never issue a second inventory intent or revision.
	changed.candidate[Inventory.FIELD].flour += int(config.flour)
	ledger.revision += 1
	changed.candidate[Inventory.FIELD].production_revision = ledger.revision
	ledger.receipts.append({"id":ledger.revision,"action":"mill_wheat","day":day,"period":period,"ap":int(config.ap),"ingredients":{"wheat":int(config.wheat)},"products":{"flour":int(config.flour)},"experience":{"cooking":int(config.experience)}})
	changed.candidate[FIELD] = ledger
	return changed
