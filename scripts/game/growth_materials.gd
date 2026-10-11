extends RefCounted
## Read-only, executable-material selection. Catalogs are supplied by the
## director AFTER checking tools, target space, unlocks and action points.
## No default actions/costs; a material whitelist is not a gameplay catalog.
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Decor := preload("res://scripts/inventory/yard_decor.gd")
const Contract := preload("res://scripts/exploration/exploration_contract.gd")

static func stock(snapshot: Dictionary) -> Dictionary:
	var inventory := Inventory.read(snapshot)
	var keepsakes := Decor.available(snapshot)
	if inventory.is_empty() or keepsakes.is_empty(): return {}
	var result := keepsakes.duplicate(true)
	for material: String in Inventory.FOOD:
		result[material] = int(inventory.fish.get(material, 0) if material in Inventory.FISH else inventory.get(material, 0))
	return result

static func valid_cost(cost: Variant) -> bool:
	if not cost is Dictionary or cost.is_empty(): return false
	for material: Variant in cost:
		if material not in Inventory.FOOD and material not in ExplorationRoutes.FINDS: return false
		if Contract.as_int(cost[material], 1, Inventory.MAX_COUNT) == null: return false
	return true

## Full relevant snapshot guard catches decor reservations and exploration
## returns as well as food writes. A plan is not a reservation or save intent.
static func guard(snapshot: Dictionary) -> Dictionary:
	var inventory := Inventory.read(snapshot)
	var decor := Decor.read(snapshot)
	var day: Variant = Contract.as_int(snapshot.get("holiday_day", 1), 1)
	var serial: Variant = Contract.as_int(snapshot.get("exploration_committed_serial", 0))
	var owned: Variant = snapshot.get("keepsakes", {})
	if day == null or serial == null or inventory.is_empty() or decor.is_empty() or not owned is Dictionary: return {}
	# Unknown ownership must not be silently normalized or overwritten.
	var normalized := {}
	for key: Variant in owned:
		if key not in ExplorationRoutes.FINDS or Contract.as_int(owned[key], 1, Inventory.MAX_COUNT) == null: return {}
		normalized[key] = int(owned[key])
	return {"day":int(day), "inventory":inventory, "decor":decor, "keepsakes":normalized, "trip_serial":int(serial)}

static func can_afford(counts: Dictionary, cost: Dictionary) -> bool:
	if counts.is_empty() or not valid_cost(cost): return false
	for material: String in cost:
		if int(counts.get(material, 0)) - int(cost[material]) < (1 if material in Inventory.GRAINS else 0): return false
	return true

## Catalog primary -> {id, materials}. One action per primary prevents an
## ingredient with many recipes from getting extra probability.
static func plan(snapshot: Dictionary, catalog: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var source := guard(snapshot)
	var counts := stock(snapshot)
	if source.is_empty() or counts.is_empty() or rng == null: return {}
	var eligible := {}
	for primary: Variant in catalog:
		var action: Variant = catalog[primary]
		if not counts.has(primary) or not action is Dictionary: return {}
		if action.size() != 2 or not action.has_all(["id", "materials"]): return {}
		if not Contract.is_valid_stop_id(action.id) or not valid_cost(action.materials) or not action.materials.has(primary): return {}
		var writable := true
		for material: String in action.materials:
			if material in Inventory.FOOD and source.inventory.revision >= Inventory.MAX_REVISION: writable = false
		if writable and can_afford(counts, action.materials): eligible[primary] = counts[primary]
	if eligible.is_empty(): return {}
	var maximum: Array[String] = []
	var other: Array[String] = []
	var largest := 0
	for material: String in eligible: largest = maxi(largest, eligible[material])
	for material: String in eligible:
		if eligible[material] == largest: maximum.append(material)
		else: other.append(material)
	maximum.sort()
	other.sort()
	# Same producer tie policy as meals: uniform within the maximum group;
	# fall back to it when there is no other group.
	var pool := maximum if other.is_empty() or rng.randf() < 0.5 else other
	var chosen: String = pool[rng.randi_range(0, pool.size()-1)]
	var cost := {}
	for material: String in catalog[chosen].materials: cost[material] = int(catalog[chosen].materials[material])
	return {"source":source, "primary":chosen, "action_id":catalog[chosen].id, "materials":cost}

## Pure subtransition only. The caller must compose AP, world result, experience
## and a durable completion receipt into ONE SaveCoordinator intent. Never save
## this candidate alone as an autonomous action completion.
static func consume(snapshot: Dictionary, proposal: Dictionary) -> Dictionary:
	if proposal.size() != 4 or not proposal.has_all(["source", "primary", "action_id", "materials"]): return {"error":"GROWTH_INVALID"}
	if not proposal.source is Dictionary or not Contract.is_valid_stop_id(proposal.action_id) or not valid_cost(proposal.materials): return {"error":"GROWTH_INVALID"}
	if not proposal.materials.has(proposal.primary): return {"error":"GROWTH_INVALID"}
	var source := guard(snapshot)
	if source.is_empty(): return {"error":"GROWTH_INVALID"}
	if source != proposal.source: return {"error":"GROWTH_CHANGED"}
	if not can_afford(stock(snapshot), proposal.materials): return {"error":"GROWTH_EMPTY"}
	var inventory: Dictionary = source.inventory.duplicate(true)
	var owned: Dictionary = source.keepsakes.duplicate(true)
	var uses_inventory := false
	for material: String in proposal.materials:
		var amount := int(proposal.materials[material])
		if material in ExplorationRoutes.FINDS:
			owned[material] -= amount
			if owned[material] == 0: owned.erase(material)
		else:
			uses_inventory = true
			if material in Inventory.FISH:
				inventory.fish[material] -= amount
				if inventory.fish[material] == 0: inventory.fish.erase(material)
			else: inventory[material] -= amount
	if uses_inventory:
		if inventory.revision >= Inventory.MAX_REVISION: return {"error":"GROWTH_LIMIT"}
		inventory.revision += 1
	var candidate := snapshot.duplicate(true)
	candidate.keepsakes = owned
	if uses_inventory: candidate[Inventory.FIELD] = inventory
	return {"candidate":candidate}
