extends SceneTree
const Decoder=preload("res://scripts/persistence/web_save_reply.gd")
const Backend=preload("res://scripts/persistence/web_save_host.gd")
var checks := 0
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures.append(label)
func root_envelope() -> Dictionary:
	var value={"schema":"youjia.save-envelope/v1","store_id":"a".repeat(32),"commit_id":"b".repeat(32),"request_id":"c".repeat(32),"parent_commit_id":"","generation":"1","payload_bytes":"{\"version\":5}","payload_sha256":"{\"version\":5}".sha256_text(),"envelope_sha256":""}
	var context=HashingContext.new();context.start(HashingContext.HASH_SHA256)
	for key in Decoder.ENVELOPE_FIELDS.slice(0,-1):
		var part=value[key].to_utf8_buffer();var prefix=PackedByteArray()
		for shift in range(7,-1,-1):prefix.append((part.size()>>(shift*8))&255)
		context.update(prefix)
		if not part.is_empty():context.update(part)
	value.envelope_sha256=context.finish().hex_encode()
	return value
func run() -> void:
	var env=root_envelope()
	check(Decoder.envelope(env),"valid complete envelope")
	var open={"schema":"youjia.host-open/v1","status":"ready","code":"clean","current_payload":env.payload_bytes,"current_token":env.commit_id,"current_envelope":env}
	check(Decoder.opened(Decoder.parse(JSON.stringify(open))),"full open wire valid")
	var broken=open.duplicate(true);broken.current_envelope.payload_bytes="{\"version\":5,\"x\":1}"
	check(not Decoder.opened(broken),"payload digest mismatch blocked")
	broken=open.duplicate(true);broken.current_envelope.envelope_sha256="0".repeat(64)
	check(not Decoder.opened(broken),"canonical envelope digest mismatch blocked")
	check(Decoder.parse('{"schema":"x","schema":"y"}').is_empty(),"duplicate keys rejected")
	check(Decoder.parse('{"schema":"x","sc\\u0068ema":"y"}').is_empty(),"escaped duplicate keys rejected")
	check(Decoder.parse('{"generation":1}').is_empty(),"numeric identity rejected")
	check(Decoder.parse('{"generation":[]}').is_empty(),"array identity rejected")
	check(not Decoder.decimal("9223372036854775808") and not Decoder.decimal("01"),"int64 overflow and leading zero rejected")
	var prepared={"schema":"youjia.save-prepared/v1","namespace":Decoder.NAMESPACE,"store_id":env.store_id,"write_id":"1","request_id":"d".repeat(32),"candidate_token":"e".repeat(32),"parent_token":env.commit_id,"payload_sha256":"f".repeat(64),"generation":"2"}
	check(Decoder.prepared(prepared),"complete prepared identity")
	var receipt=prepared.duplicate(true);receipt.schema="youjia.save-receipt/v2";receipt.merge({"observed_token":prepared.candidate_token,"outcome":"confirmed","transaction_state":"complete","readback_verified":true,"old_write_terminated":true})
	check(Decoder.receipt(receipt,prepared),"confirmed complete durable receipt")
	for key in Decoder.RECEIPT_FIELDS:
		var malformed=receipt.duplicate(true);malformed.erase(key)
		check(not Decoder.receipt(malformed,prepared),"missing receipt field "+key)
	for key in ["namespace","store_id","write_id","request_id","candidate_token","parent_token","payload_sha256","generation","observed_token"]:
		var malformed=receipt.duplicate(true);malformed[key]="wrong"
		check(not Decoder.receipt(malformed,prepared),"mismatched identity "+key)
	for key in ["readback_verified","old_write_terminated"]:
		var malformed=receipt.duplicate(true);malformed[key]=1
		check(not Decoder.receipt(malformed,prepared),"numeric truth not bool "+key)
	var rejected=receipt.duplicate(true);rejected.outcome="rejected";rejected.transaction_state="terminated";rejected.observed_token=prepared.parent_token
	check(Decoder.receipt(rejected,prepared),"terminated verified parent rejection")
	rejected.old_write_terminated=false;check(not Decoder.receipt(rejected,prepared),"unterminated parent never rejected")
	var backend=Backend.new();root.add_child(backend);backend.set_process(false)
	var delivered:Array=[];backend.completed.connect(func(id,method,reply):delivered.append({"id":id,"method":method,"reply":reply}))
	backend._flight=prepared.duplicate(true);backend._submitted=true
	backend._pending={"id":"one","method":"submit","args":{},"expected":{},"deadline":0}
	backend._receive(["stale",JSON.stringify(receipt)])
	check(not backend._pending.is_empty(),"late unrelated callback ignored")
	backend._receive(["one",JSON.stringify(receipt)])
	check(delivered.is_empty(),"completion deferred beyond request return")
	await process_frame
	check(delivered.size()==1 and delivered[0].reply.status=="confirmed","valid callback completes once")
	backend._receive(["one",JSON.stringify(receipt)]);await process_frame
	check(delivered.size()==1,"duplicate ignored")
	backend._pending={"id":"two","method":"submit","args":{},"expected":{},"deadline":0}
	backend._process(0);await process_frame
	check(delivered[-1].reply.status=="unknown","submit timeout remains unknown")
	backend._receive(["two",JSON.stringify(receipt)]);await process_frame
	check(delivered.size()==2,"late timeout success cannot confirm")
	backend._pending={"id":"three","method":"acknowledge","args":{},"expected":{},"deadline":0};backend._process(0);await process_frame
	check(delivered[-1].reply.status=="ack_failed" and backend._current.token==prepared.candidate_token,"ack timeout preserves confirmed token")
	backend.free()
	print("WEB SAVE BRIDGE DECODER ",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)
