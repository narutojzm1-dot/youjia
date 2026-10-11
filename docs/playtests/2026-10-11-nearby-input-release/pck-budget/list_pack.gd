extends SceneTree

const PACK := "D:/games/youjia-test/assistant-recovery/nearby-public-inputc282-release/game-c28246f.pck"
const OUTPUT := "D:/games/youjia-test/assistant-recovery/pck-budget-c282/result.json"
var rows: Array[Dictionary] = []

func _walk(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("Cannot inspect pack directory " + path)
		quit(1)
		return
	dir.include_hidden = true
	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		if name != "." and name != "..":
			var child := path.path_join(name)
			if dir.current_is_dir():
				_walk(child)
			elif child not in ["res://project.godot", "res://list_pack.gd"]:
				var file := FileAccess.open(child, FileAccess.READ)
				if file != null:
					rows.append({"path": child, "bytes": file.get_length()})
					file.close()
		name = dir.get_next()
	dir.list_dir_end()

func _init() -> void:
	if not ProjectSettings.load_resource_pack(PACK, false):
		push_error("Cannot mount actual verified public pack")
		quit(1)
		return
	_walk("res://")
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.bytes) > int(b.bytes))
	var output := FileAccess.open(OUTPUT, FileAccess.WRITE)
	if output == null:
		quit(1)
		return
	output.store_string(JSON.stringify({"source": "c28246f14dd8bca837624699ca9447124e39d0d1", "pack": PACK, "method": "Godot readonly mounted virtual filesystem, no production project/autoload instantiated; probe project.godot and list_pack.gd excluded", "entries": rows}, "\t") + "\n")
	output.close()
	print("PUBLIC_PACK_BUDGET files=", rows.size(), " readonly=true")
	quit(0)
