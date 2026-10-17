extends "res://test/milling_director_suite.gd"
const Garden := preload("res://scripts/game/yard_garden.gd")
const View := preload("res://scripts/game/yard_garden_view.gd")
const SEEDS := ExplorationRoutes.FIND_FLOWER_SEEDS

func prepare_garden(tired := false) -> void:
	await reset(2,0,tired)
	store.request_patch("isolated-garden-fixture",{Garden.FIELD:Garden.empty(),"keepsakes":{SEEDS:2},"growth_production":Production.empty()})
	check(await store.flush_pending(),"garden fixture persisted")

func begin(seconds := 2.0) -> bool:
	var config := Schedule.GARDEN_RECIPE.duplicate(true)
	config.seconds = seconds
	return world.pond_growth.begin_garden(config,func(): return period)

func garden_item(photo: Dictionary) -> Dictionary:
	for item: Dictionary in photo.get("items",[]):
		if item.get("texture",{}).get("atlas","") == View.ART_PATH: return item
	return {}

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated.trim_suffix("/")+"/"):
		quit(2)
		return
	store = root.get_node("SaveStore")
	await prepare_garden()
	check(not world.garden_view.art.visible,"old save has no fabricated new bed")
	check(world.pond_growth.begin_available(func(): return period) and world.pond_growth.action_id == "plant_flowers","normal autonomous selection includes flower seeds")
	world.pond_growth.cancel()
	check(begin(),"planting starts")
	var frozen: Dictionary = world.pond_growth.proposal.duplicate(true)
	reach("walking")
	check(world.pond_growth.material.visible and world._walk_goal == View.APPROACH,"seed art carried from actual basket to fixed bed")
	reach("working")
	check(world.pond_growth.proposal == frozen and store.get_yard_garden().revision == 0 and not world.garden_view.art.visible,"no re-draw or pre-confirmed bed")
	finish_work()
	check(world.pond_growth.stage == "saving" and store.get_yard_garden().revision == 0,"accepted is not completion")
	check(await store.flush_pending(),"composite save confirmed")
	check(store._data.keepsakes[SEEDS] == 1 and store.get_yard_garden().revision == 1 and store.get_growth_budget(period).available == 2,"one seed, AP and gardening receipt committed together")
	check(world.garden_view.art.visible,"world bed appears only after durable confirmation")
	var photo := PhotoMoment.capture(world,{"id":"fish_first_catch"})
	check(not garden_item(photo).is_empty(),"new planted bed captured in inert photo")
	world.garden_view.sync_day(1+Schedule.GARDEN_BLOOM_DAYS)
	var bloom_photo := PhotoMoment.capture(world,{"id":"fish_first_catch"})
	check(garden_item(photo).texture != garden_item(bloom_photo).texture,"later bloom does not change frozen young-bed photo")
	check(not PhotoMoment.sanitize(JSON.parse_string(JSON.stringify(photo))).is_empty(),"new atlas photo survives JSON roundtrip")
	world.queue_free()
	await process_frame
	store._load()
	world = load("res://scripts/game/yard_world.gd").new()
	world.setup()
	root.add_child(world)
	await process_frame
	world._day_elapsed = 160.0
	world.pond_growth.autonomous_enabled = false
	check(world.garden_view.art.visible and store.get_yard_garden().revision == 1 and store._data.keepsakes[SEEDS] == 1,"real native file recreation retains bed and debits")
	check(not begin() and not world.pond_growth.begin_available(func(): return period),"occupied bed leaves eligible pool")
	for phase: String in ["fetching","taking","walking","working"]:
		await prepare_garden()
		check(begin(),"interruptible " + phase)
		reach(phase)
		world.request_pointer_action(Vector2(460,530))
		check(not world.pond_growth.busy() and not world.pond_growth.material.visible and not world.garden_view.intent.visible,"player takeover clears transient garden " + phase)
		check(store.get_yard_garden().revision == 0 and store._data.keepsakes[SEEDS] == 2 and store.get_growth_budget(period).available == 3,"interruption charges nothing " + phase)
	await prepare_garden(true)
	check(begin(),"tired gardener begins")
	reach("working")
	for i in 61: world.tick(1.0/30,Vector2.ZERO)
	check(world.pond_growth.stage == "working","fatigue slows only garden production")
	finish_work()
	check(await store.flush_pending() and store.get_yard_garden().receipts[0].experience == 1,"tired gardener keeps full XP")
	await prepare_garden()
	check(begin(),"stale gardening plan begins")
	reach("working")
	store.request_patch("isolated-stock-race",{"keepsakes":{SEEDS:1}})
	check(await store.flush_pending(),"competing inventory change persisted")
	finish_work()
	check(await store.flush_pending() and store.get_yard_garden().revision == 0 and store._data.keepsakes[SEEDS] == 1,"stale completion cannot mint bed or XP")
	world.queue_free()
	await process_frame
	print("GARDEN_DIRECTOR checks=%d failures=%d" % [checks,failures.size()])
	for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
