extends RefCounted
## Pure cooking intake. The director supplies unlocked, executable recipes;
## this does not turn the ledger's material whitelist into a recipe catalog.
## A plan reserves nothing. Keep its revisions/cost until completion, then
## let SaveStore reject concurrent stock changes instead of rerolling a write.
const Meals := preload("res://scripts/game/meal_ledger.gd")
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Contract := preload("res://scripts/exploration/exploration_contract.gd")
const Rest := preload("res://scripts/game/rest_context.gd")

## Catalog: primary material -> {id: String, ingredients: Dictionary}.
## One eligible recipe per primary avoids multiplying an ingredient's chance
## just because more recipes happen to use it. Empty/invalid catalogs fail closed.
static func plan(snapshot: Dictionary, meal: String, catalog: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var ledger := Meals.read(snapshot)
	var inventory := Inventory.read(snapshot)
	var day: Variant = Contract.as_int(snapshot.get("holiday_day", 1), 1, Inventory.MAX_REVISION)
	if rng == null or day == null or ledger.is_empty() or inventory.is_empty() or meal not in Meals.GRANTS: return {}
	if Rest.read(snapshot).is_empty(): return {}
	if ledger.revision >= Inventory.MAX_REVISION or inventory.revision >= Inventory.MAX_REVISION: return {}
	for receipt: Dictionary in ledger.receipts:
		if receipt.day > day or (receipt.day == day and receipt.meal == meal): return {}
	var candidates := {}
	for primary: Variant in catalog:
		var recipe: Variant = catalog[primary]
		if primary not in Meals.MATERIALS or not recipe is Dictionary: return {}
		if recipe.size() != 2 or not recipe.has_all(["id", "ingredients"]): return {}
		if not recipe.id is String or recipe.id.strip_edges().is_empty(): return {}
		if not Meals.valid_cost(recipe.ingredients) or not recipe.ingredients.has(primary): return {}
		var available := true
		for material: String in recipe.ingredients:
			var remaining := _stock(inventory, material) - int(recipe.ingredients[material])
			if remaining < (1 if material in Inventory.GRAINS else 0): available = false
		if available: candidates[primary] = _stock(inventory, primary)
	if candidates.is_empty(): return {}
	# Stable ordering prevents dictionary insertion order changing seeded replays.
	var maximum: Array[String] = []
	var other: Array[String] = []
	var largest := 0
	for material: String in candidates: largest = maxi(largest, candidates[material])
	for material: String in candidates:
		if candidates[material] == largest: maximum.append(material)
		else: other.append(material)
	maximum.sort()
	other.sort()
	# Producer tie rule: choose equally within the maximum pool; if all tie
	# or only one candidate exists, use that pool rather than fail half the time.
	var pool := maximum if other.is_empty() or rng.randf() < 0.5 else other
	var chosen: String = pool[rng.randi_range(0, pool.size() - 1)]
	var cost := {}
	for material: String in catalog[chosen].ingredients: cost[material] = int(catalog[chosen].ingredients[material])
	return {"day": int(day), "meal": meal, "revision": int(ledger.revision), "inventory_revision": int(inventory.revision), "primary": chosen, "recipe_id": catalog[chosen].id, "ingredients": cost}

static func _stock(inventory: Dictionary, material: String) -> int:
	return int(inventory.fish.get(material, 0) if material in Inventory.FISH else inventory.get(material, 0))
