class_name AnimalRelationships
extends RefCounted

## Minimal, deliberately sparse memory for the first REQ-011 relationship slice.
const GOOSE_LLAMA_SHARED_SPACE := "goose_llama_shared_space_after_player_lead"
const SHARE_SPACE_RADIUS := 128.0
const CALM_RESOLVE_SECONDS := 1.25
const BASE_LINGER_CHANCE := 0.0
const REMEMBERED_LINGER_CHANCE := 0.10


static func sanitize(raw: Variant) -> Dictionary:
	var result := {}
	if not raw is Dictionary:
		return result
	if bool(raw.get(GOOSE_LLAMA_SHARED_SPACE, false)):
		result[GOOSE_LLAMA_SHARED_SPACE] = true
	return result


static func has_shared_space_memory(memory: Dictionary) -> bool:
	return bool(memory.get(GOOSE_LLAMA_SHARED_SPACE, false))


static func calm_shared_space(goose: Node2D, llama: Node2D) -> bool:
	if goose == null or llama == null or not is_instance_valid(goose) or not is_instance_valid(llama):
		return false
	if goose.position.distance_to(llama.position) > SHARE_SPACE_RADIUS:
		return false
	if str(goose.get("state")) not in ["graze", "rest"] or str(llama.get("state")) not in ["graze", "rest"]:
		return false
	if bool(goose.get("posed")) or bool(llama.get("posed")):
		return false
	return true


static func should_linger(roll: float, memory: Dictionary) -> bool:
	var chance := REMEMBERED_LINGER_CHANCE if has_shared_space_memory(memory) else BASE_LINGER_CHANCE
	return roll >= 0.0 and roll < chance
