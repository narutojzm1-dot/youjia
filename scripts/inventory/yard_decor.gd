extends RefCounted
## Keepsakes remain total ownership. Each occupied place reserves exactly one;
## putting it back releases that reservation, never grants another keepsake.
const FIELD := "yard_decor"
const Contract := preload("res://scripts/exploration/exploration_contract.gd")
const MAX_REVISION := 2147483647
const SPOTS := {"house_edge": Vector2(290, 575), "fence_edge": Vector2(655, 465), "pond_path": Vector2(490, 516)}
const NUDGE := Vector2(16, 8)

static func empty() -> Dictionary:
	return {"schema": 1, "revision": 0, "places": {}}

static func read(snapshot: Dictionary) -> Dictionary:
	if not snapshot.has(FIELD): return empty()
	var raw: Variant = snapshot[FIELD]
	if not raw is Dictionary or raw.size() != 3 or not raw.has_all(["schema", "revision", "places"]): return {}
	if Contract.as_int(raw.schema, 1, 1) == null or Contract.as_int(raw.revision, 0, MAX_REVISION) == null: return {}
	if not raw.places is Dictionary or raw.places.size() > SPOTS.size(): return {}
	var used := {}
	for spot: Variant in raw.places:
		if spot not in SPOTS: return {}
		var entry: Variant = raw.places[spot]
		if not entry is Dictionary or entry.size() != 3 or not entry.has_all(["find_id", "dx", "dy"]): return {}
		if not entry.find_id is String or not ExplorationRoutes.is_formal_find(entry.find_id): return {}
		if not offset_valid(entry): return {}
		used[entry.find_id] = int(used.get(entry.find_id, 0)) + 1
	var owned: Variant = snapshot.get("keepsakes", {})
	if not owned is Dictionary: return {}
	for find_id: String in used:
		var count: Variant = Contract.as_int(owned.get(find_id), 1, 9999)
		if count == null or int(count) < int(used[find_id]): return {}
	var result: Dictionary = raw.duplicate(true)
	result.schema = 1
	result.revision = int(result.revision)
	for entry: Dictionary in result.places.values():
		entry.dx = int(entry.dx)
		entry.dy = int(entry.dy)
	return result

static func offset_valid(entry: Dictionary) -> bool:
	return Contract.as_int(entry.get("dx"), -1, 1) != null and Contract.as_int(entry.get("dy"), -1, 1) != null

static func position_for(spot: String, entry: Dictionary) -> Vector2:
	return SPOTS[spot] + Vector2(float(entry.dx), float(entry.dy)) * NUDGE

static func available(snapshot: Dictionary) -> Dictionary:
	var decor := read(snapshot)
	if decor.is_empty(): return {}
	var raw: Variant = snapshot.get("keepsakes", {})
	if not raw is Dictionary: return {}
	var counts := {}
	for id: String in ExplorationRoutes.FINDS:
		var count: Variant = Contract.as_int(raw.get(id, 0), 0, 9999)
		if count == null: return {}
		counts[id] = int(count)
	for entry: Dictionary in decor.places.values(): counts[entry.find_id] -= 1
	return counts

## This executes at the shared save FIFO head, against the latest confirmed
## exploration and decor data. Preview selection never changes this snapshot.
static func transition(snapshot: Dictionary, revision: int, action: String, spot: String, details: Dictionary) -> Dictionary:
	var decor := read(snapshot)
	if decor.is_empty(): return {"error": "DECOR_INVALID"}
	if int(decor.revision) != revision: return {"error": "DECOR_CHANGED"}
	if revision >= MAX_REVISION: return {"error": "DECOR_LIMIT"}
	if spot not in SPOTS: return {"error": "DECOR_INVALID"}
	match action:
		"place":
			if details.size() != 3 or not details.has_all(["find_id", "dx", "dy"]) or not offset_valid(details): return {"error": "DECOR_INVALID"}
			if decor.places.has(spot): return {"error": "DECOR_OCCUPIED"}
			var counts := available(snapshot)
			if not details.find_id is String or details.find_id not in ExplorationRoutes.FINDS: return {"error": "DECOR_INVALID"}
			if int(counts.get(details.find_id, 0)) <= 0: return {"error": "DECOR_EMPTY"}
			decor.places[spot] = details.duplicate(true)
		"move":
			if not decor.places.has(spot): return {"error": "DECOR_EMPTY"}
			if details.size() != 2 or not details.has_all(["dx", "dy"]) or not offset_valid(details): return {"error": "DECOR_INVALID"}
			decor.places[spot].dx = details.dx
			decor.places[spot].dy = details.dy
		"remove":
			if not details.is_empty(): return {"error": "DECOR_INVALID"}
			if not decor.places.has(spot): return {"error": "DECOR_EMPTY"}
			decor.places.erase(spot)
		_: return {"error": "DECOR_INVALID"}
	decor.revision = revision + 1
	var candidate := snapshot.duplicate(true)
	candidate[FIELD] = decor
	return {"candidate": candidate}
