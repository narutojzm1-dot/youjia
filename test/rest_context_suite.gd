extends SceneTree
const Rest := preload("res://scripts/game/rest_context.gd")
const Backend := preload("res://test/save_coordinator_suite.gd").Backend
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return
	var old := {"holiday_day": 23}
	check(Rest.read(old).cause == "legacy" and not old.has(Rest.FIELD), "legacy has no retroactive penalty or mutation")
	check(Rest.work_speed(Rest.read(old)) == 1.0, "legacy normal autonomous speed")
	var awake := Rest.advance(old,24,false)
	check(awake.cause == "awake" and Rest.work_speed(awake) == 0.5, "natural morning halves work speed exactly once")
	var current := {"holiday_day":24,Rest.FIELD:awake}
	check(Rest.advance(current,24,false) == awake, "same-day save retains evidence")
	check(Rest.advance(current,24,true) == awake, "same-day call is not invented nap recovery")
	check(Rest.work_speed(Rest.advance(current,25,false)) == 0.5, "consecutive missed nights do not stack")
	check(Rest.advance(current,25,true).cause == "sleep", "completed sleep restores next day")
	check(Rest.advance(current,23,false).is_empty(), "backdated context rejected")
	check(Rest.read(JSON.parse_string(JSON.stringify(current))) == awake, "JSON normalizes context")
	for raw: Variant in [null,{}, {"schema":2,"day":24,"cause":"awake"}, {"schema":1,"day":23,"cause":"awake"}, {"schema":1,"day":24,"cause":"nap"}]:
		var bad := {"holiday_day":24,Rest.FIELD:raw}
		check(Rest.read(bad).is_empty() and Rest.advance(bad,25,true).is_empty(), "invalid/future context preserved, not reset")
	var store = root.get_node("SaveStore")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	check(await store.flush_pending(), "scene initial state confirmed")
	var world = main._world
	var inventory: Dictionary = store.get_yard_inventory()
	inventory.wheat = 10
	store.request_patch("rest-fixture", {"yard_inventory":inventory})
	check(await store.flush_pending(), "controlled ingredient fixture saved")
	world._day_elapsed = 599.9
	# This same production method also advances time while Main is exploring.
	world.advance_world_time(0.2)
	check(store.get_holiday_day() == 1 and not Rest.fatigued(store.get_rest_context()), "natural rollover acceptance does not publish fatigue early")
	check(await store.flush_pending(), "production rollover clock and fatigue persist")
	check(store.get_holiday_day() == 2 and Rest.fatigued(store.get_rest_context()), "actual world rollover records missed sleep")
	for meal: String in ["breakfast","lunch","dinner"]:
		var ledger: Dictionary = store.get_meal_ledger()
		store.request_meal_completion(int(ledger.revision),int(store.get_yard_inventory().revision),2,meal,{"wheat":1})
		check(await store.flush_pending(), "fatigued meal commits " + meal)
	var receipts: Array = store.get_meal_ledger().receipts
	check([receipts[0].earned,receipts[1].earned,receipts[2].earned] == [0,1,1], "SaveStore derives real fatigue; caller cannot choose grants")
	store._load()
	check(store.get_holiday_day() == 2 and Rest.fatigued(store.get_rest_context()) and store.get_yard_inventory().wheat == 7, "real native reread keeps fatigue and three meal costs")
	var night := {"holiday_day":2,"holiday_day_elapsed":400.0,"world_weather":world._regional_weather.snapshot()}
	store.request_house_sleep(night)
	check(await store.flush_pending(), "sleep commits morning and rest together")
	check(store.get_holiday_day() == 3 and store.get_rest_context().cause == "sleep", "confirmed sleep gives rested next day")
	store.request_yard_progress(2,599.0,0,0,-1)
	store.request_house_sleep(night)
	store.request_yard_progress(3,3.0,0,0,-1)
	check(await store.flush_pending(), "stale pre-sleep autosave and duplicate sleep drain")
	check(store.get_holiday_day() == 3 and store.get_rest_context().cause == "sleep", "stale events cannot undo normal sleep or advance twice")
	store.request_meal_completion(3,int(store.get_yard_inventory().revision),3,"breakfast",{"wheat":1})
	check(await store.flush_pending(), "rested breakfast saved")
	check(store.get_meal_ledger().receipts[3].earned == 1, "next rested morning restores ordinary breakfast grant")
	store._load()
	check(store.get_rest_context().cause == "sleep", "rested provenance also survives reread")
	main.queue_free()
	await process_frame
	store.set_holiday_progress(4,0.0)
	check(store.get_holiday_day() == 4 and Rest.fatigued(store.get_rest_context()), "legacy native clock setter keeps context aligned")
	check(store.set_yard_progress(3,0.0,0,0,-1), "legacy explicit clock assignment retains bounds contract")
	check(store.get_rest_context().day == 3 and Rest.fatigued(store.get_rest_context()), "legacy rewind does not erase fatigue or corrupt rest day")
	store.request_house_sleep({"holiday_day":3,"holiday_day_elapsed":400.0,"world_weather":night.world_weather})
	check(await store.flush_pending() and store.get_rest_context().cause == "sleep", "normal sleep restores rest after legacy assignments")
	# Production SaveStore with controlled unknown receipts: neither clock nor
	# fatigue may change until the same transaction is authoritatively resolved.
	for landed: bool in [false,true]:
		check(store._coordinator.close_when_idle(), "writer drained before fault fixture")
		store._backend = Backend.new()
		var backend = store._backend
		backend.backend_namespace = "youjia-native-file-v1"
		check(store._connect_coordinator(store._data,"root-token","youjia-native-file-v1"), "fault coordinator connected")
		var before: int = store.get_holiday_day()
		store.request_yard_progress(before+1,0.1,0,0,-1)
		await process_frame
		backend.prepare_ok()
		backend.send("unknown",{},"TIMEOUT")
		check(store.get_holiday_day() == before and store.get_rest_context().cause == "sleep", "unknown keeps old clock and rest")
		store.retry_pending()
		backend.receipt("confirmed" if landed else "rejected")
		backend.ack()
		check(store.get_holiday_day() == before + (1 if landed else 0) and store.get_rest_context().cause == ("awake" if landed else "sleep"), "resolution changes both or neither")
	for failure in failures: push_error(failure)
	print("REST_CONTEXT checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
