extends SceneTree
## Shared-model tests only; fixture quantities do not enable a gameplay recipe.
const Production := preload("res://scripts/game/growth_production.gd")
const Budget := preload("res://scripts/game/growth_budget.gd")
const Materials := preload("res://scripts/game/growth_materials.gd")
const Meals := preload("res://scripts/game/meal_ledger.gd")
const Edging := preload("res://scripts/game/pond_edging.gd")
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Crops := preload("res://scripts/game/yard_crops.gd")
const Coordinator := preload("res://scripts/persistence/save_coordinator.gd")
const Backend := preload("res://test/save_coordinator_suite.gd").Backend
const CONFIG := {"ap":1,"wheat":2,"flour":3,"experience":1}
const STONE := ExplorationRoutes.FIND_STONE
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func fixture() -> Dictionary:
	var inv := Inventory.empty()
	inv.wheat = 20
	return {"version":5,"holiday_day":1,"keepsakes":{STONE:12},Inventory.FIELD:inv,"other_owner":{"keep":[1,2]}}
func eat(s: Dictionary, meal: String, tired: bool = false) -> Dictionary:
	return Meals.complete(s,Meals.read(s).revision,Inventory.read(s).revision,s.holiday_day,meal,{"wheat":1},tired).candidate
func propose(s: Dictionary, config: Dictionary = CONFIG) -> Dictionary:
	return Materials.plan(s,{"wheat":{"id":"mill_wheat","materials":{"wheat":config.wheat}}},RandomNumberGenerator.new())
func mill(s: Dictionary, period: String, config: Dictionary = CONFIG) -> Dictionary:
	return Budget.complete_milling(s,Budget.budget(s,period),propose(s,config),config)
func pond(s: Dictionary, period: String, id: String) -> Dictionary:
	var plan := Materials.plan(s,{STONE:{"id":"pond_edging","materials":{STONE:1}}},RandomNumberGenerator.new())
	return Budget.complete(s,Budget.budget(s,period),id,plan,1,1,1)
