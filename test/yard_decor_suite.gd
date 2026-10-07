extends SceneTree
const Model := preload("res://scripts/inventory/yard_decor.gd")
const Controller := preload("res://scripts/inventory/yard_decor_controller.gd")
const MemoryStore := preload("res://test/fixtures/exploration_memory_store.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func run() -> void:
	var id: String = ExplorationRoutes.FIND_PINE_CONE
	var original := {"keepsakes": {id: 1}, "future_root": {"raw": [3, 4]}, "yard_inventory": {"future_schema": 7}}
	var details := {"find_id": id, "dx": 0, "dy": 0}
	check(Model.read(original) == Model.empty(), "legacy read is empty without write")
	check(not original.has(Model.FIELD), "legacy source untouched")
	var placed: Dictionary = Model.transition(original, 0, "place", "house_edge", details).candidate
	check(Model.available(placed)[id] == 0, "one reservation exhausts the only available item")
	check(placed.keepsakes == original.keepsakes, "total ownership never decremented")
	check(placed.future_root == original.future_root and placed.yard_inventory == original.yard_inventory, "unrelated and future domains preserved")
	check(Model.transition(placed, 0, "place", "fence_edge", details).get("error") == "DECOR_CHANGED", "replayed revision cannot duplicate")
	check(Model.transition(placed, 1, "place", "fence_edge", details).get("error") == "DECOR_EMPTY", "latest revision cannot reuse reserved item")
	check(Model.transition(placed, 1, "place", "house_edge", details).get("error") == "DECOR_OCCUPIED", "occupied slot not overwritten")
	var moved: Dictionary = Model.transition(placed, 1, "move", "house_edge", {"dx": 1, "dy": -1}).candidate
	check(moved.yard_decor.places.house_edge.find_id == id, "adjust preserves identity")
	check(Model.available(moved)[id] == 0, "adjust preserves reservation")
	var returned: Dictionary = Model.transition(moved, 2, "remove", "house_edge", {}).candidate
	check(Model.available(returned)[id] == 1 and returned.keepsakes == original.keepsakes, "return releases rather than grants")
	check(Model.transition(returned, 3, "remove", "house_edge", {}).get("error") == "DECOR_EMPTY", "repeat remove cannot mint")
	check(Model.read(JSON.parse_string(JSON.stringify(moved))) == moved.yard_decor, "JSON round trip retains slot and offsets")
	for spot: String in Model.SPOTS:
		for dx: int in [-1, 0, 1]:
			for dy: int in [-1, 0, 1]:
				check(YardGround.allows(Model.position_for(spot, {"dx": dx, "dy": dy}), YardGround.lawn(), true), "candidate center remains lawn " + spot)
	for bad: Variant in [null, [], {"schema": 2, "revision": 0, "places": {}}, {"schema": 1, "revision": 0, "places": {}, "future": true}]:
		var source := original.duplicate(true)
		source[Model.FIELD] = bad
		var before := JSON.stringify(source)
		check(Model.read(source).is_empty(), "corrupt/future record blocked")
		check(Model.transition(source, 0, "place", "house_edge", details).get("error") == "DECOR_INVALID", "cannot overwrite blocked record")
		check(JSON.stringify(source) == before, "blocked record retained byte equivalent")
	for bad_offset: Variant in [2, -2, 0.5, "1", null, INF, NAN, true]:
		check(Model.transition(original, 0, "place", "house_edge", {"find_id": id, "dx": bad_offset, "dy": 0}).get("error") == "DECOR_INVALID", "invalid adjustment rejected")
	var insufficient := placed.duplicate(true)
	insufficient.keepsakes = {}
	check(Model.read(insufficient).is_empty(), "orphan reservation cannot manufacture ownership")
	var future_entry := placed.duplicate(true)
	future_entry.yard_decor.places.house_edge.future = 1
	check(Model.read(future_entry).is_empty(), "future entry cannot be normalized away")
	var store := MemoryStore.new()
	store._data.keepsakes = {id: 1}
	var controller := Controller.new(store)
	store.fail_kind_once = "decor"
	check(controller.request("place", "house_edge", details), "intent accepted")
	check(controller.busy() and controller.view().places.is_empty(), "acceptance cannot show placed item")
	details.dx = 1
	check(not controller.request("place", "fence_edge", details), "double click blocked")
	store.pump()
	check(controller.state == "failed" and controller.view().places.is_empty(), "failed placement leaves basket usable count intact")
	check(store.get_available_keepsakes()[id] == 1, "failed placement reserves nothing")
	check(controller.retry(), "rejected intent can retry")
	store.pump()
	check(controller.view().places.house_edge.dx == 0, "retry uses frozen click details")
	check(store.get_available_keepsakes()[id] == 0 and store.get_keepsakes()[id] == 1, "confirm exposes exactly one reservation")
	store.unknown_kind = "decor"
	controller.request("remove", "house_edge")
	store.pump()
	check(controller.state == "unknown" and controller.view().places.has("house_edge"), "unknown removal does not free ownership")
	check(not controller.request("place", "fence_edge", details), "cannot act across unknown")
	store.resolve_unknown(true)
	check(not controller.busy() and store.get_available_keepsakes()[id] == 1, "landed removal releases once")
	# An exploration grant at the FIFO head must survive the later reservation.
	store.request_intent("exploration_trip", func(current: Dictionary) -> Dictionary:
		current.keepsakes[id] += 1
		current.exploration_committed_serial = 9
		return current)
	controller.request("place", "pond_path", details)
	store.pump()
	check(store.get_keepsakes()[id] == 2 and store.get_available_keepsakes()[id] == 1, "FIFO late evaluation preserves incoming find")
	check(store._data.exploration_committed_serial == 9, "exploration watermark retained")
	# Two independent clients cannot both reserve the last item at one revision.
	var revision := int(controller.view().revision)
	store.request_decor_action(revision, "place", "house_edge", details)
	store.request_decor_action(revision, "place", "fence_edge", details)
	store.pump()
	check(store.get_yard_decor().places.size() == 2 and store.get_available_keepsakes()[id] == 0, "concurrent requests cannot overbook")
	controller = null
	store.free()
	print("YARD_DECOR checks=%d failures=%d" % [checks, failures.size()])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
