extends SceneTree
const Crops := preload("res://scripts/game/yard_crops.gd")
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Memory := preload("res://test/fixtures/exploration_memory_store.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func step(source: Dictionary, action: String, kind: String = "") -> Dictionary:
	return Crops.transition(source,int(Crops.read(source).revision),int(Inventory.read(source).revision),action,kind)
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated):
		quit(2)
		return
	var original := {"version":5,"holiday_day":1,"plant_state":0,"album":["old"],"keepsakes":{"pine_cone":2},"unknown_root":{"data":[1,2]}}
	var source := step(original,"initialize").candidate as Dictionary
	check(not original.has(Crops.FIELD),"initialization does not mutate source")
	check(Inventory.read(source).wheat == 2 and Inventory.read(source).corn == 2,"two initial grain portions of each kind")
	check(step(source,"initialize").candidate == source,"initialization marker cannot grant twice")
	check(source.album == original.album and source.keepsakes == original.keepsakes and source.unknown_root == original.unknown_root,"unrelated old data preserved")
	for crop: String in Crops.KINDS:
		var state := source.duplicate(true)
		var before := Inventory.read(state)
		state = step(state,"plant",crop).candidate
		check(Crops.read(state).kind == crop,"plant "+crop)
		check(Inventory.read(state)[crop] == before[crop] - (0 if crop == "grass" else 1),"seed debit shares bed snapshot "+crop)
		check(step(state,"plant",crop).error == "CROP_OCCUPIED","cannot overwrite occupied crop "+crop)
		check(step(state,"harvest").error == "CROP_NOT_READY","cannot harvest immediately "+crop)
		state = step(state,"water").candidate
		check(step(state,"water").error == "CROP_WATERED","same-day water rejected "+crop)
		state.holiday_day += int(Crops.DAYS[crop])
		check(Crops.mature(Crops.read(state),state.holiday_day),"matures after appropriate days "+crop)
		var crop_revision := int(Crops.read(state).revision)
		var inventory_revision := int(Inventory.read(state).revision)
		var count := int(Inventory.read(state)[crop])
		var harvested := step(state,"harvest").candidate as Dictionary
		check(Inventory.read(harvested)[crop] == count+3 and Crops.read(harvested).kind == "","harvest credits basket and clears bed atomically "+crop)
		check(Crops.transition(harvested,crop_revision,inventory_revision,"harvest").error == "CROP_CHANGED","replayed harvest cannot mint "+crop)
		var reopened: Dictionary = JSON.parse_string(JSON.stringify(harvested))
		check(Crops.read(reopened) == Crops.read(harvested) and Inventory.read(reopened) == Inventory.read(harvested),"JSON reopen retains both sides "+crop)
		var held := Inventory.transition(harvested,int(Inventory.read(harvested).revision),"withdraw",crop).candidate as Dictionary
		check(Inventory.read(held).held == crop,"harvested crop can be withdrawn "+crop)
		var dropped := Inventory.transition(held,int(Inventory.read(held).revision),"drop",crop,{"x":430.0,"y":520.0}).candidate as Dictionary
		check(Inventory.read(dropped).ground.size() == 1,"harvest can enter real ground-food ledger "+crop)
		var eaten := Inventory.transition(dropped,int(Inventory.read(dropped).revision),"eat",crop,{"id":1}).candidate as Dictionary
		check(Inventory.read(eaten).ground.is_empty(),"food consumed once "+crop)
		check(Inventory.transition(eaten,int(Inventory.read(eaten).revision),"eat",crop,{"id":1}).error == "BASKET_EMPTY","second animal cannot eat same food "+crop)
	var growing := step(source,"plant","wheat").candidate as Dictionary
	growing.holiday_day = 100
	check(not Crops.mature(Crops.read(growing),100),"unwatered plant waits without dying")
	var last_seed := source.duplicate(true)
	last_seed.yard_inventory.wheat = 1
	check(Inventory.transition(last_seed,int(last_seed.yard_inventory.revision),"withdraw","wheat").error == "BASKET_SEED_RESERVED","last grain reserved for continued planting")
	check(step(last_seed,"plant","wheat").candidate.yard_inventory.wheat == 0,"last grain can be planted")
	var flowers := source.duplicate(true)
	flowers.plant_state = 3
	check(step(flowers,"plant","corn").error == "CROP_OCCUPIED","legacy flowers never overwritten")
	for raw: Variant in [null,[],{"schema":2}, {"schema":1,"revision":0,"kind":"wheat","planted_day":0,"watered_day":-1}]:
		var invalid := source.duplicate(true)
		invalid[Crops.FIELD] = raw
		var text := JSON.stringify(invalid)
		check(Crops.read(invalid).is_empty() and step_invalid(invalid).error == "CROP_INVALID","invalid/future crops blocked")
		check(JSON.stringify(invalid) == text,"future raw data preserved")
	var memory := Memory.new()
	memory._data = source.duplicate(true)
	memory.fail_kind_once = "crops"
	var rev := int(Crops.read(source).revision)
	var inv_rev := int(Inventory.read(source).revision)
	memory.request_crop_action(rev,inv_rev,"plant","corn")
	check(memory.get_yard_crops().kind == "" and memory.get_yard_inventory().corn == 2,"accepted write does not expose seed debit or bed")
	memory.pump()
	check(memory.get_yard_crops().kind == "" and memory.get_yard_inventory().corn == 2,"failed write retains both seed and empty bed")
	memory.request_crop_action(rev,inv_rev,"plant","corn")
	memory.pump()
	check(memory.get_yard_crops().kind == "corn" and memory.get_yard_inventory().corn == 1,"retry commits both exactly once")
	memory.free()
	for landed: bool in [false,true]:
		var uncertain := Memory.new()
		uncertain._data = source.duplicate(true)
		uncertain.unknown_kind = "crops"
		uncertain.request_crop_action(rev,inv_rev,"plant","corn")
		uncertain.pump()
		check(uncertain.get_yard_crops().kind == "" and uncertain.get_yard_inventory().corn == 2,"unknown sow exposes neither side")
		uncertain.resolve_unknown(landed)
		check(uncertain.get_yard_crops().kind == ("corn" if landed else "") and uncertain.get_yard_inventory().corn == (1 if landed else 2),"unknown sow resolves both together")
		uncertain.free()
	var store = root.get_node("SaveStore")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	check(await store.flush_pending(),"production seed initialization durably drains")
	check(store.get_yard_inventory().wheat == 2 and store.get_yard_inventory().corn == 2,"production initial basket grains")
	main._world.get_player().position = main._world._plant_point()
	main._world._interact_plant()
	check(main._crop_panel.visible and paused and not main._world.input_enabled,"actual plant interaction opens modal and freezes world")
	main._crop_panel._request("plant","wheat")
	main._hide_crops()
	check(main._crop_panel.visible and paused and main._crop_panel.close_button.disabled,"pending sow cannot expose stale inventory to another writer")
	check(await store.flush_pending(),"production sow transaction persists")
	check(store.get_yard_crops().kind == "wheat" and store.get_yard_inventory().wheat == 1,"production sow confirms both")
	check(main._world.crop_sprite.visible,"actual scene shows installed crop art after confirmation")
	var photo := PhotoMoment.capture(main._world,{"id":"llama_fed_gentle"})
	var recorded_crop := false
	for item: Dictionary in photo.get("items",[]):
		if item.subject == "crop": recorded_crop = true
	check(recorded_crop and not PhotoMoment.sanitize(photo).is_empty(),"crop atlas remains reconstructible in photograph")
	main._crop_panel._request("water")
	check(await store.flush_pending(),"production watering persists")
	store._load()
	check(store.get_yard_crops().kind == "wheat" and store.get_yard_crops().watered_day == 1 and store.get_yard_inventory().wheat == 1,"actual native reopen retains growing crop and seed debit")
	# Explicit controlled clock fixture, not ordinary browser-play evidence.
	store.request_patch("crop-test-clock",{"holiday_day":3})
	check(await store.flush_pending(),"controlled maturity clock persists")
	main._crop_panel._request("harvest")
	check(await store.flush_pending(),"production harvest durably drains")
	check(store.get_yard_crops().kind == "" and store.get_yard_inventory().wheat == 4,"production harvest credits basket and clears bed")
	store._load()
	check(store.get_yard_crops().kind == "" and store.get_yard_inventory().wheat == 4,"actual native reopen retains harvest without another grant")
	for viewport: Vector2i in [Vector2i(1280,720),Vector2i(390,844),Vector2i(568,320)]:
		root.size = viewport
		main._crop_panel.refresh()
		for i in 4: await process_frame
		var bounds: Rect2 = main._crop_panel.paper.get_global_rect()
		check(Rect2(Vector2.ZERO,Vector2(viewport)).encloses(bounds),"crop paper fits viewport %s" % viewport)
		check(main._crop_panel.scroll.get_global_rect().size.y > 100,"crop scroll remains usable %s" % viewport)
	main._crop_panel.scroll.scroll_vertical = 1000
	for i in 3: await process_frame
	check(main._crop_panel.scroll.get_global_rect().encloses(main._crop_panel.close_button.get_global_rect()),"short landscape scroll reaches close button")
	root.size = Vector2i(1280,720)
	main._hide_crops()
	check(not paused and main._world.input_enabled,"closing restores movement")
	check(not main._basket_panel.scoop_button.visible,"obsolete infinite chicken tin hidden")
	main._show_basket()
	check(main._basket_panel.grid.counts.wheat == 4 and main._basket_panel.grid.icons.wheat.texture != null,"real basket shows grain count and art")
	main._hide_basket()
	main._inventory.request("withdraw","wheat")
	check(await store.flush_pending(),"production grain withdrawal persists")
	check(main._world.ground_food.held() == "wheat","production world carries distinct wheat")
	check(main._world.ground_food._accepts(main._world.actor_named("chicken"),{"kind":"wheat"}),"chicken accepts harvested wheat")
	check(not main._world.ground_food._accepts(main._world.actor_named("goose"),{"kind":"corn"}),"corn does not masquerade as fish")
	main.queue_free()
	await process_frame
	print("YARD_CROPS checks=%d failures=%d" % [checks,failures.size()])
	for label: String in failures: push_error(label)
	quit(0 if failures.is_empty() else 1)
func step_invalid(source: Dictionary) -> Dictionary:
	return Crops.transition(source,0,0,"initialize")
