extends SceneTree
const Memory := preload("res://test/fixtures/exploration_memory_store.gd")
const CLOCK := {"day": 2, "elapsed": 20.0}
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)
func run() -> void:
	var catalog := ExplorationRoutes.catalog()
	check(catalog.is_valid(), "hidden catalog validates")
	var invalid := ExplorationRoutes.routes()
	invalid[ExplorationRoutes.NEAR_PATH].stops.leaf_pile.hidden.actor_id = "unknown"
	check(not ExplorationCatalog.new(ExplorationContract.SOURCE_FORMAL, invalid).is_valid(), "bad hidden identity fails catalog validation")
	var cow := ExplorationSession.new(catalog, 0)
	var seed_value := 0
	while AnimalCompanions.choose({"nearby": ["cow"], "rope": ""}, str(seed_value)).is_empty(): seed_value += 1
	cow.begin(ExplorationRoutes.NEAR_PATH, CLOCK, seed_value, {"nearby": ["cow"], "rope": ""})
	cow.visit("leaf_pile")
	check(not cow.uncover().ok, "different companion does not get a llama-only discovery")
	var old_routes := ExplorationRoutes.routes()
	old_routes[ExplorationRoutes.NEAR_PATH].stops.erase("leaf_pile")
	for stop: Dictionary in old_routes[ExplorationRoutes.NEAR_PATH].stops.values(): stop.next.erase("leaf_pile")
	var old_catalog := ExplorationCatalog.new(ExplorationContract.SOURCE_FORMAL, old_routes)
	for seed_number in 10:
		var old := ExplorationSession.new(old_catalog, 0)
		var current := ExplorationSession.new(catalog, 0)
		old.begin(ExplorationRoutes.NEAR_PATH, CLOCK, seed_number)
		current.begin(ExplorationRoutes.NEAR_PATH, CLOCK, seed_number)
		for stop_id: String in ExplorationRoutes.ORDINARY_STOPS:
			if stop_id != "gate":
				old.visit(stop_id)
				current.visit(stop_id)
			check(old.get_view().offer == current.get_view().offer, "ordinary solo rewards retain their exact seed result")
	await full_basket()
	for context in [{}, {"nearby": [], "rope": "llama"}]:
		var session := ExplorationSession.new(catalog, 0)
		session.begin(ExplorationRoutes.NEAR_PATH, CLOCK, 7, context)
		check(not session.uncover().ok, "no remote discovery from another stop")
		session.visit("leaf_pile")
		check(session.get_view().offer == "" and not session.take(ExplorationRoutes.FIND_PINE_CONE).ok, "looking alone does not expose hidden reward")
		if context.is_empty():
			check(not session.uncover().ok and session.get_view().offer == "", "solo cannot uncover")
		else:
			check(session.uncover().ok and session.get_view().offer == ExplorationRoutes.FIND_PINE_CONE, "frozen llama reveals the fixed find")
			var before: Dictionary = session.to_record()
			check(session.uncover().ok and before == session.to_record(), "repeated discovery does not reroll or revise")
			check(session.take(ExplorationRoutes.FIND_PINE_CONE).ok and not session.take(ExplorationRoutes.FIND_PINE_CONE).ok, "one item, not duplicate grants")
			check(session.release(ExplorationRoutes.FIND_PINE_CONE).ok and session.get_view().offer == ExplorationRoutes.FIND_PINE_CONE, "can leave it behind")
			session.take(ExplorationRoutes.FIND_PINE_CONE)
			var restored := ExplorationSession.restore(JSON.parse_string(JSON.stringify(session.to_record())), catalog, 0)
			check(restored.host_action == ExplorationContract.HOST_REQUEST_RETURN_RESTORED and restored.session.get_view().carried == [ExplorationRoutes.FIND_PINE_CONE], "real record shape survives JSON and requests safe return")
			var retired := ExplorationSession.restore(session.to_record(), old_catalog, 0)
			check(retired.session.get_view().carried == [ExplorationRoutes.FIND_PINE_CONE] and retired.session.to_record().session.offers.leaf_pile == ExplorationRoutes.FIND_PINE_CONE, "older route without the hidden stop preserves the carried find and its origin")
	for landed in [false, true]:
		var memory := Memory.new()
		var host := ExplorationHost.new(memory)
		host.restore()
		host.begin(CLOCK, 7, {"nearby": [], "rope": "llama"})
		memory.pump()
		host.visit("leaf_pile")
		memory.pump()
		memory.unknown_kind = "exploration"
		host.uncover()
		memory.pump()
		check(host.view().unsaved_changes and memory.get_exploration_record().session.offers.leaf_pile == "", "unknown save cannot claim confirmed find")
		var count: int = memory.queue.size()
		host.uncover()
		check(memory.queue.size() == count, "unknown result cannot enqueue another retry")
		memory.resolve_unknown(landed)
		if not landed:
			check(host.view().unsaved_changes, "rejection remains unconfirmed")
			host.uncover()
			memory.pump()
		check(not host.view().unsaved_changes, "confirmed discovery or explicit retry settles")
		host.take(ExplorationRoutes.FIND_PINE_CONE)
		host.request_return("player")
		memory.pump()
		check(host.can_begin() and memory.get_keepsakes().get(ExplorationRoutes.FIND_PINE_CONE, 0) == 1, "return puts exactly one find in the shared basket")
		memory.free()
	await adapter()
	print("ANIMAL_HIDDEN_FIND checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
func full_basket() -> void:
	var memory := Memory.new()
	var host := ExplorationHost.new(memory)
	host.restore()
	var seed_value := 0
	while seed_value < 1000:
		var trial := ExplorationSession.new(ExplorationRoutes.catalog(), 0)
		trial.begin(ExplorationRoutes.NEAR_PATH, CLOCK, seed_value)
		var count := 0
		for stop_id: String in ExplorationRoutes.ORDINARY_STOPS:
			if stop_id != "gate": trial.visit(stop_id)
			if not trial.get_view().offer.is_empty(): count += 1
		if count >= 3: break
		seed_value += 1
	host.begin(CLOCK, seed_value, {"nearby": [], "rope": "llama"})
	for stop_id: String in ExplorationRoutes.ORDINARY_STOPS:
		if stop_id != "gate": host.visit(stop_id)
		var offer: String = host.view().offer
		if not offer.is_empty() and host.view().carried.size() < 3: host.take(offer)
	check(host.view().carried.size() == 3, "ordinary finds can still fill the basket")
	host.visit("leaf_pile")
	host.uncover()
	memory.pump()
	check(not host.take(ExplorationRoutes.FIND_PINE_CONE).ok, "hidden item obeys the original three-item capacity")
	var first: String = host.view().carried[0]
	check(host.swap(first, ExplorationRoutes.FIND_PINE_CONE).ok and host.view().carried.size() == 3, "hidden item can atomically replace a carried find")
	host.request_return("player")
	memory.pump()
	var total := 0
	for value: Variant in memory.get_keepsakes().values(): total += int(value)
	check(total == 3 and host.can_begin(), "swapped basket settles once with no extra reward")
	memory.free()
	await process_frame
func adapter() -> void:
	var memory := Memory.new()
	var host := ExplorationHost.new(memory)
	root.add_child(memory)
	host.restore()
	host.begin(CLOCK, 7, {"nearby": [], "rope": "llama"})
	memory.pump()
	var scene = load("res://scripts/exploration/near_path_scroll.gd").new()
	root.add_child(scene)
	scene.setup(host, "sunny")
	check(scene._caption.text.contains(root.get_node("I18n").t("target.llama")), "departure caption names the accompanying resident")
	scene.set_process(false)
	scene.place_at("leaf_pile")
	scene.observe()
	memory.pump()
	check(scene.pick_choice().kind == "none", "no pick before search animation")
	scene._update_search()
	check(scene.companion.search_elapsed == 0.0, "distant partner must walk over first")
	for i in 12:
		scene.walk(Vector2.ZERO, 0.1)
		scene._update_search()
	check(host.view().offer == "", "partial search gives no reward")
	paused = true
	for i in 3: await process_frame
	check(host.view().offer == "" and scene.companion.search_spot.is_empty(), "actual pause interrupts the action without granting a find")
	paused = false
	scene.end_observe()
	check(scene.companion.search_spot.is_empty() and host.view().offer == "", "leaving interrupts without reward")
	scene.observe()
	memory.pump()
	root.get_node("TuningStore").set_value("ui.reduced_motion", true, false)
	memory.unknown_kind = "exploration"
	for i in 100:
		scene.walk(Vector2.ZERO, 0.1)
		scene._update_search()
		memory.pump()
	check(scene.companion.search_cel.visible and scene.pick_choice().kind == "none" and scene.revealed.get("leaf_pile", "") == "", "low-motion pose is visible but unknown save cannot reveal or pick the item")
	check(not scene.pick(), "button/API cannot claim an unconfirmed hidden offer")
	memory.resolve_unknown(true)
	scene._update_search()
	check(scene.pick_choice().kind == "take" and scene.revealed.get("leaf_pile") == ExplorationRoutes.FIND_PINE_CONE, "visible completed action plus confirmed save exposes pickup")
	check(scene.pick(), "player chooses to pick up")
	check(host.view().carried == [ExplorationRoutes.FIND_PINE_CONE], "picked find uses original carried ledger")
	memory.pump()
	scene._update_search()
	check(scene._caption.text.contains(root.get_node("I18n").t("exploration.caption.in_basket", {"item": scene._find_name(ExplorationRoutes.FIND_PINE_CONE)})), "confirmed pickup replaces the saving caption with its real basket state")
	check(scene.pick() and host.view().carried.is_empty(), "visible release returns the find to its original location")
	memory.pump()
	for size: Vector2i in [Vector2i(390, 844), Vector2i(568, 320)]:
		root.size = size
		await process_frame
		scene.walk(Vector2.ZERO, 0.0)
		for locale: String in ["zh-CN", "en"]:
			root.get_node("I18n").set_locale(locale)
			scene._show_caption(scene._observe_caption(), 0.0)
			scene._refresh()
			var head: Vector2 = scene.art_to_screen(scene.foot() + Vector2(0, -108) * NearPathLayout.depth(scene.foot().y))
			check(not scene._caption.get_global_rect().has_point(head), "hidden-find caption leaves the player head visible in " + locale)
			check(scene._caption.position.y + scene._caption.size.y <= scene._basket.position.y, "caption and basket remain separate in " + locale)
			check(scene._pick_button.get_global_rect().end.y <= size.y and scene._return_button.get_global_rect().end.x <= size.x, "pickup and return stay in the viewport")
	root.get_node("I18n").set_locale("zh-CN")
	root.get_node("TuningStore").set_value("ui.reduced_motion", false, false)
	scene.release()
	scene.queue_free()
	memory.queue_free()
	await process_frame
