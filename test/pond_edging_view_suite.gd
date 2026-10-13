extends SceneTree
const View := preload("res://scripts/game/pond_edging_view.gd")
const Budget := preload("res://scripts/game/growth_budget.gd")
const Edging := preload("res://scripts/game/pond_edging.gd")
const Materials := preload("res://scripts/game/growth_materials.gd")
const Meals := preload("res://scripts/game/meal_ledger.gd")
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const STONE := ExplorationRoutes.FIND_STONE
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func eat(s: Dictionary, meal: String) -> Dictionary:
	return Meals.complete(s,Meals.read(s).revision,Inventory.read(s).revision,s.holiday_day,meal,{"wheat":1},false).candidate
func plan(s: Dictionary) -> Dictionary:
	return Materials.plan(s,{STONE:{"id":"pond_edging","materials":{STONE:1}}},RandomNumberGenerator.new())
func stone_items(photo: Dictionary) -> Array:
	return photo.get("items",[]).filter(func(i: Dictionary): return i.kind == "prop" and i.subject == "keepsake")
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated.trim_suffix("/")+"/"):
		quit(2)
		return
	var store = root.get_node("SaveStore")
	var inv := Inventory.empty()
	inv.wheat = 20
	# Explicit fixture meal/costs. No production automation or recipe is added.
	var snapshot := eat({"version":5,"holiday_day":1,"keepsakes":{STONE:20},Inventory.FIELD:inv},"breakfast")
	store.request_patch("fixture",snapshot)
	check(await store.flush_pending(),"isolated starting save confirmed")
	root.size = Vector2i(1280,720)
	var world = load("res://scripts/game/yard_world.gd").new()
	world.setup()
	world.simulation_active = false
	root.add_child(world)
	await process_frame
	var view: Node2D = world.pond_edging_view
	check(view.visuals.is_empty(),"old save has no fabricated construction")
	var before := PhotoMoment.capture(world,{"id":"fish_first_catch"})
	check(stone_items(before).is_empty(),"old photo has no construction")
	var expected: Dictionary = store.get_growth_budget("breakfast")
	var proposal := plan(snapshot)
	store.request_pond_growth(expected,"rim_04",proposal,1,1,1)
	check(view.visuals.is_empty(),"accepted write does not show result early")
	check(await store.flush_pending(),"real native growth completes")
	check(view.visuals.size() == 1 and view.visuals.rim_04.size() == 3,"confirmed result projects one arc")
	var prop: Node2D = view.visuals.rim_04[0]
	view.refresh()
	check(view.visuals.rim_04[0] == prop,"duplicate confirmation does not recreate props")
	var frozen := PhotoMoment.capture(world,{"id":"fish_first_catch"})
	check(stone_items(frozen).size() == 3,"photo captures constructed stones")
	check(same_json(PhotoMoment.sanitize(JSON.parse_string(JSON.stringify(frozen))), frozen),"JSON photo roundtrip retains stones")
	store.request_pond_growth(expected,"rim_04",proposal,1,1,1)
	await store.flush_pending()
	check(view.visuals.size() == 1,"rejected replay creates no extra stones")
	check(not view.sync({"schema":2}) and view.visuals.size() == 1,"future/corrupt ledger preserves last display")
	var copied: Dictionary = store.get_pond_edging()
	copied.sections.clear()
	check(store.get_pond_edging().sections.size() == 1,"read getter cannot mutate saved world")
	world.queue_free()
	await process_frame
	store._load()
	world = load("res://scripts/game/yard_world.gd").new()
	world.setup()
	world.simulation_active = false
	root.add_child(world)
	await process_frame
	check(world.pond_edging_view.visuals.size() == 1,"disk reload and scene recreation restore world")
	# Fill all eight render addresses using valid, spent meal budgets over two days.
	snapshot = store._data.duplicate(true)
	snapshot = eat(snapshot,"lunch")
	var sections := ["rim_00","rim_01","rim_02","rim_03","rim_05","rim_06","rim_07"]
	for i in sections.size():
		var period := "lunch"
		if i == 3: snapshot = eat(snapshot,"dinner")
		if i in [3,4]: period = "dinner"
		if i == 5:
			snapshot.holiday_day = 2
			snapshot = eat(snapshot,"breakfast")
			period = "breakfast"
		if i == 6: snapshot = eat(snapshot,"lunch")
		var result := Budget.complete(snapshot,Budget.budget(snapshot,period),sections[i],plan(snapshot),1,1,1)
		check(result.has("candidate"),"valid fixture action "+sections[i])
		if result.has("candidate"): snapshot = result.candidate
	store.request_patch("growth",snapshot)
	check(await store.flush_pending(),"full fixture reaches confirmed store")
	check(world.pond_edging_view.visuals.size() == 8,"all arc IDs have stable positions")
	var complete := PhotoMoment.capture(world,{"id":"fish_first_catch"})
	check(not complete.is_empty() and stone_items(complete).size() == 24,"full rim stays in bounded photo record")
	check(stone_items(frozen).size() == 3 and stone_items(before).is_empty(),"old photos do not gain future construction")
	var photo := PhotoMoment.new()
	root.add_child(photo)
	photo.setup(frozen)
	check(photo._snapshot == frozen,"inert photo replay keeps original result")
	photo.queue_free()
	for id: String in View.IDS:
		for visual: Node2D in world.pond_edging_view.visuals[id]:
			check(visual.z_index == roundi(visual.position.y) and not visual.z_as_relative,"stone uses same depth as actors")
	world.simulation_active = true
	world.set_weather("rain")
	world.tick(4.0,Vector2.ZERO)
	check(world.pond_edging_view.modulate == world._scene_feedback.modulate,"weather light matches yard")
	var output := OS.get_environment("YOUJIA_EDGING_CAPTURE")
	if not output.is_empty():
		world.set_weather("sun")
		world.tick(4.0,Vector2.ZERO)
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(output) == OK,"native render evidence")
	world.queue_free()
	await process_frame
	for failure in failures: push_error(failure)
	print("POND_EDGING_VIEW checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)


func same_json(a: Variant, b: Variant) -> bool:
	if (a is int or a is float) and (b is int or b is float):
		return is_equal_approx(float(a), float(b))
	if a is Array and b is Array:
		if a.size() != b.size(): return false
		for index: int in a.size():
			if not same_json(a[index], b[index]): return false
		return true
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not same_json(a[key], b[key]): return false
		return true
	return a == b
