extends SceneTree
## Capture real director stages, then round-trip and replay the frozen record.
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Meals := preload("res://scripts/game/meal_ledger.gd")
const Budget := preload("res://scripts/game/growth_budget.gd")
const Production := preload("res://scripts/game/growth_production.gd")
const Schedule := preload("res://scripts/game/growth_schedule.gd")
const Basket := preload("res://scripts/game/physical_basket.gd")
const Mill := preload("res://scripts/game/yard_mill_view.gd")
var checks := 0
var failures: Array[String] = []
var store: Node
var world: Node2D

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func items_with_texture(photo: Dictionary, descriptor: Dictionary) -> Array:
	return photo.get("items",[]).filter(func(item: Dictionary): return item.get("texture",{}) == descriptor)

func verify_carried_photos(sprite: Sprite2D, label: String) -> void:
	check(sprite.is_visible_in_tree(),"real carry visible " + label)
	var texture := PhotoMoment._texture_data(sprite.texture)
	check(not texture.is_empty(),"carried texture is serializable " + label)
	var saved: Dictionary = store._data.duplicate(true)
	for rule: String in ["llama_sun_sheep_happy","fish_first_catch"]:
		var with_player := rule == "fish_first_catch"
		var captured := PhotoMoment.capture(world,{"id":rule})
		check(not captured.is_empty(),"real action photograph " + label + ":" + rule)
		var carried := items_with_texture(captured,texture)
		check(carried.size() == (1 if with_player else 0),"carry follows existing player inclusion " + label + ":" + rule)
		if with_player: check(carried[0].subject == "player","temporary prop belongs to player " + label)
		check(not items_with_texture(captured,{"path":Mill.ART.resource_path}).is_empty(),"fixed mill is not tagged as carried " + label + ":" + rule)
		var frozen: Dictionary = PhotoMoment.sanitize(JSON.parse_string(JSON.stringify(captured)))
		check(not frozen.is_empty() and items_with_texture(frozen,texture).size() == carried.size(),"JSON retains correct prop membership " + label + ":" + rule)
		var replay := PhotoMoment.new()
		root.add_child(replay)
		replay.setup(frozen)
		var actual := 0
		for child in replay._stage.get_children():
			if child is Sprite2D and PhotoMoment._texture_data(child.texture) == texture:
				actual += 1
				check(child.get_meta("subject", "") == "player","replay keeps prop owner " + label)
		check(actual == carried.size(),"inert replay has no floating prop " + label + ":" + rule)
		replay.free()
	check(store._data == saved,"photos do not change production or meals " + label)

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated.trim_suffix("/")+"/"):
		quit(2)
		return
	store = root.get_node("SaveStore")
	var inventory := Inventory.empty()
	inventory.wheat = 3
	var source := {"version":5,"holiday_day":1,"holiday_day_elapsed":160.0,
		Inventory.FIELD:inventory,"keepsakes":{},"growth_actions":Budget.empty(),
		"pond_edging":{"schema":1,"revision":0,"sections":{}},"growth_production":Production.empty(),
		"resident_rest":{"schema":1,"day":1,"cause":"sleep"}}
	source = Meals.complete(source,0,0,1,"lunch",{"wheat":1},false).candidate
	store.request_patch("isolated-growth-photo-fixture",source)
	check(await store.flush_pending(),"isolated action setup durably saved")
	world = load("res://scripts/game/yard_world.gd").new()
	world.setup([],{},1,160.0)
	root.add_child(world)
	await process_frame
	world.simulation_active = true
	world.input_enabled = true
	world.pond_growth.autonomous_enabled = false
	var recipe := Schedule.MILL_RECIPE.duplicate(true)
	recipe.seconds = 2.0
	check(world.pond_growth.begin_milling(Mill.APPROACH,recipe,func(): return "lunch"),"actual milling starts")
	for frame in 2400:
		world.tick(1.0/30,Vector2.ZERO)
		if world.pond_growth.stage == "walking": break
	check(world.pond_growth.stage == "walking","real basket pickup reaches wheat transport")
	verify_carried_photos(world.pond_growth.material,"wheat")
	var saw_work := false
	for frame in 2400:
		world.tick(1.0/30,Vector2.ZERO)
		if world.pond_growth.stage == "working" and not saw_work:
			saw_work = true
			var work_photo := PhotoMoment.capture(world,{"id":"fish_first_catch"})
			var mill_lines: Array = work_photo.items.filter(func(item: Dictionary): return item.kind == "line" and item.depth == roundi(Mill.ANCHOR.y) and item.subject == "")
			check(mill_lines.size() == 3,"fixed contact lines and working flour remain world effects")
		if world.pond_growth.stage == "saving": break
	check(saw_work and await store.flush_pending(),"actual milling produces confirmed flour")
	check(store.get_yard_inventory().flour == 1,"photo actions did not prevent flour production")
	# Same day at the next legitimate meal; walk normally back to the basket.
	world._day_elapsed = 320.0
	check(world.try_walk_to(Basket.APPROACH),"normal return path to basket")
	for frame in 2400:
		world.tick(1.0/30,Vector2.ZERO)
		if not world._has_walk_goal: break
	check(world.get_player().position.distance_to(Basket.APPROACH) < 16,"actual return reaches basket")
	world.house.take_from_basket()
	check(world.house.stage == "take" and world.house.cooking_plan.get("primary") == "flour","actual house takes confirmed flour")
	verify_carried_photos(world.house.meal_ingredient,"flour")
	world.free()
	await process_frame
	for failure in failures: push_error(failure)
	print("GROWTH_CARRIED_PHOTO checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
