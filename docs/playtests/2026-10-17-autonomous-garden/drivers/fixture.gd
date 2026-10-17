extends SceneTree
func _initialize() -> void:
	var d := preload("res://scripts/persistence/save_data_codec.gd").defaults()
	d.holiday_day_elapsed = 160.0
	d.tutorial_version = 1
	d.yard_gate_open = true
	d.resident_rest = {"schema":1,"day":1,"cause":"sleep"}
	var inventory := preload("res://scripts/inventory/yard_inventory.gd").empty()
	inventory.wheat = 2
	d.yard_inventory = inventory
	d.yard_crops = preload("res://scripts/game/yard_crops.gd").empty()
	d.keepsakes = {ExplorationRoutes.FIND_FLOWER_SEEDS:2}
	d = preload("res://scripts/game/meal_ledger.gd").complete(d,0,0,1,"lunch",{"wheat":1},false).candidate
	assert(preload("res://scripts/game/growth_budget.gd").budget(d,"lunch").available == 3)
	FileAccess.open(OS.get_environment("GARDEN_FIXTURE"),FileAccess.WRITE).store_string(JSON.stringify(d))
	print("LEGAL_GARDEN_FIXTURE budget3 wheat1 seeds2, no garden; controlled QA start only")
	quit()
