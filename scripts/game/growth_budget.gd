extends RefCounted
## Meal-backed intraday AP accounting. No clock policy or production action
## costs are supplied here. The future director owns the current period.
const FIELD := "growth_actions"
const PERIODS := ["breakfast", "lunch", "dinner"]
const Meals := preload("res://scripts/game/meal_ledger.gd")
const Edging := preload("res://scripts/game/pond_edging.gd")
const Contract := preload("res://scripts/exploration/exploration_contract.gd")
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")

static func empty() -> Dictionary:
	return {"schema":1, "revision":0, "actions":{}}

static func read(snapshot: Dictionary) -> Dictionary:
	var raw: Variant = snapshot.get(FIELD, empty())
	var edging := Edging.read(snapshot)
	if edging.is_empty() or not raw is Dictionary: return {}
	if raw.size() != 3 or not raw.has_all(empty().keys()): return {}
	if Contract.as_int(raw.schema,1,1) == null or Contract.as_int(raw.revision,0,Inventory.MAX_REVISION) == null: return {}
	if not raw.actions is Dictionary or raw.actions.size() != raw.revision or raw.actions.size() != edging.sections.size(): return {}
	var result := empty()
	result.revision = int(raw.revision)
	for section: Variant in raw.actions:
		var receipt: Variant = raw.actions[section]
		if not edging.sections.has(section) or not receipt is Dictionary: return {}
		if receipt.size() != 3 or not receipt.has_all(["day","period","ap"]): return {}
		if Contract.as_int(receipt.day,1,Inventory.MAX_REVISION) == null or receipt.day != edging.sections[section].day: return {}
		if receipt.period not in PERIODS or Contract.as_int(receipt.ap,1,6) == null: return {}
		result.actions[section] = {"day":int(receipt.day), "period":receipt.period, "ap":int(receipt.ap)}
	return result

## Recompute from durable earnings and spends, never add grants on every read.
## Old-day surplus is retained and explicitly unresolved, not reset or carried.
static func budget(snapshot: Dictionary, period: String) -> Dictionary:
	var day: Variant = Contract.as_int(snapshot.get("holiday_day",1),1,Inventory.MAX_REVISION)
	var meals := Meals.read(snapshot)
	var actions := read(snapshot)
	if day == null or period not in PERIODS or meals.is_empty() or actions.is_empty(): return {"error":"AP_INVALID"}
	var days := {int(day):{"earned":[0,0,0],"spent":[0,0,0],"last":-1}}
	for receipt: Dictionary in meals.receipts:
		if receipt.day > day: return {"error":"AP_INVALID"}
		if not days.has(receipt.day): days[receipt.day] = {"earned":[0,0,0],"spent":[0,0,0],"last":-1}
		var index := PERIODS.find(receipt.meal)
		days[receipt.day].earned[index] = receipt.earned
		days[receipt.day].last = maxi(days[receipt.day].last,index)
	for receipt: Dictionary in actions.actions.values():
		if not days.has(receipt.day): return {"error":"AP_INVALID"}
		var index := PERIODS.find(receipt.period)
		days[receipt.day].spent[index] += receipt.ap
		days[receipt.day].last = maxi(days[receipt.day].last,index)
	var current := PERIODS.find(period)
	if days[int(day)].last > current: return {"error":"AP_PERIOD_CHANGED"}
	var available := 0
	var unresolved := {}
	for date: int in days:
		var record: Dictionary = days[date]
		var balance := 0
		for index in 3:
			if index == 2: balance = mini(balance,1)
			balance += int(record.earned[index]) - int(record.spent[index])
			if balance < 0: return {"error":"AP_INVALID"}
			if date == day and index == current: available = balance
		if date < day and balance > 0: unresolved[str(date)] = balance
	if not unresolved.is_empty(): return {"error":"AP_CROSS_DAY_UNRESOLVED", "remaining":unresolved}
	return {"day":int(day),"period":period,"available":available,"source":{"meals":meals,"actions":actions}}

## The only composite completion: AP, material, durable world section and its
## experience receipt are committed together. No intermediate write is exposed.
static func complete(snapshot: Dictionary, expected: Dictionary, section: String, proposal: Dictionary, ap_cost: int, stones: int, experience: int) -> Dictionary:
	if expected.size() != 4 or not expected.has_all(["day","period","available","source"]) or not expected.period is String: return {"error":"AP_INVALID"}
	var current := budget(snapshot,expected.period)
	if current.has("error"): return current
	if current != expected: return {"error":"AP_CHANGED"}
	if ap_cost < 1 or ap_cost > 6: return {"error":"AP_INVALID"}
	if current.available < ap_cost: return {"error":"AP_EMPTY"}
	var actions := read(snapshot)
	if actions.revision >= Inventory.MAX_REVISION: return {"error":"AP_LIMIT"}
	var changed := Edging.complete(snapshot,actions.revision,section,proposal,stones,experience)
	if changed.has("error"): return changed
	actions.actions[section] = {"day":current.day,"period":current.period,"ap":ap_cost}
	actions.revision += 1
	changed.candidate[FIELD] = actions
	return changed
