extends SceneTree
# 首片正式接入：SaveStore 探索字段、宿主提交/恢复/失败、画卷操作、Main 出门与回院。
# 文件写入用内存替身注入失败；Main 一节用真实 SaveStore（verify 脚本已隔离 XDG）。

const Codec := preload("res://scripts/persistence/save_data_codec.gd")
const MemoryStore := preload("res://test/fixtures/exploration_memory_store.gd")
const C := preload("res://scripts/exploration/exploration_contract.gd")
const L := preload("res://scripts/exploration/near_path_layout.gd")
const CLOCK := {"day": 3, "elapsed": 12.5}

var Director: GDScript
var failures: Array[String] = []
var stores: Array[Node] = []
var checks := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


func run() -> void:
	Director = load("res://scripts/exploration/exploration_director.gd")
	_codec()
	_host_commit()
	_host_failure_and_retry()
	_host_restore()
	await _scroll_and_director()
	await _main_round_trip()
	for store in stores:
		store.free()
	print("EXPLORATION SLICE PASS ", checks - failures.size(), "/", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)


## 找一个让溪边 / 树荫各自有无东西的种子（每个停留点只由种子决定）
func seed_where(brook: bool, shade: bool, distinct := false) -> int:
	for value in 2000:
		var session := ExplorationSession.new(ExplorationRoutes.catalog(), 0)
		session.begin(ExplorationRoutes.NEAR_PATH, CLOCK, value)
		session.visit("brook")
		var at_brook := str(session.get_view().get("offer", ""))
		session.visit("shade")
		var at_shade := str(session.get_view().get("offer", ""))
		if distinct and at_brook == at_shade:
			continue
		if (not at_brook.is_empty()) == brook and (not at_shade.is_empty()) == shade:
			return value
	return -1


func make_store() -> MemoryStore:
	var store := MemoryStore.new()
	stores.append(store)
	return store


func offer(host: ExplorationHost) -> String:
	return str(host.view().get("offer", ""))


func _codec() -> void:
	var defaults := Codec.defaults()
	check(defaults.exploration == null and defaults.exploration_committed_serial == 0 and defaults.keepsakes == {}, "fresh save has idle exploration, watermark 0, no keepsakes")
	check(Codec.project({}) == Codec.defaults(), "legacy save without exploration fields projects to defaults")
	check(Codec.project({"exploration_committed_serial": "7"}).exploration_committed_serial == -1, "malformed watermark becomes untrusted (-1)")
	check(Codec.project({"exploration_committed_serial": 4.0}).exploration_committed_serial == 4, "JSON float watermark keeps its integer value")
	var keepsakes := Codec.clean_keepsakes({ExplorationRoutes.FIND_STONE: 2, ExplorationRoutes.FIND_FEATHER: 0,
		ExplorationRoutes.FIND_PINE_CONE: 1.5, "fixture.find.x": 3, "formal.find.unknown": 1, 7: 1})
	check(keepsakes == {ExplorationRoutes.FIND_STONE: 2}, "keepsakes keep only formal finds with whole positive counts")
	var record := {"version": 1, "nested": {"a": [1]}}
	var source := {"exploration": record}
	var projected := Codec.project(source)
	projected.exploration.nested.a.append(2)
	check(record.nested.a == [1], "projected exploration record does not alias the source")


func _host_commit() -> void:
	var value := seed_where(true, true)
	check(value >= 0, "a seed with finds at both brook and shade exists")
	var store := make_store()
	var host := ExplorationHost.new(store)
	host.restore()
	check(host.can_begin(), "fresh store can start a walk")
	check(host.begin(CLOCK, value).ok and host.state() == C.STATE_ACTIVE, "begin starts an active walk")
	check(store.get_exploration_record() is Dictionary, "begin persists the session record")
	host.visit("brook")
	var stone := offer(host)
	check(not stone.is_empty() and host.take(stone).ok, "brook find can be taken")
	host.visit("brook")
	check(host.view().get("carried", []) == [stone], "revisiting the current stop is a no-op")
	var result := host.request_return("player")
	check(result.navigate and result.outcome.state == "committed" and result.outcome.items == PackedStringArray([stone]), "return commits the carried find")
	check(store.get_keepsakes() == {stone: 1} and store.get_exploration_committed_serial() == 1, "keepsake and watermark land in one commit")
	check(host.state() == C.STATE_IDLE and host.can_begin(), "after commit the walk is closed and a new one can start")
	var again := host.request_return("player")
	check(again.navigate and store.get_keepsakes() == {stone: 1}, "duplicate return navigates without granting twice")
	check(Director.outcome_notice(result.outcome) == "notice.exploration.kept.%s" % stone.get_slice(".", 2), "kept notice names the find only after commit")
	host.begin(CLOCK, value)
	var empty := host.request_return("player")
	check(empty.outcome.state == "committed" and empty.outcome.items.is_empty(), "empty-handed return is allowed")
	check(store.get_keepsakes() == {stone: 1} and store.get_exploration_committed_serial() == 2, "empty trip advances the watermark only")
	check(Director.outcome_notice(empty.outcome) == "notice.exploration.back_empty", "empty trip says back, not kept")
	check(store.commit_exploration_trip(store.get_exploration_record(), 2, PackedStringArray([stone])) == false, "store refuses a serial at or below the watermark")
	check(store.commit_exploration_trip(null, 9, PackedStringArray(["fixture.find.x"])) == false and store.get_exploration_committed_serial() == 2, "store refuses non-formal finds and keeps memory unchanged")


