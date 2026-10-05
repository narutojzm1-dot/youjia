extends RefCounted
## Business read projection shared by SaveStore and future migration.
## No I/O and no mutation of the source Dictionary. This is NOT validation of
## migration versions, a lossless archive, or permission to replace raw sources.

const AnimalRelationshipsType := preload("res://scripts/game/animal_relationships.gd")
const SAVE_VERSION := 5
const TUTORIAL_VERSION := 1

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
		# 植物床状态（0=空, 1=已种, 2=发芽, 3=开花）
		"plant_state": 0,
		"plant_day_planted": 0,
		"plant_watered_day": -1,
		# 钓鱼记录
		"first_fish_caught": false,
		"animal_relationship_memory": {},
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
	data.plant_state = clampi(int(candidate.get("plant_state", 0)), 0, 3)
	data.plant_day_planted = maxi(0, int(candidate.get("plant_day_planted", 0)))
	data.plant_watered_day = int(candidate.get("plant_watered_day", -1))
	data.first_fish_caught = bool(candidate.get("first_fish_caught", false))
	data.animal_relationship_memory = AnimalRelationshipsType.sanitize(candidate.get("animal_relationship_memory", {}))

	return data


static func clean_moments(raw: Variant, album: Array) -> Dictionary:
	var result: Dictionary = {}
	if not raw is Dictionary: return result
	for photo_id: Variant in raw:
		if not photo_id is String or photo_id not in album or photo_id not in ExpressionCatalog.all_ids(): continue
		var moment := PhotoMoment.sanitize(raw[photo_id])
		if not moment.is_empty() and str(moment.get("rule_id","")) == photo_id:
			result[photo_id] = moment
	return result
