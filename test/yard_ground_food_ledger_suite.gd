extends SceneTree
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Controller := preload("res://scripts/inventory/yard_inventory_controller.gd")
const MemoryStore := preload("res://test/fixtures/exploration_memory_store.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func run() -> void:
	var legacy := {"yard_inventory": {"schema": 1, "revision": 9, "fish": {"odd": 2}, "held": "small"}, "keepsakes": {"pine_cone": 1}}
	var before := JSON.stringify(legacy)
	var view := Inventory.read(legacy)
	check(view.schema == 2 and view.fish.odd == 2 and view.held == "small", "schema1 basket upgraded without losing counts or hand")
	check(JSON.stringify(legacy) == before, "reading upgrade does not rewrite source")
	var result := Inventory.transition(legacy, 9, "drop", "small", {"x": 450, "y": 500})
	var state: Dictionary = result.candidate
	check(state.keepsakes == legacy.keepsakes, "drop preserves exploration finds")
	check(state.yard_inventory.held == "" and state.yard_inventory.ground.size() == 1, "hand moved to one ground object")
	var food: Dictionary = state.yard_inventory.ground[0]
	check(Inventory.transition(state, 9, "drop", "small", {"x": 450, "y": 500}).get("error") == "BASKET_CHANGED", "repeated drop cannot duplicate")
	var contested := state.duplicate(true)
	state = Inventory.transition(state, 10, "eat", "small", {"id": food.id}).candidate
	check(Inventory.read(state).ground.is_empty(), "first animal consumes one confirmed object")
	check(Inventory.transition(state, 10, "eat", "small", {"id": food.id}).get("error") == "BASKET_CHANGED", "second animal with same observation rejected")
	check(Inventory.transition(state, 11, "eat", "small", {"id": food.id}).get("error") == "BASKET_EMPTY", "new revision cannot consume missing old ID")
	var picked: Dictionary = Inventory.transition(contested, 10, "pickup", "small", {"id": food.id}).candidate
	check(Inventory.read(picked).held == "small" and Inventory.read(picked).ground.is_empty(), "player can reclaim uneaten food exactly once")
	state = Inventory.transition(state, 11, "harvest", "grass").candidate
	check(Inventory.read(state).held == "grass", "grass harvest creates durable hand")
	check(Inventory.transition(state, 12, "withdraw", "odd").get("error") == "BASKET_HAND_OCCUPIED", "grass and fish cannot occupy hand together")
	state = Inventory.transition(state, 12, "return", "grass").candidate
	check(Inventory.read(state).grass == 1 and Inventory.read(state).held == "", "grass can be saved in basket")
	state = Inventory.transition(state, 13, "withdraw", "grass").candidate
	state = Inventory.transition(state, 14, "drop", "grass", {"x": 460, "y": 505}).candidate
	check(Inventory.read(state).ground[0].id > food.id, "consumed IDs never reused")
	check(Inventory.read(JSON.parse_string(JSON.stringify(state))) == Inventory.read(state), "JSON reopen preserves ground object and next ID")
	for invalid: Dictionary in [{"x": NAN, "y": 500}, {"x": -1, "y": 500}, {"x": "450", "y": 500}, {"x": 450, "y": INF}]:
		check(Inventory.transition(legacy, 9, "drop", "small", invalid).get("error") == "BASKET_INVALID", "invalid drop position rejected without losing held fish")
	var duplicated := state.duplicate(true)
	duplicated.yard_inventory.ground.append(duplicated.yard_inventory.ground[0].duplicate())
	check(Inventory.read(duplicated).is_empty(), "corrupt duplicate ground IDs blocked")
	var store := MemoryStore.new()
	store._data = contested.duplicate(true)
	var controller := Controller.new(store)
	store.unknown_kind = "inventory"
	controller.request("eat", "small", {"id": food.id})
	store.pump()
	check(controller.state == "unknown" and controller.view().ground.size() == 1, "unknown consume leaves visible authoritative object")
	check(not controller.request("eat", "small", {"id": food.id}), "no second consumer over unknown result")
	store.resolve_unknown(true)
	check(controller.view().ground.is_empty() and not controller.busy(), "resolved consume removes one object")
	store.free()
	print("YARD_GROUND_FOOD_LEDGER checks=%d failures=%d" % [checks, failures.size()])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
