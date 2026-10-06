class_name AnimalCompanions
extends RefCounted
## A choice belongs to one trip, never to a render frame or a retry.
const SPECIES := {"llama": "llama", "cow": "cow", "horse": "horse", "sheep_a": "sheep", "sheep_b": "sheep", "goose": "goose"}
const NEAR := 120.0
const CHANCE := 0.35

static func valid_choice(value: Variant) -> bool:
	if not value is Dictionary: return false
	if value.is_empty(): return true
	if value.size() != 2 or not value.has("actor_id") or not value.has("mode"): return false
	if not value.actor_id is String or not value.mode is String: return false
	return value.actor_id in SPECIES and (value.mode == "nearby" or (value.mode == "rope" and value.actor_id == "llama"))

static func valid_context(value: Dictionary) -> bool:
	if value.is_empty(): return true
	if value.size() != 2 or not value.get("nearby") is Array or not value.get("rope") is String: return false
	if value.rope not in ["", "llama"] or value.nearby.size() > SPECIES.size(): return false
	var seen := {}
	for id: Variant in value.nearby:
		if not id is String or not SPECIES.has(id) or seen.has(id): return false
		seen[id] = true
	return true

static func choose(context: Dictionary, seed_text: String) -> Dictionary:
	if not valid_context(context) or context.is_empty(): return {}
	if context.rope == "llama": return {"actor_id": "llama", "mode": "rope"}
	if context.nearby.is_empty(): return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = ExplorationContract.derive_stop_seed(seed_text, "animal_companion")
	if rng.randf() >= CHANCE: return {}
	var ids: Array = context.nearby.duplicate()
	ids.sort()
	return {"actor_id": ids[rng.randi_range(0, ids.size() - 1)], "mode": "nearby"}
