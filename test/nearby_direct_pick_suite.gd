extends SceneTree

const Store := preload("res://test/fixtures/exploration_memory_store.gd")
const CLOCK := {"day": 3, "elapsed": 12.5}
var Scroll: GDScript
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func seed_four() -> int:
	for seed_value in 2000:
		var session := ExplorationSession.new(ExplorationRoutes.catalog(), 0)
		session.begin(ExplorationRoutes.NEAR_PATH, CLOCK, seed_value)
		if session.get_view().ground_offers.size() == 4: return seed_value
	return -1

func run() -> void:
	Scroll = load("res://scripts/exploration/near_path_scroll.gd")
	var seed_value := seed_four()
	check(seed_value >= 0, "four-find deterministic route exists")
	_preview(seed_value)
	for view_size: Vector2i in [Vector2i(390, 844), Vector2i(844, 390), Vector2i(1280, 720)]:
		await _scene(seed_value, view_size)
	await _pending_and_failure(seed_value)
	print("NEARBY_DIRECT_PICK checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

func _preview(seed_value: int) -> void:
	var session := ExplorationSession.new(ExplorationRoutes.catalog(), 0)
	session.begin(ExplorationRoutes.NEAR_PATH, CLOCK, seed_value)
	var before: Dictionary = session.to_record()
	var finds: Dictionary = session.get_view().ground_offers
	check(session.to_record() == before, "read-only ground preview never visits or persists")
	check(not finds.has("leaf_pile"), "ordinary preview cannot expose companion secret")
	finds["brook"] = "fake"
	check(session.get_view().ground_offers.brook != "fake", "preview cannot mutate session")
	for stop_id: String in ExplorationRoutes.ORDINARY_STOPS:
		var promised: String = session.get_view().ground_offers[stop_id]
		if session.get_view().current_stop != stop_id: session.visit(stop_id)
		check(session.get_view().offer == promised, "visit matches visible find at " + stop_id)
	var restored := ExplorationSession.restore(session.to_record(), ExplorationRoutes.catalog(), 0).session as ExplorationSession
	check(restored.get_view().ground_offers == session.get_view().ground_offers, "existing record and seeds reproduce visible finds")

func _new_scene(seed_value: int) -> Dictionary:
	var store := Store.new()
	root.add_child(store)
	var host := ExplorationHost.new(store)
	host.restore()
	host.begin(CLOCK, seed_value)
	store.pump()
	var scroll: Node2D = Scroll.new()
	root.add_child(scroll)
	scroll.setup(host, "sunny")
	scroll.set_process(false)
	return {"store": store, "host": host, "scroll": scroll}

func _approach(scroll: Node2D, store: Node, stop_id: String) -> void:
	var entry: Dictionary = scroll.layout.stop(stop_id)
	# Start within sight, still far enough away to verify an actual road walk.
	scroll.spot = scroll.layout.nearest(scroll.layout.position(entry) + Vector2(90, 40))
	scroll.walker.position = scroll.foot()
	scroll._snap_camera()
	check(Rect2(Vector2.ZERO, Vector2(root.size)).has_point(scroll.art_to_screen(entry.item)), "target is genuinely visible before its click")
	scroll.press_at(scroll.art_to_screen(entry.item))
	check(scroll.walk_target.get("collect_stop", "") == stop_id, "ground click targets actual find " + stop_id)
	for i in 500:
		scroll.walk(Vector2.ZERO, 0.05)
		store.pump()
		if not scroll._pending_collect_stop.is_empty(): scroll._collect_at_stop(scroll._pending_collect_stop)
		if scroll.walk_target.is_empty() and scroll._pending_collect_stop.is_empty(): break
	check(scroll.layout.route_length(scroll.spot, entry) < 0.5, "pickup walks to road anchor " + stop_id)

func _scene(seed_value: int, view_size: Vector2i) -> void:
	root.size = view_size
	var context := _new_scene(seed_value)
	var scroll := context.scroll as Node2D
	var store := context.store as Node
	var host := context.host as ExplorationHost
	await process_frame
	var frame: Dictionary = scroll.target_frame()
	check(float(frame.zoom) > minf(view_size.x / scroll.layout.SIZE.x, view_size.y / scroll.layout.SIZE.y), "all sizes use a local yard-scale view")
	check(scroll.painting.scale == Vector2.ONE, "camera never changes map/person ratio")
	var zoom: float = scroll.camera_zoom()
	for stop_id: String in ExplorationRoutes.ORDINARY_STOPS:
		var before: Array = host.view().carried.duplicate()
		var visible: String = scroll.ground_finds()[stop_id]
		_approach(scroll, store, stop_id)
		if before.size() < 3:
			check(host.view().carried == before + [visible], "one click adds exactly the pictured find")
			check(not scroll.ground_finds().has(stop_id), "taken find disappears only from its location")
		else:
			check(host.view().carried == before and scroll.ground_finds().has(stop_id), "capacity full preserves basket and ground item without swapping")
		check(scroll.observing.is_empty() and not scroll._go_button.visible, "pickup needs no continue action")
		check(is_equal_approx(scroll.camera_zoom(), zoom), "walking and pickup preserve camera scale")
		var screen: Vector2 = scroll.art_to_screen(scroll.foot())
		check(scroll.screen_to_art(screen).distance_to(scroll.foot()) < 0.01, "camera click transform remains reversible")
		var count: int = host.view().carried.size()
		scroll.press_at(scroll.art_to_screen(scroll.layout.stop(stop_id).item))
		scroll.walk(Vector2.ZERO, 0.05)
		store.pump()
		check(host.view().carried.size() == count, "repeated click never duplicates or releases a find")
		scroll.walk_target = {}
	var north: Dictionary = scroll.layout.nearest(scroll.layout.point("north", scroll.layout.arm_length("north")))
	scroll.spot = north
	scroll.walk(scroll.layout.tangent("north", north.d), 0.1)
	check(scroll._caption.text == root.get_node("I18n").t("exploration.caption.closed_edge"), "unopened road edge gives requested prompt")
	var granted: Array = host.view().carried.duplicate()
	host.request_return()
	store.pump()
	for find_id: String in granted:
		check(store.get_keepsakes().get(find_id, 0) == granted.count(find_id), "return grants each picked quantity once")
	var second := ExplorationHost.new(store)
	second.restore()
	store.pump()
	check(second.can_begin() and store.get_keepsakes().values().reduce(func(a: int, b: int) -> int: return a + b, 0) == 3, "re-entry cannot duplicate returned inventory")
	scroll.release()
	scroll.queue_free()
	store.queue_free()
	await process_frame

func _pending_and_failure(seed_value: int) -> void:
	var context := _new_scene(seed_value)
	var scroll := context.scroll as Node2D
	var store := context.store as Node
	var host := context.host as ExplorationHost
	await process_frame
	store.unknown_kind = "exploration"
	_approach(scroll, store, "brook")
	check(host.view().carried.size() == 1 and host.view().unsaved_changes, "unknown record keeps one pending pickup")
	scroll.press_at(scroll.art_to_screen(scroll.layout.stop("shade").item))
	for i in 500:
		scroll.walk(Vector2.ZERO, 0.05)
		if scroll.walk_target.is_empty(): break
	check(host.view().carried.size() == 1 and scroll._pending_collect_stop == "shade", "second pickup waits for unresolved persistence")
	scroll.press_at(scroll.art_to_screen(scroll.layout.point("lane", 320.0)))
	check(scroll._pending_collect_stop.is_empty() and not scroll.walk_target.is_empty(), "ground movement cancels waiting pickup without locking player")
	store.resolve_unknown(false)
	store.pump()
	var carried: Array = host.view().carried.duplicate()
	store.fail_kind_once = "exploration_trip"
	host.request_return()
	store.pump()
	check(host.state() == ExplorationContract.STATE_FAILURE and store.get_keepsakes().is_empty(), "failed return never publishes inventory")
	host.retry_deferred()
	store.pump()
	check(host.can_begin() and store.get_keepsakes().get(carried[0], 0) == 1, "retry grants retained pickup once")
	var restored := ExplorationHost.new(store)
	restored.restore()
	store.pump()
	check(store.get_keepsakes().get(carried[0], 0) == 1, "reopen after retry cannot duplicate quantity")
	scroll.release()
	scroll.queue_free()
	store.queue_free()
	await process_frame