func intent(expected: Dictionary, proposal: Dictionary, config: Dictionary = CONFIG) -> Callable:
	var e := expected.duplicate(true)
	var p := proposal.duplicate(true)
	var c := config.duplicate(true)
	return func(s: Dictionary) -> Variant:
		var result := Budget.complete_milling(s,e,p,c)
		return Coordinator.IntentRejection.new(result.error) if result.has("error") else result.candidate
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated.trim_suffix("/")+"/"):
		quit(2)
		return
	inventory_compatibility()
	var none := fixture()
	check(Production.read(none) == Production.empty() and not none.has(Production.FIELD),"absent production is empty without migration write")
	check(mill(none,"breakfast").error == "AP_EMPTY","no meal cannot mill")
	var morning := eat(none,"breakfast")
	var before := morning.duplicate(true)
	var e := Budget.budget(morning,"breakfast")
	var p := propose(morning)
	var first: Dictionary = mill(morning,"breakfast").candidate
	check(morning == before,"pure milling preserves its source")
	var inv := Inventory.read(first)
	check(inv.wheat == 17 and inv.flour == 3 and inv.revision == 2,"one meal then milling changes stock with one inventory revision")
	check(first.other_owner == before.other_owner and first.keepsakes == before.keepsakes and first.meal_ledger == before.meal_ledger,"milling preserves unrelated state, keepsakes and meal receipts")
	check(not first.has(Budget.FIELD) and not first.has(Edging.FIELD),"milling never mints a pond action or pond revision")
	var receipt: Dictionary = Production.read(first).receipts[0]
	check(receipt.id == 1 and receipt.action == "mill_wheat" and receipt.ap == 1 and receipt.ingredients == {"wheat":2} and receipt.products == {"flour":3} and receipt.experience == {"cooking":1},"one typed receipt contains exact configured AP/input/output/XP")
	check(Budget.budget(first,"breakfast").available == 0,"milling consumes the same meal AP pool")
	check(pond(first,"breakfast","first").error == "AP_EMPTY","pond cannot reuse milling AP")
	check(Budget.complete_milling(first,e,p,CONFIG).error == "AP_CHANGED","duplicate rejected by frozen composite budget")
	var noon := eat(first,"lunch")
	var after_pond: Dictionary = pond(noon,"lunch","first").candidate
	check(Edging.read(after_pond).revision == 1 and Budget.read(after_pond).revision == 1 and Production.read(after_pond).revision == 1,"pond paired revisions remain independent from production")
	var second: Dictionary = mill(after_pond,"lunch").candidate
	check(Budget.budget(second,"lunch").available == 1 and Production.read(second).revision == 2 and Edging.read(second).revision == 1,"mill pond mill consume one common budget")
	check(Inventory.read(second).revision == Inventory.read(after_pond).revision+1 and Inventory.read(second).flour == 6,"second milling output has one inventory revision")
	check(Production.read(second).receipts[1].id == 2,"repeat action gets distinct durable sequence")
	var stale_pond_plan := Materials.plan(after_pond,{STONE:{"id":"pond_edging","materials":{STONE:1}}},RandomNumberGenerator.new())
	check(Budget.complete(second,Budget.budget(after_pond,"lunch"),"second",stale_pond_plan,1,1,1).error == "AP_CHANGED","milling invalidates pending pond expected source")
	var old_pond: Dictionary = pond(morning,"breakfast","legacy").candidate
	var old_pair := {"actions":old_pond[Budget.FIELD].duplicate(true),"edging":old_pond[Edging.FIELD].duplicate(true)}
	var upgraded := eat(old_pond,"lunch")
	upgraded = mill(upgraded,"lunch").candidate
	check(upgraded[Budget.FIELD] == old_pair.actions and upgraded[Edging.FIELD] == old_pair.edging,"first new production preserves old paired fields byte-for-value")
	check(Budget.budget(upgraded,"lunch").available == 2,"old pond spend still counts alongside milling")
	var tomorrow := second.duplicate(true)
	tomorrow.holiday_day = 2
	check(Budget.budget(tomorrow,"breakfast").available == 0,"mixed old-day surplus is excluded from new-day AP")
	check(Budget.budget(tomorrow,"breakfast").source == Budget.budget(second,"dinner").source,"mixed old receipts remain guarded without clearing or carrying")
	check(mill(tomorrow,"breakfast").error == "AP_EMPTY","mixed historical surplus cannot buy today's milling")
	var spent: Dictionary = pond(second,"lunch","second").candidate
	spent.holiday_day = 2
	check(Budget.budget(spent,"breakfast").available == 0,"zero mixed prior balance needs no new cross-day policy")
	var tired := eat(none,"breakfast",true)
	check(mill(tired,"breakfast").error == "AP_EMPTY" and Meals.read(tired).receipts.size() == 1,"zero AP breakfast remains completed and cannot mill")
	tired = eat(tired,"lunch",true)
	tired = mill(tired,"lunch").candidate
	check(Inventory.read(tired).flour == 3 and Production.read(tired).receipts[0].experience.cooking == 1,"fatigue never halves products or XP again")
	var configured := {"ap":2,"wheat":3,"flour":2,"experience":4}
	var tuned: Dictionary = mill(eat(morning,"lunch"),"lunch",configured).candidate
	check(Production.read(tuned).receipts[0].experience.cooking == 4 and Inventory.read(tuned).flour == 2 and Budget.budget(tuned,"lunch").available == 2,"caller configuration used without hidden default costs")
	var recovered: Dictionary = JSON.parse_string(JSON.stringify(second))
	check(Production.read(recovered) == Production.read(second) and Budget.budget(recovered,"lunch") == Budget.budget(second,"lunch"),"JSON roundtrip preserves mixed accounting")
	var caught: Dictionary = Inventory.transition(second,Inventory.read(second).revision,"catch","small").candidate
	check(Inventory.read(caught).flour == 6 and Production.read(caught) == Production.read(second),"ordinary inventory writes preserve flour and production")
	var cooked := eat(second,"dinner")
	check(Inventory.read(cooked).flour == 6 and Production.read(cooked) == Production.read(second),"existing meal write preserves flour and production")
	var planted: Dictionary = Crops.transition(second,Crops.read(second).revision,Inventory.read(second).revision,"initialize","").candidate
	check(Inventory.read(planted).flour == 6 and Production.read(planted) == Production.read(second),"crop initialization preserves flour and production")
	check(Inventory.read(second).production_revision == 2 and Budget.budget(second,"lunch").source.actions.revision == 1 and Budget.budget(second,"lunch").source.production.revision == 2,"expected source guards both ledgers without a second AP balance")
	rejections(morning,first,e,p)
	await uncertain(morning,first,e,p)
	await native_roundtrip(morning,first,e,p)
	for failure in failures: push_error(failure)
	print("GROWTH_PRODUCTION checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func inventory_compatibility() -> void:
	for schema: int in range(1,5):
		var old := {"schema":schema,"revision":9,"fish":{"small":2},"held":"small"}
		if schema >= 2: old.merge({"grass":3,"ground":[{"id":1,"kind":"grass","x":400.0,"y":500.0}],"next_food_id":2})
		if schema >= 3: old.millet = 4
		if schema >= 4: old.merge({"wheat":5,"corn":6})
		var raw := old.duplicate(true)
		var view := Inventory.read({Inventory.FIELD:old})
		check(view.schema == 5 and view.flour == 0 and view.production_revision == 0 and view.revision == 9 and view.held == "small" and view.fish == {"small":2},"schema %d migration preserves ownership and revision"%schema)
		check(old == raw,"schema %d read does not mutate source"%schema)
		check(view.wheat == (5 if schema >= 4 else 0) and view.corn == (6 if schema >= 4 else 0) and view.millet == (4 if schema >= 3 else 0),"schema %d grain quantities preserved"%schema)
		check(view.ground.size() == (1 if schema >= 2 else 0) and view.next_food_id == (2 if schema >= 2 else 1),"schema %d ground identities preserved"%schema)
		var returned: Dictionary = Inventory.transition({Inventory.FIELD:old},9,"return","small").candidate[Inventory.FIELD]
		check(returned.schema == 5 and returned.flour == 0 and returned.fish.small == 3 and returned.revision == 10,"schema %d first normal write migrates once"%schema)
	var pantry := Inventory.empty()
	pantry.flour = 4
	check(Inventory.transition({Inventory.FIELD:pantry},0,"withdraw","flour").error == "BASKET_INVALID","flour model does not silently enable missing hand/feed presentation")
	check(Materials.stock({Inventory.FIELD:pantry}).get("flour") == 4,"flour is recognized durable stock")
	for value: Variant in [-1,1.5,Inventory.MAX_COUNT+1,"2",null]:
		var bad := pantry.duplicate(true)
		bad.flour = value
		check(Inventory.read({Inventory.FIELD:bad}).is_empty(),"invalid flour blocked")
	pantry.schema = 6
	check(Inventory.read({Inventory.FIELD:pantry}).is_empty(),"future inventory remains blocked")

func rejections(morning: Dictionary, first: Dictionary, expected: Dictionary, proposal: Dictionary) -> void:
	for key: String in CONFIG:
		for value: Variant in [0,-1,1.5,"1",null]:
			var bad := CONFIG.duplicate()
			bad[key] = value
			check(not Budget.complete_milling(morning,expected,proposal,bad).has("candidate"),"invalid config %s"%key)
	var extra := CONFIG.duplicate()
	extra.future = 1
	check(Budget.complete_milling(morning,expected,proposal,extra).error == "PRODUCTION_INVALID","unknown recipe config blocked")
	var full := morning.duplicate(true)
	full[Inventory.FIELD].flour = Inventory.MAX_COUNT - 2
	check(mill(full,"breakfast").error == "PRODUCTION_LIMIT","capacity failure has no input/AP debit")
	full[Inventory.FIELD].flour = Inventory.MAX_COUNT - 3
	check(Inventory.read(mill(full,"breakfast").candidate).flour == Inventory.MAX_COUNT,"exact output capacity succeeds")
	var seed := morning.duplicate(true)
	seed[Inventory.FIELD].wheat = 2
	check(propose(seed).is_empty(),"planner protects last seed")
	var forced := {"source":Materials.guard(seed),"primary":"wheat","action_id":"mill_wheat","materials":{"wheat":2}}
	check(Budget.complete_milling(seed,Budget.budget(seed,"breakfast"),forced,CONFIG).error == "GROWTH_EMPTY","FIFO transition also protects last seed")
	var changed := morning.duplicate(true)
	changed[Inventory.FIELD].corn += 1
	changed[Inventory.FIELD].revision += 1
	check(Budget.complete_milling(changed,expected,proposal,CONFIG).error == "GROWTH_CHANGED","inventory race rechecked at FIFO head")
	changed = morning.duplicate(true)
	changed[Inventory.FIELD].revision = Inventory.MAX_REVISION
	check(propose(changed).is_empty(),"inventory revision limit prevents material proposal")
	changed = first.duplicate(true)
	changed[Production.FIELD].receipts[0].ap = 2
	check(Budget.budget(changed,"breakfast").error == "AP_INVALID","production overdraft fails shared budget validation")
	for raw: Variant in [null,{},[],{"schema":2,"revision":0,"receipts":[]},{"schema":1,"revision":1,"receipts":[]}]:
		changed = morning.duplicate(true)
		changed[Production.FIELD] = raw
		check(Production.read(changed).is_empty() and Budget.budget(changed,"breakfast").error == "AP_INVALID","malformed or future production fails closed")
	for key: String in ["id","action","day","period","ap","ingredients","products","experience"]:
		changed = first.duplicate(true)
		changed[Production.FIELD].receipts[0][key] = "future"
		check(Production.read(changed).is_empty(),"invalid production receipt %s"%key)
	changed = first.duplicate(true)
	changed[Production.FIELD].receipts[0].day = 2
	check(Production.read(changed).is_empty(),"future day rejected")
	changed = first.duplicate(true)
	changed[Production.FIELD].receipts.append(changed[Production.FIELD].receipts[0].duplicate(true))
	changed[Production.FIELD].revision = 2
	changed[Inventory.FIELD].production_revision = 2
	check(Production.read(changed).is_empty(),"duplicate production identity rejected")
	changed = first.duplicate(true)
	changed.erase(Production.FIELD)
	check(Budget.budget(changed,"breakfast").error == "AP_INVALID","missing production ledger cannot erase AP spend while inventory anchor remains")
	changed[Inventory.FIELD].flour = 0
	check(Budget.budget(changed,"breakfast").error == "AP_INVALID","anchor preserves spend even after all products have been consumed")
	changed = first.duplicate(true)
	changed[Inventory.FIELD].production_revision = 0
	check(Budget.budget(changed,"breakfast").error == "AP_INVALID","orphan production receipt cannot detach from inventory result")
	changed = first.duplicate(true)
	changed[Inventory.FIELD].production_revision = 2
	check(Budget.budget(changed,"breakfast").error == "AP_INVALID","mismatched production revisions fail closed")
	changed = first.duplicate(true)
	changed[Inventory.FIELD].schema = 4
	changed[Inventory.FIELD].erase("flour")
	changed[Inventory.FIELD].erase("production_revision")
	check(Budget.budget(changed,"breakfast").error == "AP_INVALID","legacy inventory cannot carry unlinked new production receipts")
	check(morning[Inventory.FIELD].flour == 0 and morning[Inventory.FIELD].wheat == 19,"all rejections leave caller snapshot unchanged")

func uncertain(morning: Dictionary, first: Dictionary, expected: Dictionary, proposal: Dictionary) -> void:
	for landed: bool in [false,true]:
		var backend := Backend.new()
		var coordinator := Coordinator.new()
		check(coordinator.initialize(backend,morning,"root-token"),"writer initialized")
		coordinator.enqueue(intent(expected,proposal))
		await process_frame
		backend.prepare_ok()
		backend.send("unknown",{},"TIMEOUT")
		check(coordinator.get_confirmed() == morning,"unknown exposes neither output nor any debit/XP")
		check(coordinator.enqueue(intent(expected,proposal)).is_empty(),"unknown blocks replacement request")
		coordinator.retry_resolve()
		backend.receipt("confirmed" if landed else "rejected")
		backend.ack()
		check(coordinator.get_confirmed() == (first if landed else morning),"unknown resolution publishes all effects or none")
		backend.sync = true
		coordinator.enqueue(intent(expected,proposal))
		await process_frame
		check(coordinator.get_confirmed() == first,"retry yields exactly one milling receipt and stock result")
		check(coordinator.close_when_idle(),"queue drains after acknowledgement")
	var backend := Backend.new()
	backend.sync = true
	var coordinator := Coordinator.new()
	coordinator.initialize(backend,morning,"root-token")
	coordinator.enqueue(func(s: Dictionary) -> Dictionary:
		s[Inventory.FIELD].corn += 1
		s[Inventory.FIELD].revision += 1
		return s)
	coordinator.enqueue(intent(expected,proposal))
	for i in 4: await process_frame
	check(coordinator.get_confirmed()[Inventory.FIELD].corn == 1 and not coordinator.get_confirmed().has(Production.FIELD),"actual FIFO earlier stock write rejects stale milling without overwrite")

func native_roundtrip(morning: Dictionary, first: Dictionary, expected: Dictionary, proposal: Dictionary) -> void:
	var store = root.get_node("SaveStore")
	var refusals: Array = []
	var receive_rejection := func(id: String, kind: String, code: String) -> void: refusals.append({"id":id,"kind":kind,"code":code})
	store.commit_rejected.connect(receive_rejection)
	store.request_patch("fixture",morning)
	check(await store.flush_pending(),"native fixture saved")
	var e: Dictionary = store.get_growth_budget("breakfast")
	var p := propose(morning)
	var config := CONFIG.duplicate(true)
	var ticket: String = store.request_milling(e,p,config)
	e.available = 999
	p.materials.wheat = 9
	config.flour = 999
	store.request_milling(expected,proposal,CONFIG)
	check(not ticket.is_empty() and store.get_growth_production().revision == 0 and store.get_yard_inventory().flour == 0,"SaveStore freezes caller values and acceptance is not success")
	check(await store.flush_pending(),"native queue drains including stale duplicate")
	check(refusals.size() == 1 and refusals[0].kind == "growth" and refusals[0].code == "AP_CHANGED","SaveStore preserves typed stale-budget refusal")
	var disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(store.SAVE_PATH))
	check(Inventory.read(disk) == Inventory.read(first) and Production.read(disk) == Production.read(first) and Budget.budget(disk,"breakfast").available == 0,"real file contains all four effects exactly once")
	store._load()
	store.request_milling(expected,proposal,CONFIG)
	check(await store.flush_pending(),"reopened replay drains")
	check(store.get_growth_production().revision == 1 and store.get_yard_inventory().flour == 3 and store.get_yard_inventory().wheat == 17 and store.get_growth_budget("breakfast").available == 0,"real reopen cannot duplicate input debit/output/XP/AP")
	var full := morning.duplicate(true)
	full[Inventory.FIELD].flour = Inventory.MAX_COUNT
	# request_patch merges root fields, so explicitly reset the test receipt
	# sidecar too; a real detached inventory/receipt pair correctly fails closed.
	full[Production.FIELD] = Production.empty()
	store.request_patch("fixture",full)
	check(await store.flush_pending(),"capacity fixture saved")
	store.request_milling(store.get_growth_budget("breakfast"),propose(full),CONFIG)
	check(await store.flush_pending() and refusals.back().code == "PRODUCTION_LIMIT","SaveStore preserves capacity refusal instead of generic invalid intent")
	check(store.get_yard_inventory().wheat == 19 and store.get_growth_budget("breakfast").available == 1,"capacity refusal does not charge stock or AP")
	var race := morning.duplicate(true)
	race[Inventory.FIELD].revision += 1
	store.request_patch("fixture",race)
	check(await store.flush_pending(),"stock race fixture saved")
	store.request_milling(expected,proposal,CONFIG)
	check(await store.flush_pending() and refusals.back().code == "GROWTH_CHANGED","SaveStore preserves material-race refusal")
	check(Coordinator.IntentRejection.new("FUTURE_UNTRUSTED").code == "INVALID_LOCAL_INTENT","unknown refusal strings remain blocked")
	store.commit_rejected.disconnect(receive_rejection)
