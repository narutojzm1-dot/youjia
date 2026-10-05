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
	_host_basket_sizes()
	_painted_path_layout()
	await _painted_path_walk()
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


## 四处停留点都有东西的种子：能走到“篮子满了还遇到第四件”
func seed_all_four() -> int:
	for value in 4000:
		var session := ExplorationSession.new(ExplorationRoutes.catalog(), 0)
		session.begin(ExplorationRoutes.NEAR_PATH, CLOCK, value)
		var full := str(session.get_view().get("offer", "")) != ""
		for stop_id: String in ["brook", "shade", "slope"]:
			session.visit(stop_id)
			full = full and str(session.get_view().get("offer", "")) != ""
		if full:
			return value
	return -1


func I18n_t(key: String) -> String:
	return root.get_node("I18n").t(key)


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
	check(store.get_exploration_record() == null and host.view().unsaved_changes, "the record is only accepted, not yet published, before confirmation")
	store.pump()
	check(store.get_exploration_record() is Dictionary and not host.view().unsaved_changes, "begin persists the session record once confirmed")
	host.visit("brook")
	var stone := offer(host)
	check(not stone.is_empty() and host.take(stone).ok, "brook find can be taken")
	host.visit("brook")
	check(host.view().get("carried", []) == [stone], "revisiting the current stop is a no-op")
	var result := host.request_return("player")
	check(result.navigate and result.outcome.is_empty() and host.is_settling(), "return navigates at once while the commit waits in the queue")
	check(store.get_keepsakes().is_empty() and not host.can_begin(), "nothing is granted and no new walk starts before confirmation")
	var settled: Array[Dictionary] = []
	host.settled.connect(func(outcome: Dictionary) -> void: settled.append(outcome))
	store.pump()
	check(settled.size() == 1 and settled[0].state == "committed" and settled[0].items == PackedStringArray([stone]), "confirmation settles the return with the carried find")
	check(store.get_keepsakes() == {stone: 1} and store.get_exploration_committed_serial() == 1, "keepsake and watermark land in one commit")
	check(host.state() == C.STATE_IDLE and host.can_begin(), "after commit the walk is closed and a new one can start")
	var again := host.request_return("player")
	store.pump()
	check(again.navigate and store.get_keepsakes() == {stone: 1} and settled.size() == 1, "duplicate return navigates without granting twice")
	check(Director.outcome_notice(settled[0]) == "notice.exploration.kept.%s" % stone.get_slice(".", 2), "kept notice names the find only after commit")
	host.begin(CLOCK, value)
	host.request_return("player")
	store.pump()
	check(settled[-1].state == "committed" and settled[-1].items.is_empty(), "empty-handed return is allowed")
	check(store.get_keepsakes() == {stone: 1} and store.get_exploration_committed_serial() == 2, "empty trip advances the watermark only")
	check(Director.outcome_notice(settled[-1]) == "notice.exploration.back_empty", "empty trip says back, not kept")
	var receipt := {}
	check(not store.request_exploration_trip(store.get_exploration_record(), 2, PackedStringArray([stone]), receipt).is_empty(), "a stale trip is still accepted into the queue")
	store.pump()
	check(receipt.granted == false and store.get_keepsakes() == {stone: 1} and store.get_exploration_committed_serial() == 2, "a serial at or below the watermark grants nothing when it reaches the head")
	check(store.request_exploration_trip(null, 9, PackedStringArray(["fixture.find.x"]), {}).is_empty() and store.queue.is_empty(), "store refuses non-formal finds before queueing")
	# 两笔同一趟的提交先后到达队首：第二笔看到已前进的水位线，只写记录
	var first := {}
	var second := {}
	store.request_exploration_trip(null, 3, PackedStringArray([stone]), first)
	store.request_exploration_trip(null, 3, PackedStringArray([stone]), second)
	store.pump()
	check(first.granted and not second.granted and store.get_keepsakes() == {stone: 2}, "two queued commits of one trip grant once")


