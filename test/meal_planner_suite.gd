extends SceneTree
const Planner := preload("res://scripts/game/meal_planner.gd")
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func recipe(material: String, amount: int = 1) -> Dictionary:
	# Fixtures are not production food recipes.
	return {"id": "fixture_" + material, "ingredients": {material: amount}}
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated.trim_suffix("/") + "/"):
		quit(2)
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 700
	var inv := Inventory.empty()
	inv.fish = {"small":100,"medium":4,"odd":2}
	inv.wheat = 1
	inv.held = "corn"
	inv.ground = [{"id":1,"kind":"wheat","x":500.0,"y":500.0}]
	inv.next_food_id = 2
	var snapshot := {"holiday_day":1, Inventory.FIELD:inv}
	var before := snapshot.duplicate(true)
	var catalog := {"small":recipe("small"),"medium":recipe("medium"),"odd":recipe("odd")}
	var counts := {"small":0,"medium":0,"odd":0}
	for i in 4000:
		var p := Planner.plan(snapshot,"breakfast",catalog,rng)
		counts[p.primary] += 1
	check(counts.small > 1800 and counts.small < 2200, "most-stock branch remains approximately half, not inventory-weighted")
	check(counts.medium > 800 and counts.medium < 1200 and counts.odd > 800 and counts.odd < 1200, "other branch distributes across other kinds, not unit counts")
	check(snapshot == before, "planning does not debit, grant or reserve")
	check(Planner.plan(snapshot,"breakfast",{},rng).is_empty(), "no recipe means no raw-material meal")
	check(Planner.plan(snapshot,"snack",catalog,rng).is_empty(), "unknown meal rejected")
	check(Planner.plan(snapshot,"breakfast",{"wheat":recipe("wheat")},rng).is_empty(), "last seed and ground seed cannot become cooking stock")
	check(Planner.plan(snapshot,"breakfast",{"corn":recipe("corn")},rng).is_empty(), "held food is not silently stolen")
	check(Planner.plan(snapshot,"breakfast",{"medium":recipe("medium",5)},rng).is_empty(), "insufficient recipe quantity is not eligible")
	var mixed := {"small":{"id":"fixture_mixed","ingredients":{"small":1,"wheat":1}},"medium":recipe("medium")}
	check(Planner.plan(snapshot,"breakfast",mixed,rng).primary == "medium", "most stock cannot bypass missing secondary ingredients")
	for bad: Dictionary in [{"grass":recipe("grass")},{"small":{"id":"","ingredients":{"small":1}}},{"small":recipe("odd")},{"small":recipe("small",0)},{"small":{"id":"fixture","ingredients":{"small":1},"future":true}}]:
		check(Planner.plan(snapshot,"breakfast",bad,rng).is_empty(), "invalid catalogs fail closed")
	var invalid := snapshot.duplicate(true)
	invalid.yard_inventory.schema = 99
	check(Planner.plan(invalid,"breakfast",catalog,rng).is_empty(), "future inventory not normalized away")
	invalid = snapshot.duplicate(true)
	invalid.meal_ledger = {"schema":99}
	check(Planner.plan(invalid,"breakfast",catalog,rng).is_empty(), "future ledger not normalized away")
	invalid = snapshot.duplicate(true)
	invalid.resident_rest = {"schema":1,"day":9,"cause":"awake"}
	check(Planner.plan(invalid,"breakfast",catalog,rng).is_empty(), "inconsistent rest provenance cannot propose a meal")
	inv.fish = {"small":2,"medium":2}
	var tie_counts := {"small":0,"medium":0}
	for i in 100:
		var p := Planner.plan(snapshot,"breakfast",{"small":recipe("small"),"medium":recipe("medium")},rng)
		tie_counts[p.primary] += 1
	check(tie_counts.small > 0 and tie_counts.medium > 0, "equal largest counts can select either")
	rng.seed = 11
	var first := Planner.plan(snapshot,"breakfast",{"small":recipe("small"),"medium":recipe("medium")},rng)
	rng.seed = 11
	check(Planner.plan(snapshot,"breakfast",{"medium":recipe("medium"),"small":recipe("small")},rng) == first, "insertion order does not change seeded choice")
	var only := Planner.plan(snapshot,"breakfast",{"small":recipe("small")},rng)
	check(only.primary == "small" and only.revision == 0 and only.inventory_revision == 0, "single choice produces guarded plan")
	# Real SaveStore: changed stock rejects the old plan, then a fresh plan
	# completes once and a native reload cannot produce another breakfast.
	var store = root.get_node("SaveStore")
	store.request_patch("planner-fixture",snapshot)
	check(await store.flush_pending(), "native fixture saved")
	var plan: Dictionary = store.plan_meal("breakfast",{"small":recipe("small")},rng)
	var changed := inv.duplicate(true)
	changed.revision = 1
	changed.fish.small = 1
	store.request_patch("concurrent-stock",{Inventory.FIELD:changed})
	check(await store.flush_pending(), "concurrent inventory change confirmed")
	store.request_meal_completion(plan.revision,plan.inventory_revision,plan.day,plan.meal,plan.ingredients)
	check(await store.flush_pending(), "stale plan rejected without replacement")
	check(store.get_meal_ledger().receipts.is_empty() and store.get_yard_inventory().fish.small == 1, "stale plan cannot consume or grant")
	plan = store.plan_meal("breakfast",{"small":recipe("small")},rng)
	store.request_meal_completion(plan.revision,plan.inventory_revision,plan.day,plan.meal,plan.ingredients)
	check(await store.flush_pending(), "fresh plan completes atomically")
	check(store.get_meal_ledger().receipts.size() == 1 and not store.get_yard_inventory().fish.has("small"), "one ingredient and one receipt")
	store._load()
	check(store.plan_meal("breakfast",catalog,rng).is_empty(), "native reopen does not plan completed meal")
	check(not store.plan_meal("lunch",catalog,rng).is_empty(), "another meal can use remaining stock")
	for failure in failures: push_error(failure)
	print("MEAL_PLANNER checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