func _host_failure_and_retry() -> void:
	var value := seed_where(true, false)
	var store := make_store()
	var host := ExplorationHost.new(store)
	host.restore()
	host.begin(CLOCK, value)
	host.visit("brook")
	var find := offer(host)
	host.take(find)
	var before := store._data.duplicate(true)
	store.fail_commits = true
	var result := host.request_return("player")
	check(result.navigate, "return navigation does not wait for a failed save")
	check(result.outcome.state == "deferred" and result.outcome.items == PackedStringArray([find]), "failed commit is reported as deferred, not kept")
	check(store._data == before, "failed commit leaves the published save untouched")
	check(host.state() == C.STATE_FAILURE and not host.can_begin(), "a deferred trip blocks a new walk until saved")
	check(Director.outcome_notice(result.outcome) == "notice.exploration.deferred_items", "deferred notice does not claim the find is put away")
	check(host.retry_deferred().get("state", "") == "deferred", "retry while the disk still fails stays deferred")
	store.fail_commits = false
	var retried := host.retry_deferred()
	check(retried.get("state", "") == "committed" and store.get_keepsakes() == {find: 1}, "idle retry commits once the save works")
	check(host.retry_deferred().is_empty() and store.get_keepsakes() == {find: 1}, "extra retries never grant twice")
	check(host.can_begin(), "after the retry a new walk can start")


func _host_restore() -> void:
	var value := seed_where(false, true)
	var store := make_store()
	var host := ExplorationHost.new(store)
	host.restore()
	host.begin(CLOCK, value)
	host.visit("shade")
	var cone := offer(host)
	host.take(cone)
	# 进程在画卷中被关掉：新宿主从同一份存档恢复
	var reopened := ExplorationHost.new(store)
	var outcome := reopened.restore()
	check(outcome.get("restored", false) and outcome.state == "committed" and outcome.items == PackedStringArray([cone]), "restart mid-walk returns home and keeps the carried find")
	check(store.get_keepsakes() == {cone: 1} and reopened.can_begin(), "restored find is granted once and walks can resume")
	check(ExplorationHost.new(store).restore().is_empty() and store.get_keepsakes() == {cone: 1}, "a second restart grants nothing more")
	# 提交成功、紧接着的空闲记录没写上就断电：水位线挡住重复授予
	reopened.begin(CLOCK, value)
	reopened.visit("shade")
	reopened.take(offer(reopened))
	store.fail_after = 2
	reopened.request_return("player")
	check(store.get_keepsakes() == {cone: 2} and str(store.get_exploration_record().session.state) == C.STATE_PENDING, "crash window leaves a pending record behind an advanced watermark")
	store.fail_after = -1
	var after_crash := ExplorationHost.new(store)
	after_crash.restore()
	check(store.get_keepsakes() == {cone: 2} and after_crash.can_begin(), "pending trip at the watermark settles without a second grant")
	# 存档损坏：不崩溃、不授予，给温和说明
	var broken := make_store()
	broken._data.exploration = {"schema": "nonsense", "state": 42}
	var director: Node = Director.new()
	var notice: String = director.attach(broken, null)
	check(broken.get_keepsakes().is_empty(), "malformed record grants nothing")
	check(notice in ["", "notice.exploration.unavailable"], "malformed record restores to a calm yard notice")
	director.free()
	var untrusted := make_store()
	untrusted._data.exploration_committed_serial = -1
	var guarded := ExplorationHost.new(untrusted)
	guarded.restore()
	check(not guarded.begin(CLOCK, 1).ok, "untrusted watermark refuses new walks instead of risking double grants")


