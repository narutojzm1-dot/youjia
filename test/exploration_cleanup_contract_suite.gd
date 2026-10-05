extends SceneTree
const Store = preload("res://autoload/save_store.gd")
const Backend = preload("res://test/save_coordinator_suite.gd").Backend
const Native = preload("res://scripts/persistence/native_save_host.gd")
const Codec = preload("res://scripts/persistence/save_data_codec.gd")
class TestStore extends "res://autoload/save_store.gd":
 func _ready(): pass # explicit backend fixture, no player profile boot
var checks := 0
var failures: Array[String] = []
var stores: Array = []
var refused: Array = []
var confirmed: Array = []
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
 checks += 1
 if not ok: failures.append(label); push_error(label)
func fixture() -> Dictionary:
 var session := ExplorationSession.new(ExplorationRoutes.catalog(), 0)
 session.begin(ExplorationRoutes.NEAR_PATH, {"day": 1, "elapsed": 0.0}, 7)
 session.request_return("player")
 var expected = session.to_record()
 session.commit_succeeded("trip-1")
 session.close()
 var snapshot = Codec.defaults()
 snapshot.exploration = expected.duplicate(true)
 snapshot.exploration_committed_serial = 1
 snapshot.keepsakes = {"formal.find.feather": 1}
 return {"expected": expected, "target": session.to_record(), "snapshot": snapshot}
func pair(snapshot: Dictionary, backend = null):
 var store = TestStore.new()
 root.add_child(store)
 var b = backend if backend != null else Backend.new()
 if backend == null: b.sync = true
 store._backend = b
 store._boot_state = "ready"
 store._data = snapshot.duplicate(true)
 var token = b.get_initial_token() if backend != null else "trusted-root"
 var ns = Native.NAMESPACE if backend != null else b.backend_namespace
 check(store._connect_coordinator(snapshot, token, ns), "coordinator initializes")
 store.commit_rejected.connect(func(id, kind, code): refused.append([id, kind, code]))
 store.commit_confirmed.connect(func(id, kind): confirmed.append([id, kind]))
 stores.append(store)
 return [store, b]
