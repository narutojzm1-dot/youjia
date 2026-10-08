extends RefCounted
## REQ-20261008-075（Owner GROK-CONTRIBUTOR）：手持食物 / 可摆小物的「选中后点地」意图解析。
## 只做纯函数判定，不读写存档、不扣数量。合法时返回可交给既有事务的参数：
##   食物 → YardInventoryController.request("drop", kind, {x,y})
##   小物 → YardDecorController.request("place", spot, {find_id,dx,dy})
## 非法 / 空手 / 占满 → {"error": …}，调用方不得发 request（取消与失败不扣数）。

const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Decor := preload("res://scripts/inventory/yard_decor.gd")

## 点地落鱼 / 草 / 小米：落点必须在可走草坪上，且脚下有空位。不改 held，不发信号。
static func food_drop_at(held: String, point: Vector2, obstacles: Array = []) -> Dictionary:
	if held.is_empty():
		return {"error": "EMPTY_HAND"}
	if held not in Inventory.FOOD:
		return {"error": "BASKET_INVALID"}
	if not _finite_point(point):
		return {"error": "BASKET_INVALID"}
	if not YardGround.allows(point, YardGround.lawn(), true):
		return {"error": "ILLEGAL_SPOT"}
	if not YardBodies.clear_at(point, Vector2(12, 6), obstacles):
		return {"error": "ILLEGAL_SPOT"}
	return {
		"action": "drop",
		"kind": held,
		"details": {"x": float(point.x), "y": float(point.y)},
	}


## 与 YardGroundFood.drop_held 相同的近身候选：面向前方优先。仍不扣数。
static func food_drop_near_player(held: String, player_position: Vector2, facing: float, obstacles: Array = []) -> Dictionary:
	if held.is_empty():
		return {"error": "EMPTY_HAND"}
	for offset: Vector2 in [Vector2(30.0 * facing, 8.0), Vector2(-30.0 * facing, 8.0), Vector2(0.0, 22.0), Vector2(0.0, -22.0)]:
		var point: Vector2 = player_position + offset
		var result := food_drop_at(held, point, obstacles)
		if not result.has("error"):
			return result
	return {"error": "ILLEGAL_SPOT"}


## 可摆小物：点地落到最近的空固定摆放处（屋前 / 篱边 / 塘边小路），偏移默认 0。
## available 是 SaveStore.get_available_keepsakes()（已扣掉已摆数量）；decor 是 yard_decor 视图。
static func decor_place_at(find_id: String, point: Vector2, decor: Dictionary, available: Dictionary, max_distance: float = 72.0) -> Dictionary:
	if not ExplorationRoutes.is_formal_find(find_id):
		return {"error": "DECOR_INVALID"}
	if int(available.get(find_id, 0)) <= 0:
		return {"error": "DECOR_EMPTY"}
	if not _finite_point(point):
		return {"error": "DECOR_INVALID"}
	var places: Dictionary = decor.get("places", {}) if decor is Dictionary else {}
	var best_spot := ""
	var best_dist := max_distance
	for spot: String in Decor.SPOTS:
		if places.has(spot):
			continue
		var at: Vector2 = Decor.SPOTS[spot]
		var dist := point.distance_to(at)
		if dist < best_dist:
			best_dist = dist
			best_spot = spot
	if best_spot.is_empty():
		return {"error": "DECOR_OCCUPIED" if places.size() >= Decor.SPOTS.size() else "ILLEGAL_SPOT"}
	return {
		"action": "place",
		"spot": best_spot,
		"details": {"find_id": find_id, "dx": 0, "dy": 0},
	}


## 用既有 Inventory.transition 证明：只有合法 drop 才推进 revision；非法细节不改快照。
static func would_commit_food_drop(snapshot: Dictionary, held: String, point: Vector2, obstacles: Array = []) -> Dictionary:
	var intent := food_drop_at(held, point, obstacles)
	if intent.has("error"):
		return intent
	var inventory := Inventory.read(snapshot)
	if inventory.is_empty():
		return {"error": "BASKET_INVALID"}
	return Inventory.transition(snapshot, int(inventory.revision), "drop", held, intent.details)


static func _finite_point(point: Vector2) -> bool:
	return is_finite(point.x) and is_finite(point.y) and point.x >= 0.0 and point.y >= 0.0 and point.x <= 1000000.0 and point.y <= 1000000.0
