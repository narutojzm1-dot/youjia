extends "res://test/milling_director_suite.gd"
const Stove := preload("res://scripts/game/yard_stove.gd")
const View := preload("res://scripts/game/yard_stove_view.gd")

func begin(seconds := 2.0) -> bool:
	var config := Schedule.STOVE_RECIPE.duplicate(true)
	config.seconds = seconds
	return world.pond_growth.begin_stove(config,func(): return period)

func stove_item(photo: Dictionary) -> Dictionary:
	for item: Dictionary in photo.get("items",[]):
		if item.get("texture",{}).get("atlas","") == View.ART.resource_path: return item
	return {}

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated.trim_suffix("/")+"/"):
		quit(2)
		return
	store = root.get_node("SaveStore")
	await reset(2,6)
	var start_stock: Dictionary = store._data.keepsakes.duplicate(true)
	check(not world.stove_view.art.visible and store.get_yard_stove().revision == 0,"old save creates no fabricated stove")
	var frozen_photo := {}
	for index in 3:
		check(begin(),"stove stage starts")
		check(world.pond_growth.action_id == "build_stove" and world._walk_goal == Basket.APPROACH,"same actor retrieves from actual basket")
		var plan: Dictionary = world.pond_growth.proposal.duplicate(true)
		reach("walking")
		check(world._walk_goal == View.APPROACH and world.pond_growth.material.visible,"stone carried toward ONE stove site")
		reach("working")
		check(world.get_player().position.distance_to(View.APPROACH) < 16 and world.stove_view.intent.visible,"work only at reachable site with intent")
		check(world.pond_growth.proposal == plan and store.get_yard_stove().revision == index,"no redraw or early stage")
		var feet: Vector2 = world.get_player().position
		var first_frame: int = world.get_player()._sequence_walker.frame
		for i in 8: world.tick(1.0/30,Vector2.ZERO)
		check(world.get_player()._sequence_walker.frame != first_frame,"full authored work cycle advances")
		for i in 12: world.tick(1.0/30,Vector2.ZERO)
		check(not world.pond_growth.material.visible and world.get_player().position == feet,"set-down material does not hover or slide actor")
		finish_work()
		check(world.pond_growth.stage == "saving" and store.get_yard_stove().revision == index,"stage not credited on accepted save")
		check(await store.flush_pending(),"stage durable confirmation")
		check(store.get_yard_stove().revision == index+1 and int(world.stove_view.confirmed.revision) == index+1,"confirmed stage projected")
		check(world.stove_view.art.visible and world.stove_view.art.texture is AtlasTexture,"authored stage atlas projected")
		check(store._data.keepsakes[STONE] == start_stock[STONE]-index-1 and store.get_growth_budget(period).available == 2-index,"one common AP/material debit per stage")
		var photo := PhotoMoment.capture(world,{"id":"fish_first_catch"})
		check(not stove_item(photo).is_empty(),"existing photo captures stove stage")
		if index == 0: frozen_photo = photo.duplicate(true)
		else: check(stove_item(photo).texture != stove_item(frozen_photo).texture,"photo atlas region identifies different phase")
		world.queue_free()
		await process_frame
		store._load()
		world = load("res://scripts/game/yard_world.gd").new()
		world.setup()
		root.add_child(world)
		await process_frame
		world._day_elapsed = 160.0
		world.pond_growth.autonomous_enabled = false
		check(int(world.stove_view.confirmed.revision) == index+1,"real store + world recreation resumes stage")
	check(not begin() and not world.pond_growth.begin_available(func(): return period),"completed stove removed from eligible pool")
	var restored_photo := PhotoMoment.sanitize(JSON.parse_string(JSON.stringify(frozen_photo)))
	check(not restored_photo.is_empty() and stove_item(restored_photo).texture == stove_item(frozen_photo).texture and int(stove_item(restored_photo).texture.region[0]) == 0,"early atlas frame survives serialized replay after later construction")
	for phase: String in ["fetching","taking","walking","working"]:
		await reset(2,6)
		check(begin(),"interruptible " + phase)
		reach(phase)
		world.request_pointer_action(Vector2(460,530))
		check(not world.pond_growth.busy() and not world.pond_growth.material.visible and not world.stove_view.intent.visible,"player takeover clears transient work " + phase)
		check(store.get_yard_stove().revision == 0 and store._data.keepsakes[STONE] == 6 and store.get_growth_budget(period).available == 3,"interruption charges nothing " + phase)
	await reset(2,6,true)
	check(begin(),"tired stove work begins")
	reach("working")
	for i in 61: world.tick(1.0/30,Vector2.ZERO)
	check(world.pond_growth.stage == "working","only production takes twice as long")
	finish_work()
	check(await store.flush_pending() and store.get_yard_stove().receipts[0].experience == 1,"fatigue does not halve construction XP")
	await reset(2,6)
	check(begin(),"stale material work starts")
	reach("working")
	store.request_patch("test-stock-race",{"keepsakes":{STONE:5}})
	check(await store.flush_pending(),"competing stock write persisted")
	finish_work()
	check(await store.flush_pending() and store.get_yard_stove().revision == 0 and store._data.keepsakes[STONE] == 5,"FIFO stale completion has no stage/AP/XP")
	await reset(2,6)
	check(world.pond_growth.begin_available(func(): return period) and world.pond_growth.action_id == "build_stove","new autonomous stone work chooses stove instead of pond")
	world.pond_growth.cancel()
	for phase: String in ["fetching","working","saving"]:
		await reset(2,6)
		world.queue_free()
		await process_frame
		var main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		await process_frame
		main.set_process(false)
		await main._start_holiday()
		world = main._world
		world.pond_growth.autonomous_enabled = false
		world.get_player().position = Vector2(440,545)
		check(begin(),"actual Main starts stove " + phase)
		if phase == "saving":
			reach("working")
			finish_work()
		else: reach(phase)
		var accepted: String = world.pond_growth.pending
		check(world.pond_growth.stage == phase,"actual pause boundary reached " + phase)
		main._toggle_pause()
		check(not world.stove_view.intent.visible and not world.pond_growth.material.visible,"pause clears temporary stove presentation " + phase)
		check(world.pond_growth.pending == accepted,"pause never replaces accepted identity " + phase)
		main._toggle_pause()
		check(await store.flush_pending(),"paused completion settles " + phase)
		check(store.get_yard_stove().revision == (1 if phase == "saving" else 0),"only accepted phase survives pause " + phase)
		main.queue_free()
		await process_frame
	world = null
	await process_frame
	for failure in failures: push_error(failure)
	print("STOVE_DIRECTOR checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
