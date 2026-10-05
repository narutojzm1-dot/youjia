extends Node
const Snapshot = preload("res://source_snapshot.gd")
var host: JavaScriptObject
var callbacks: Array = []
var token := ""
var request := ""
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
	request = str(r.request_id)
	host.submit(request, "1", cb(submitted))
func submitted(args: Array) -> void:
	var r := parse(args)
	if r.has("error"):
		publish(r)
		return
	if r.parent_token != token or r.observed_token != r.candidate_token or not r.old_write_terminated:
		publish({"error":"unverified receipt"})
		return
	host.acknowledge(request, cb(acknowledged))
func acknowledged(args: Array) -> void:
	publish({"receipt":parse(args),"done":true})
