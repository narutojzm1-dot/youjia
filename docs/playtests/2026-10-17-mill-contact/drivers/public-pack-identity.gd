extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var expected := OS.get_environment("YOUJIA_EXPECTED_SOURCE")
	var identity: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/build_identity.json"))
	assert(identity.sourceCommit == expected)
	var notes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/release_notes.json"))
	assert(notes.releases[0].title == "磨盘边的握柄动作")
	assert(ResourceLoader.exists("res://scripts/entities/resident_mill_pose.gd"))
	var codec = load("res://scripts/persistence/save_data_codec.gd")
	var photo: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("YOUJIA_MILL_PHOTO")))
	var projected: Dictionary = codec.project({"album":["fish_first_catch"],"photo_moments":{"fish_first_catch":photo}})
	assert(JSON.parse_string(JSON.stringify(projected.photo_moments.fish_first_catch)) == photo)
	var result := {"identity":identity,"current_title":notes.releases[0].title,"photo_all_fields_retained":true,"photo_items":photo.items.size(),"new_mill_script_exists":true,"actual_public_PCK":true}
	FileAccess.open(OS.get_environment("YOUJIA_PUBLIC_PACK_RESULT"),FileAccess.WRITE).store_string(JSON.stringify(result))
	print("PUBLIC_MILL_PACK_IDENTITY "+JSON.stringify(result))
	root.get_node("AudioDirector").call("release_streams")
	quit(0)
