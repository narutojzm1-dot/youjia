extends RefCounted
## One durable hand, basket and ground-food ledger. Existing exploration keepsakes remain in their
## authoritative root field; this extension never copies or rewrites them.
const FIELD := "yard_inventory"
const FISH := ["small", "medium", "odd"]
const FOOD_V2 := ["small", "medium", "odd", "grass"]
const FOOD_V3 := ["small", "medium", "odd", "grass", "millet"]
const FOOD := ["small", "medium", "odd", "grass", "millet", "wheat", "corn"]
const GRAINS := ["wheat", "corn"]
const MAX_GROUND := 32
const MAX_COUNT := 9999
const MAX_REVISION := 2147483647
const Contract := preload("res://scripts/exploration/exploration_contract.gd")


static func empty() -> Dictionary:
	return {"schema": 4, "revision": 0, "fish": {}, "grass": 0, "millet": 0, "wheat": 0, "corn": 0, "held": "", "ground": [], "next_food_id": 1}


## Absent is a legacy empty inventory; present but unknown/corrupt is blocked.
## Never normalize away future fields to make a write appear valid.
static func read(snapshot: Dictionary) -> Dictionary:
	if not snapshot.has(FIELD):
		return empty()
	var raw: Variant = snapshot[FIELD]
	if not raw is Dictionary:
		return {}
	var schema: Variant = Contract.as_int(raw.get("schema"), 1, 4)
	if schema == null: return {}
	var keys := ["schema", "revision", "fish", "held"] if schema == 1 else ["schema", "revision", "fish", "grass", "held", "ground", "next_food_id"]
	if schema >= 3: keys.append("millet")
	if schema == 4: keys.append_array(GRAINS)
	if raw.size() != keys.size(): return {}
	for key: String in keys:
		if not raw.has(key): return {}
	if Contract.as_int(raw.revision, 0, MAX_REVISION) == null:
		return {}
	if not raw.fish is Dictionary or not raw.held is String:
		return {}
	var allowed_food: Array = FISH if schema == 1 else (FOOD_V2 if schema == 2 else FOOD_V3 if schema == 3 else FOOD)
	if not raw.held.is_empty() and raw.held not in allowed_food:
		return {}
	for kind: Variant in raw.fish:
		if kind not in FISH or Contract.as_int(raw.fish[kind], 1, MAX_COUNT) == null:
			return {}
	var result: Dictionary = raw.duplicate(true)
	result.schema = 4
	if schema >= 3 and Contract.as_int(raw.millet, 0, MAX_COUNT) == null: return {}
	result.millet = int(raw.millet) if schema >= 3 else 0
	for grain: String in GRAINS:
		if schema == 4 and Contract.as_int(raw[grain], 0, MAX_COUNT) == null: return {}
		result[grain] = int(raw[grain]) if schema == 4 else 0
	result.revision = int(raw.revision)
	for kind: String in result.fish: result.fish[kind] = int(result.fish[kind])
	if schema == 1:
		result.grass = 0
		result.ground = []
		result.next_food_id = 1
	else:
		if Contract.as_int(raw.grass, 0, MAX_COUNT) == null or Contract.as_int(raw.next_food_id, 1, MAX_REVISION) == null: return {}
		if not raw.ground is Array or raw.ground.size() > MAX_GROUND: return {}
		var ids := {}
		for item: Variant in raw.ground:
			if not item is Dictionary or item.size() != 4: return {}
			if not item.has_all(["id", "kind", "x", "y"]): return {}
			var id: Variant = Contract.as_int(item.id, 1, int(raw.next_food_id) - 1)
			if id == null or ids.has(id) or item.kind not in allowed_food or not _position_valid(item): return {}
			ids[id] = true
		result.grass = int(raw.grass)
		result.next_food_id = int(raw.next_food_id)
		for item: Dictionary in result.ground:
			item.id = int(item.id)
			item.x = float(item.x)
			item.y = float(item.y)
	return result


