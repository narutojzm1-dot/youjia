extends SceneTree
const Model := preload("res://scripts/inventory/yard_original_plants.gd")
const View := preload("res://scripts/game/original_plant_view.gd")
const Moment := preload("res://scripts/ui/photo_moment.gd")
var checks := 0
var failures: Array[String] = []
var store: Node
var main: Control

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated):
		quit(2)
		return
	store = root.get_node("SaveStore")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await main._start_holiday()
	main.set_process(false)
	await store.flush_pending()
	await ordinary_entry()
	await projection_and_photos()
	await native_failure_and_retry()
	await layout()
	main.queue_free()
	await process_frame
	print("ORIGINAL_PLANT_RUNTIME checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func ordinary_entry() -> void:
	var world = main._world
	check(View.enabled() and world.original_plants_view != null,"accepted resources enable the actual yard entry")
	var hits := {"left_cluster":Vector2(70,525),"door_pots":Vector2(209,433),"pond_cluster":Vector2(451,595)}
	for area: String in Model.AREAS:
		world.debug_place_player(YardSceneHotspots.get_hotspot("original_plant:"+area).approach_points[0])
		world.request_pointer_action(hits[area])
		await process_frame
		check(main._original_plant_panel.visible and main._original_plant_panel.area == area,"real target signal opens selected paper: "+area)
		check(paused and not world.input_enabled,"flower paper owns pause and blocks movement: "+area)
		main._original_plant_panel.close_button.pressed.emit()
		await process_frame
		check(not paused and world.input_enabled and not main._original_plant_panel.visible,"close restores yard interaction: "+area)
		check(root.gui_get_focus_owner() == null,"close releases paper keyboard focus: "+area)

func projection_and_photos() -> void:
	var world = main._world
	var view = world.original_plants_view
	for area: String in Model.AREAS:
		var hotspot := YardSceneHotspots.get_hotspot("original_plant:"+area)
		check(YardGround.allows(hotspot.approach_points[0],world.player_ground(),true),"safe approach stays on actual walkable yard: "+area)
		for cloudy: bool in [false,true]:
			var source := View.plate_source(area,cloudy)
			var bounds := Rect2(Vector2(source.rect.x,source.rect.y),Vector2(source.rect.z,source.rect.w))
			var covers := true
			for point: Vector2 in View.points(area):
				covers = covers and bounds.has_point(point / View.WORLD_SIZE)
			check(covers,"registered plate contains entire polygon without edge clamp: %s %s" % [area,cloudy])
		for other: String in Model.AREAS:
			if area >= other: continue
			check(Geometry2D.intersect_polygons(View.points(area),View.points(other)).is_empty(),"independent area polygons never overlap: "+area+"/"+other)
	var photos: Array = []
	for bits in 8:
		var removed: Array = []
		for i in 3:
			if bits & (1 << i): removed.append(Model.AREAS[i])
		var state := {"schema":1,"revision":bits,"removed":removed}
		view.sync(state,0.375,Color.WHITE,Color(0.92,0.95,0.98))
		for area: String in Model.AREAS: check(view.patches[area].visible == (area in removed),"only confirmed groups clear: %d %s" % [bits,area])
		var photo := Moment.capture(world,ExpressionCatalog.find_rule("llama_fed_gentle"))
		check(not photo.is_empty(),"ordinary photo capture succeeds for combination %d" % bits)
		if bits == 0: check(not photo.has("original_plants"),"untouched original scene keeps legacy photo shape")
		else:
			check(photo.original_plants.removed == removed and is_equal_approx(photo.original_plants.mix,0.375),"photo freezes exact groups and crossfade %d" % bits)
			photos.append(photo)
	view.sync(Model.original(),1.0,Color.WHITE,Color.WHITE)
	for photo: Dictionary in photos:
		var frozen := Moment.sanitize(JSON.parse_string(JSON.stringify(photo)))
		var card := Moment.new()
		root.add_child(card)
		card.setup(frozen)
		var replay: Node2D
		for child in card._stage.get_children():
			if child.get_script() == View: replay = child
		check(replay != null and replay.record == frozen.original_plants and replay.record.removed == photo.original_plants.removed,"photo survives live restoration and JSON reopen")
		check(replay.get_index() < card._shadows.get_index(),"recorded cleared ground remains beneath actors/shadows")
		for piece in replay.get_children(): check(piece.z_index == 0,"photo cutout cannot leak above modal UI")
		var legacy := photo.duplicate(true)
		legacy.erase("original_plants")
		check(not Moment.sanitize(legacy).has("original_plants"),"old photo never reads current garden")
		legacy.original_plants = {"removed":["unknown"],"mix":0.5,"sun":[1,1,1,1],"cloud":[1,1,1,1]}
		check(not Moment.sanitize(legacy).is_empty() and not Moment.sanitize(legacy).has("original_plants"),"invalid optional extension does not destroy valid old photo")
		card.free()
	var before: Dictionary = view.record.duplicate(true)
	var legacy_recipe := before.duplicate(true)
	legacy_recipe.erase("art_version")
	check(View.sanitize(legacy_recipe).art_version == 1,"unversioned flower photo fixtures retain recipe one")
	legacy_recipe.art_version = 99
	check(View.sanitize(legacy_recipe).is_empty(),"unknown photo recipe never silently substitutes current art")
	view.sync({},0.0,Color.WHITE,Color.WHITE)
	check(view.record == before,"invalid future garden retains last confirmed visual state")

func native_failure_and_retry() -> void:
	var client = main._original_plants
	var panel = main._original_plant_panel
	panel.open("door_pots")
	paused = true
	var temporary: String = store._backend._temporary
	store._backend._temporary = "user://missing-garden-runtime/write.tmp"
	panel.action_button.pressed.emit()
	check(client.busy() and panel.close_button.disabled,"UI locks closure while write identity is unresolved")
	main._hide_original_plants()
	check(panel.visible and paused,"closing cannot abandon an in-flight flower operation")
	await store.flush_pending()
	check(client.state == "unknown" and panel.action_button.text == root.get_node("I18n").t("garden.retry"),"unknown write gives truthful retry action")
	check(not main._world.original_plants_view.record.removed.has("door_pots"),"unknown result cannot clear flowers")
	var first_id: String = client.operation
	main._retry_save()
	await store.flush_pending()
	check(client.state == "failed" and main._save_problems.has(first_id),"actual failure tracked by Main recovery")
	store._backend._temporary = temporary
	main._retry_save()
	await store.flush_pending()
	check(client.state == "idle" and client.view().removed == ["door_pots"],"global recovery commits one flower removal")
	check(not main._save_problems.has(first_id),"confirmed retry clears exactly the replaced failure identity")
	check(not panel.close_button.disabled and panel.action_button.text == root.get_node("I18n").t("garden.restore"),"confirmed UI offers inverse operation")
	store._load()
	check(store.get_yard_original_plants().removed == ["door_pots"],"actual NativeSaveHost reload retains removed group")
	panel.action_button.pressed.emit()
	await store.flush_pending()
	check(client.view().removed.is_empty(),"inverse action restores the one original group")
	var protected := {
		"growth_actions":{"schema":1,"revision":0,"actions":{}},
		"pond_edging":{"schema":1,"revision":0,"sections":{}},
		"meal_ledger":{"schema":1,"revision":1,"receipts":[{"day":store.get_holiday_day(),"meal":"breakfast","ingredients":{"wheat":1},"fatigued":false,"earned":1}]},
		"resident_rest":{"schema":1,"day":store.get_holiday_day(),"cause":"sleep"},
	}
	store.request_patch("protected_fixture",protected)
	await store.flush_pending()
	client.request("remove","pond_cluster")
	await store.flush_pending()
	for key in protected: check(store._data.get(key) == protected[key],"garden intent preserves unrelated persisted key "+key)
	check(not store.get_meal_ledger().is_empty() and not store.get_rest_context().is_empty(),"existing meal and rest contracts still decode after flower edit")
	client.request("remove","pond_cluster")
	await store.flush_pending()
	check(client.state == "blocked" and main._save_problems.is_empty(),"stale domain refusal never creates unrecoverable disk warning")
	paused = false

func layout() -> void:
	var panel = main._original_plant_panel
	for dims: Vector2i in [Vector2i(1280,720),Vector2i(390,844),Vector2i(844,390),Vector2i(568,320)]:
		root.size = dims
		panel.open("left_cluster")
		for frame in 4: await process_frame
		var screen := Rect2(Vector2.ZERO,Vector2(dims))
		check(screen.encloses(panel.paper.get_global_rect()),"paper remains on screen %s" % dims)
		check(panel.close_button.custom_minimum_size.y >= 44.0 and panel.action_button.custom_minimum_size.y >= 44.0,"touch target size %s" % dims)
		check(root.gui_get_focus_owner() == panel.action_button,"keyboard starts on actionable flower choice %s" % dims)
		for expected: Button in [panel.close_button,panel.action_button]:
			var key := InputEventKey.new()
			key.keycode = KEY_TAB
			key.pressed = true
			root.push_input(key)
			await process_frame
			check(root.gui_get_focus_owner() == expected,"Tab stays on flower paper %s" % dims)
		if "--preview" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var output := OS.get_environment("TEMP").path_join("youjia-flower642-gpu-preview")
			DirAccess.make_dir_recursive_absolute(output)
			check(root.get_texture().get_image().save_png(output.path_join("paper-%dx%d.png" % [dims.x,dims.y])) == OK,"save actual GPU panel %s" % dims)
	panel.hide()
