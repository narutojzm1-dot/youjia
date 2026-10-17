extends SceneTree
const Garden := preload("res://scripts/game/yard_garden.gd")
const Budget := preload("res://scripts/game/growth_budget.gd")
const Materials := preload("res://scripts/game/growth_materials.gd")
const Production := preload("res://scripts/game/growth_production.gd")
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Meals := preload("res://scripts/game/meal_ledger.gd")
const Stove := preload("res://scripts/game/yard_stove.gd")
const SEEDS := ExplorationRoutes.FIND_FLOWER_SEEDS
const STONE := ExplorationRoutes.FIND_STONE
const Coordinator := preload("res://scripts/persistence/save_coordinator.gd")
const Backend := preload("res://test/save_coordinator_suite.gd").Backend
var checks := 0
var failures: Array[String] = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func _initialize() -> void: call_deferred("run")

func intent(expected: Dictionary, proposal: Dictionary, config: Dictionary) -> Callable:
	return func(snapshot: Dictionary) -> Variant:
		var result := Budget.complete_garden(snapshot,expected,proposal,config)
		return Coordinator.IntentRejection.new(result.error) if result.has("error") else result.candidate

func run() -> void:
	var inventory := Inventory.empty()
	inventory.wheat = 4
	var source := {"version":5,"holiday_day":5,Inventory.FIELD:inventory,"keepsakes":{SEEDS:2,STONE:2},"yard_original_plants":{"schema":1,"revision":1,"removed":["door_pots"]},"exploration_committed_serial":7}
	source = Meals.complete(source,0,0,5,"lunch",{"wheat":1},false).candidate
	var before := source.duplicate(true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0
	var catalog := {SEEDS:{"id":"plant_flowers","materials":{SEEDS:1}}}
	var proposal := Materials.plan(source,catalog,rng)
	var config := {"ap":1,"seeds":1,"experience":1}
	var budget := Budget.budget(source,"lunch")
	var done := Budget.complete_garden(source,budget,proposal,config)
	check(not done.has("error") and source == before,"pure composite does not mutate source")
	var candidate: Dictionary = done.candidate
	check(candidate.keepsakes[SEEDS] == 1 and candidate.keepsakes[STONE] == 2,"exact seed debit, other finds retained")
	check(Garden.read(candidate).receipts[0].experience == 1 and Garden.read(candidate).revision == 1,"receipt is durable world and gardening XP")
	check(Budget.budget(candidate,"lunch").available == 2,"one shared AP spent")
	check(candidate.growth_production.schema == 3 and not Production.read(candidate).is_empty(),"garden AP is fenced in production scope3")
	check(candidate.yard_original_plants == source.yard_original_plants and candidate.exploration_committed_serial == 7,"original flowers and trip watermark retained")
	check(Budget.complete_garden(candidate,budget,proposal,config).get("error") == "AP_CHANGED","replay cannot spend twice")
	var fresh := Materials.plan(candidate,catalog,rng)
	check(Budget.complete_garden(candidate,Budget.budget(candidate,"lunch"),fresh,config).get("error") == "GARDEN_COMPLETE","new identity cannot replant occupied bed")
	var stale := source.duplicate(true)
	stale.keepsakes[SEEDS] = 1
	check(Budget.complete_garden(stale,budget,proposal,config).has("error"),"stale stock rejected without reselect")
	for key: String in ["ap","seeds","experience"]:
		var bad := config.duplicate(true)
		bad[key] = 0
		check(Budget.complete_garden(source,budget,proposal,bad).has("error"),"invalid config rejected " + key)
	var corrupt := candidate.duplicate(true)
	corrupt.growth_production.schema = 2
	check(Budget.budget(corrupt,"lunch").get("error") == "AP_INVALID","missing garden AP scope rejected")
	corrupt = candidate.duplicate(true)
	corrupt.erase(Garden.FIELD)
	check(Production.read(corrupt).is_empty(),"orphan garden scope rejected")
	var stone_plan := Materials.plan(candidate,{STONE:{"id":"build_stove","materials":{STONE:1}}},rng)
	var built := Budget.complete_stove(candidate,Budget.budget(candidate,"lunch"),0,stone_plan,{"ap":1,"stones":1,"experience":1})
	check(not built.has("error") and built.candidate.growth_production.schema == 3 and Budget.budget(built.candidate,"lunch").available == 1,"later stove retains garden scope and shares AP")
	var milled := Materials.plan(built.candidate,{"wheat":{"id":"mill_wheat","materials":{"wheat":1}}},rng)
	var final := Budget.complete_milling(built.candidate,Budget.budget(built.candidate,"lunch"),milled,{"ap":1,"wheat":1,"flour":1,"experience":1})
	check(not final.has("error") and final.candidate.growth_production.schema == 3 and Budget.budget(final.candidate,"lunch").available == 0,"milling retains garden scope and exhausts same AP")
	var later: Dictionary = final.candidate.duplicate(true)
	later.holiday_day = 6
	check(Budget.budget(later,"breakfast").available == 0 and later.yard_garden == candidate.yard_garden,"next day preserves garden without carrying AP")
	for bad in [{"schema":2,"revision":0,"receipts":[]},{"schema":1,"revision":1,"receipts":[]},{"schema":1,"revision":0,"receipts":[],"future":true}]:
		check(Garden.read({Garden.FIELD:bad}).is_empty(),"unknown or corrupt garden never normalized")
	check(preload("res://scripts/inventory/yard_decor.gd").transition(source,0,"place","house_edge",{"find_id":SEEDS,"dx":0,"dy":0}).has("error"),"seed is not an unapproved decor capability")
	var old_trip := ExplorationSession.new(ExplorationRoutes.catalog(),7)
	var discovered := false
	for seed in 60:
		old_trip = ExplorationSession.new(ExplorationRoutes.catalog(),7)
		old_trip.begin(ExplorationRoutes.NEAR_PATH,{"day":5,"elapsed":160.0},str(seed))
		old_trip.visit("slope")
		if old_trip.get_view().get("offer") == SEEDS: discovered = true; break
	check(discovered,"normal slope catalog can produce flower seeds")
	var recorded: Dictionary = old_trip.to_record()
	var restored: Dictionary = ExplorationSession.restore(JSON.parse_string(JSON.stringify(recorded)),ExplorationRoutes.catalog(),7)
	check(not restored.session.is_quarantined() and restored.session.get_view().offer == SEEDS,"visited flower offer persists without reroll on restore")
	for landed: bool in [false,true]:
		var backend := Backend.new()
		var coordinator := Coordinator.new()
		check(coordinator.initialize(backend,source,"root-token"),"garden writer initialized")
		coordinator.enqueue(intent(budget,proposal,config))
		await process_frame
		backend.prepare_ok()
		backend.send("unknown",{},"TIMEOUT")
		check(coordinator.get_confirmed() == source,"unknown exposes no seed/AP/world/XP change")
		check(coordinator.enqueue(intent(budget,proposal,config)).is_empty(),"unknown forbids replacement garden write")
		coordinator.retry_resolve()
		backend.receipt("confirmed" if landed else "rejected")
		backend.ack()
		check(coordinator.get_confirmed() == (candidate if landed else source),"resolved planting publishes all effects or none")
		backend.sync = true
		coordinator.enqueue(intent(budget,proposal,config))
		await process_frame
		check(coordinator.get_confirmed() == candidate,"retry leaves exactly one garden receipt")
		check(coordinator.close_when_idle(),"garden acknowledgement drains queue")
	print("GARDEN_GROWTH checks=%d failures=%d" % [checks,failures.size()])
	for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
