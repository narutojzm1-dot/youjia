extends SceneTree
## Production flour -> ordinary house cooking -> durable meal; isolated native data.
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Meals := preload("res://scripts/game/meal_ledger.gd")
const Planner := preload("res://scripts/game/meal_planner.gd")
const Schedule := preload("res://scripts/game/meal_schedule.gd")
const Budget := preload("res://scripts/game/growth_budget.gd")
const Materials := preload("res://scripts/game/growth_materials.gd")
const Production := preload("res://scripts/game/growth_production.gd")
const Basket := preload("res://scripts/game/physical_basket.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func milled() -> Dictionary:
	var inv := Inventory.empty()
	inv.millet = 1
	inv.wheat = 2
	var state := {"version":5,"holiday_day":4,"holiday_day_elapsed":175.0,
		"resident_rest":{"schema":1,"day":4,"cause":"sleep"},Inventory.FIELD:inv}
	state = Meals.complete(state,0,0,4,"breakfast",{"millet":1},false).candidate
	var plan := Materials.plan(state,{"wheat":{"id":"mill_wheat","materials":{"wheat":1}}},RandomNumberGenerator.new())
	return Budget.complete_milling(state,Budget.budget(state,"breakfast"),plan,{"ap":1,"wheat":1,"flour":1,"experience":1}).candidate

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated.trim_suffix("/")+"/"):
		quit(2)
		return
	var source := milled()
	check(source.yard_inventory.flour == 1 and source.yard_inventory.wheat == 1,"milling yields flour while preserving last seed")
	var rng := RandomNumberGenerator.new()
	rng.seed = 9182
	var plan := Planner.plan(source,"lunch",Schedule.recipes_for("lunch"),rng)
	check(plan.primary == "flour" and plan.recipe_id == "wheat_noodles" and plan.ingredients == {"flour":1},"no raw wheat fallback: available flour makes noodles")
	check(Schedule.recipes_for("dinner").flour.id == "steamed_bun","evening flour recipe is steamed buns")
	check(Schedule.recipes_for("breakfast").flour.id == "steamed_bun","morning flour recipe is steamed buns")
	check(not Schedule.RECIPES.has("flour") and not Schedule.recipes_for("").has("flour"),"returned catalog cannot mutate original or enable an invalid meal")
	var none := source.duplicate(true)
	none.yard_inventory.flour = 0
	check(Planner.plan(none,"lunch",Schedule.recipes_for("lunch"),rng).is_empty(),"no flour cannot eat the reserved raw seed")
	var cooked := Meals.complete(source,plan.revision,plan.inventory_revision,4,"lunch",plan.ingredients,false)
	check(not cooked.has("error") and cooked.candidate.yard_inventory.flour == 0,"last flour portion can be eaten without seed reservation")
	check(Production.read(cooked.candidate) == Production.read(source) and cooked.candidate.yard_inventory.production_revision == 1,"cooking retains milling receipt and paired inventory anchor")
	check(Budget.budget(cooked.candidate,"lunch").available == 3,"meal grants lunch points without refunding morning milling AP")
	check(Meals.complete(cooked.candidate,plan.revision,plan.inventory_revision,4,"lunch",plan.ingredients,false).error == "MEAL_ALREADY_COMPLETED","replayed flour meal cannot spend or grant twice")
	var grid: Control = load("res://scripts/ui/yard_basket_grid.gd").new()
	root.add_child(grid)
	await process_frame
	for locale: String in ["zh-CN","en"]:
		root.get_node("I18n").set_locale(locale)
		grid.update_view(source.yard_inventory,{},"ready",false)
		grid.open_menu("flour")
		check(grid.counts.flour == 1 and grid.icons.flour.texture != null,"flour has own count and image " + locale)
		check(grid.menu_action.disabled and not grid.menu_hotbar.visible and grid.action_for("flour")[0] == "","pantry flour cannot emit withdraw/place/hotbar actions " + locale)
	grid.free()
	root.get_node("I18n").set_locale("zh-CN")
	var store = root.get_node("SaveStore")
	source.holiday_day_elapsed = 160.0 # noon in the existing 600-second day
	store.request_patch("flour-meal-fixture",source)
	check(await store.flush_pending(),"production flour fixture saved to real isolated NativeSaveHost")
	var world: Node2D = load("res://scripts/game/yard_world.gd").new()
	world.setup([],{},4,160.0)
	root.add_child(world)
	await process_frame
	world.simulation_active = true
	world.input_enabled = true
	world.pond_growth.autonomous_enabled = false
	world.get_player().position = Basket.APPROACH
	world.house.take_from_basket()
	check(world.house.stage == "take" and world.house.cooking_plan.get("primary", "") == "flour","actual house director picks the available flour from physical basket")
	check(world.house.meal_ingredient.visible and world.house.meal_ingredient.texture.resource_path.ends_with("flour-pouch-v1.png"),"flour uses its pouch in the hand, never a fish fallback")
	var saw_cook := false
	var correct_cook_hint := true
	for frame in 2400:
		world.tick(1.0/30.0,Vector2.ZERO)
		if world.house.stage == "cook":
			saw_cook = true
			correct_cook_hint = correct_cook_hint and world.house.meal_hint() == "notice.meal.noodles"
		if store.get_meal_ledger().receipts.size() == 2 and not world.house.owns_actor(): break
		if frame % 15 == 0: await process_frame
	check(saw_cook and world.house.stage.is_empty(),"normal house entry, cooking and return completed")
	check(saw_cook and correct_cook_hint,"actual cooking hint consistently identifies the flour recipe")
	check(await store.flush_pending(),"flour meal and progress flushed")
	check(store.get_yard_inventory().flour == 0 and store.get_yard_inventory().wheat == 1,"actual director atomically consumes flour and preserves last seed")
	check(store.get_meal_ledger().receipts.size() == 2 and store.get_growth_production().revision == 1,"meal receipt added once without changing milling history")
	var disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(store.SAVE_PATH))
	check(Inventory.read(disk).flour == 0 and Meals.read(disk).receipts.size() == 2,"real saved file contains completed flour meal")
	world.free()
	store._load()
	check(store.plan_meal("lunch",Schedule.recipes_for("lunch"),rng).is_empty() and store.get_yard_inventory().flour == 0,"reopen cannot eat flour or grant lunch a second time")
	for failure in failures: push_error(failure)
	print("FLOUR_MEAL checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
