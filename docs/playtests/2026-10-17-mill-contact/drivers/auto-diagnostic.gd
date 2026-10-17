extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var store = root.get_node("SaveStore")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("C:/Users/Zengm/AppData/Local/Temp/youjia-round-20261017-1032/web-ordinary-valid/initial-controlled-fixture.json"))
	store.request_patch("isolated-auto-diagnostic",data)
	assert(await store.flush_pending())
	var world = load("res://scripts/game/yard_world.gd").new()
	world.setup([],{},store.get_holiday_day(),store.get_holiday_day_elapsed())
	root.add_child(world)
	await process_frame
	world.simulation_active = true
	world.input_enabled = true
	var rows := []
	var previous := ""
	for i in 9000:
		world.tick(1.0/30,Vector2.ZERO)
		if not store.is_save_idle(): await store.flush_pending()
		if i % 30 == 0: await process_frame
		var director = world.pond_growth
		var state: String = director.stage+":"+world.house.stage+":"+str(store.get_growth_production().revision)
		if i%300 == 0 or state != previous:
			var row := {"seconds":float(i)/30,"elapsed":world._day_elapsed,"stage":director.stage,"production":store.get_growth_production().revision,"available":director.available(),"save_idle":store.is_save_idle(),"idle_seconds":director.idle_seconds,"walk_goal":world._has_walk_goal,"pending":world._pending_interaction,"inventory_busy":world.inventory_busy,"house":world.house.stage,"budget":store.get_growth_budget("lunch"),"position":[world.get_player().position.x,world.get_player().position.y]}
			rows.append(row)
			print("AUTO_DIAGNOSTIC "+JSON.stringify(row))
		previous = state
		if store.get_growth_production().revision>=2: break
	FileAccess.open("C:/Users/Zengm/AppData/Local/Temp/youjia-round-20261017-1032/auto-diagnostic.json",FileAccess.WRITE).store_string(JSON.stringify(rows))
	world.queue_free()
	await process_frame
	root.get_node("AudioDirector").call("release_streams")
	quit(0)
