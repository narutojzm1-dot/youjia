extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/build_identity.json"))
	assert(source.sourceCommit == "c8d994fecf83195e2949820324c24520dec19302")
	var photo: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("C:/Users/Zengm/AppData/Local/Temp/youjia-round-20261017-0537/stove-contact-0-photo.json"))
	var raw := {"album":["fish_first_catch"],"photo_moments":{"fish_first_catch":photo}}
	var codec = load("res://scripts/persistence/save_data_codec.gd")
	var projected: Dictionary = codec.project(raw)
	var result := {"source":source,"before_records":raw.photo_moments.size(),"after_old_album_clean":projected.photo_moments.size(),"old_asset_available":ResourceLoader.exists("res://assets/holiday/characters/resident_stove_actions_v1/actions.png"),"cleaned":projected.photo_moments}
	FileAccess.open("C:/Users/Zengm/AppData/Local/Temp/youjia-round-20261017-0537/old-c8-photo-clean.json",FileAccess.WRITE).store_string(JSON.stringify(result))
	print("OLD_C8_PHOTO "+JSON.stringify(result))
	assert(result.before_records == 1 and result.after_old_album_clean == 0 and not result.old_asset_available)
	root.get_node("AudioDirector").call("release_streams")
	quit(0)
