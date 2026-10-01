class_name ExpressionCatalog
extends RefCounted

const RULES := [
	{
		"id": "llama_overcast_goose_annoyed",
		"owner": "llama",
		"priority": 90,
		"weather": "overcast",
		"nearby": ["goose"],
		"expression": "annoyed",
		"hold": 6.0,
		"polaroid": true,
		"observe_nearby": true,
		"spit": true,
		"title_key": "photo.llama_annoyed.title",
		"note_key": "photo.llama_annoyed.note",
	},
	{
		"id": "llama_sun_sheep_happy",
		"owner": "llama",
		"priority": 85,
		"weather": "sun",
		"nearby": ["sheep"],
		"not_nearby": ["goose"],
		"expression": "happy",
		"hold": 6.5,
		"polaroid": true,
		"observe_nearby": true,
		"spit": false,
		"title_key": "photo.llama_happy.title",
		"note_key": "photo.llama_happy.note",
	},
	{
		"id": "llama_sheep_cow_smirk",
		"owner": "llama",
		"priority": 65,
		# Historical ID is retained for existing collected-photo saves.
		"same_zone": ["cow", "horse"],
		"zone": "pasture",
		"sees": true,
		"expression": "smirk",
		"hold": 7.0,
		"polaroid": true,
		"observe_nearby": true,
		"spit": false,
		"title_key": "photo.llama_smirk.title",
		"note_key": "photo.llama_smirk.note",
	},
	{
		"id": "llama_fed_gentle",
		"owner": "llama",
		"priority": 100,
		"player": "just_fed",
		"expression": "happy",
		"hold": 4.0,
		"polaroid": true,
		"observe_nearby": true,
		"spit": false,
		"title_key": "photo.llama_fed.title",
		"note_key": "photo.llama_fed.note",
	},
	{
		"id": "goose_overcast_patrol",
		"owner": "goose",
		"priority": 40,
		"weather": "overcast",
		"expression": "idle",
		"hold": 3.0,
		"polaroid": false,
		"spit": false,
		"title_key": "",
		"note_key": "",
	},
	{
		"id": "duck_pond_chorus",
		"owner": "duck",
		"priority": 35,
		"zone": "pond",
		"expression": "idle",
		"hold": 4.0,
		"polaroid": true,
		"observe_nearby": true,
		"spit": false,
		"title_key": "photo.duck.title",
		"note_key": "photo.duck.note",
	},
	{
		"id": "cow_rare_calm",
		"owner": "cow",
		"priority": 30,
		"weather": "sun",
		"zone": "pasture",
		"expression": "idle",
		"hold": 8.0,
		"polaroid": true,
		"observe_nearby": true,
		"spit": false,
		"title_key": "photo.cow.title",
		"note_key": "photo.cow.note",
	},
]


static func all_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for rule: Dictionary in RULES:
		if bool(rule.get("polaroid", false)):
			ids.append(str(rule.get("id", "")))
	return ids


static func llama_mainline_ids() -> PackedStringArray:
	return PackedStringArray([
		"llama_overcast_goose_annoyed",
		"llama_sun_sheep_happy",
		"llama_sheep_cow_smirk",
		"llama_fed_gentle",
	])


static func find_rule(rule_id: String) -> Dictionary:
	for rule: Dictionary in RULES:
		if str(rule.get("id", "")) == rule_id:
			return rule
	return {}
