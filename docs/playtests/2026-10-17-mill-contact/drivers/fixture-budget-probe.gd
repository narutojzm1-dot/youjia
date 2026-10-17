extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var identity: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/build_identity.json"))
	assert(identity.sourceCommit == "24c9dd33cb32934ff3727492fb561fe86bcdfdd7")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("YOUJIA_FIXTURE_INPUT")))
	var period: String = load("res://scripts/game/growth_schedule.gd").period(float(data.holiday_day_elapsed)/600.0)
	var budget: Dictionary = load("res://scripts/game/growth_budget.gd").budget(data,period)
	assert(period == "lunch" and not budget.has("error") and budget.available == 3)
	assert(data.growth_production.schema == 2 and data.yard_stove.revision == 3)
	assert(not PhotoMoment.sanitize(data.photo_moments.fish_first_catch).is_empty())
	print("ACTUAL_OLD_BUDGET_FIXTURE "+JSON.stringify({"source":identity.sourceCommit,"period":period,"available":budget.available,"day":budget.day,"photo_items":data.photo_moments.fish_first_catch.items.size()}))
	root.get_node("AudioDirector").call("release_streams")
	quit(0)
