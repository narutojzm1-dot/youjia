extends "res://test/yard_stove_suite.gd"
const OldBudget := preload("res://test/fixtures/growth_70de87a/growth_budget.gd")
const OldProduction := preload("res://test/fixtures/growth_70de87a/growth_production.gd")

func run() -> void:
	var s := eat(fixture(),"breakfast")
	s = pond(s,"breakfast","legacy").candidate
	s = eat(s,"lunch")
	check(OldBudget.budget(s,"lunch").available == 3,"unchanged legacy save stays usable in old reader")
	var before := s.duplicate(true)
	for stage in 3:
		s = build(s,stage).candidate
		var old := OldBudget.budget(s,"lunch")
		print("OLD_CLIENT stage=%d result=%s new_available=%d" % [stage+1,JSON.stringify(old),Budget.budget(s,"lunch").available])
		check(old.get("error") == "AP_INVALID","old reader must block AP work after stove stage %d" % (stage+1))
		check(OldProduction.read(s).is_empty(),"old Production cannot silently discard stove AP scope")
		check(Budget.budget(s,"lunch").available == 2-stage,"current reader accounts for exact combined spends")
	var old_plan := Materials.plan(s,{STONE:{"id":"pond_edging","materials":{STONE:1}}},RandomNumberGenerator.new())
	var extra := OldBudget.complete(s,OldBudget.budget(s,"lunch"),"old_extra",old_plan,1,1,1)
	check(not extra.has("candidate"),"old client cannot perform a fourth AP spend after three stove stages")
	check(s.has(Production.FIELD),"stove commits explicit forward AP scope")
	if not s.has(Production.FIELD):
		finish()
		return
	# Ordinary old-client inventory writes must retain the opaque forward fence.
	var carried: Dictionary = Inventory.transition(s,Inventory.read(s).revision,"withdraw","wheat").candidate
	check(carried[Production.FIELD] == s[Production.FIELD] and carried[Stove.FIELD] == s[Stove.FIELD],"old inventory clone keeps AP fence and stages")
	check(OldBudget.budget(carried,"lunch").get("error") == "AP_INVALID","old inventory write cannot reopen AP budget")
	var fed := eat(carried,"dinner")
	check(OldBudget.budget(fed,"dinner").get("error") == "AP_INVALID","old meal write cannot reopen AP budget")
	check(not Budget.budget(fed,"dinner").has("error") and Stove.read(fed).revision == 3,"new reader recovers old ordinary writes with stove intact")
	var milled: Dictionary = mill(fed,"dinner").candidate
	check(milled[Production.FIELD].schema == 2 and Production.read(milled).revision == 1,"milling preserves forward AP scope and its own sequence")
	check(OldBudget.budget(milled,"dinner").get("error") == "AP_INVALID","milling never downgrades old reader fence")
	for invalid in ["downgrade","drop_stove","empty_stove","drop_production","future"]:
		var bad := s.duplicate(true)
		match invalid:
			"downgrade": bad[Production.FIELD].schema = 1
			"drop_stove": bad.erase(Stove.FIELD)
			"empty_stove": bad[Stove.FIELD] = Stove.empty()
			"drop_production": bad.erase(Production.FIELD)
			"future": bad[Production.FIELD].schema = 3
		check(Budget.budget(bad,"lunch").get("error") == "AP_INVALID","orphaned AP scope fails closed: " + invalid)
	check(not before.has(Production.FIELD) and not before.has(Stove.FIELD),"read and completion do not mutate legacy source")
	finish()

func finish() -> void:
	for failure in failures: push_error(failure)
	print("STOVE_CROSS_VERSION checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
