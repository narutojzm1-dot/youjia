extends SceneTree
## Deterministic backend contract tests, not a mock claim of disk durability.
const Coordinator = preload("res://scripts/persistence/save_coordinator.gd")
var checks := 0
var failures: Array[String] = []

class Backend extends RefCounted:
	signal completed(request_id: String, method: String, reply: Dictionary)
	var calls: Array[Dictionary] = []
	var sync := false
	var backend_namespace := "youjia-save-host-v1"
	var generation := 0
	var prepared: Dictionary = {}
	func request(method: String, args: Dictionary, expected: Dictionary = {}) -> String:
		var id := "call-" + str(calls.size() + 1)
		calls.append({"id": id, "method": method, "args": args, "expected": expected})
		if sync:
			if method == "prepare": prepare_ok()
			elif method == "submit": receipt("confirmed")
			elif method == "acknowledge": ack()
		return id
	func send(status: String, wire: Dictionary = {}, code: String = "TEST") -> void:
		var c: Dictionary = calls.back()
		completed.emit(c.id, c.method, {"status": status, "code": code, "wire": wire})
	func prepare_ok() -> void:
		var args: Dictionary = calls.back().args
		prepared = {"schema": "youjia.save-prepared/v1", "namespace": backend_namespace, "store_id": "store-a", "write_id": args.write_id, "request_id": "req-"+args.write_id, "candidate_token": "token-"+args.write_id, "parent_token": args.parent_token, "payload_sha256": str(args.payload).sha256_text(), "generation": str(generation+1)}
		send("prepared", prepared)
	func wire_for(outcome: String) -> Dictionary:
		var w := prepared.duplicate(true)
		w.schema = "youjia.save-receipt/v2"
		w.outcome = outcome
		w.observed_token = w.candidate_token if outcome == "confirmed" else w.parent_token
		w.transaction_state = "complete" if outcome == "confirmed" else "terminated"
		w.readback_verified = true
		w.old_write_terminated = true
		return w
	func receipt(outcome: String) -> void:
		if outcome == "confirmed": generation += 1
		send(outcome, wire_for(outcome))
	func ack() -> void:
		send("acknowledged", {"schema":"youjia.save-ack/v1", "namespace":backend_namespace, "request_id":prepared.request_id, "write_id":prepared.write_id, "status":"cleared"})

func _initialize() -> void:
	call_deferred("_run")

func change(key: String, value: Variant) -> Callable:
	return func(snapshot: Dictionary) -> Dictionary:
		snapshot[key] = value
		return snapshot

func setup_pair(sync: bool = false, ns: String = "youjia-save-host-v1") -> Array:
	var b := Backend.new()
	b.sync = sync
	b.backend_namespace = ns
	var c = Coordinator.new()
	check(c.initialize(b, {"version":5,"album":[],"plant":0}, "root-token", ns), "trusted initialization")
	return [c,b]