## 四处都有东西、且有同名的种子 → 依次要带上的三处停留点（含重复）
func full_repeat_trip() -> Dictionary:
	for value in 6000:
		var session := ExplorationSession.new(ExplorationRoutes.catalog(), 0)
		session.begin(ExplorationRoutes.NEAR_PATH, CLOCK, value)
		var offers := {"gate": str(session.get_view().get("offer", ""))}
		for stop_id: String in ["brook", "shade", "slope"]:
			session.visit(stop_id)
			offers[stop_id] = str(session.get_view().get("offer", ""))
		if offers.values().has(""):
			continue
		for triple: Array in [["gate", "brook", "shade"], ["gate", "brook", "slope"], ["gate", "shade", "slope"], ["brook", "shade", "slope"]]:
			var finds: Array = triple.map(func(stop_id: String) -> String: return offers[stop_id])
			if finds.count(finds[0]) > 1 or finds.count(finds[1]) > 1:
				return {"seed": value, "stops": triple, "finds": finds}
	return {}


func _counts(finds: Array) -> Dictionary:
	var counts := {}
	for find_id: String in finds:
		counts[find_id] = int(counts.get(find_id, 0)) + 1
	return counts


## 0/1 件在别处覆盖；这里补 2 件回院、3 件含重复的中途重启与重启时写盘失败
func _host_basket_sizes() -> void:
	var trip := full_repeat_trip()
	check(not trip.is_empty(), "a seed with finds everywhere and a repeat exists")
	var store := make_store()
	var host := ExplorationHost.new(store)
	host.restore()
	host.begin(CLOCK, trip.seed)
	for i in 2:
		host.visit(trip.stops[i])
		host.take(trip.finds[i])
	host.request_return("player")
	store.pump()
	var two := host.last_outcome
	check(two.state == "committed" and two.items.size() == 2 and store.get_keepsakes() == _counts(trip.finds.slice(0, 2)), "returning with two finds keeps exactly those two")
	check(Director.outcome_notice(two) == "notice.exploration.kept_many", "two finds get the kept-many notice")
	var before: Dictionary = store.get_keepsakes().duplicate()
	host.begin(CLOCK, trip.seed)
	for i in 3:
		host.visit(trip.stops[i])
		host.take(trip.finds[i])
	store.pump()
	var saved: Dictionary = store.get_exploration_record().session
	check(saved.taken.size() == 3 and saved.carried.size() == 3 and saved.carried.count(trip.finds[0]) + saved.carried.count(trip.finds[1]) > 2, "a full basket with a repeat is saved with every source")
	# 中途关掉游戏，重启时写盘先被拒：回院但不说收好了，之后补存只授予一次
	store.fail_commits = true
	var reopened := ExplorationHost.new(store)
	check(reopened.restore().is_empty(), "a restart's commit waits in the queue")
	store.pump()
	var deferred := reopened.last_outcome
	check(deferred.get("restored", false) and deferred.state == "deferred" and store.get_keepsakes() == before, "a restart whose save is rejected keeps nothing yet")
	store.fail_commits = false
	reopened.retry_deferred()
	store.pump()
	var retried := reopened.last_outcome
	var expected := before.duplicate()
	for find_id: String in trip.finds:
		expected[find_id] = int(expected.get(find_id, 0)) + 1
	check(retried.get("state", "") == "committed" and retried.items.size() == 3 and store.get_keepsakes() == expected, "the retry keeps all three finds, repeats counted")
	var third := ExplorationHost.new(store)
	third.restore()
	store.pump()
	check(third.last_outcome.is_empty() and store.get_keepsakes() == expected, "another restart grants nothing more")
	reopened.begin(CLOCK, trip.seed)
	for i in 3:
		reopened.visit(trip.stops[i])
		reopened.take(trip.finds[i])
	store.pump()
	var clean_host := ExplorationHost.new(store)
	clean_host.restore()
	store.pump()
	var clean := clean_host.last_outcome
	for find_id: String in trip.finds:
		expected[find_id] = int(expected.get(find_id, 0)) + 1
	check(clean.get("restored", false) and clean.state == "committed" and clean.items.size() == 3 and store.get_keepsakes() == expected, "a restart mid-walk with a full repeat basket keeps all three")