func _scroll_and_director() -> void:
	root.size = Vector2i(1280, 720)
	var value := seed_where(true, true, true)
	var store := make_store()
	var world := Node2D.new()
	root.add_child(world)
	var director: Node = Director.new()
	root.add_child(director)
	director.attach(store, world)
	var keys: Array[String] = []
	director.returned.connect(func(key: String) -> void: keys.append(key))
	check(director.try_begin(CLOCK, "sunny", value) and director.is_exploring(), "director opens the scroll")
	check(not director.try_begin(CLOCK, "sunny", value), "a second begin while walking is ignored")
	var scroll: Node2D = director.scroll
	await process_frame
	check(scroll.camera.is_current(), "scroll camera takes over")
	check(scroll.hud.layer < 10, "scroll HUD sits under the pause overlay")
	check(scroll.observe("gate") and scroll.pick_choice().kind == "none", "gate is just for looking")
	scroll.end_observe()
	scroll.x = L.stop("brook").x
	check(scroll.nearby_stop() == "brook", "walking to the brook makes it nearby")
	check(scroll.observe() and scroll.observing == "brook", "observe always enters at a nearby stop")
	var first: String = scroll.pick_choice().find_id
	check(scroll.pick_choice().kind == "take" and scroll.pick() and scroll.carried() == [first], "take puts the find in the basket")
	check(scroll.pick_choice().kind == "release", "the find can be put back where it was found")
	scroll.press_at(Vector2(200, 300))
	check(scroll.suppressed_touches == 1 and scroll.observing == "brook", "tapping the scene while looking does not walk away")
	scroll.end_observe()
	scroll.x = L.stop("shade").x
	scroll.observe()
	var second: String = scroll.pick_choice().find_id
	var commits_before: int = store.commits
	check(scroll.pick_choice().kind == "swap" and scroll.pick() and scroll.carried() == [second], "a full basket swaps instead of piling up")
	var saved_carried: Array = store.get_exploration_record().session.carried
	check(store.commits == commits_before + 1 and saved_carried == [second], "a swap is saved in one write, never as an empty basket")
	scroll.end_observe()
	scroll.x = L.stop("brook").x
	scroll.observe()
	check(scroll.pick_choice().kind == "swap" and scroll.pick_choice().find_id == first, "the swapped-out find is still at its own stop")
	scroll.end_observe()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_R
	key.pressed = true
	root.push_input(key)
	scroll._request_return("player")
	await process_frame
	check(keys.size() == 1 and not director.is_exploring(), "R / return button leaves exactly once")
	check(keys[0] == "notice.exploration.kept.%s" % second.get_slice(".", 2), "return notice names the committed find")
	check(store.get_keepsakes() == {second: 1}, "only the carried find is kept")
	check(not is_instance_valid(scroll) or scroll.is_queued_for_deletion(), "scroll is released after return")
	await process_frame
	var notices: Array[String] = []
	director.notice.connect(func(k: String) -> void: notices.append(k))
	director.try_begin(CLOCK, "sunny", value)
	director.scroll.x = L.stop("brook").x
	director.scroll.observe()
	var late: String = director.scroll.pick_choice().find_id
	director.scroll.pick()
	store.fail_commits = true
	director.scroll._request_return("player")
	await process_frame
	check(keys[-1] == "notice.exploration.deferred_items", "a failed save returns home without claiming the find is kept")
	store.fail_commits = false
	check(not director.try_begin(CLOCK, "sunny", value) and notices[-1] == "notice.exploration.kept.%s" % late.get_slice(".", 2), "a late save on the way out stays in the yard so its kept notice is seen")
	check(director.try_begin(CLOCK, "sunny", value), "the next tap goes out")
	director.scroll._request_return("player")
	await process_frame
	director.try_begin(CLOCK, "overcast", value)
	scroll = director.scroll
	scroll.x = L.WALK_MIN
	scroll._hold_direction = -1
	for i in 40:
		scroll._process(1.0 / 60.0)
	await process_frame
	check(keys[-1] == "notice.exploration.back_empty", "holding left at the path start walks home empty-handed")
	director.free()
	world.free()


