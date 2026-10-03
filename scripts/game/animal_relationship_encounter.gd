class_name AnimalRelationshipEncounter
extends RefCounted

const AnimalRelationshipsType := preload("res://scripts/game/animal_relationships.gd")

var _lead_started_apart := false
var _lead_source_pending := false
var _calm_seconds := 0.0
var _linger_cooldown := 42.0


func begin_lead(goose: FeltActor, llama: FeltActor) -> void:
	_lead_started_apart = goose != null and llama.position.distance_to(goose.position) > AnimalRelationshipsType.SHARE_SPACE_RADIUS


func release_lead(goose: FeltActor, llama: FeltActor) -> bool:
	_lead_started_apart = false
	return _lead_source_pending and goose != null and llama != null and llama.position.distance_to(goose.position) <= AnimalRelationshipsType.SHARE_SPACE_RADIUS


func has_pending_source() -> bool:
	return _lead_source_pending


func tick(delta: float, leading: bool, goose: FeltActor, llama: FeltActor, memory: Dictionary) -> Dictionary:
	if goose == null or llama == null:
		return {"remembered": false, "extend_linger": false}
	var safe_pair := llama._stands_on(llama.position) and goose._stands_on(goose.position)
	if leading and safe_pair and llama.position.distance_to(goose.position) > AnimalRelationshipsType.SHARE_SPACE_RADIUS:
		_lead_started_apart = true
	if leading and _lead_started_apart and safe_pair and llama.position.distance_to(goose.position) <= AnimalRelationshipsType.SHARE_SPACE_RADIUS:
		_lead_source_pending = true
		_lead_started_apart = false
	if _lead_source_pending and (not safe_pair or llama.position.distance_to(goose.position) > AnimalRelationshipsType.SHARE_SPACE_RADIUS):
		_lead_source_pending = false
		_calm_seconds = 0.0
	var next_memory := AnimalRelationshipsType.sanitize(memory)
	var remembered := false
	if not AnimalRelationshipsType.has_shared_space_memory(next_memory):
		if _lead_source_pending and not leading and safe_pair and AnimalRelationshipsType.calm_shared_space(goose, llama):
			_calm_seconds += delta
		else:
			_calm_seconds = 0.0
		if _calm_seconds >= AnimalRelationshipsType.CALM_RESOLVE_SECONDS:
			next_memory[AnimalRelationshipsType.GOOSE_LLAMA_SHARED_SPACE] = true
			_lead_source_pending = false
			_calm_seconds = 0.0
			_linger_cooldown = 42.0
			remembered = true
	if not AnimalRelationshipsType.has_shared_space_memory(next_memory):
		return {"remembered": remembered, "extend_linger": false}
	_linger_cooldown -= delta
	if _linger_cooldown > 0.0 or not safe_pair or not AnimalRelationshipsType.calm_shared_space(goose, llama):
		return {"remembered": remembered, "extend_linger": false}
	_linger_cooldown = 42.0
	return {"remembered": remembered, "extend_linger": AnimalRelationshipsType.should_linger(randf(), next_memory)}
