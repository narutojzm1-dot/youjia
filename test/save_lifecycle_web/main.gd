extends Node
const Snapshot = preload("res://source_snapshot.gd")
var host: JavaScriptObject
var callbacks: Array = []
var token := ""
var request := ""
var candidate_token := ""
const WRITE_ID := "1"
var seeded := "{\"version\":5,\"album\":[\"kept\"],\"x_raw\":9007199254740993}"
func cb(f: Callable) -> JavaScriptObject:
	var value := JavaScriptBridge.create_callback(f)
	callbacks.append(value)
	return value
func _ready() -> void:
	if bool(JavaScriptBridge.eval("new URLSearchParams(location.search).has('seed')")):
		var file := FileAccess.open("user://youjia_save.json", FileAccess.WRITE)
		file.store_string(seeded)
		file.close()
		JavaScriptBridge.eval("window.seedWritten=true")
		return
	host = JavaScriptBridge.get_interface("YoujiaRecoveryHostBridge")
	host.open(str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('store')")), "candidate-v1", cb(opened))
func parse(args: Array) -> Dictionary:
	return JSON.parse_string(str(args[0]))
func publish(value: Dictionary) -> void:
	JavaScriptBridge.eval("window.lifecycleResult=" + JSON.stringify(value))
func opened(args: Array) -> void:
	var r := parse(args)
	if r.has("error"):
		publish(r)
		return
	if r.verdict == "empty":
		var sources := Snapshot.new().capture("user://youjia_save.json", "user://youjia_save.bak", "candidate-v1")
		JavaScriptBridge.eval("window.captureAfterRuntime=" + str(bool(JavaScriptBridge.eval("window.runtimeComplete === true"))).to_lower())
		host.initializeLegacy(JSON.stringify(sources), cb(opened))
		return
	token = str(r.current_token)
	var payload: Dictionary = JSON.parse_string(str(r.current_payload))
	if payload.get("schema", "") == "youjia.legacy-v5-import/v1":
		if payload.sources.primary.text != seeded:
			publish({"error":"legacy raw mismatch"})
			return
		JavaScriptBridge.eval("window.rawPreserved=true")
		host.prepare('{"version":5,"saved_after_ready":true}', token, cb(prepared))
	else:
		publish({"reloaded":payload.get("saved_after_ready",false)})
func prepared(args: Array) -> void:
	var r := parse(args)
	if r.has("error"):
		publish(r)
		return
	if r.size() != 2 or not valid_identity(r.get("request_id")) or not valid_identity(r.get("candidate_token")):
		publish({"error":"invalid prepare identity"})
		return
	request = r.request_id
	candidate_token = r.candidate_token
	host.submit(request, WRITE_ID, cb(submitted))
func submitted(args: Array) -> void:
	var r := parse(args)
	if r.has("error"):
		publish(r)
		return
	if r.size() != 6 or r.get("schema") != "youjia.save-receipt/v1" or r.get("write_id") != WRITE_ID \
		or r.get("parent_token") != token or r.get("candidate_token") != candidate_token \
		or r.get("observed_token") != candidate_token or not r.get("old_write_terminated") is bool \
		or r.get("old_write_terminated") != true:
		publish({"error":"unverified receipt"})
		return
	host.acknowledge(request, cb(acknowledged))
func acknowledged(args: Array) -> void:
	var r := parse(args)
	if r.size() != 2 or r.get("request_id") != request or r.get("status") not in ["cleared", "already_clear"]:
		publish({"error":"unverified acknowledgement"})
		return
	publish({"receipt":r,"done":true})
func valid_identity(value: Variant) -> bool:
	if not value is String or value.length() != 32:
		return false
	for character: String in value:
		if character not in "0123456789abcdef":
			return false
	return true
