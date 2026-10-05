extends SceneTree
const L=preload("res://scripts/persistence/web_save_legacy_reply.gd")
const R=preload("res://scripts/persistence/web_save_reply.gd")
var checks=0
func check(value:bool,label:String)->void:
	checks+=1
	if not value: push_error(label);quit(1)
func _initialize()->void:
	var row={"status":"absent","snapshot_status":"absent","sha256":"","bytes":0,"baseline_status":"absent","baseline_sha256":"","baseline_bytes":0,"reason":""}
	var w={"schema":"youjia.legacy-inspection/v1","namespace":R.NAMESPACE,"current_token":"a".repeat(32),"baseline":"none","status":"absent","sources":{"primary":row.duplicate(),"backup":row.duplicate()}}
	check(L.inspection(w),"empty fingerprints")
	check(L.inspection(R.parse(JSON.stringify(w),true)),"JSON numeric byte counts accepted")
	check(R.parse(JSON.stringify(w)).is_empty(),"old wire still refuses numeric tokens")
	for key in row:
		var bad=w.duplicate(true);bad.sources.primary.erase(key);check(not L.inspection(bad),"missing "+key)
	for value in [-1,0.5,"0",true,1572865]:
		var bad=w.duplicate(true);bad.sources.primary.bytes=value;check(not L.inspection(bad),"invalid count")
	var unavailable=w.duplicate(true);unavailable.status="unavailable";unavailable.sources.primary.status="unavailable";unavailable.sources.primary.snapshot_status="unavailable";unavailable.sources.primary.reason="read_failed"
	check(L.inspection(unavailable),"unavailable distinct from absent")
	unavailable.status="same";check(not L.inspection(unavailable),"unavailable cannot same")
	var changed=w.duplicate(true);changed.status="changed";changed.sources.primary.merge({"status":"changed","snapshot_status":"present","sha256":"b".repeat(64),"bytes":1},true)
	check(L.inspection(changed),"no baseline present means changed")
	changed.sources.primary.status="same";check(not L.inspection(changed),"no baseline cannot same")
	check(R.parse('{"bytes":0,"bytes":1}',true).is_empty(),"numeric mode duplicate blocked")
	check(not L.exported({}),"missing export refused")
	print("LEGACY_BRIDGE_PASS ",checks);quit()
