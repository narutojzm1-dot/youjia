extends "res://test/growth_production_suite.gd"
const Stove := preload("res://scripts/game/yard_stove.gd")
const STOVE_CONFIG := {"ap":1,"stones":1,"experience":1}

func plan_stove(s: Dictionary) -> Dictionary:
	return Materials.plan(s,{STONE:{"id":"build_stove","materials":{STONE:1}}},RandomNumberGenerator.new())
func build(s: Dictionary, stage: int) -> Dictionary:
	return Budget.complete_stove(s,Budget.budget(s,"lunch"),stage,plan_stove(s),STOVE_CONFIG)
func stove_intent(e: Dictionary, p: Dictionary) -> Callable:
	return func(s: Dictionary) -> Variant:
		var r := Budget.complete_stove(s,e,0,p,STOVE_CONFIG)
		return Coordinator.IntentRejection.new(r.error) if r.has("error") else r.candidate

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated.trim_suffix("/")+"/"):
		quit(2)
		return
	var old := eat(fixture(),"breakfast")
	old = pond(old,"breakfast","old_rim").candidate
	var s := eat(old,"lunch")
	var original := s.duplicate(true)
	check(Stove.read(s) == Stove.empty() and not s.has(Stove.FIELD),"old pond save reads as no stove without conversion")
	var stages: Array[Dictionary] = []
	for stage in 3:
		var previous := s.duplicate(true)
		s = build(s,stage).candidate
		stages.append(s)
		check(Stove.read(s).revision == stage+1 and Stove.read(s).receipts.size() == stage+1,"one receipt IS one stage")
		check(s.keepsakes[STONE] == original.keepsakes[STONE]-stage-1 and Budget.budget(s,"lunch").available == 2-stage,"stage shares material and meal AP")
		check(s[Edging.FIELD] == original[Edging.FIELD] and s[Budget.FIELD] == original[Budget.FIELD] and Inventory.read(s) == Inventory.read(original),"old pond, inventory and AP receipts retained")
		check(Stove.read(s).receipts[stage].experience == 1 and s.other_owner == original.other_owner,"exact XP and other owner preserved")
		check(Stove.read(JSON.parse_string(JSON.stringify(s))) == Stove.read(s),"stage JSON recovery")
		check(not Budget.complete_stove(s,Budget.budget(previous,"lunch"),stage,plan_stove(previous),STOVE_CONFIG).has("candidate"),"replay stale stage never debits twice")
	check(original == eat(old,"lunch"),"pure construction does not change source")
	var fed := eat(s,"dinner")
	check(Budget.complete_stove(fed,Budget.budget(fed,"dinner"),3,plan_stove(fed),STOVE_CONFIG).error == "STOVE_COMPLETE","complete stove cannot spend new meal AP")
	for raw: Variant in [null,{},[],{"schema":2,"revision":0,"receipts":[]},{"schema":1,"revision":4,"receipts":[]}]:
		var bad := original.duplicate(true)
		bad[Stove.FIELD] = raw
		check(Stove.read(bad).is_empty() and Budget.budget(bad,"lunch").error == "AP_INVALID","malformed/future ledger fails closed")
	for key: String in ["stage","day","period","ap","stones","experience"]:
		var bad := stages[0].duplicate(true)
		bad[Stove.FIELD].receipts[0].erase(key)
		check(Stove.read(bad).is_empty(),"partial stage rejected " + key)
	for key: String in STOVE_CONFIG:
		for invalid: Variant in [0,-1,1.5,"1",null]:
			var config := STOVE_CONFIG.duplicate(true)
			config[key] = invalid
			check(not Budget.complete_stove(original,Budget.budget(original,"lunch"),0,plan_stove(original),config).has("candidate"),"invalid cost rejected " + key)
	var raced := original.duplicate(true)
	raced.keepsakes[STONE] -= 1
	check(Budget.complete_stove(raced,Budget.budget(original,"lunch"),0,plan_stove(original),STOVE_CONFIG).error == "GROWTH_CHANGED","FIFO rechecks actual material stock")
	for landed: bool in [false,true]:
		var backend := Backend.new()
		var writer := Coordinator.new()
		check(writer.initialize(backend,original,"stove-test"),"writer initialized")
		writer.enqueue(stove_intent(Budget.budget(original,"lunch"),plan_stove(original)))
		await process_frame
		backend.prepare_ok()
		backend.send("unknown",{},"TIMEOUT")
		check(writer.get_confirmed() == original,"unknown paints/charges no stage")
		check(writer.enqueue(stove_intent(Budget.budget(original,"lunch"),plan_stove(original))).is_empty(),"unknown blocks replacement")
		writer.retry_resolve()
		backend.receipt("confirmed" if landed else "rejected")
		backend.ack()
		check(writer.get_confirmed() == (stages[0] if landed else original),"unknown resolves all-or-none")
		backend.sync = true
		writer.enqueue(stove_intent(Budget.budget(original,"lunch"),plan_stove(original)))
		await process_frame
		check(writer.get_confirmed() == stages[0],"retry exactly once")
		check(writer.close_when_idle(),"writer drained")
	var store = root.get_node("SaveStore")
	var patch := original.duplicate(true)
	patch[Stove.FIELD] = Stove.empty()
	store.request_patch("stove-fixture",patch)
	check(await store.flush_pending(),"native old save fixture")
	var e: Dictionary = store.get_growth_budget("lunch")
	var proposal := plan_stove(patch)
	var config := STOVE_CONFIG.duplicate(true)
	check(not store.request_stove_growth(e,0,proposal,config).is_empty(),"SaveStore accepts intent")
	e.available = 999
	proposal.materials[STONE] = 999
	config.experience = 999
	check(store.get_yard_stove().revision == 0,"acceptance is not completion")
	check(await store.flush_pending(),"native stage committed")
	store._load()
	check(store.get_yard_stove() == Stove.read(stages[0]) and store.get_growth_budget("lunch").available == 2,"actual reopen retains stage/AP/XP")
	check(store.get_pond_edging() == Edging.read(original),"native reopen retains historical pond")
	for failure in failures: push_error(failure)
	print("YARD_STOVE checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
