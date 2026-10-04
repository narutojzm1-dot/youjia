extends Node
const Gate = preload("res://gate.gd")
var gate = Gate.new({"value": "parent"})
var bridge
var callback
var flight: Dictionary
var phase := 0
var checks := 0
func check(value: bool, label: String) -> void:
	if not value:
		push_error(label)
		bridge.fail(label)
		return
	checks += 1
func _ready() -> void:
	bridge = JavaScriptBridge.get_interface("GateProbe")
	callback = JavaScriptBridge.create_callback(_receipt)
	gate.replace_working({"value": "candidate"})
	flight = gate.begin_write("candidate-1", "parent-0")
	check(gate.mark_unknown(flight.write_id), "mark unknown")
	gate.replace_working({"value": "newer-unsaved"})
	check(gate.begin_write("candidate-2", "candidate-1").is_empty(), "B blocked")
	check(not gate.resolve_verified_json("{}"), "bad receipt rejected")
	bridge.run(JSON.stringify({"write_id": str(flight.write_id), "candidate_token": flight.candidate_token, "parent_token": flight.parent_token, "payload": flight.payload}), false, callback)
func _receipt(args) -> void:
	var raw := str(args[0])
	check(gate.blocked() and gate.uncertain(), "ownership retained until receipt")
	var forged: Dictionary = JSON.parse_string(raw)
	forged.write_id = "999"
	check(not gate.resolve_verified_json(JSON.stringify(forged)), "wrong identity rejected")
	check(gate.blocked(), "bad identity keeps ownership")
	check(gate.resolve_verified_json(raw), "verified terminal receipt accepted")
	check(not gate.resolve_verified_json(raw), "duplicate rejected")
	check(gate.working() == {"value": "newer-unsaved"}, "working preserved")
	check(gate.confirmed() == {"value": "candidate"}, "confirmed candidate preserved")
	check(gate.dirty() and not gate.blocked(), "unsaved newer progress retained")
	if phase == 0:
		phase = 1
		flight = gate.begin_write("candidate-2", "candidate-1")
		check(gate.mark_unknown(flight.write_id), "abort flight unknown")
		bridge.run(JSON.stringify({"write_id": str(flight.write_id), "candidate_token": flight.candidate_token, "parent_token": flight.parent_token, "payload": flight.payload}), true, callback)
	else:
		bridge.done(checks)
		print("SAVE GATE WEB PASS ", checks)
