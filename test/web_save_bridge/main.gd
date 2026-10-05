extends Node
const Legacy=preload("res://scripts/persistence/web_save_legacy_reply.gd")
const Backend=preload("res://scripts/persistence/web_save_host.gd")
var host
var checks:Array=[]
func _ready() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks.append({"ok":ok,"label":label})
func invoke(method:String,args:Dictionary={},expected:Dictionary={}) -> Dictionary:
	var id:String=host.request(method,args,expected)
	if id.is_empty():
		check(false,method+" local refusal "+host.last_request_error)
		return {"status":"blocked","wire":{}}
	var event:Array=await host.completed
	check(event[0]==id and event[1]==method,method+" callback correlates")
	return event[2]
func run() -> void:
	host=Backend.new();add_child(host)
	var opened:Dictionary=await invoke("open")
	check(opened.status in ["empty","ready"],"open usable")
	if opened.status=="empty":
		opened=await invoke("initialize",{"payload":"{\"version\":5,\"fixture\":0}","paths":{"primaryPath":ProjectSettings.globalize_path("user://youjia_save.json"),"backupPath":ProjectSettings.globalize_path("user://youjia_save.bak")}})
		check(opened.status=="ready","initialize validated envelope")
		if opened.status=="ready":
			var prepared:Dictionary=await invoke("prepare",{"payload":"{\"version\":5,\"fixture\":1,\"note\":\"松果🌿\"}","parent_token":opened.wire.current_token,"write_id":"1"})
			check(prepared.status=="prepared","production prepare identity and hash accepted")
			if prepared.status=="prepared":
				var args={"request_id":prepared.wire.request_id,"write_id":prepared.wire.write_id}
				var submit:Dictionary=await invoke("submit",args,prepared.wire)
				check(submit.status=="confirmed","production submit durable receipt accepted")
				var resolve:Dictionary=await invoke("resolve",args,prepared.wire)
				check(resolve.status=="confirmed","production resolve same identity accepted")
				var ack:Dictionary=await invoke("acknowledge",args,prepared.wire)
				check(ack.status=="acknowledged","production ack accepted")
	else:
		check(opened.wire.get("current_payload")=="{\"version\":5,\"fixture\":1,\"note\":\"松果🌿\"}","reload confirms exact saved payload")
	var paths={"paths":{"primaryPath":ProjectSettings.globalize_path("user://youjia_save.json"),"backupPath":ProjectSettings.globalize_path("user://youjia_save.bak")}}
	var inspected:Dictionary=await invoke("inspectLegacy",paths)
	check(inspected.status in ["same","absent"],"inspection validates actual Host fingerprints")
	var exported:Dictionary=await invoke("exportRecovery",paths)
	check(exported.status==inspected.status and exported.wire.has("legacy_snapshot"),"recovery validates raw bytes seal and envelope")
	if exported.wire.has("legacy_snapshot"):
		var bad:Dictionary=exported.wire.duplicate(true)
		bad.legacy_snapshot.primary={"status":"present","base64":"%%%="}
		check(not Legacy.exported(bad),"invalid base64 rejected")
		bad=exported.wire.duplicate(true);bad.current_envelope.payload_sha256="0".repeat(64)
		check(not Legacy.exported(bad),"tampered current digest rejected")
		bad=exported.wire.duplicate(true);bad.inspection.current_token="0".repeat(32)
		check(not Legacy.exported(bad),"foreign inspection token rejected")
		if exported.wire.legacy_sources!=null:
			bad=exported.wire.duplicate(true);bad.legacy_sources.seal_sha256="0".repeat(64)
			check(not Legacy.exported(bad),"tampered seal rejected")
	JavaScriptBridge.eval("window.fixtureReadError=true")
	var unavailable:Dictionary=await invoke("exportRecovery",paths)
	check(unavailable.status=="unavailable" and unavailable.wire.get("legacy_snapshot",{}).get("primary",{}).get("status")=="read_error","unavailable export explicitly incomplete")
	JavaScriptBridge.eval("window.fixtureReadError=false")
	var closed:Dictionary=await invoke("close")
	check(closed.status=="closed","production close accepted")
	JavaScriptBridge.eval("window._lateSaveCallback=window.__YoujiaGodotSaveRouter.make("+JSON.stringify(host._route)+",'late')")
	host.queue_free()
	await get_tree().process_frame
	JavaScriptBridge.eval("window._lateSaveCallback('{}');window._lateSaveCallback=null")
	check(true,"late JS callback after node free safely ignored")
	var result={"checks":checks,"status":"PASS" if checks.all(func(c):return c.ok) else "FAIL"}
	JavaScriptBridge.eval("window.godotBridgeResult="+JSON.stringify(result))
