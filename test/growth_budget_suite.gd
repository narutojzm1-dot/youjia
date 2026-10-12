extends SceneTree
const Budget := preload("res://scripts/game/growth_budget.gd")
const Materials := preload("res://scripts/game/growth_materials.gd")
const Meals := preload("res://scripts/game/meal_ledger.gd")
const Edging := preload("res://scripts/game/pond_edging.gd")
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Coordinator := preload("res://scripts/persistence/save_coordinator.gd")
const Backend := preload("res://test/save_coordinator_suite.gd").Backend
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
func propose(s: Dictionary) -> Dictionary:
	return Materials.plan(s,{STONE:{"id":"pond_edging","materials":{STONE:1}}},RandomNumberGenerator.new())
func work(s: Dictionary, period: String, section: String, cost: int = 1) -> Dictionary:
	# Explicit fixture costs; no production balance or scene is implied.
	return Budget.complete(s,Budget.budget(s,period),section,propose(s),cost,1,1)
func intent(expected: Dictionary, proposal: Dictionary) -> Callable:
	var e := expected.duplicate(true)
	var p := proposal.duplicate(true)
	return func(s: Dictionary) -> Variant:
		var result := Budget.complete(s,e,"first",p,1,1,1)
		return Coordinator.IntentRejection.new(result.error) if result.has("error") else result.candidate
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated.trim_suffix("/")+"/"):
		quit(2)
		return
	var none := fixture()
	for period: String in Budget.PERIODS:
		check(Budget.budget(none,period).available == 0,"no meal no AP: "+period)
		check(work(none,period,"first").error == "AP_EMPTY","no meal cannot consume material: "+period)
	var morning := eat(none,"breakfast")
	var before := morning.duplicate(true)
	check(Budget.budget(morning,"breakfast").available == 1,"breakfast grants once")
	check(Budget.budget(morning,"lunch").available == 1,"breakfast carries despite missed lunch")
	var noon := eat(morning,"lunch")
	check(Budget.budget(noon,"lunch").available == 4,"breakfast remainder plus lunch")
	check(Budget.budget(noon,"dinner").available == 1,"evening carry capped even without dinner")
	var night := eat(noon,"dinner")
	check(Budget.budget(night,"dinner").available == 3,"capped carry plus dinner, never six")
	check(Budget.budget(noon,"breakfast").error == "AP_PERIOD_CHANGED","later meal prevents period rewind")
	check(Budget.budget(night,"lunch").error == "AP_PERIOD_CHANGED","dinner prevents noon rewind")
	var first := work(morning,"breakfast","first").candidate as Dictionary
	check(first.keepsakes[STONE] == 11 and first.pond_edging.sections.first.experience == 1 and first.growth_actions.actions.first.ap == 1,"AP/material/world/XP in one snapshot")
	check(Budget.budget(first,"breakfast").available == 0,"AP spent once")
	check(morning == before,"pure transition never mutates source")
	check(first.other_owner == before.other_owner and first.meal_ledger == before.meal_ledger,"unrelated data and meal receipt preserved")
	check(work(first,"breakfast","second").error == "AP_EMPTY","spent breakfast cannot build again")
	var spent_noon := eat(first,"lunch")
	spent_noon = work(spent_noon,"lunch","second",2).candidate
	check(Budget.budget(spent_noon,"lunch").available == 1,"configured two AP charged once")
	check(Budget.budget(spent_noon,"dinner").available == 1,"one unspent carries")
	var spent_night := eat(spent_noon,"dinner")
	spent_night = work(spent_night,"dinner","third",3).candidate
	check(Budget.budget(spent_night,"dinner").available == 0,"evening spends its combined pool")
	check(Budget.budget(spent_night,"lunch").error == "AP_PERIOD_CHANGED","spent phase cannot rewind")
	var tired := eat(none,"breakfast",true)
	check(Budget.budget(tired,"breakfast").available == 0 and Meals.read(tired).receipts.size() == 1,"zero grant still completed meal")
	tired = eat(tired,"lunch",true)
	check(Budget.budget(tired,"lunch").available == 1,"tired lunch one")
	tired = eat(tired,"dinner",true)
	check(Budget.budget(tired,"dinner").available == 2,"tired dinner one plus one carry, no second halving")
	var recovered: Dictionary = JSON.parse_string(JSON.stringify(spent_night))
	check(Budget.read(recovered) == Budget.read(spent_night),"AP receipts normalize JSON")
	check(Budget.budget(recovered,"dinner") == Budget.budget(spent_night,"dinner"),"JSON budget guard remains equal")
	for i in 5: check(Budget.budget(night,"dinner").available == 3,"reads never regrant or compound cap")
	var tomorrow := night.duplicate(true)
	tomorrow.holiday_day = 2
	check(Budget.budget(tomorrow,"breakfast").error == "AP_CROSS_DAY_UNRESOLVED","unspent old day not silently cleared/carried")
	check(Budget.budget(tomorrow,"breakfast").remaining == {"1":3},"unresolved surplus remains inspectable")
	check(not work(tomorrow,"breakfast","future").has("candidate"),"unresolved policy cannot debit")
	var empty_tomorrow := spent_night.duplicate(true)
	empty_tomorrow.holiday_day = 2
	check(Budget.budget(empty_tomorrow,"breakfast").available == 0,"zero prior balance needs no carry decision")
	empty_tomorrow = eat(empty_tomorrow,"breakfast")
	check(Budget.budget(empty_tomorrow,"breakfast").available == 1,"new day actual breakfast, not old grants")
	var e := Budget.budget(morning,"breakfast")
	var p := propose(morning)
	check(Budget.complete(first,e,"another",p,1,1,1).error == "AP_CHANGED","queued duplicate uses stale budget")
	check(Budget.complete(noon,e,"another",p,1,1,1).error == "AP_PERIOD_CHANGED","meal change invalidates started work")
	var material_changed := morning.duplicate(true)
	material_changed.keepsakes[STONE] += 1
	check(Budget.complete(material_changed,e,"another",p,1,1,1).error == "GROWTH_CHANGED","material change does not spend AP")
	for cost in [-1,0,7]: check(Budget.complete(morning,e,"first",p,cost,1,1).error == "AP_INVALID","invalid AP configuration")
	check(Budget.complete(morning,e,"first",p,2,1,1).error == "AP_EMPTY","cost exceeds available")
	check(Budget.complete(morning,e,"first",p,1,2,1).error == "EDGING_INVALID","material config rejection does not spend AP")
	for raw: Variant in [null,[],{}, {"schema":2,"revision":0,"actions":{}}, {"schema":1,"revision":1,"actions":{}}]:
		var bad := morning.duplicate(true)
		bad[Budget.FIELD] = raw
		check(Budget.budget(bad,"breakfast").error == "AP_INVALID","invalid/future AP ledger fails closed")
	for field: String in ["ap","period","day"]:
		var bad := first.duplicate(true)
		bad.growth_actions.actions.first[field] = 1.5 if field == "ap" else ("future" if field == "period" else 2)
		check(Budget.read(bad).is_empty(),"invalid receipt: "+field)
	var orphan := first.duplicate(true)
	orphan.erase(Budget.FIELD)
	check(Budget.read(orphan).is_empty(),"world result missing AP record cannot reset ledger")
	orphan = first.duplicate(true)
	orphan.erase(Edging.FIELD)
	check(Budget.read(orphan).is_empty(),"AP charge missing world result invalid")
	var overdraft := first.duplicate(true)
	overdraft.growth_actions.actions.first.ap = 2
	check(Budget.budget(overdraft,"breakfast").error == "AP_INVALID","historical overdraft rejected")
	for landed: bool in [false,true]:
		var backend := Backend.new()
		var coordinator := Coordinator.new()
		check(coordinator.initialize(backend,morning,"root-token"),"writer initialized")
		coordinator.enqueue(intent(e,p))
		await process_frame
		backend.prepare_ok()
		backend.send("unknown",{},"TIMEOUT")
		check(coordinator.get_confirmed() == morning,"unknown result publishes no partial charge/result")
		check(coordinator.enqueue(intent(e,p)).is_empty(),"unknown prevents replacement")
		coordinator.retry_resolve()
		backend.receipt("confirmed" if landed else "rejected")
		backend.ack()
		check(coordinator.get_confirmed() == (first if landed else morning),"resolution all four effects or none")
		backend.sync = true
		coordinator.enqueue(intent(e,p))
		await process_frame
		check(coordinator.get_confirmed() == first,"retry no double AP/material/world/XP")
		check(coordinator.close_when_idle(),"queue drained")
	var store = root.get_node("SaveStore")
	store.request_patch("fixture",morning)
	check(await store.flush_pending(),"native fixture saved")
	var expected: Dictionary = store.get_growth_budget("breakfast")
	var proposal := propose(morning)
	var ticket: String = store.request_pond_growth(expected,"first",proposal,1,1,1)
	expected.available = 999
	proposal.materials[STONE] = 9
	store.request_pond_growth(e,"first",p,1,1,1)
	check(not ticket.is_empty() and not store._data.has(Budget.FIELD),"accepted is not committed, captures caller values")
	check(await store.flush_pending(),"native duplicate queue drains")
	var disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(store.SAVE_PATH))
	check(Budget.budget(disk,"breakfast").available == 0 and disk.keepsakes[STONE] == 11 and Edging.read(disk).revision == 1,"real file contains all effects once")
	store._load()
	store.request_pond_growth(e,"first",p,1,1,1)
	check(await store.flush_pending(),"reopen replay drains")
	check(store.get_growth_budget("breakfast").available == 0 and store.get_keepsakes()[STONE] == 11,"reopen cannot double charge or regrant")
	for failure in failures: push_error(failure)
	print("GROWTH_BUDGET checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
