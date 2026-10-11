extends SceneTree
const Materials := preload("res://scripts/game/growth_materials.gd")
const Edging := preload("res://scripts/game/pond_edging.gd")
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Decor := preload("res://scripts/inventory/yard_decor.gd")
const Coordinator := preload("res://scripts/persistence/save_coordinator.gd")
const Backend := preload("res://test/save_coordinator_suite.gd").Backend
const STONE := ExplorationRoutes.FIND_STONE
const PINE := ExplorationRoutes.FIND_PINE_CONE
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func fixture() -> Dictionary:
	var inv := Inventory.empty()
	inv.wheat = 8
	inv.corn = 4
	inv.fish = {"small":1}
	inv.held = "corn"
	return {"version":5, "holiday_day":1, "keepsakes":{STONE:12, PINE:100}, Inventory.FIELD:inv, "album":["old"], "other_owner":{"keep":[1,2]}}
func action(primary: String, amount: int = 1) -> Dictionary:
	return {"id":"pond_edging" if primary == STONE else "fixture_only", "materials":{primary:amount}}
func propose(s: Dictionary) -> Dictionary:
	return Materials.plan(s, {STONE:action(STONE, 2)}, RandomNumberGenerator.new())
func intent(p: Dictionary) -> Callable:
	var frozen := p.duplicate(true)
	return func(s: Dictionary) -> Variant:
		# Fixture-only composition. Production must also validate/debit AP here.
		var result := Edging.complete(s, 0, "fixture_section", frozen, 2, 1)
		return Coordinator.IntentRejection.new(result.error) if result.has("error") else result.candidate
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated.trim_suffix("/") + "/"):
		quit(2)
		return
	var original := fixture()
	var before := original.duplicate(true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 700
	var catalog := {STONE:action(STONE,2), "wheat":action("wheat"), "corn":action("corn")}
	var counts := {STONE:0, "wheat":0, "corn":0}
	for i in 4000:
		var p := Materials.plan(original,catalog,rng)
		counts[p.primary] += 1
	check(counts[STONE] > 1800 and counts[STONE] < 2200, "50 percent maximum eligible stock, not all owned items or unit-weighted")
	check(counts.wheat > 800 and counts.wheat < 1200 and counts.corn > 800 and counts.corn < 1200, "other half distributes among other eligible materials")
	check(original == before, "planning never writes/reserves/grants")
	check(Materials.plan(original,{},rng).is_empty(), "no executable catalog does not invent an action for 100 pine cones")
	check(Materials.plan(original,{STONE:action(STONE,13),"wheat":action("wheat")},rng).primary == "wheat", "unaffordable maximum excluded")
	var mixed := {STONE:{"id":"fixture_only","materials":{STONE:1,"corn":5}},"wheat":action("wheat")}
	check(Materials.plan(original,mixed,rng).primary == "wheat", "secondary material missing excludes action")
	var tied := original.duplicate(true)
	tied.yard_inventory.wheat = 12
	tied.yard_inventory.corn = 12
	var seen := {}
	for i in 90: seen[Materials.plan(tied,catalog,rng).primary] = true
	check(seen.size() == 3, "all maximum ties remain selectable")
	rng.seed = 14
	var first := Materials.plan(original,catalog,rng)
	rng.seed = 14
	check(Materials.plan(original,{"corn":action("corn"),"wheat":action("wheat"),STONE:action(STONE,2)},rng) == first, "seeded replay independent of catalog insertion order")
	var protected := original.duplicate(true)
	protected.keepsakes[STONE] = 1
	protected[Decor.FIELD] = {"schema":1,"revision":1,"places":{"pond_path":{"find_id":STONE,"dx":0,"dy":0}}}
	check(Materials.plan(protected,{STONE:action(STONE)},rng).is_empty(), "placed last stone cannot be consumed")
	protected.yard_inventory.wheat = 1
	protected.yard_inventory.corn = 0
	check(Materials.plan(protected,{"wheat":action("wheat"),"corn":action("corn")},rng).is_empty(), "last seed and hand are protected")
	var p := propose(original)
	var result := Edging.complete(original,0,"fixture_section",p,2,1)
	check(result.has("candidate"), "valid explicit fixture produces a candidate")
	var completed: Dictionary = result.candidate
	check(completed.keepsakes[STONE] == 10 and completed.pond_edging.sections.fixture_section.experience == 1, "debit, world section and XP receipt share one snapshot")
	check(completed.yard_inventory == original.yard_inventory and completed.album == original.album and completed.other_owner == original.other_owner, "food, photos and unknown fields preserved")
	check(original == before, "subtransition does not mutate original")
	check(Edging.complete(completed,1,"fixture_section",propose(completed),2,1).error == "EDGING_ALREADY_COMPLETED", "same world section cannot award twice even with fresh plan")
	check(Edging.complete(completed,1,"another",p,2,1).error == "GROWTH_CHANGED", "old material plan cannot spend again")
	check(Edging.complete(original,1,"fixture_section",p,2,1).error == "EDGING_CHANGED", "world revision checked")
	check(Edging.complete(original,0,"fixture_section",p,1,1).error == "EDGING_INVALID", "configured cost must match plan")
	check(Edging.complete(original,0,"fixture_section",p,2,0).error == "EDGING_INVALID", "invalid reward rejected")
	var future := completed.duplicate(true)
	future.pond_edging.sections.fixture_section.day = 2
	check(Edging.read(future).is_empty(), "future completion cannot load as earned progress")
	var reopened: Dictionary = JSON.parse_string(JSON.stringify(completed))
	check(Edging.read(reopened) == Edging.read(completed) and Materials.guard(reopened) == Materials.guard(completed), "JSON number normalization retains ledger and guard")
	for key: String in ["holiday_day","keepsakes","yard_decor","yard_inventory","exploration_committed_serial"]:
		var changed := original.duplicate(true)
		match key:
			"holiday_day": changed.holiday_day = 2
			"keepsakes": changed.keepsakes[STONE] += 1
			"yard_decor": changed[key] = protected[Decor.FIELD].duplicate(true)
			"yard_inventory": changed[key].revision += 1
			"exploration_committed_serial": changed[key] = 1
		check(Materials.consume(changed,p).error == "GROWTH_CHANGED", "stale plan rejects changed " + key)
	for cost: Dictionary in [{},{STONE:0},{STONE:-1},{STONE:true},{STONE:1.5},{"unknown":1}]:
		check(Materials.plan(original,{STONE:{"id":"pond_edging","materials":cost}},rng).is_empty(), "invalid cost fails closed")
	for bad: Variant in [null,[],{}, {"id":"", "materials":{STONE:1}}, {"id":"pond_edging", "materials":{STONE:1}, "future":true}, {"id":"pond_edging", "materials":{"corn":1}}]:
		check(Materials.plan(original,{STONE:bad},rng).is_empty(), "invalid action schema fails closed")
	for bad: Dictionary in [{},{"source":{},"primary":STONE,"action_id":"pond_edging","materials":{}}, {"source":{},"primary":STONE,"action_id":"pond_edging","materials":{STONE:1}}]:
		check(not Materials.consume(original,bad).has("candidate"), "malformed proposal cannot consume")
	var exhausted := original.duplicate(true)
	exhausted.yard_inventory.revision = Inventory.MAX_REVISION
	check(Materials.plan(exhausted,{"wheat":action("wheat")},rng).is_empty(), "unwritable food ledger excluded before selection")
	check(not propose(exhausted).is_empty(), "unrelated food revision ceiling does not block stone-only work")
	for key: String in ["yard_inventory","yard_decor","keepsakes"]:
		var invalid := original.duplicate(true)
		invalid[key] = {"future":true}
		check(Materials.plan(invalid,catalog,rng).is_empty(), "corrupt/future " + key + " not normalized away")
	for raw: Variant in [null,[],{"schema":2,"revision":0,"sections":{}},{"schema":1,"revision":1,"sections":{}},{"schema":1,"revision":1,"sections":{"x":{}}}]:
		var invalid := original.duplicate(true)
		invalid[Edging.FIELD] = raw
		check(Edging.read(invalid).is_empty(), "invalid/future construction receipt rejected")
		check(Edging.complete(invalid,0,"fixture_section",p,2,1).error == "EDGING_INVALID", "invalid ledger cannot be replaced by new work")
	var both := Materials.plan(original,{STONE:{"id":"fixture_only","materials":{STONE:1,"small":1,"wheat":2}}},rng)
	var debited := Materials.consume(original,both).candidate as Dictionary
	check(debited.keepsakes[STONE] == 11 and debited.yard_inventory.wheat == 6 and debited.yard_inventory.fish.is_empty(), "mixed cost consumed wholly, zero fish key erased")
	check(debited.yard_inventory.revision == 1 and not Inventory.read(debited).is_empty(), "food revision advances once per multi-material action")
	var reserved := protected.duplicate(true)
	reserved.keepsakes[STONE] = 3
	var last := Edging.complete(reserved,0,"fixture_section",propose(reserved),2,1).candidate as Dictionary
	check(last.keepsakes[STONE] == 1 and last.yard_decor == reserved.yard_decor and not Decor.read(last).is_empty(), "spending basket surplus preserves placed stone ownership")
	# Real coordinator unknown-write resolution: publish all three effects or none.
	for landed: bool in [false,true]:
		var backend := Backend.new()
		var coordinator := Coordinator.new()
		check(coordinator.initialize(backend,original,"root-token"), "fault writer initialized")
		coordinator.enqueue(intent(p))
		check(coordinator.get_confirmed() == original, "accepted intent does not publish work")
		await process_frame
		backend.prepare_ok()
		backend.send("unknown",{},"TIMEOUT")
		check(coordinator.get_confirmed() == original and coordinator.enqueue(intent(p)).is_empty(), "unknown freezes replacement and old snapshot")
		coordinator.retry_resolve()
		backend.receipt("confirmed" if landed else "rejected")
		backend.ack()
		check(coordinator.get_confirmed() == (completed if landed else original), "resolve all or none")
		backend.sync = true
		coordinator.enqueue(intent(p))
		await process_frame
		check(coordinator.get_confirmed() == completed, "retry cannot double charge or award")
		check(coordinator.close_when_idle(), "fault queue drained")
	# Native SaveStore/file roundtrip exercises the same production FIFO. No
	# gameplay completion wrapper exists until AP and target layout are integrated.
	var store = root.get_node("SaveStore")
	store.request_patch("growth-fixture",original)
	check(await store.flush_pending(), "native fixture persisted")
	var planned: Dictionary = store.plan_growth_materials({STONE:action(STONE,2)},rng)
	var one: String = store.request_intent("growth-fixture",intent(planned))
	planned.materials[STONE] = 9
	store.request_intent("growth-fixture",intent(p))
	check(not one.is_empty() and not store._data.has(Edging.FIELD), "acceptance not completion, frozen intent")
	check(await store.flush_pending(), "native duplicate queue drains")
	var disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(store.SAVE_PATH))
	check(disk.keepsakes[STONE] == 10 and disk.pond_edging.sections.fixture_section.experience == 1, "native file contains material plus world/XP receipt")
	store._load()
	store.request_intent("growth-fixture",intent(p))
	check(await store.flush_pending(), "reopened replay rejected")
	check(store.get_keepsakes()[STONE] == 10 and Edging.read(store._data).revision == 1, "reopen cannot repeat work")
	for failure in failures: push_error(failure)
	print("GROWTH_MATERIALS checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