func run():
 var f = fixture()
 var p = pair(f.snapshot); var store = p[0]; var b = p[1]
 var expected = f.expected.duplicate(true); var target = f.target.duplicate(true)
 var op = store.request_exploration_cleanup(expected, 1, target, "cleanup:trip-1")
 check(not op.is_empty() and confirmed.is_empty(), "acceptance is not confirmation")
 expected.session.trip_id = "trip-999"
 target.next_trip_serial = 999
 check(await store.flush_pending(), "frozen cleanup confirms and acks")
 check(store.get_exploration_record() == f.target, "frozen target actually stored")
 check(store.get_keepsakes() == f.snapshot.keepsakes, "cleanup never grants again")
 check(confirmed.back() == [op, "exploration_cleanup"], "success reports exact op kind")
 # Exact CAS: already-cleaned is not a synthetic noop confirmation.
 var writes: int = b.calls.size(); var confirmations: int = confirmed.size()
 store.request_exploration_cleanup(f.expected, 1, f.target, "retry-old")
 await store.flush_pending()
 check(b.calls.size() == writes and confirmed.size() == confirmations, "CAS mismatch never prepares or confirms noop")
 check(refused.back()[2] == "EXPLORATION_CLEANUP_PRECONDITION_CHANGED", "CAS mismatch explicit reason")
 # FIFO: a new trip accepted first must survive old cleanup accepted second.
 p = pair(f.snapshot); store = p[0]; b = p[1]
 var next_session := ExplorationSession.new(ExplorationRoutes.catalog(), 1)
 next_session.begin(ExplorationRoutes.NEAR_PATH, {"day": 1, "elapsed": 5.0}, 9)
 var next = next_session.to_record()
 store.request_exploration_record(next)
 store.request_exploration_cleanup(f.expected, 1, f.target, "old-queued")
 await store.flush_pending()
 check(store.get_exploration_record() == next and b.calls.size() == 3, "queued new trip survives old cleanup without extra prepare")
 # Other domains ahead of cleanup are preserved from current head, not frozen snapshot.
 p = pair(f.snapshot); store = p[0]
 store.request_patch("yard", {"holiday_day": 8, "album": ["kept-photo"], "photo_moments": {"kept-photo": {"marker": 1}}})
 store.request_exploration_cleanup(f.expected, 1, f.target, "cleanup-after-yard")
 await store.flush_pending()
 check(store._data.holiday_day == 8 and store._data.album == ["kept-photo"] and store._data.photo_moments.has("kept-photo"), "head composition preserves unrelated yard/photo fields")
 # Optional null children in an active record cannot crash pre-validation.
 var active = next_session.to_record()
 active.session.erase("proposal"); active.session.erase("failure")
 p = pair(f.snapshot); store = p[0]; b = p[1]
 store.request_exploration_cleanup(active, 1, f.target, "active-optional")
 await store.flush_pending()
 check(refused.back()[2] == "EXPLORATION_CLEANUP_INVALID_ARGUMENT" and b.calls.is_empty(), "missing optional null children reject active record without script error")
 for field in ["proposal", "failure", "started_clock", "visited", "offers", "carried", "taken"]:
  var malformed = f.expected.duplicate(true)
  malformed.session[field] = 7
  p = pair(f.snapshot); store = p[0]; b = p[1]
  store.request_exploration_cleanup(malformed, 1, f.target, "bad-child")
  await store.flush_pending()
  check(refused.back()[2] == "EXPLORATION_CLEANUP_INVALID_ARGUMENT" and b.calls.is_empty(), "wrong child type rejected without error: " + field)
 for field in ["proposal", "failure"]:
  var omitted = f.expected.duplicate(true)
  omitted.session.erase(field)
  p = pair(f.snapshot); store = p[0]; b = p[1]
  store.request_exploration_cleanup(omitted, 1, f.target, "missing-child")
  await store.flush_pending()
  check(refused.back()[2] == "EXPLORATION_CLEANUP_INVALID_ARGUMENT" and b.calls.is_empty(), "omitted nullable child conservatively rejected: " + field)
 var no_taken = f.expected.duplicate(true)
 no_taken.session.erase("taken")
 var no_taken_snapshot = f.snapshot.duplicate(true); no_taken_snapshot.exploration = no_taken
 p = pair(no_taken_snapshot); store = p[0]
 store.request_exploration_cleanup(no_taken, 1, f.target, "legacy-no-taken")
 check(await store.flush_pending() and store.get_exploration_record() == f.target, "supported optional legacy taken omission cleans safely")
 # Validation failures all carry accepted identity and never touch backend.
 for label in ["future", "extension", "session-extension", "fixture", "ahead", "wrong-target", "active-target", "bad-watermark", "wrong-next", "empty-id"]:
  var e = f.expected.duplicate(true); var t = f.target.duplicate(true); var w: Variant = 1; var id := "cleanup"
  match label:
   "future": e.contract_version = 2
   "extension": e.unknown = "preserve"
   "session-extension": e.session.unknown = "preserve"
   "fixture": e.session.catalog = "fixture"
   "ahead": w = 0
   "wrong-target": t.next_trip_serial = 99
   "active-target": t.session = e.session.duplicate(true)
   "bad-watermark": w = "1"
   "wrong-next": e.next_trip_serial = 1
   "empty-id": id = ""
  p = pair(f.snapshot); store = p[0]; b = p[1]
  var bad = store.request_exploration_cleanup(e, w, t, id)
  await store.flush_pending()
  check(not bad.is_empty() and refused.back() == [bad, "exploration_cleanup", "EXPLORATION_CLEANUP_INVALID_ARGUMENT"] and b.calls.is_empty(), "reject before prepare: " + label)
  check(store._data == f.snapshot, "original preserved: " + label)
 # Future-format source is itself the authoritative snapshot, never normalized away.
 var future = f.snapshot.duplicate(true)
 future.exploration.contract_version = 99
 future.exploration.future_private_field = {"keep": "raw"}
 p = pair(future); store = p[0]; b = p[1]
 store.request_exploration_cleanup(store.get_exploration_record(), 1, f.target, "future-source")
 await store.flush_pending()
 check(store._data == future and b.calls.is_empty() and refused.back()[2] == "EXPLORATION_CLEANUP_INVALID_ARGUMENT", "authoritative future source preserved without prepare")
 # A later watermark change fails at head even if input was originally valid.
 p = pair(f.snapshot); store = p[0]; b = p[1]
 store.request_patch("watermark-test", {"exploration_committed_serial": 2})
 store.request_exploration_cleanup(f.expected, 1, f.target, "stale-watermark")
 await store.flush_pending()
 check(store.get_exploration_record() == f.expected and b.calls.size() == 3 and refused.back()[2] == "EXPLORATION_CLEANUP_PRECONDITION_CHANGED", "watermark checked at queue head")
 # Existing malformed ordinary builders keep their established rejection.
 p = pair(f.snapshot); store = p[0]; b = p[1]
 var invalid = store.request_intent("ordinary", func(_current): return {"version": 4})
 await store.flush_pending()
 check(refused.back() == [invalid, "ordinary", "INVALID_LOCAL_CANDIDATE"] and b.calls.is_empty(), "ordinary invalid builder unchanged")
 # Unknown submit and failed acknowledgement retain existing recovery identities.
 p = pair(f.snapshot); store = p[0]; b = p[1]; b.sync = false
 var uncertain = store.request_exploration_cleanup(f.expected, 1, f.target, "uncertain")
 await process_frame
 b.prepare_ok(); b.send("unknown")
 check(store.persistence_state() == "unknown" and store.get_exploration_record() == f.expected, "unknown cleanup does not publish target")
 store.retry_pending(); b.receipt("confirmed")
 check(confirmed.back() == [uncertain, "exploration_cleanup"] and b.calls.back().method == "acknowledge", "resolve confirms same cleanup identity")
 b.send("unknown")
 check(not store.is_save_idle(), "ack failure remains blocked")
 store.retry_pending(); b.ack()
 check(store.is_save_idle(), "ack retry drains original cleanup without new grant")
 # Real native file write/readback and immutable original on refused stale replay.
 var base := "user://cleanup-contract-" + str(Time.get_ticks_usec())
 var file := FileAccess.open(base + ".json", FileAccess.WRITE)
 file.store_string(JSON.stringify(f.snapshot)); file.close()
 var native = Native.new(base + ".json", base + ".tmp", base + ".bak")
 p = pair(native.get_initial_snapshot(), native); store = p[0]
 var native_expected = store.get_exploration_record()
 store.request_exploration_cleanup(native_expected, 1, f.target, "native-cleanup")
 check(await store.flush_pending(), "real native durable cleanup")
 var bytes = FileAccess.get_file_as_bytes(base + ".json")
 var saved = JSON.parse_string(bytes.get_string_from_utf8())
 check(saved.exploration.session == null and int(saved.exploration.next_trip_serial) == 2 and int(saved.keepsakes["formal.find.feather"]) == 1, "actual file idle and grants unchanged")
 store.request_exploration_cleanup(f.expected, 1, f.target, "stale-native")
 await store.flush_pending()
 check(FileAccess.get_file_as_bytes(base + ".json") == bytes, "stale native rejection preserves exact file bytes")
 # Authoritative files contain each unknown nested extension. Cleanup must not
 # normalize them through restore, prepare, or rewrite even identical-looking data.
 for location in ["clock", "proposal", "item", "failure"]:
  var nested = f.snapshot.duplicate(true)
  match location:
   "clock": nested.exploration.session.started_clock.future_payload = {"keep": "raw"}
   "proposal": nested.exploration.session.proposal.future_payload = {"keep": "raw"}
   "item": nested.exploration.session.proposal.items = [{"find_id": "formal.find.feather", "future_payload": {"keep": "raw"}}]
   "failure": nested.exploration.session.failure = {"code": "save_failed", "retryable": true, "attempts": 1, "deferred": false, "future_payload": {"keep": "raw"}}
  check(ExplorationContract.validate_session_structure(nested.exploration.session) == "", "legacy shape checker allows extension: " + location)
  var path: String = "user://cleanup-nested-" + location + "-" + str(Time.get_ticks_usec())
  var writer := FileAccess.open(path + ".json", FileAccess.WRITE)
  writer.store_string(JSON.stringify(nested)); writer.close()
  var real = Native.new(path + ".json", path + ".tmp", path + ".bak")
  p = pair(real.get_initial_snapshot(), real); store = p[0]
  var original = FileAccess.get_file_as_bytes(path + ".json")
  var call_count: int = real._calls
  var cleanup = store.request_exploration_cleanup(store.get_exploration_record(), 1, f.target, "nested-" + location)
  await store.flush_pending()
  check(refused.back() == [cleanup, "exploration_cleanup", "EXPLORATION_CLEANUP_INVALID_ARGUMENT"] and real._calls == call_count, "nested extension refused before real backend prepare: " + location)
  check(FileAccess.get_file_as_bytes(path + ".json") == original, "authoritative original bytes preserved: " + location)
 for s in stores: s.free()
 print("EXPLORATION CLEANUP ", checks, " checks failures=", failures)
 quit(0 if failures.is_empty() else 1)
