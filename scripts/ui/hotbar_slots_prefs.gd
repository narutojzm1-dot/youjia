extends RefCounted
## #597：五格快捷栏的配置是界面偏好，单独存在 user://，不进游戏存档。
## 只记物品种类引用，读坏了或不认识就当空格；数量始终来自背篓库存。
## Web 包以 persistentPaths: [] 启动，user:// 刷新即丢；那里不写也不读，配置只留在本次打开，
## 不冒充已保存。跨刷新保留要并入共享存档（CODEX-LEAD，见 #597）。

const PATH := "user://hotbar_slots.cfg"
const SECTION := "hotbar"
const KEY := "slots"


static func persistent() -> bool:
	return not OS.has_feature("web") or OS.is_userfs_persistent()


static func load_slots() -> Array:
	if not persistent(): return []
	var file := ConfigFile.new()
	if file.load(PATH) != OK: return []
	var value: Variant = file.get_value(SECTION, KEY, [])
	return value if value is Array else []


static func save_slots(slots: Array) -> bool:
	if not persistent(): return false
	var file := ConfigFile.new()
	var plain: Array = []
	for kind in slots: plain.append(str(kind))
	file.set_value(SECTION, KEY, plain)
	return file.save(PATH) == OK
