extends RefCounted
# 探索核心隔离测试用的假路线。ID 统一 fixture. 前缀；位于 test/，不进正式包。


static func routes() -> Dictionary:
	return {
		"fixture.meadow": {
			"start_stop": "gate",
			"carry_limit": 2,
			"return_stops": "any",
			"stops": {
				"gate": {"next": ["brook"], "find_pool": [], "empty_weight": 1},
				"brook": {
					"next": ["gate", "ridge"],
					"find_pool": [{"find_id": "fixture.find.pebble", "weight": 1}],
					"empty_weight": 0,
				},
				"ridge": {
					"next": ["brook"],
					"find_pool": [{"find_id": "fixture.find.flower", "weight": 1}],
					"empty_weight": 0,
				},
			},
		},
		"fixture.gate_only": {
			"start_stop": "gate",
			"carry_limit": 1,
			"return_stops": ["gate"],
			"stops": {
				"gate": {"next": ["field"], "find_pool": [], "empty_weight": 1},
				"field": {
					"next": ["gate"],
					"find_pool": [
						{"find_id": "fixture.find.feather", "weight": 3},
						{"find_id": "fixture.find.acorn", "weight": 2},
					],
					"empty_weight": 1,
				},
			},
		},
	}


static func catalog() -> ExplorationCatalog:
	return ExplorationCatalog.new(ExplorationContract.SOURCE_FIXTURE, routes())


## 模拟“正式目录”：只在测试里构造，用来验证夹具闸门与正式路径
static func formal_catalog() -> ExplorationCatalog:
	return ExplorationCatalog.new(ExplorationContract.SOURCE_FORMAL, {
		"formal.test_walk": {
			"start_stop": "gate",
			"carry_limit": 1,
			"return_stops": "any",
			"stops": {
				"gate": {"next": ["pond"], "find_pool": [], "empty_weight": 1},
				"pond": {"next": ["gate"], "find_pool": [{"find_id": "formal.find.reed", "weight": 1}], "empty_weight": 0},
			},
		},
	})
