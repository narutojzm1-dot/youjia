extends SceneTree
func _initialize() -> void:
	var codec = load("res://scripts/persistence/save_data_codec.gd")
	var photo: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("GARDEN_PHOTO")))
	var raw := {"album":["fish_first_catch"],"photo_moments":{"fish_first_catch":photo}}
	var result := {"new_asset_available":ResourceLoader.exists("res://assets/holiday/props/garden_v1/flower-garden-atlas-v1.png"),"before":1,"after_old_projection":codec.project(raw).photo_moments.size()}
	FileAccess.open(OS.get_environment("GARDEN_PROBE_RESULT"),FileAccess.WRITE).store_string(JSON.stringify(result))
	print("ACTUAL_15FC_PHOTO_PROBE "+JSON.stringify(result))
	quit()
