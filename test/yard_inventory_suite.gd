extends SceneTree
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Controller := preload("res://scripts/inventory/yard_inventory_controller.gd")
const MemoryStore := preload("res://test/fixtures/exploration_memory_store.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func _run() -> void:
	var original := {"version": 5, "keepsakes": {"pine_cone": 3}, "future_root": {"data": [1, 2]}}
	check(Inventory.read(original) == Inventory.empty(), "legacy absent reads empty without write")
	check(not original.has("yard_inventory"), "read does not migrate in place")
	var snapshot := original.duplicate(true)
	for kind: String in Inventory.FISH:
		var revision := int(Inventory.read(snapshot).revision)
		var result := Inventory.transition(snapshot, revision, "catch", kind)
		check(result.has("candidate"), "catch " + kind)
		snapshot = result.candidate
		check(Inventory.transition(snapshot, revision, "catch", kind).get("error") == "BASKET_CHANGED", "duplicate catch refused")
		check(snapshot.keepsakes == original.keepsakes and snapshot.future_root == original.future_root, "unrelated source preserved")
		revision = int(Inventory.read(snapshot).revision)
		snapshot = Inventory.transition(snapshot, revision, "withdraw", kind).candidate
		check(Inventory.read(snapshot).held == kind and Inventory.read(snapshot).fish.get(kind, 0) == 0, "withdraw conserves one fish")
		check(Inventory.transition(snapshot, revision + 1, "withdraw", kind).get("error") == "BASKET_HAND_OCCUPIED", "occupied hand refused")
		snapshot = Inventory.transition(snapshot, revision + 1, "return", kind).candidate
		check(Inventory.read(snapshot).held == "" and Inventory.read(snapshot).fish[kind] == 1, "return conserves fish")
		snapshot = Inventory.transition(snapshot, revision + 2, "withdraw", kind).candidate
		snapshot = Inventory.transition(snapshot, revision + 3, "consume", kind).candidate
		check(Inventory.read(snapshot).held == "", "consume removes held once")
		check(Inventory.transition(snapshot, revision + 3, "consume", kind).get("error") == "BASKET_CHANGED", "duplicate consume refused")
	for corrupt: Variant in [null, [], {"schema": 2}, {"schema": 1, "revision": 0, "fish": {}, "held": "", "future": 4}, {"schema": 1, "revision": 0, "fish": {"small": -1}, "held": ""}]:
		var damaged := original.duplicate(true)
		damaged.yard_inventory = corrupt
		var before := JSON.stringify(damaged)
		check(Inventory.read(damaged).is_empty(), "unknown or corrupt blocked")
		check(Inventory.transition(damaged, 0, "catch", "small").get("error") == "BASKET_INVALID", "invalid write refused")
		check(JSON.stringify(damaged) == before, "raw source preserved")
	var full := Inventory.empty()
	full.fish.small = Inventory.MAX_COUNT
	check(Inventory.transition({"yard_inventory": full}, 0, "catch", "small").get("error") == "BASKET_LIMIT", "no overflow loss")
	var store := MemoryStore.new()
	var controller := Controller.new(store)
	store.fail_kind_once = "inventory"
	check(controller.request("catch", "medium"), "async request accepted")
	check(controller.busy() and controller.view().fish.is_empty(), "acceptance is not inventory")
	check(not controller.request("catch", "medium"), "double input rejected")
	store.pump()
	check(controller.state == "failed" and controller.view().fish.is_empty(), "rejected catch not granted")
	check(controller.retry(), "retry exact pending intent")
	store.pump()
	check(not controller.busy() and controller.view().fish.medium == 1, "confirmed catch once")
	store.unknown_kind = "inventory"
	controller.request("withdraw", "medium")
	store.pump()
	check(controller.state == "unknown" and controller.view().held == "", "unknown does not expose hand")
	check(not controller.request("withdraw", "medium"), "no new write over unknown")
	store.resolve_unknown(true)
	check(controller.view().held == "medium" and not controller.busy(), "resolve landed withdraw once")
	var reopened := MemoryStore.new()
	reopened._data = JSON.parse_string(JSON.stringify(store._data))
	check(reopened.get_yard_inventory().held == "medium", "JSON reopen retains hand")
	check(reopened.get_yard_inventory().fish.is_empty(), "reopen does not duplicate stored fish")
	controller = null
	store.free()
	reopened.free()
	print("YARD_INVENTORY checks=%d failures=%d" % [checks, failures.size()])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
