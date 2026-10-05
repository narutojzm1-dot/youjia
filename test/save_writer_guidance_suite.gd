extends SceneTree
class TestStore extends "res://autoload/save_store.gd":
 func _ready(): pass
var checks := 0
var failures: Array[String] = []
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
 checks += 1
 if not ok: failures.append(label); push_error(label)
func run():
 for scenario in ["exact", "other-cause", "substring", "wrong-code", "wire-code", "schema", "extra", "initialize", "wrong-status", "stale-id"]:
  var store = TestStore.new()
  root.add_child(store)
  store._boot_call_id = "open-1"
  store._data = {"version": 5, "keep": "original"}
  var emitted: Array = []
  store.initialized.connect(func(state, code): emitted.append([state, code]))
  var reply = {"status": "blocked", "code": "OPEN_FAILED", "wire": {"schema": "youjia.save-error/v1", "code": "OPEN_FAILED", "cause": "Error: writer_owned_by_another_page"}}
  var method := "open"
  var call_id := "open-1"
  var expected := "OPEN_FAILED"
  match scenario:
   "exact": expected = "SAVE_WRITER_OWNED"
   "other-cause": reply.wire.cause = "Error: database_corrupt"
   "substring": reply.wire.cause += " extra"
   "wrong-code": reply.code = "HOST_ERROR"; expected = "HOST_ERROR"
   "wire-code": reply.wire.code = "HOST_ERROR"
   "schema": reply.wire.schema = "youjia.save-error/v2"
   "extra": reply.wire.extra = true
   "initialize": method = "initialize"
   "wrong-status": reply.status = "unknown"
   "stale-id": call_id = "old-open"
  store._on_boot_reply(call_id, method, reply)
  if scenario == "stale-id":
   check(emitted.is_empty() and store._boot_call_id == "open-1", "stale response ignored")
  else:
   check(emitted == [["blocked", expected]] and not store.can_play(), "exact boot classification: " + scenario)
  check(store._data == {"version": 5, "keep": "original"} and store._coordinator == null, "never start or replace save: " + scenario)
  store.free()
 print("SAVE WRITER GUIDANCE %d checks failures=%s" % [checks, failures])
 quit(0 if failures.is_empty() else 1)