## Pure optimistic transition, evaluated at the SaveCoordinator FIFO head.
## Replaying the same expected revision cannot mint or consume a second item.
static func transition(snapshot: Dictionary, expected_revision: int, action: String, kind: String, details: Dictionary = {}, consumer: String = "") -> Dictionary:
	var inventory := read(snapshot)
	if inventory.is_empty(): return {"error": "BASKET_INVALID"}
	if inventory.revision != expected_revision: return {"error": "BASKET_CHANGED"}
	if inventory.revision >= MAX_REVISION: return {"error": "BASKET_LIMIT"}
	if kind not in FOOD: return {"error": "BASKET_INVALID"}
	var count := int(inventory.get(kind, 0)) if kind in ["grass", "millet", "wheat", "corn"] else int(inventory.fish.get(kind, 0))
	match action:
		"catch":
			if kind not in FISH: return {"error": "BASKET_INVALID"}
			if count >= MAX_COUNT: return {"error": "BASKET_LIMIT"}
			inventory.fish[kind] = count + 1
		"harvest":
			if kind != "grass": return {"error": "BASKET_INVALID"}
			if not inventory.held.is_empty(): return {"error": "BASKET_HAND_OCCUPIED"}
			inventory.held = "grass"
		"scoop":
			if kind != "millet": return {"error": "BASKET_INVALID"}
			if not inventory.held.is_empty(): return {"error": "BASKET_HAND_OCCUPIED"}
			inventory.held = "millet"
		"withdraw":
			if not inventory.held.is_empty(): return {"error": "BASKET_HAND_OCCUPIED"}
			if count == 0: return {"error": "BASKET_EMPTY"}
			# Keep one grain for the next planting unless that crop is growing.
			if kind in GRAINS and count == 1: return {"error": "BASKET_SEED_RESERVED"}
			_set_stored_count(inventory, kind, count - 1)
			inventory.held = kind
		"return":
			if inventory.held != kind: return {"error": "BASKET_CHANGED"}
			if count >= MAX_COUNT: return {"error": "BASKET_LIMIT"}
			_set_stored_count(inventory, kind, count + 1)
			inventory.held = ""
		"consume":
			if inventory.held != kind: return {"error": "BASKET_CHANGED"}
			inventory.held = ""
		"drop":
			if inventory.held != kind: return {"error": "BASKET_CHANGED"}
			if details.size() != 2 or not details.has_all(["x", "y"]) or not _position_valid(details): return {"error": "BASKET_INVALID"}
			if inventory.ground.size() >= MAX_GROUND or inventory.next_food_id >= MAX_REVISION: return {"error": "BASKET_LIMIT"}
			inventory.ground.append({"id": int(inventory.next_food_id), "kind": kind, "x": float(details.x), "y": float(details.y)})
			inventory.next_food_id = int(inventory.next_food_id) + 1
			inventory.held = ""
		"pickup", "eat":
			if details.size() != 1 or Contract.as_int(details.get("id"), 1, MAX_REVISION) == null: return {"error": "BASKET_INVALID"}
			if action == "pickup" and not inventory.held.is_empty(): return {"error": "BASKET_HAND_OCCUPIED"}
			var found := -1
			for index: int in inventory.ground.size():
				if inventory.ground[index].id == details.id and inventory.ground[index].kind == kind:
					found = index
					break
			if found < 0: return {"error": "BASKET_EMPTY"}
			inventory.ground.remove_at(found)
			if action == "pickup": inventory.held = kind
		_:
			return {"error": "BASKET_INVALID"}
	inventory.revision = int(inventory.revision) + 1
	var candidate := snapshot.duplicate(true)
	candidate[FIELD] = inventory
	return preload("res://scripts/game/chick_care.gd").credit(candidate, action, kind, consumer)


static func _set_stored_count(inventory: Dictionary, kind: String, count: int) -> void:
	if kind in ["grass", "millet", "wheat", "corn"]: inventory[kind] = count
	elif count == 0: inventory.fish.erase(kind)
	else: inventory.fish[kind] = count


static func _position_valid(value: Dictionary) -> bool:
	for key: String in ["x", "y"]:
		var coordinate: Variant = value.get(key)
		if not (coordinate is float or coordinate is int): return false
		if not is_finite(float(coordinate)) or float(coordinate) < 0.0 or float(coordinate) > 1000000.0: return false
	return true
