class_name ExplorationRoutes
extends RefCounted
# 正式路线目录（纯数据）。首片只有用户 2026-10-04 选定的院门外近郊小路，
# 圆石、松果、落羽都可遇见。单趟合计最多带 3 件是用户 2026-10-05 的决定（同名可重复）；
# 停留点数量与出现权重仍是实验参数，不是冻结数值。

const NEAR_PATH := "formal.near_path"
const FIND_STONE := "formal.find.brook_stone"
const FIND_PINE_CONE := "formal.find.pine_cone"
const FIND_FEATHER := "formal.find.feather"
const FINDS := [FIND_STONE, FIND_PINE_CONE, FIND_FEATHER]

# 停留点按画卷从院门往外的顺序排列；彼此都可直接到达，经过但不停下看不算到过。
const ORDINARY_STOPS := ["gate", "brook", "shade", "slope"]
const VILLAGE_STOPS := ["village_entry", "village_stray", "village_lake"]
const NEAR_PATH_STOPS := ["gate", "brook", "shade", "slope", "leaf_pile"]


static func routes() -> Dictionary:
	var stops := {}
	var all_stops: Array = NEAR_PATH_STOPS + VILLAGE_STOPS
	for stop_id: String in all_stops:
		var next: Array = all_stops.duplicate()
		next.erase(stop_id)
		stops[stop_id] = {"next": next, "find_pool": [], "empty_weight": 1}
	# 四处都可能有东西，空手的权重让一趟常见 1–2 件；凑满 3 件之后还会遇到第 4 件（换不换由玩家）
	stops["gate"]["find_pool"] = [
		{"find_id": FIND_FEATHER, "weight": 1},
		{"find_id": FIND_STONE, "weight": 1},
	]
	stops["gate"]["empty_weight"] = 2
	stops["brook"]["find_pool"] = [
		{"find_id": FIND_STONE, "weight": 3},
		{"find_id": FIND_FEATHER, "weight": 1},
	]
	stops["shade"]["find_pool"] = [
		{"find_id": FIND_PINE_CONE, "weight": 3},
		{"find_id": FIND_FEATHER, "weight": 1},
	]
	stops["slope"]["find_pool"] = [
		{"find_id": FIND_PINE_CONE, "weight": 2},
		{"find_id": FIND_STONE, "weight": 1},
		{"find_id": FIND_FEATHER, "weight": 1},
	]
	# Extra discovery; ordinary solo stops keep their original pools and seeds.
	stops["leaf_pile"]["hidden"] = {"actor_id": "llama", "find_id": FIND_PINE_CONE}
	return {
		NEAR_PATH: {
			"start_stop": "gate",
			"carry_limit": 3,
			"return_stops": "any",
			"stops": stops,
		},
	}


static func catalog() -> ExplorationCatalog:
	return ExplorationCatalog.new(ExplorationContract.SOURCE_FORMAL, routes())


static func is_formal_find(find_id: String) -> bool:
	return FINDS.has(find_id)


static func find_name_key(find_id: String) -> String:
	return "exploration.find.%s" % find_id.get_slice(".", 2)