func _host_failure_and_retry() -> void:
	var value := seed_where(true, false)
	var store := make_store()
	var host := ExplorationHost.new(store)
	host.restore()
	host.begin(CLOCK, value)
	host.visit("brook")
	var find := offer(host)
	host.take(find)
	store.pump()
	var before := store._data.duplicate(true)
	store.fail_commits = true
	var result := host.request_return("player")
	check(result.navigate, "return navigation does not wait for a failed save")
	store.pump()
	var outcome := host.last_outcome
	check(outcome.state == "deferred" and outcome.items == PackedStringArray([find]), "rejected commit is reported as deferred, not kept")
	check(store._data == before, "rejected commit leaves the published save untouched")
	check(host.state() == C.STATE_FAILURE and not host.can_begin(), "a deferred trip blocks a new walk until saved")
	check(Director.outcome_notice(outcome) == "notice.exploration.deferred_items", "deferred notice does not claim the find is put away")
	host.retry_deferred()
	check(host.retry_deferred().is_empty() and store.queue.filter(func(op: Dictionary) -> bool: return op.kind == "exploration_trip").size() == 1, "a retry already in the queue is not queued twice")
	store.pump()
	check(host.last_outcome.get("state", "") == "deferred" and host.last_outcome.get("retry", false), "retry while the save is still rejected stays deferred")
	store.fail_commits = false
	host.retry_deferred()
	store.pump()
	check(host.last_outcome.get("state", "") == "committed" and store.get_keepsakes() == {find: 1}, "idle retry commits once the save works")
	check(host.retry_deferred().is_empty() and store.get_keepsakes() == {find: 1}, "extra retries never grant twice")
	check(host.can_begin(), "after the retry a new walk can start")
	# 结果未知：原地等待，不说收好也不说没收好；之后查明写上了就只授予一次
	host.begin(CLOCK, value)
	host.visit("brook")
	host.take(find)
	store.pump()
	store.unknown_kind = "exploration_trip"
	host.request_return("player")
	store.pump()
	check(host.state() == C.STATE_PENDING and host.is_settling() and host.last_outcome.is_empty() and store.get_keepsakes() == {find: 1}, "an unknown commit stays pending without any notice")
	check(host.retry_deferred().is_empty() and not host.can_begin(), "no retry or new walk while the outcome is unknown")
	store.resolve_unknown(true)
	check(host.last_outcome.get("state", "") == "committed" and store.get_keepsakes() == {find: 2} and host.can_begin(), "an unknown commit that landed settles once")
	host.begin(CLOCK, value)
	host.visit("brook")
	host.take(find)
	store.pump()
	store.unknown_kind = "exploration_trip"
	host.request_return("player")
	store.pump()
	store.resolve_unknown(false)
	check(host.last_outcome.get("state", "") == "deferred" and store.get_keepsakes() == {find: 2} and host.state() == C.STATE_FAILURE, "an unknown commit that did not land is deferred")


func _host_restore() -> void:
	var value := seed_where(false, true)
	var store := make_store()
	var host := ExplorationHost.new(store)
	host.restore()
	host.begin(CLOCK, value)
	host.visit("shade")
	var cone := offer(host)
	host.take(cone)
	store.pump()
	# 进程在画卷中被关掉：新宿主从同一份存档恢复
	var reopened := ExplorationHost.new(store)
	reopened.restore()
	store.pump()
	var outcome := reopened.last_outcome
	check(outcome.get("restored", false) and outcome.state == "committed" and outcome.items == PackedStringArray([cone]), "restart mid-walk returns home and keeps the carried find")
	check(store.get_keepsakes() == {cone: 1} and reopened.can_begin(), "restored find is granted once and walks can resume")
	var second := ExplorationHost.new(store)
	second.restore()
	store.pump()
	check(second.last_outcome.is_empty() and store.get_keepsakes() == {cone: 1}, "a second restart grants nothing more")
	# 提交成功、紧接着的空闲记录没写上就断电：水位线挡住重复授予
	reopened.begin(CLOCK, value)
	reopened.visit("shade")
	reopened.take(offer(reopened))
	store.pump()
	store.fail_after = 2
	reopened.request_return("player")
	store.pump()
	check(store.get_keepsakes() == {cone: 2} and str(store.get_exploration_record().session.state) == C.STATE_PENDING, "crash window leaves a pending record behind an advanced watermark")
	store.fail_after = -1
	var after_crash := ExplorationHost.new(store)
	var settled_now := after_crash.restore()
	store.pump()
	check(settled_now.get("items", PackedStringArray()).is_empty() and after_crash.last_outcome.get("items", PackedStringArray()).is_empty() and store.get_keepsakes() == {cone: 2} and after_crash.can_begin(), "pending trip at the watermark settles without a second grant")
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


