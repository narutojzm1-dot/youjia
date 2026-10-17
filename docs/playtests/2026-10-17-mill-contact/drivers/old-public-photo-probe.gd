extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
	assert(not isolated.is_empty() and OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated.trim_suffix("/")+"/"))
	var identity: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/build_identity.json"))
	assert(identity.sourceCommit == "24c9dd33cb32934ff3727492fb561fe86bcdfdd7")
	var photo: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("YOUJIA_MILL_PHOTO")))
	var codec = load("res://scripts/persistence/save_data_codec.gd")
	var raw := {"album":["fish_first_catch"],"photo_moments":{"fish_first_catch":photo}}
	var projected: Dictionary = codec.project(raw)
	var kept: Dictionary = projected.get("photo_moments",{}).get("fish_first_catch",{})
	assert(JSON.parse_string(JSON.stringify(kept)) == photo)
	var invalid := photo.duplicate(true)
	invalid.items[0].texture = {"path":"res://assets/holiday/characters/unavailable_mill_negative.png"}
	var negative: Dictionary = codec.project({"album":["fish_first_catch"],"photo_moments":{"fish_first_catch":invalid}})
	assert(negative.get("photo_moments",{}).is_empty())
	var result := {"old_public_source":identity.sourceCommit,"photo_items":photo.items.size(),"all_fields_retained":true,"unknown_texture_negative_dropped":true,"pack_contains_new_mill_script":ResourceLoader.exists("res://scripts/entities/resident_mill_pose.gd")}
	assert(not result.pack_contains_new_mill_script)
	FileAccess.open(OS.get_environment("YOUJIA_OLD_PHOTO_RESULT"),FileAccess.WRITE).store_string(JSON.stringify(result))
	print("OLD_PUBLIC_MILL_PHOTO "+JSON.stringify(result))
	root.get_node("AudioDirector").call("release_streams")
	quit(0)
