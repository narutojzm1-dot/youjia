extends RefCounted
## Read-only import of pre-#597 native preferences. New writes use SaveStore.

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