## 原画路径的几何：脚点都在画内、停留点在路上、物件不压在画里已有的松果/落羽上
func _painted_path_layout() -> void:
	var art: Texture2D = load(L.ART)
	check(art != null and Vector2(art.get_size()) == L.SIZE, "the near-path painting loads at its original 1672x941")
	var inside := Rect2(Vector2(60, 60), L.SIZE - Vector2(120, 60))
	var all_inside := true
	for arm: String in L.ARMS:
		check(Vector2(L.ARMS[arm][0]) == L.JUNCTION, "%s path starts at the junction" % arm)
		for i in 21:
			all_inside = all_inside and inside.has_point(L.point(arm, L.arm_length(arm) * i / 20.0))
	check(all_inside, "every foot point stays inside the painted area, off the paper edge")
	var painted := [Vector2(1283, 800), Vector2(1390, 800)]
	var stops_ok := true
	for entry: Dictionary in L.STOPS:
		stops_ok = stops_ok and float(entry.d) <= L.arm_length(entry.arm) and L.nearby({"arm": entry.arm, "d": entry.d}) == entry.id
		for drawn: Vector2 in painted:
			stops_ok = stops_ok and Vector2(entry.item).distance_to(drawn) > 80.0
	check(stops_ok and L.STOPS.map(func(e: Dictionary) -> String: return e.id) == ExplorationRoutes.NEAR_PATH_STOPS, "each catalog stop sits on a path, away from the painted cone and feather")
	check(L.nearby(L.START).is_empty() and not L.at_home(L.START), "the walk starts just outside the gate, not at a stop")
	var producer: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/concepts/producer_world_20261005/near_path_anchors.candidate.json"))
	var route_points: Array = L.ARMS[L.HOME_ARM].duplicate()
	route_points.reverse()
	var matches: bool = producer.route.points.size() == route_points.size()
	for i in mini(producer.route.points.size(), route_points.size()):
		matches = matches and Vector2(producer.route.points[i][0], producer.route.points[i][1]) == route_points[i]
	check(matches and L.ARMS.size() == 1, "the walkable lane is exactly the producer's candidate route, nothing more")
	var painted_ok := true
	for region: Dictionary in producer.painted_object_cleanup_regions:
		var rect := Rect2(region.rect_xywh[0], region.rect_xywh[1], region.rect_xywh[2], region.rect_xywh[3]).grow(30.0)
		for entry: Dictionary in L.STOPS:
			painted_ok = painted_ok and not rect.has_point(entry.item)
	check(painted_ok, "no find is drawn over the producer's painted-object cleanup regions")
	check(L.depth(L.point(L.HOME_ARM, 0.0).y) > L.depth(L.point(L.HOME_ARM, L.arm_length(L.HOME_ARM)).y) * 1.3, "the walker grows toward the foreground")
	var middle := {"arm": L.HOME_ARM, "d": 300.0}
	check(float(L.step_input(middle, Vector2.LEFT, 5.0).d) < 300.0 and float(L.step_input(middle, Vector2.DOWN, 5.0).d) < 300.0, "left or down walks toward the foreground")
	check(float(L.step_input(middle, Vector2.RIGHT, 5.0).d) > 300.0 and float(L.step_input(middle, Vector2.UP, 5.0).d) > 300.0, "right or up walks back toward the gate")
	var tip := {"arm": L.HOME_ARM, "d": 0.0}
	check(L.step_input(tip, Vector2.LEFT, 5.0) == tip and not L.at_home(tip), "the foreground end is not an exit; pushing on stays put")
	var route := {"arm": L.HOME_ARM, "d": 600.0}
	var goal := {"arm": L.HOME_ARM, "d": 195.0}
	var guard := 0
	while L.route_length(route, goal) > 0.5 and guard < 400:
		route = L.step_toward(route, goal, 5.0)
		guard += 1
	check(is_equal_approx(float(route.d), 195.0) and guard == 81, "walking toward a spot arrives without overshooting")
	var desk := L.frame(L.point(L.HOME_ARM, 300.0), Vector2(1280, 720))
	check(L.visible_rect(desk).encloses(Rect2(Vector2.ZERO, L.SIZE).grow(-1.0)), "desktop shows the whole painting")
	var phone_zoom := -1.0
	var phone_ok := true
	for arm: String in L.ARMS:
		for i in 11:
			var foot := L.point(arm, L.arm_length(arm) * i / 10.0)
			var view := L.frame(foot, Vector2(390, 844))
			phone_zoom = float(view.zoom) if phone_zoom < 0.0 else phone_zoom
			phone_ok = phone_ok and is_equal_approx(float(view.zoom), phone_zoom) and L.visible_rect(view).grow(-30.0).has_point(foot) and L.visible_rect(view).grow(-30.0).has_point(foot + L.WALKER_BOX.position * L.depth(foot.y))
	check(phone_ok and phone_zoom > minf(390.0 / L.SIZE.x, 844.0 / L.SIZE.y) * 2.0, "portrait phone keeps one zoom and the walker in view everywhere")
	var wide := L.frame(L.point(L.HOME_ARM, 30.0), Vector2(844, 390))
	check(float(wide.zoom) > minf(844.0 / L.SIZE.x, 390.0 / L.SIZE.y) and L.visible_rect(wide).has_point(L.point(L.HOME_ARM, 30.0)), "landscape phone zooms in past a tiny full view and keeps the walker")


