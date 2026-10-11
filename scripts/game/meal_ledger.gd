extends RefCounted
## Completion receipts, not an AP balance or a recipe/time-window controller.
## The director supplies recipe cost; SaveStore derives confirmed fatigue.
## Neither clock observation nor this API starts cooking or simulates offline meals.
const FIELD := "meal_ledger"
const GRANTS := {"breakfast": 1, "lunch": 3, "dinner": 2}
const MATERIALS := ["wheat", "corn", "millet", "small", "medium", "odd"]
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Contract := preload("res://scripts/exploration/exploration_contract.gd")

static func empty() -> Dictionary:
	return {"schema": 1, "revision": 0, "receipts": []}

static func valid_cost(cost: Variant) -> bool:
	if not cost is Dictionary or cost.is_empty(): return false
	for material: Variant in cost:
		if material not in MATERIALS or Contract.as_int(cost[material], 1, Inventory.MAX_COUNT) == null: return false
	return true

static func read(snapshot: Dictionary) -> Dictionary:
	if not snapshot.has(FIELD): return empty()
	var raw: Variant = snapshot[FIELD]
	if not raw is Dictionary or raw.size() != 3 or not raw.has_all(empty().keys()): return {}
	if Contract.as_int(raw.schema, 1, 1) == null or Contract.as_int(raw.revision, 0, Inventory.MAX_REVISION) == null: return {}
	if not raw.receipts is Array or raw.receipts.size() != raw.revision: return {}
	var seen := {}
	var fatigue_by_day := {}
	var last_day := 0
	var receipts: Array = []
	for receipt: Variant in raw.receipts:
		if not receipt is Dictionary or receipt.size() != 5 or not receipt.has_all(["day", "meal", "ingredients", "fatigued", "earned"]): return {}
		var day: Variant = Contract.as_int(receipt.day, 1, Inventory.MAX_REVISION)
		if day == null or day < last_day or receipt.meal not in GRANTS or not receipt.fatigued is bool or not valid_cost(receipt.ingredients): return {}
		var earned: Variant = Contract.as_int(receipt.earned, 0, 3)
		if earned == null or earned != grant(receipt.meal, receipt.fatigued): return {}
		var key := "%d:%s" % [day, receipt.meal]
		if seen.has(key) or (fatigue_by_day.has(day) and fatigue_by_day[day] != receipt.fatigued): return {}
		seen[key] = true
		fatigue_by_day[day] = receipt.fatigued
		last_day = day
		var cost := {}
		for material: String in receipt.ingredients: cost[material] = int(receipt.ingredients[material])
		receipts.append({"day": int(day), "meal": receipt.meal, "ingredients": cost, "fatigued": receipt.fatigued, "earned": int(earned)})
	return {"schema": 1, "revision": int(raw.revision), "receipts": receipts}

static func grant(meal: String, fatigued: bool) -> int:
	return int(floor(float(GRANTS.get(meal, 0)) / (2.0 if fatigued else 1.0)))

static func complete(snapshot: Dictionary, revision: int, inventory_revision: int, day: int, meal: String, ingredients: Dictionary, fatigued: bool) -> Dictionary:
	var ledger := read(snapshot)
	var inventory := Inventory.read(snapshot)
	if ledger.is_empty() or inventory.is_empty() or meal not in GRANTS or not valid_cost(ingredients): return {"error": "MEAL_INVALID"}
	var current_day: Variant = Contract.as_int(snapshot.get("holiday_day", 1), 1, Inventory.MAX_REVISION)
	if current_day == null or day != current_day: return {"error": "MEAL_CHANGED"}
	for receipt: Dictionary in ledger.receipts:
		if receipt.day > day: return {"error": "MEAL_INVALID"}
		if receipt.day == day:
			if receipt.meal == meal: return {"error": "MEAL_ALREADY_COMPLETED"}
			if receipt.fatigued != fatigued: return {"error": "MEAL_CHANGED"}
	if ledger.revision != revision or inventory.revision != inventory_revision: return {"error": "MEAL_CHANGED"}
	if ledger.revision >= Inventory.MAX_REVISION or inventory.revision >= Inventory.MAX_REVISION: return {"error": "MEAL_LIMIT"}
	for material: String in ingredients:
		var count := int(inventory.fish.get(material, 0) if material in Inventory.FISH else inventory[material])
		var remaining := count - int(ingredients[material])
		if remaining < 0: return {"error": "MEAL_EMPTY"}
		# Preserve the existing planting loop's last seed, including multi-item costs.
		if material in Inventory.GRAINS and remaining < 1: return {"error": "BASKET_SEED_RESERVED"}
	for material: String in ingredients:
		if material in Inventory.FISH:
			inventory.fish[material] -= int(ingredients[material])
			if inventory.fish[material] == 0: inventory.fish.erase(material)
		else: inventory[material] -= int(ingredients[material])
	var cost := {}
	for material: String in ingredients: cost[material] = int(ingredients[material])
	ledger.receipts.append({"day": day, "meal": meal, "ingredients": cost, "fatigued": fatigued, "earned": grant(meal, fatigued)})
	ledger.revision += 1
	inventory.revision += 1
	var candidate := snapshot.duplicate(true)
	candidate[FIELD] = ledger
	candidate[Inventory.FIELD] = inventory
	return {"candidate": candidate}
