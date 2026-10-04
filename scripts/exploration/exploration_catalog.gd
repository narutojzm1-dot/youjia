class_name ExplorationCatalog
extends RefCounted
# 路线定义的只读注册表（纯数据）。区分 formal 与 fixture 两个来源；
# 画面资源映射留在表现适配器，这里不含执行逻辑。

var source: String = ""
var errors := PackedStringArray()
var _routes: Dictionary = {}


func _init(catalog_source: String = ExplorationContract.SOURCE_FORMAL, routes: Dictionary = {}) -> void:
	source = catalog_source
	errors = ExplorationContract.validate_catalog(catalog_source, routes)
	if errors.is_empty():
		_routes = routes.duplicate(true)


func is_valid() -> bool:
	return errors.is_empty()


func has_route(route_id: String) -> bool:
	return _routes.has(route_id)


func route_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for route_id: String in _routes:
		ids.append(route_id)
	ids.sort()
	return ids


## 返回深拷贝，调用方修改不影响目录
func get_route(route_id: String) -> Dictionary:
	if not _routes.has(route_id):
		return {}
	return _routes[route_id].duplicate(true)


func has_stop(route_id: String, stop_id: String) -> bool:
	return _routes.has(route_id) and _routes[route_id]["stops"].has(stop_id)


func carry_limit(route_id: String) -> int:
	return int(_routes[route_id].get("carry_limit", 1))