## 实际的适配器：点按路面沿路走过去、方向键沿路走、停下看不变焦、原画不变形
func _painted_path_walk() -> void:
	root.size = Vector2i(390, 844)
	var store := make_store()
	var host := ExplorationHost.new(store)
	host.restore()
	host.begin(CLOCK, seed_all_four())
	var scroll: Node2D = load("res://scripts/exploration/near_path_scroll.gd").new()
	root.add_child(scroll)
	scroll.setup(host, "sunny")
	await process_frame
	check(scroll.painting.scale == Vector2.ONE and scroll.camera.zoom.x == scroll.camera.zoom.y, "the painting is drawn 1:1 and zoomed evenly, never stretched")
	var zoom: float = scroll.camera_zoom()
	var brook: Dictionary = L.stop("brook")
	scroll.press_at(scroll.art_to_screen(L.point(brook.arm, brook.d)))
	check(not scroll.walk_target.is_empty(), "tapping the lane sets a walk target")
	var guard := 0
	while not scroll.walk_target.is_empty() and guard < 1200:
		scroll.walk(Vector2.ZERO, 1.0 / 30.0)
		guard += 1
	check(scroll.nearby_stop() == "brook" and is_equal_approx(float(scroll.spot.d), float(brook.d)), "a tap walks along the lane to the spot")
	check(is_equal_approx(scroll.camera_zoom(), zoom), "walking pans without zooming")
	var shown := Rect2(Vector2.ZERO, Vector2(390, 844))
	check(shown.has_point(scroll.art_to_screen(scroll.foot())), "the walker stays on screen on a portrait phone")
	check(scroll.observe() and is_equal_approx(scroll.camera_zoom(), zoom), "stopping to look keeps the same framing")
	var item_screen: Vector2 = scroll.art_to_screen(brook.item)
	check(shown.grow(-20.0).has_point(item_screen), "the find being looked at is on screen")
	scroll.end_observe()
	var before: float = scroll.spot.d
	scroll.walk(Vector2.LEFT, 0.2)
	check(float(scroll.spot.d) < before and scroll.facing < 0.0, "left walks on down the lane and faces left")
	scroll.press_at(scroll.art_to_screen(Vector2(40, 300)))
	check(not scroll.walk_target.is_empty() and L.nearest(Vector2(40, 300)).arm == scroll.walk_target.arm, "a tap off the path walks to its nearest point instead of leaving it")
	scroll.walk(Vector2.RIGHT, 0.1)
	check(scroll.walk_target.is_empty(), "a key press cancels the tap walk")
	scroll.press_at(scroll.art_to_screen(L.point(brook.arm, brook.d)))
	scroll.notification(Node.NOTIFICATION_PAUSED)
	check(scroll.walk_target.is_empty(), "pausing drops a pending tap walk so resume does not walk on its own")
	scroll.press_at(scroll.art_to_screen(L.point(brook.arm, brook.d)))
	scroll.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(scroll.walk_target.is_empty(), "losing focus drops a pending tap walk")
	scroll.free()
	root.size = Vector2i(1280, 720)


