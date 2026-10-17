extends "res://test/stove_pose_suite.gd"
func capture(label: String) -> void:
	var photo := PhotoMoment.capture(world,{"id":"fish_first_catch"})
	FileAccess.open("C:/Users/Zengm/AppData/Local/Temp/youjia-round-20261017-0537/"+label+"-photo.json",FileAccess.WRITE).store_string(JSON.stringify(photo))
	var restored := PhotoMoment.sanitize(JSON.parse_string(JSON.stringify(photo)))
	assert(not restored.is_empty())
	var found := false
	for item: Dictionary in restored.items:
		if item.get("texture",{}).get("atlas","").contains("resident_stove_actions_v1"):
			found = true
			print("STOVE_PHOTO "+JSON.stringify({"stage":label,"frozen_texture":item.texture}))
	assert(found)
	await super.capture(label)