func _main_round_trip() -> void:
	var save_store := root.get_node("SaveStore")
	var keep_before: Dictionary = save_store.get_keepsakes()
	# 先在真实 SaveStore 里留一趟“走到一半”的记录，模拟上次外出途中关掉游戏
	var value := seed_where(true, false)
	var pre := ExplorationHost.new(save_store)
	pre.restore()
	pre.begin(CLOCK, value)
	pre.visit("brook")
	var find := offer(pre)
	pre.take(find)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	main._start_holiday()
	await process_frame
	check(main._notice_key == "notice.exploration.kept.%s" % find.get_slice(".", 2), "Main restores an interrupted walk with a kept notice")
	check(int(save_store.get_keepsakes().get(find, 0)) == int(keep_before.get(find, 0)) + 1, "the interrupted walk's find is in the real save")
	var world = main._world
	var exit := YardSceneHotspots.get_hotspot(YardSceneHotspots.PATH_OUT)
	check(YardInteraction.pointer(world, Vector2(120, 680)).target == YardSceneHotspots.PATH_OUT, "tapping the bottom-left stone path targets the way out")
	check(YardInteraction.pointer(world, world._plant_point()).target == "plant", "the plant bed keeps its own tap target")
	world.debug_place_player(exit.approach_points[0])
	check(world.primary_action().target == YardSceneHotspots.PATH_OUT and world.primary_action_key() == "action.go_out", "standing at the path end offers going out")
	var stolen := 0
	var core_stolen := 0
	var sampled := 0
	for x in range(130, 284, 3):
		for y in range(500, 652, 3):
			var spot := Vector2(x, y)
			if spot.distance_to(world._plant_point()) >= 75.0 or not YardGround.allows(spot, YardGround.lawn(), true):
				continue
			sampled += 1
			world.debug_place_player(spot)
			if world.primary_action().target == YardSceneHotspots.PATH_OUT:
				stolen += 1
				core_stolen += 1 if spot.distance_to(world._plant_point()) < YardInteraction.PLANT_CORE else 0
	check(sampled > 100 and core_stolen == 0 and stolen * 20 <= sampled, "going out only takes a sliver at the path end from the plant bed (%d/%d)" % [stolen, sampled])
	world.debug_place_player(exit.approach_points[0] + Vector2(-8, -8))
	check(world.primary_action().target == YardSceneHotspots.PATH_OUT, "stopping just short of the path end still offers going out")
	world.debug_place_player(YardSceneHotspots.get_hotspot(YardSceneHotspots.FENCE_GATE).approach_points[0])
	check(world.primary_action().target == YardSceneHotspots.FENCE_GATE, "fence gate observation is unchanged")
	world.debug_place_player(exit.approach_points[0] + Vector2(3, 2))
	world._interact_with_target(YardSceneHotspots.PATH_OUT)
	await process_frame
	check(main._screen == "exploring" and main._exploration.is_exploring(), "going out opens the near-path scroll")
	check(not world.visible and not world.input_enabled and not main._hud.visible, "the yard and its HUD rest while walking")
	var day_before: float = world._day_elapsed
	main._process(1.0)
	check(world._day_elapsed == day_before, "yard time does not run while out walking")
	var esc := InputEventAction.new()
	esc.action = "pause"
	esc.pressed = true
	main._input(esc)
	var scroll = main._exploration.scroll
	check(main._pause_screen.visible and paused and not scroll.can_process(), "Esc pauses the walk under the pause menu")
	main._input(esc)
	check(not main._pause_screen.visible and not paused and scroll.can_process(), "Esc resumes the walk")
	check(not world.input_enabled, "resuming the walk keeps the yard input off")
	var pause_chip: Button = scroll._pause_button
	check(pause_chip.is_visible_in_tree(), "the scroll has its own touch pause button")
	scroll.press_at(pause_chip.get_global_rect().get_center())
	check(main._pause_screen.visible and paused, "tapping the scroll pause button opens the pause menu")
	main._toggle_pause()
	check(not main._pause_screen.visible and not paused, "resume returns to the walk")
	scroll._request_return("player")
	await process_frame
	check(main._screen == "game" and world.visible and world.input_enabled and main._hud.visible, "return restores the yard")
	check(world.get_player().position.distance_to(exit.approach_points[0]) < 1.0, "the resident stands at the path end after returning")
	check(main._camera.is_current(), "yard camera is current again")
	check(main._notice_key == "notice.exploration.back_empty", "empty return notice in the yard")
	# 外出中回标题：按宿主中断回院，带上的东西照常收下
	world._save_progress()
	check(main._exploration.try_begin({"day": world.holiday_day, "elapsed": world._day_elapsed}, "sunny", value), "can go out again")
	await process_frame
	check(main._screen == "exploring", "director entry switches Main to the walk")
	scroll = main._exploration.scroll
	scroll.observe("brook")
	var carried_find: String = scroll.pick_choice().find_id
	scroll.pick()
	var before_title: Dictionary = save_store.get_keepsakes()
	main._show_title()
	await process_frame
	check(main._screen == "title" and not main._exploration.is_exploring(), "title interrupts the walk safely")
	check(main._exploration.host.state() == C.STATE_IDLE, "interrupted walk is closed in the save")
	check(int(save_store.get_keepsakes().get(carried_find, 0)) == int(before_title.get(carried_find, 0)) + 1, "the find carried when leaving to the title is kept")
	main._start_holiday()
	await process_frame
	check(main._screen == "game" and main._notice_key == "notice.arrive", "next holiday starts in the yard with nothing pending")
	main.queue_free()
	await process_frame