func _scroll_and_director() -> void:
	root.size = Vector2i(1280, 720)
	var value := seed_all_four()
	var store := make_store()
	var world := Node2D.new()
	root.add_child(world)
	var director: Node = Director.new()
	root.add_child(director)
	director.attach(store, world)
	var keys: Array[String] = []
	director.returned.connect(func(key: String) -> void: keys.append(key))
	var notices: Array[String] = []
	director.notice.connect(func(k: String) -> void: notices.append(k))
	check(director.try_begin(CLOCK, "sunny", value) and director.is_exploring(), "director opens the scroll")
	check(not director.try_begin(CLOCK, "sunny", value), "a second begin while walking is ignored")
	var scroll: Node2D = director.scroll
	await process_frame
	check(scroll.camera.is_current(), "scroll camera takes over")
	check(scroll.hud.layer < 10, "scroll HUD sits under the pause overlay")
	check(scroll.observe("gate") and scroll.pick_choice().kind == "take", "the gate may have something too")
	var at_gate: String = scroll.pick_choice().find_id
	scroll.pick()
	scroll.end_observe()
	scroll.place_at("brook")
	check(scroll.nearby_stop() == "brook", "walking to the brook makes it nearby")
	check(scroll.observe() and scroll.observing == "brook", "observe always enters at a nearby stop")
	var at_brook: String = scroll.pick_choice().find_id
	check(scroll.pick_choice().kind == "take" and scroll.pick() and scroll.carried() == [at_gate, at_brook], "take adds to the basket")
	check(scroll.pick_choice().kind == "release" and scroll.pick_choice().find_id == at_brook, "the find can be put back where it was found")
	scroll.press_at(Vector2(200, 300))
	check(scroll.suppressed_touches == 1 and scroll.observing == "brook", "tapping the scene while looking does not walk away")
	scroll.end_observe()
	scroll.place_at("shade")
	scroll.observe()
	var at_shade: String = scroll.pick_choice().find_id
	check(scroll.pick_choice().kind == "take" and scroll.pick() and scroll.carried().size() == 3, "three finds fit in the basket")
	scroll.end_observe()
	scroll.place_at("slope")
	scroll.observe()
	var at_slope: String = scroll.pick_choice().find_id
	check(scroll.pick_choice().kind == "swap" and scroll.pick_choice().old == at_gate, "a fourth find offers to swap out the earliest one")
	check(scroll._caption.text.contains(I18n_t("exploration.find.%s" % at_gate.get_slice(".", 2))), "the caption says which find goes back")
	store.pump()
	var commits_before: int = store.commits
	check(scroll.pick() and scroll.carried().size() == 3 and scroll.carried().count(at_slope) >= 1, "swapping keeps the basket at three")
	store.pump()
	var saved: Dictionary = store.get_exploration_record().session
	check(store.commits == commits_before + 1 and saved.carried.size() == 3 and saved.taken.has("slope") and not saved.taken.has("gate"), "a swap is saved in one write, never with a gap")
	scroll.end_observe()
	scroll.place_at("gate")
	scroll.observe()
	check(scroll.pick_choice().kind == "swap" and scroll.pick_choice().find_id == at_gate, "the swapped-out find is back at its own stop")
	scroll.end_observe()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_R
	key.pressed = true
	root.push_input(key)
	scroll._request_return("player")
	await process_frame
	check(keys.size() == 1 and not director.is_exploring(), "R / return button leaves exactly once")
	check(keys[0] == "" and store.get_keepsakes().is_empty(), "the yard is back before the commit is confirmed, without claiming anything is kept")
	store.pump()
	check(notices[-1] == "notice.exploration.kept_many" and director.last_params.items != "", "the confirmed commit's notice lists the kept finds")
	var expected := {}
	for find_id: String in [at_brook, at_shade, at_slope]:
		expected[find_id] = int(expected.get(find_id, 0)) + 1
	check(store.get_keepsakes() == expected, "exactly the three carried finds are kept, repeats counted")
	check(not is_instance_valid(scroll) or scroll.is_queued_for_deletion(), "scroll is released after return")
	await process_frame
	director.try_begin(CLOCK, "sunny", value)
	director.scroll.place_at("brook")
	director.scroll.observe()
	var late: String = director.scroll.pick_choice().find_id
	director.scroll.pick()
	store.fail_commits = true
	director.scroll._request_return("player")
	await process_frame
	store.pump()
	check(notices[-1] == "notice.exploration.deferred_items", "a rejected save returns home without claiming the find is kept")
	store.fail_commits = false
	check(not director.try_begin(CLOCK, "sunny", value) and notices[-1] == "notice.exploration.still_saving", "going out while the last trip is unsaved queues it again and stays in the yard")
	store.pump()
	check(notices[-1] == "notice.exploration.kept.%s" % late.get_slice(".", 2), "the late save's kept notice is seen in the yard")
	check(director.try_begin(CLOCK, "sunny", value), "the next tap goes out")
	director.scroll._request_return("player")
	await process_frame
	store.pump()
	director.try_begin(CLOCK, "overcast", value)
	scroll = director.scroll
	scroll.spot = {"arm": L.HOME_ARM, "d": L.arm_length(L.HOME_ARM)}
	for i in 40:
		scroll.walk(L.home_direction(), 1.0 / 60.0)
	await process_frame
	store.pump()
	check(notices[-1] == "notice.exploration.back_empty", "walking on into the gate goes home empty-handed")
	# 院内空闲重试又被拒：不再弹提示，之后写上了才说收好了
	director.try_begin(CLOCK, "sunny", value)
	director.scroll.place_at("brook")
	director.scroll.observe()
	director.scroll.pick()
	store.pump()
	store.fail_commits = true
	director.scroll._request_return("player")
	await process_frame
	store.pump()
	var quiet := notices.size()
	director.idle_tick(Director.RETRY_SECONDS + 1.0)
	store.pump()
	check(notices.size() == quiet, "an idle retry that is rejected again stays quiet")
	store.fail_commits = false
	director.idle_tick(Director.RETRY_SECONDS + 1.0)
	store.pump()
	check(notices.size() == quiet + 1 and notices[-1].begins_with("notice.exploration.kept."), "an idle retry that lands says the find is kept")
	director.free()
	world.free()


