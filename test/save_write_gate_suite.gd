extends SceneTree
const Gate = preload("res://scripts/persistence/save_write_gate.gd")
var failures: Array[String] = []
var checks := 0
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)
func receipt(flight: Dictionary, succeeded: bool) -> Dictionary:
	return {"write_id": flight.write_id, "candidate_token": flight.candidate_token,
		"parent_token": flight.parent_token, "observed_token": flight.candidate_token if succeeded else flight.parent_token,
		"old_write_terminated": not succeeded}
func _initialize() -> void:
	var initial := {"photos": ["old"], "relation": 1}
	var gate = Gate.new(initial)
	initial.photos.append("external")
	check(gate.working().photos == ["old"], "initial copy")
	check(gate.begin_write("candidate-a", "parent-a").is_empty(), "clean skips write")
	gate.replace_working({"photos": ["old", "first"], "relation": 2})
	var a: Dictionary = gate.begin_write("candidate-a", "parent-a")
	check(not a.is_empty(), "begin candidate")
	a.payload.photos.append("mutated return")
	check(gate.begin_write("candidate-a", "parent-a").is_empty(), "one in flight")
	gate.replace_working({"photos": ["old", "first", "new"], "relation": 3})
	check(not gate.finish(999, true), "stale callback ignored")
	check(gate.mark_unknown(a.write_id), "unknown accepted")
	check(gate.uncertain() and gate.blocked(), "unknown holds ownership")
	check(gate.begin_write("candidate-a", "parent-a").is_empty(), "unknown blocks next write")
	check(not gate.finish(a.write_id, false), "timeout cannot reject unknown")
	check(not gate.finish(a.write_id, true), "late callback requires verification")
	check(gate.confirmed().photos == ["old"], "unknown does not publish")
	check(gate.resolve_verified(receipt(a, true)), "verified candidate accepted")
	check(gate.confirmed().photos == ["old", "first"], "candidate is immutable")
	check(gate.working().relation == 3 and gate.working().photos.size() == 3, "new changes retained")
	check(gate.dirty(), "new revision remains dirty")
	check(not gate.resolve_verified(receipt(a, true)), "duplicate verification ignored")
	var b: Dictionary = gate.begin_write("candidate-b", "parent-b")
	check(b.write_id != a.write_id and b.payload.relation == 3, "next write is current snapshot")
	check(not gate.finish(a.write_id, true), "old callback cannot complete new flight")
	check(gate.finish(b.write_id, false) and gate.dirty(), "rejection retains dirty")
	check(gate.confirmed().relation == 2, "rejection leaves confirmed")
	var c: Dictionary = gate.begin_write("candidate-c", "parent-c")
	gate.mark_unknown(c.write_id)
	check(gate.resolve_verified(receipt(c, false)), "verified terminated parent permits retry")
	check(gate.dirty() and not gate.blocked(), "failed verification outcome retains working")
	var d: Dictionary = gate.begin_write("candidate-d", "parent-d")
	check(gate.finish(d.write_id, true), "retry succeeds")
	check(not gate.dirty() and gate.confirmed().relation == 3, "current revision confirmed")
	var copy: Dictionary = gate.confirmed()
	copy.photos.clear()
	check(gate.confirmed().photos.size() == 3, "confirmed getter defensive copy")
	var nested: Dictionary = gate.working()
	nested.photos.clear()
	check(gate.working().photos.size() == 3, "nested working getter copy")
	check(not gate.resolve_verified(receipt(d, false)), "verification without unknown rejected")
	gate.replace_working({"photos": ["later"], "relation": 4})
	var e: Dictionary = gate.begin_write("candidate-e", "parent-e")
	check(not gate.mark_unknown(e.write_id + 10) and not gate.uncertain(), "wrong unknown identity ignored")
	gate.mark_unknown(e.write_id)
	check(not gate.resolve_verified({"write_id": e.write_id + 10}) and gate.uncertain(), "wrong verification retains unknown")
	check(not gate.finish(e.write_id, true) and gate.blocked(), "ordinary success cannot release unknown")
	gate.resolve_verified(receipt(e, false))
	check(gate.working().relation == 4 and gate.confirmed().relation == 3, "verified rejection keeps both snapshots")
	var f: Dictionary = gate.begin_write("candidate-f", "parent-f")
	gate.finish(f.write_id, true)
	check(not gate.dirty() and gate.begin_write("candidate-a", "parent-a").is_empty(), "same revision success stays clean")
	check(not gate.finish(f.write_id, false) and gate.confirmed().relation == 4, "duplicate failure cannot roll back success")
	gate.replace_working({"relation": 5})
	var g: Dictionary = gate.begin_write("candidate-g", "parent-g")
	gate.mark_unknown(g.write_id)
	var wrong: Dictionary = receipt(g, true)
	wrong.observed_token = "different-digest"
	check(not gate.resolve_verified(wrong) and gate.uncertain(), "same id wrong digest rejected")
	wrong = receipt(g, false)
	wrong.old_write_terminated = false
	check(not gate.resolve_verified(wrong) and gate.blocked(), "parent without termination rejected")
	check(not gate.resolve_verified(receipt(a, true)), "old flight receipt rejected")
	var restarted = Gate.new({})
	restarted.replace_working({"relation": 6})
	var fresh: Dictionary = restarted.begin_write("new-context-candidate", "new-context-parent")
	restarted.mark_unknown(fresh.write_id)
	check(fresh.write_id == a.write_id, "process id is reused across contexts")
	check(not restarted.resolve_verified(receipt(a, true)) and restarted.uncertain(), "stable identity rejects reused process id")
	check(restarted.resolve_verified(receipt(fresh, true)), "matching stable identity resolves")
	check(gate.resolve_verified(receipt(g, false)), "terminated matching parent resolves rejection")
	check(gate.begin_write("", "parent").is_empty(), "empty identity rejected")
	check(gate.begin_write("same", "same").is_empty(), "candidate must differ from parent")
	# Every malformed token is rejected without changing the pending operation.
	for key in ["candidate_token", "parent_token", "observed_token"]:
		for bad in [null, [], {}, true, 7, 1.5, ""]:
			var guarded = Gate.new({"value": 1})
			guarded.replace_working({"value": 2})
			var held: Dictionary = guarded.begin_write("candidate", "parent")
			guarded.mark_unknown(held.write_id)
			guarded.replace_working({"value": 3})
			var malformed := receipt(held, true)
			malformed[key] = bad
			check(not guarded.resolve_verified(malformed), "malformed token rejected: " + key)
			malformed.erase(key)
			check(not guarded.resolve_verified(malformed), "missing token rejected: " + key)
			check(guarded.uncertain() and guarded.blocked() and guarded.dirty(), "malformed preserves lifecycle")
			check(guarded.working() == {"value": 3} and guarded.confirmed() == {"value": 1}, "malformed preserves snapshots")
			check(guarded.begin_write("next", "candidate").is_empty(), "malformed cannot release writer")
			check(guarded.resolve_verified(receipt(held, true)) and guarded.confirmed() == {"value": 2} and guarded.working() == {"value": 3} and guarded.dirty(), "original flight intact after malformed receipt")
	var wire_gate = Gate.new({"value": 1})
	wire_gate.replace_working({"value": 2})
	var wire_flight: Dictionary = wire_gate.begin_write("wire-candidate", "wire-parent")
	wire_gate.mark_unknown(wire_flight.write_id)
	var wire := receipt(wire_flight, true)
	wire.schema = "youjia.save-receipt/v1"
	wire.write_id = str(wire_flight.write_id)
	for raw in ["{", "null", "[]", "true", "7", "{}"]:
		check(not wire_gate.resolve_verified_json(raw) and wire_gate.uncertain(), "invalid wire JSON rejected")
	for bad_id in [null, [], {}, 1, 1.0, true, "01", "+1", "-1", "0", "1.0", "9223372036854775808", "999999999999999999999999999"]:
		var bad := wire.duplicate(true)
		bad.write_id = bad_id
		check(not wire_gate.resolve_verified_json(JSON.stringify(bad)) and wire_gate.blocked(), "invalid wire identity rejected")
	for bad_schema in [null, [], {}, 1, "youjia.save-receipt/v2"]:
		var bad := wire.duplicate(true)
		bad.schema = bad_schema
		check(not wire_gate.resolve_verified_json(JSON.stringify(bad)) and wire_gate.uncertain(), "invalid wire version rejected")
	for key in ["candidate_token", "parent_token", "observed_token"]:
		var bad := wire.duplicate(true)
		bad[key] = []
		check(not wire_gate.resolve_verified_json(JSON.stringify(bad)), "wire token type rejected")
	check(wire_gate.confirmed() == {"value": 1} and wire_gate.working() == {"value": 2}, "wire rejects preserve snapshots")
	check(wire_gate.resolve_verified_json(JSON.stringify(wire)), "valid wire candidate accepted")
	check(wire_gate.confirmed() == {"value": 2} and not wire_gate.blocked(), "wire confirmation once")
	check(not wire_gate.resolve_verified_json(JSON.stringify(wire)), "duplicate wire receipt ignored")
	if not failures.is_empty():
		push_error(str(failures))
		quit(1)
		return
	print("SAVE WRITE GATE PASS ", checks)
	quit(0)
