extends SceneTree
func _initialize() -> void:
	var identity: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/build_identity.json"))
	assert(identity.sourceCommit == OS.get_environment("GARDEN_EXPECTED_SOURCE"))
	var notes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/release_notes.json"))
	assert(notes.releases[0].title == "从花种开始的小花畦")
	assert(ResourceLoader.exists("res://assets/holiday/props/garden_v1/flower-garden-atlas-v1.png"))
	var photo: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("GARDEN_PHOTO")))
	var codec = load("res://scripts/persistence/save_data_codec.gd")
	var projected: Dictionary = codec.project({"album":["fish_first_catch"],"photo_moments":{"fish_first_catch":photo}})
	var cleaned: Dictionary = projected.photo_moments.get("fish_first_catch",{})
	# GDScript Dictionary equality hashes int and JSON float keys/values
	# differently inside nested records. Compare the actual JSON boundary.
	var serialized: Dictionary = JSON.parse_string(JSON.stringify(cleaned))
	var differences := []
	for key: String in photo:
		if serialized.get(key) != photo[key]: differences.append(key)
	var bad := []
	var moment = load("res://scripts/ui/photo_moment.gd")
	for item: Dictionary in photo.items:
		if moment._sanitize_item(item).is_empty(): bad.append(item.get("texture",{"subject":item.subject}))
	var result := {"identity":identity,"title":notes.releases[0].title,"actual_pack":true,"new_atlas_available":true,"all_photo_fields_retained":serialized == photo,"json_number_boundary_normalized":true,"differences":differences,"invalid_items":bad,"cleaned_count":cleaned.size()}
	FileAccess.open(OS.get_environment("GARDEN_PACK_RESULT"),FileAccess.WRITE).store_string(JSON.stringify(result))
	print("GARDEN_PACK_IDENTITY "+JSON.stringify(result))
	quit()
