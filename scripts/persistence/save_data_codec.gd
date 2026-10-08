extends RefCounted
## Business read projection shared by SaveStore and future migration.
## No I/O and no mutation of the source Dictionary. This is NOT validation of
## migration versions, a lossless archive, or permission to replace raw sources.

const AnimalRelationshipsType := preload("res://scripts/game/animal_relationships.gd")
const SAVE_VERSION := 5
const TUTORIAL_VERSION := 1
const ExplorationContractType := preload("res://scripts/exploration/exploration_contract.gd")
const MAX_KEEPSAKE_COUNT := 9999
const WorldWeather := preload("res://scripts/game/world_weather.gd")

static func defaults() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"locale": "zh-CN",
		"tutorial_version": 0,
		"album": [],
		"photo_moments": {},
		# 假期天数系统（v4 兼容新增字段）
		"holiday_day": 1,
		"holiday_day_elapsed": 0.0,
		"world_weather": {},
		"yard_gate_open": false,
		# 植物床状态（0=空, 1=已种, 2=发芽, 3=开花）
		"plant_state": 0,
		"plant_day_planted": 0,
		"plant_watered_day": -1,
		# 钓鱼记录
		"first_fish_caught": false,
		"animal_relationship_memory": {},
		# 探索：原样保存的会话记录（由 ExplorationSession.restore 校验）、已提交旅程水位线、带回的小物计数
		"exploration": null,
		"exploration_committed_serial": 0,
		"keepsakes": {},
	}


static func project(candidate: Dictionary) -> Dictionary:
	var data := defaults()
	var locale := str(candidate.get("locale", "zh-CN"))
	data.locale = locale if locale in ["en", "zh-CN"] else "zh-CN"
	data.tutorial_version = clampi(int(candidate.get("tutorial_version", 0)), 0, TUTORIAL_VERSION)
	var album: Array = []
	var raw: Variant = candidate.get("album", [])
	if raw is Array:
		for item: Variant in raw:
			var photo_id := str(item)
			if not photo_id.is_empty() and photo_id not in album:
				album.append(photo_id)
	data.album = album
	data.photo_moments = clean_moments(candidate.get("photo_moments",{}),album)
	# 读取假期进度（旧存档没有这些字段时用默认值）
	data.holiday_day = maxi(1, int(candidate.get("holiday_day", 1)))
	data.holiday_day_elapsed = maxf(0.0, float(candidate.get("holiday_day_elapsed", 0.0)))
	data.yard_gate_open = candidate.get("yard_gate_open", false) is bool and candidate.get("yard_gate_open", false) == true
	data.world_weather = WorldWeather.sanitize(candidate.get("world_weather", {}))
	data.plant_state = clampi(int(candidate.get("plant_state", 0)), 0, 3)
	data.plant_day_planted = maxi(0, int(candidate.get("plant_day_planted", 0)))
	data.plant_watered_day = int(candidate.get("plant_watered_day", -1))
	data.first_fish_caught = bool(candidate.get("first_fish_caught", false))
	data.animal_relationship_memory = AnimalRelationshipsType.sanitize(candidate.get("animal_relationship_memory", {}))
	var exploration: Variant = candidate.get("exploration", null)
	data.exploration = exploration.duplicate(true) if exploration is Dictionary or exploration is Array else exploration
	data.exploration_committed_serial = committed_serial(candidate)
	data.keepsakes = clean_keepsakes(candidate.get("keepsakes", {}))

	return data


## 缺字段视为从未提交（0）；字段存在但损坏时返回 -1，让探索核心把水位线当作不可信。
static func committed_serial(candidate: Dictionary) -> int:
	if not candidate.has("exploration_committed_serial"):
		return 0
	var serial: Variant = ExplorationContractType.as_int(candidate.exploration_committed_serial)
	return -1 if serial == null else int(serial)


static func clean_keepsakes(raw: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not raw is Dictionary: return result
	for find_id: Variant in raw:
		if not find_id is String or not ExplorationRoutes.is_formal_find(find_id): continue
		var count: Variant = ExplorationContractType.as_int(raw[find_id], 1, MAX_KEEPSAKE_COUNT)
		if count != null:
			result[find_id] = int(count)
	return result


static func clean_moments(raw: Variant, album: Array) -> Dictionary:
	var result: Dictionary = {}
	if not raw is Dictionary: return result
	for photo_id: Variant in raw:
		if not photo_id is String or photo_id not in album or photo_id not in ExpressionCatalog.all_ids(): continue
		var moment := PhotoMoment.sanitize(raw[photo_id])
		if not moment.is_empty() and str(moment.get("rule_id","")) == photo_id:
			result[photo_id] = moment
	return result
