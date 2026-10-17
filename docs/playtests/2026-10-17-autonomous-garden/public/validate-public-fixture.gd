extends SceneTree
func _initialize() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("GARDEN_FIXTURE")))
	var budget := preload("res://scripts/game/growth_budget.gd").budget(data,"lunch")
	assert(budget.available == 3 and data.yard_inventory.wheat == 1 and data.keepsakes[ExplorationRoutes.FIND_FLOWER_SEEDS] == 2)
	assert(preload("res://scripts/game/yard_garden.gd").read(data).revision == 0)
	var projected: Dictionary = preload("res://scripts/persistence/save_data_codec.gd").project(data)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(projected.photo_moments.fish_first_catch))
	var differences := []
	for key: String in data.photo_moments.fish_first_catch:
		if saved.get(key) != data.photo_moments.fish_first_catch[key]: differences.append(key)
	print("PHOTO_DIAGNOSTIC "+JSON.stringify({"differences":differences,"projected":saved,"original":data.photo_moments.fish_first_catch}))
	if not same_photo(saved,data.photo_moments.fish_first_catch):
		quit(2)
		return
	print("PUBLIC_LEGAL_FIXTURE day4 lunch3AP seeds2 wheat1; actual old15fc photo intact")
	quit()

func same_photo(a: Variant,b: Variant) -> bool:
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not same_photo(a[key],b[key]): return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size(): return false
		for i: int in a.size():
			if not same_photo(a[i],b[i]): return false
		return true
	if (a is float or a is int) and (b is float or b is int):
		return absf(float(a)-float(b)) <= 0.000000000001
	return a == b