## 真实 SaveStore 的队列在帧末推进：等到空闲（或超时）再看结果
func drain(save_store: Node) -> bool:
	for i in 120:
		if save_store.is_save_idle():
			return true
		await process_frame
	return save_store.is_save_idle()


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
	check(await drain(save_store) and save_store.get_exploration_record() is Dictionary, "the half-walked record reaches the real save")
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	await main._start_holiday()
	check(main._notice_key == "notice.arrive" or main._notice_key.begins_with("notice.exploration.kept."), "Main enters the yard before the restored commit settles")
	await drain(save_store)
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
	check(main._notice_key == "notice.exploration.back" or main._notice_key == "notice.exploration.back_empty", "back in the yard says so at once")
	await drain(save_store)
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
	await main._show_title()
	check(main._screen == "title" and not main._exploration.is_exploring(), "title interrupts the walk safely")
	check(main._exploration.host.state() == C.STATE_IDLE, "interrupted walk is closed in the save")
	check(int(save_store.get_keepsakes().get(carried_find, 0)) == int(before_title.get(carried_find, 0)) + 1, "the find carried when leaving to the title is kept")
	await main._start_holiday()
	await drain(save_store)
	check(main._screen == "game" and main._notice_key == "notice.arrive", "next holiday starts in the yard with nothing pending")
	main.queue_free()
	await process_frame