func _run() -> void:
	var loading = Coordinator.new()
	check(loading.get_state() == "initializing" and loading.enqueue(change("x",1)) == "", "loading rejects writes")
	check(not loading.initialize(Backend.new(), {"version":4}, "root"), "untrusted initialization refused")
	await queue_and_sync()
	await uncertain_and_ack()
	await identity_cases()
	await malformed_and_native()
	print("SAVE_COORDINATOR checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)

func queue_and_sync() -> void:
	var pair = setup_pair(); var c = pair[0]; var b: Backend = pair[1]
	var events: Array = []
	c.confirmed.connect(func(id,snapshot,token): events.append([id,snapshot,token]))
	var one: String = c.enqueue(change("album",["photo"]))
	var two: String = c.enqueue(change("plant",7))
	check(one == "1" and two == "2" and b.calls.is_empty(), "acceptance returns before starting or confirming")
	check(c.get_confirmed().album.is_empty(), "accepted photo is not confirmed")
	check(not c.is_idle(), "accepted deferred queue is not idle before first pump")
	check(not c.close_when_idle(), "queued work cannot be abandoned by close")
	await process_frame
	check(b.calls.size() == 1 and b.calls.back().method == "prepare", "single FIFO head prepared")
	b.prepare_ok(); b.receipt("confirmed")
	check(events.size() == 1 and events[0][0] == one and c.get_confirmed().album == ["photo"], "confirmed snapshot published before ack")
	check(b.calls.back().method == "acknowledge", "ack before next prepare")
	b.ack()
	check(c.get_state() == "ready" and not c.is_idle(), "ready between queued operations is not drained")
	await process_frame
	var candidate: Dictionary = JSON.parse_string(b.calls.back().args.payload)
	check(candidate.album == ["photo"] and candidate.plant == 7, "second intent derives from newest confirmed, preserving another owner")
	check(b.calls.back().args.parent_token == "token-1", "second write uses latest token")
	b.prepare_ok(); b.receipt("confirmed"); b.ack()
	check(c.get_state() == "ready" and events.size() == 2, "FIFO completes")
	check(c.is_idle(), "only final acknowledgement drains queue")
	var leaked: Dictionary = c.get_confirmed(); leaked.album.clear()
	check(c.get_confirmed().album == ["photo"], "getter returns deep copy")
	events[1][1].album.clear()
	check(c.get_confirmed().album == ["photo"], "signal snapshot cannot mutate confirmed")
	pair = setup_pair(true); c = pair[0]; b = pair[1]
	var seen: Array = []; var caller_ids: Array = []
	c.confirmed.connect(func(id,_snapshot,_token): seen.append(caller_ids.has(id)))
	caller_ids.append(c.enqueue(change("plant",3)))
	check(seen.is_empty(), "synchronous adapter cannot complete inside enqueue")
	await process_frame
	check(seen == [true] and c.get_state() == "ready", "synchronous completion buffered and returned ID registered first")

func uncertain_and_ack() -> void:
	var pair = setup_pair(); var c = pair[0]; var b: Backend = pair[1]
	var confirmations: Array = []; var rejections: Array = []; var unknowns: Array = []
	c.confirmed.connect(func(id,_s,_t): confirmations.append(id))
	c.rejected.connect(func(id,_r): rejections.append(id))
	c.unknown.connect(func(id,_r): unknowns.append(id))
	c.enqueue(change("album",["pending"])); c.enqueue(change("plant",8)); await process_frame
	b.prepare_ok(); var old_call: Dictionary = b.calls.back().duplicate(true)
	b.send("unknown", {}, "TIMEOUT")
	check(c.get_state() == "unknown" and rejections.is_empty() and confirmations.is_empty(), "timeout is unknown, not rejection or confirmation")
	check(not c.is_idle(), "unknown is never idle")
	check(not c.close_when_idle(), "unknown operation cannot be discarded")
	check(c.enqueue(change("x",1)) == "" and c.get_confirmed().album.is_empty(), "unknown blocks writes and retains confirmed parent")
	check(c.retry_resolve(), "explicit resolve allowed")
	b.completed.emit(old_call.id, old_call.method, {"status":"confirmed","wire":b.wire_for("confirmed")})
	check(c.get_state() == "resolving" and confirmations.is_empty(), "late submit receipt cannot overtake resolve")
	var w := b.wire_for("rejected"); w.old_write_terminated = false; b.send("rejected",w)
	check(c.get_state() == "unknown" and rejections.is_empty(), "parent without termination cannot reject")
	c.retry_resolve(); b.receipt("rejected")
	check(rejections == ["1"] and c.get_confirmed().album.is_empty(), "trusted terminated parent rejects only that operation")
	await process_frame
	var next: Dictionary = JSON.parse_string(b.calls.back().args.payload)
	check(next.album.is_empty() and next.plant == 8, "queued intent replays from parent after rejection")
	b.prepare_ok(); b.receipt("confirmed"); var ack_call: Dictionary = b.calls.back().duplicate(true)
	b.send("ack_failed",{},"ACK_IO")
	check(c.get_state() == "blocked" and c.get_confirmed().plant == 8 and confirmations == ["2"], "ack error never rolls back committed business state")
	check(c.enqueue(change("x",1)) == "", "ack failure blocks new enqueue")
	check(not c.is_idle(), "ack-blocked is never idle")
	check(c.retry_resolve() and b.calls.back().method == "acknowledge", "retry resolves ack cleanup, not another write")
	b.completed.emit(ack_call.id,ack_call.method,{"status":"acknowledged","wire":{}})
	check(c.get_state() == "acknowledging", "late ack ignored")
	b.ack()
	check(c.get_state() == "ready" and confirmations == ["2"], "ack retry clears without duplicate confirmation")
	pair = setup_pair(); c = pair[0]; b = pair[1]
	c.enqueue(change("plant",4)); await process_frame; b.prepare_ok(); b.send("unknown")
	c.retry_resolve(); b.receipt("confirmed"); b.ack()
	check(c.get_confirmed().plant == 4 and c.get_state() == "ready", "resolve trusted candidate confirms and acknowledges")

func identity_cases() -> void:
	for key in ["namespace","store_id","write_id","request_id","candidate_token","parent_token","payload_sha256","generation","observed_token","schema","outcome","transaction_state","readback_verified","old_write_terminated"]:
		var pair = setup_pair(); var c = pair[0]; var b: Backend = pair[1]
		c.enqueue(change("plant",1)); await process_frame; b.prepare_ok()
		var w := b.wire_for("confirmed")
		w[key] = false if key in ["readback_verified","old_write_terminated"] else "wrong"
		b.send("confirmed",w)
		check(c.get_state() == "unknown" and c.get_confirmed().plant == 0, "mismatched receipt refused: " + key)
	var pair = setup_pair(); var c = pair[0]; var b: Backend = pair[1]
	c.enqueue(change("plant",1)); await process_frame; b.prepare_ok()
	b.send("rejected",b.wire_for("rejected"))
	check(c.get_state() == "unknown", "submit rejection is not authoritative parent resolution")
	pair = setup_pair(); c = pair[0]; b = pair[1]
	c.enqueue(change("plant",1)); await process_frame
	var call: Dictionary = b.calls.back()
	b.completed.emit("other",call.method,{"status":"prepared","wire":{}})
	check(c.get_state() == "writing" and b.calls.size() == 1, "wrong transport ID ignored")
	b.prepare_ok(); var submit_call: Dictionary = b.calls.back().duplicate(true)
	b.receipt("confirmed"); b.ack()
	b.completed.emit(submit_call.id,submit_call.method,{"status":"confirmed","wire":b.wire_for("confirmed")})
	check(c.get_state() == "ready" and c.get_confirmed().plant == 1, "duplicate late confirmation ignored")

func malformed_and_native() -> void:
	var pair = setup_pair(); var c = pair[0]; var b: Backend = pair[1]
	var rejects: Array = []; c.rejected.connect(func(id,_why):rejects.append(id))
	c.enqueue(func(s): s.album.append("bad"); return {"version":4})
	await process_frame
	check(rejects == ["1"] and c.get_confirmed().album.is_empty() and b.calls.is_empty(), "bad local candidate cannot mutate confirmed or reach backend")
	c.enqueue(change("plant",3)); await process_frame; b.send("blocked",{},"PREPARE_TIMEOUT")
	check(c.get_state() == "blocked" and rejects == ["1"] and not c.retry_resolve(), "prepare failure blocks, never claims rejection or invents candidate identity")
	pair = setup_pair(true, "youjia-native-file-v1"); c = pair[0]; b = pair[1]
	c.enqueue(change("plant",9)); await process_frame
	check(c.get_state() == "ready" and c.get_confirmed().plant == 9, "explicit native namespace follows same receipt contract")

	# Native raw-file token is allowed to stay equal for a byte-identical no-op.
	pair = setup_pair(false, "youjia-native-file-v1"); c = pair[0]; b = pair[1]
	c.enqueue(change("plant",0)); await process_frame
	var a: Dictionary = b.calls.back().args
	b.prepared = {"schema":"youjia.save-prepared/v1", "namespace":b.backend_namespace, "store_id":"store-a", "write_id":a.write_id, "request_id":"noop-request", "candidate_token":"root-token", "parent_token":"root-token", "payload_sha256":str(a.payload).sha256_text(), "generation":"1"}
	b.send("prepared", b.prepared); b.receipt("confirmed"); b.ack()
	check(c.get_state() == "ready" and c.get_confirmed_token() == "root-token", "native byte-identical save confirms with unchanged raw token")
	for key in ["readback_verified", "old_write_terminated"]:
		pair = setup_pair(); c = pair[0]; b = pair[1]
		c.enqueue(change("plant",1)); await process_frame; b.prepare_ok()
		var w := b.wire_for("confirmed"); w[key] = 1
		b.send("confirmed", w)
		check(c.get_state() == "unknown", "integer cannot stand in for verified boolean: " + key)

	pair = setup_pair(); c = pair[0]; b = pair[1]
	check(c.close_when_idle() and c.get_state() == "closed", "idle coordinator closes explicitly")
	check(not b.is_connected("completed", c._on_completed), "closed coordinator disconnects backend signal")
	check(c.enqueue(change("plant",2)) == "" and not c.close_when_idle(), "closed coordinator refuses writes and repeated close")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
