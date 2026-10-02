class_name ExpressionCatalog
extends RefCounted

const RULES := [
	# ── 草泥马主线（4张）────────────────────────────────────────────────────────
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
		# 需要在第3天之后才解锁，让玩家先理解游戏再收集
		"min_day": 3,
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
		"caption_variants": 2,
	},
	# ── 其他动物（非主线）────────────────────────────────────────────────────────
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
		# 第2天后才解锁，避免第一次进院子就全部集齐
		"min_day": 2,
		"title_key": "photo.duck.title",
		"note_key": "photo.duck.note",
		"caption_variants": 2,
	},
	{
		"id": "goose_pond_rest",
		"owner": "goose",
		"priority": 46,
		"owner_posture": "rest",
		"min_day": 2,
		"expression": "idle",
		"hold": 3.0,
		"polaroid": true,
		"observe_nearby": true,
		"title_key": "photo.goose_rest.title",
		"note_key": "photo.goose_rest.note",
		"caption_variants": 3,
	},
	{
		"id": "goose_duck_shore",
		"owner": "goose",
		"priority": 41,
		"nearby": ["duck"],
		"observe_species": "duck",
		"min_day": 3,
		"expression": "idle",
		"hold": 3.0,
		"polaroid": true,
		"observe_nearby": true,
		"title_key": "photo.goose_duck.title",
		"note_key": "photo.goose_duck.note",
		"caption_variants": 3,
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
		# 第2天后才解锁
		"min_day": 2,
		"title_key": "photo.cow.title",
		"note_key": "photo.cow.note",
		"caption_variants": 2,
	},
	# ── 新增：抚摸羊（玩家触碰后由表情脉冲抓拍）──────────────────────────────────
	{
		"id": "sheep_pet_gentle",
		"owner": "sheep",
		"priority": 55,
		"player": "just_petted",
		"expression": "idle",
		"hold": 3.0,
		"polaroid": true,
		"observe_nearby": true,
		"spit": false,
		"title_key": "photo.sheep_pet.title",
		"note_key": "photo.sheep_pet.note",
	},
	{
		"id": "sheep_pair_near",
		"owner": "sheep",
		"priority": 36,
		"nearby": ["sheep"],
		"min_day": 2,
		"expression": "idle",
		"hold": 3.0,
		"polaroid": true,
		"observe_nearby": true,
		"title_key": "photo.sheep_pair.title",
		"note_key": "photo.sheep_pair.note",
		"caption_variants": 3,
	},
	# ── 新增：抚摸牛（第2天后解锁）──────────────────────────────────────────────
	{
		"id": "cow_pet_gentle",
		"owner": "cow",
		"priority": 52,
		"player": "just_petted",
		"expression": "idle",
		"hold": 4.0,
		"polaroid": true,
		"observe_nearby": true,
		"spit": false,
		"min_day": 2,
		"title_key": "photo.cow_pet.title",
		"note_key": "photo.cow_pet.note",
	},
	# ── 新增：抚摸马（第3天后解锁，搭配晴天）────────────────────────────────────
	{
		"id": "horse_pet_sunny",
		"owner": "horse",
		"priority": 48,
		"player": "just_petted",
		"weather": "sun",
		"expression": "idle",
		"hold": 4.5,
		"polaroid": true,
		"observe_nearby": true,
		"spit": false,
		"min_day": 3,
		"title_key": "photo.horse_pet.title",
		"note_key": "photo.horse_pet.note",
		"caption_variants": 2,
	},
	# ── 新增：植物开花（手动触发，manual_only 防止自动匹配）─────────────────────
	{
		"id": "plant_first_bloom",
		"owner": "duck",
		"priority": 50,
		"expression": "idle",
		"hold": 4.0,
		"polaroid": true,
		"manual_only": true,
		"title_key": "photo.plant_bloom.title",
		"note_key": "photo.plant_bloom.note",
	},
	# ── 新增：第一次钓到鱼（手动触发）────────────────────────────────────────────
	{
		"id": "fish_first_catch",
		"owner": "goose",
		"priority": 50,
		"expression": "idle",
		"hold": 4.0,
		"polaroid": true,
		"manual_only": true,
		"title_key": "photo.fish_catch.title",
		"note_key": "photo.fish_catch.note",
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
