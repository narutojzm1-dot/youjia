extends SceneTree
# Whole domain restore -> real SaveStore/Coordinator -> Native file regression.
# Controlled records only; not a public-player incident or Web/IDB claim.
const Native = preload("res://scripts/persistence/native_save_host.gd")
const Codec = preload("res://scripts/persistence/save_data_codec.gd")
class TestStore extends "res://autoload/save_store.gd":
	func _ready(): pass
var checks := 0
var failures := 0
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", label)
func fixture() -> Dictionary:
	var session := ExplorationSession.new(ExplorationRoutes.catalog(), 0)
	session.begin(ExplorationRoutes.NEAR_PATH, {"day":1,"elapsed":0.0}, 7)
	session.request_return("player")
	var snapshot := Codec.defaults()
	snapshot.exploration = session.to_record()
	snapshot.exploration_committed_serial = 1
	snapshot.keepsakes = {"formal.find.feather":1}
	return snapshot
func run():
	for location in ["clock", "proposal", "item", "failure", "record", "normal"]:
		var snapshot := fixture()
		var session: Dictionary = snapshot.exploration.session
		match location:
			"clock": session.started_clock.future_payload={"keep":"raw"}
			"proposal": session.proposal.future_payload={"keep":"raw"}
			"item": session.proposal.items=[{"find_id":"formal.find.feather","future_payload":{"keep":"raw"}}]
			"failure": session.failure={"code":"save_failed","retryable":true,"attempts":1,"deferred":false,"future_payload":{"keep":"raw"}}
			"record": snapshot.exploration.future_payload={"keep":"raw"}
		check(ExplorationContract.validate_session_structure(session)=="",location+" accepted historical session structure")
		var base: String = "user://preservation-"+location
		var writer := FileAccess.open(base+".json",FileAccess.WRITE)
		writer.store_string(JSON.stringify(snapshot));writer.close()
		var backend := Native.new(base+".json",base+".tmp",base+".bak")
		var store := TestStore.new()
		root.add_child(store)
		store._backend=backend
		store._boot_state="ready"
		store._data=backend.get_initial_snapshot()
		check(store._connect_coordinator(store._data,backend.get_initial_token(),Native.NAMESPACE),location+" real coordinator ready")
		var before := FileAccess.get_file_as_bytes(base+".json")
		var record: Variant = store.get_exploration_record()
		var rejects := []
		var confirms := []
		store.commit_rejected.connect(func(op,kind,code): rejects.append([op,kind,code]))
		store.commit_confirmed.connect(func(op,kind): confirms.append([op,kind]))
		var host := ExplorationHost.new(store)
		host.restore()
		check(host.restore_action==ExplorationContract.HOST_CLOSE,location+" actual domain restore reaches cleanup")
		await store.flush_pending()
		await process_frame
		if location=="normal":
			check(store.get_exploration_record().session==null and confirms.size()==1 and rejects.is_empty(),"normal cleanup still confirms once")
			check(backend._calls==3,"normal real prepare submit ack")
		else:
			check(rejects.size()==1 and rejects[0][1]=="exploration_cleanup" and rejects[0][2]=="EXPLORATION_CLEANUP_INVALID_ARGUMENT",location+" original precise failure remains")
			check(confirms.is_empty(),location+" no fallback confirmed or fake success")
			check(backend._calls==0,location+" no backend prepare submit ack")
			check(FileAccess.get_file_as_bytes(base+".json")==before and store.get_exploration_record()==record,location+" authoritative file bytes and record preserved")
			check(store.is_save_idle() and not host.pending_cleanup(),location+" stops without unbounded same-page retry")
		check(store.get_keepsakes()==snapshot.keepsakes,location+" no repeated grant")
		host=null
		store.free()
	print("EXPLORATION CLEANUP PRESERVATION checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
