extends SceneTree
var main
var checks := 0
var failures := 0
var intermediate_ready := false
func _initialize():
 call_deferred("run")
func check(value: bool, label: String):
 checks += 1
 if not value:
  failures += 1
  print("FAIL ", label)
func ready():
 main._on_save_state_changed("ready")
func run():
 main = load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 await process_frame
 await root.get_node("SaveStore").flush_pending()
 main._on_save_problem("1", "yard", "UNKNOWN")
 main._on_save_confirmed("other", "yard")
 ready()
 check(main._save_problem_active, "unrelated confirmed cannot hide")
 main._on_save_confirmed("1", "wrong-kind")
 ready()
 check(main._save_problem_active, "wrong kind cannot hide")
 main._show_save_pending(false) # transition waits without inventing an unqueued intent
 main._on_save_confirmed("1", "yard")
 check(main._save_problem_active, "confirmed before ack stays visible")
 ready()
 check(not main._save_problem_active, "specific confirmed then idle clears")
 main._on_save_problem("2", "yard", "UNKNOWN")
 ready() # coordinator emits ready before rejected
 check(main._save_problem_active, "ready before rejection stays")
 main._on_save_rejected("2", "yard", "RESOLVED_PARENT")
 main._save_retry_coverage["tail"] = {"problems": main._save_problems.duplicate(true), "untracked_revision": main._save_untracked_revision}
 main._on_save_problem("3", "relationships", "NEW_FAILURE")
 main._on_save_confirmed("tail", "album")
 ready()
 check(main._save_problem_active and main._save_problems.has("3"), "retry tail cannot erase newer domain failure")
 main._on_save_confirmed("3", "relationships")
 main._pending_photo_saves["photo"] = {"fresh": false, "latest_id": ""}
 ready()
 check(main._save_problem_active, "pending photo still blocks")
 main._on_save_confirmed("photo", "album")
 ready()
 check(not main._save_problem_active, "final photo plus idle clears")
 main._on_save_confirmed("4", "yard")
 main._on_save_problem("4", "", "ACK_FAILED")
 check(main._save_problems["4"].durable, "empty ack kind keeps exact durable op")
 main._save_ack_coverage = main._save_problems.duplicate(true)
 main._on_save_problem("4", "", "ACK_FAILED_AGAIN")
 ready()
 check(main._save_problem_active, "new revision of same ack not erased")
 main._save_ack_coverage = main._save_problems.duplicate(true)
 ready()
 check(not main._save_problem_active, "matching ack coverage plus idle clears")
 main._show_save_pending()
 main._on_save_confirmed("unrelated", "yard")
 ready()
 check(main._save_problem_active, "untracked failed intent not cleared by unrelated write")
 main._save_untracked_problem = false
 main._on_save_problem("yard-unknown", "yard", "UNKNOWN")
 main._show_save_pending() # photo enqueue refused while the coordinator is unknown
 main._on_save_confirmed("yard-unknown", "yard")
 ready()
 check(main._save_problem_active and main._save_untracked_problem, "unqueued photo survives unrelated unknown recovery")
 main._save_retry_coverage["full-tail"] = {"problems": main._save_problems.duplicate(true), "untracked_revision": main._save_untracked_revision}
 main._show_save_pending() # still later unqueued intent
 main._on_save_confirmed("full-tail", "album")
 ready()
 check(main._save_problem_active, "later unqueued revision survives earlier retry tail")
 main._save_retry_coverage["final-tail"] = {"problems": main._save_problems.duplicate(true), "untracked_revision": main._save_untracked_revision}
 main._on_save_confirmed("final-tail", "album")
 ready()
 check(not main._save_problem_active, "matching full retry clears unqueued source")
 main._on_save_rejected("explore", "exploration_trip", "REJECTED")
 main._on_save_rejected("other", "unknown-owner", "REJECTED")
 main._on_save_rejected("yard", "yard", "REJECTED")
 var covered: Dictionary = main._retryable_save_problems(false)
 check(covered.has("yard") and not covered.has("explore") and not covered.has("other"), "retry only covers domains it actually resubmits")
 main._clear_covered_save_problems(covered)
 check(main._save_problems.has("explore") and main._save_problems.has("other"), "unresent domains remain unresolved")
 main._save_problems.clear() # isolate next actual backend sequence
 main._save_untracked_problem = false
 var store = root.get_node("SaveStore")
 var id: String = store.request_patch("feedback_first", {"feedback_test": 1})
 store.request_patch("feedback_second", {"feedback_test": 2})
 main._on_save_problem(id, "feedback_first", "TEST_UNKNOWN")
 store.persistence_state_changed.connect(func(state: String):
  if state == "ready" and not store.is_save_idle():
   intermediate_ready = true
   check(main._save_problem_active, "actual queued ready cannot clear before full idle"))
 check(await store.flush_pending(), "actual native queue flush succeeds")
 check(intermediate_ready, "actual native two-intent ready window observed")
 check(not main._save_problem_active, "actual native queue clears at final idle")
 # Real SaveStore acceptance identities, actual native durable callbacks, UI completion.
 var record := {"contract_version": 1, "next_trip_serial": 2, "session": {"trip_id": "trip-1", "trip_serial": 1, "record_revision": 4}}
 var old: String = store.request_exploration_trip(record, 1, PackedStringArray(["formal.find.brook_stone"]), {})
 # Find catalog key below is validated by production Store, no bypass.
 check(not old.is_empty(), "real exploration trip accepted")
 if not old.is_empty():
  main._on_save_rejected(old, "exploration_trip", "TEST_REJECTED")
  var failed: Dictionary = main._save_problems[old].duplicate(true)
  var wrong: String = store.request_exploration_record(record)
  await store.flush_pending()
  # The original actual queued op confirms too: recreate its captured terminal failure
  # to test later retry acceptance independently of that synthetic rejection.
  main._save_problems[old] = failed
  main._show_save_pending(false)
  store.request_exploration_record(record)
  await store.flush_pending()
  check(main._save_problems.has(old), "record cannot cover failed trip grant")
  var other := record.duplicate(true)
  other.session.trip_id = "trip-2"
  other.session.trip_serial = 2
  store.request_exploration_trip(other, 2, PackedStringArray(["formal.find.brook_stone"]), {})
  await store.flush_pending()
  check(main._save_problems.has(old), "different trip confirmation cannot cover")
  store.request_exploration_trip(record, 1, PackedStringArray(["formal.find.feather"]), {})
  await store.flush_pending()
  check(main._save_problems.has(old), "same trip different grant cannot cover")
  var stale := record.duplicate(true)
  stale.session.record_revision = 3
  store.request_exploration_trip(stale, 1, PackedStringArray(["formal.find.brook_stone"]), {})
  await store.flush_pending()
  check(main._save_problems.has(old), "older trip revision cannot cover")
  var retry: String = store.request_exploration_trip(record, 1, PackedStringArray(["formal.find.brook_stone"]), {})
  main._show_save_pending() # distinct unqueued photo survives exact retry
  await store.flush_pending()
  check(not main._save_problems.has(old) and main._save_problem_active, "same trip real confirm covers old but not unqueued photo")
  main._save_untracked_problem = false
  main._save_problems[old] = failed
  main._show_save_pending(false)
  store.request_exploration_trip(record, 1, PackedStringArray(["formal.find.brook_stone"]), {})
  main._on_save_problem(old, "exploration_trip", "LATER_FAILURE")
  await store.flush_pending()
  check(main._save_problems.has(old), "later failure revision survives accepted coverage")
  main._save_problems[old] = failed
  store.request_exploration_trip(record, 1, PackedStringArray(["formal.find.brook_stone"]), {})
  await store.flush_pending()
  check(not main._save_problem_active, "matching retry confirmed ack idle clears")
  check(main._save_exploration_scopes.is_empty() and main._save_exploration_coverage.is_empty(), "accepted identity maps cleaned after terminal callbacks")
 # Real SaveStore + Coordinator signal ordering with a controlled backend contract.
 # This is not claimed as physical disk failure; Web evidence exercises IDB.
 var backend = preload("res://test/save_coordinator_suite.gd").Backend.new()
 store._backend = backend
 check(store._connect_coordinator(store._data, "test-root", backend.backend_namespace), "controlled coordinator ready")
 var failed_op: String = store.request_exploration_trip(record, 1, PackedStringArray(["formal.find.brook_stone"]), {})
 await process_frame
 backend.prepare_ok()
 backend.send("unknown")
 check(main._save_problems.has(failed_op), "real unknown callback records accepted trip identity")
 check(store.retry_pending(), "real retry starts resolution")
 backend.receipt("rejected")
 check(main._save_problems.has(failed_op), "real ready-before-rejected preserves failed op")
 var retry_op: String = store.request_exploration_trip(record, 1, PackedStringArray(["formal.find.brook_stone"]), {})
 check(retry_op != failed_op and main._save_exploration_coverage[retry_op].problems.has(failed_op), "new accepted op captures exact old failure")
 await process_frame
 backend.prepare_ok()
 backend.send("unknown")
 check(main._save_problem_active, "retry unknown keeps panel")
 store.retry_pending()
 backend.receipt("confirmed")
 check(main._save_problem_active, "new op confirmed still waits actual ack")
 backend.send("unknown") # real Coordinator ack_failed; SaveStore kind already erased
 check(main._save_problem_active and main._save_problems[retry_op].durable and main._save_problems[retry_op].kind == "", "new durable empty-kind ack failure remains visible")
 main._retry_save()
 check(backend.calls.back().method == "acknowledge", "retry ack uses same confirmed identity")
 backend.ack()
 check(not main._save_problem_active, "real rejected then new op confirmed ack idle clears")
 # Cloud's actual ordering: record and trip accepted BEFORE the record fails.
 var queued_record: String = store.request_exploration_record(record)
 var queued_trip: String = store.request_exploration_trip(record, 1, PackedStringArray(["formal.find.brook_stone"]), {})
 await process_frame
 backend.prepare_ok()
 backend.send("unknown")
 check(main._save_exploration_coverage[queued_trip].problems.is_empty(), "unknown does not retroactively cover queued intent")
 store.retry_pending()
 backend.receipt("rejected")
 check(main._save_exploration_coverage[queued_trip].problems.has(queued_record), "terminal record rejection binds exact revision to later queued trip")
 await process_frame
 backend.prepare_ok()
 backend.receipt("confirmed")
 check(main._save_problem_active, "queued trip still waits ack")
 backend.ack()
 check(not main._save_problem_active, "Cloud prequeued trip clears rejected return record at idle")
 var earlier: String = store.request_exploration_record(record)
 var later: String = store.request_exploration_record(record)
 check(not main._exploration_save_covers(main._save_exploration_scopes[earlier], {"kind": "exploration", "scope": main._save_exploration_scopes[later]}), "earlier accepted op cannot cover later record")
 await process_frame
 backend.prepare_ok()
 backend.send("unknown")
 store.retry_pending()
 backend.receipt("rejected")
 check(main._save_exploration_coverage[later].problems.has(earlier), "queued successor bound after rejection")
 main._on_save_problem(earlier, "exploration", "LATE_UNKNOWN")
 await process_frame
 backend.prepare_ok()
 backend.receipt("confirmed")
 backend.ack()
 check(main._save_problem_active and main._save_problems.has(earlier), "late failure after terminal binding cannot be erased by queued confirmation")
 main.queue_free()
 await process_frame
 print("SAVE FEEDBACK ", checks, " checks, failures ", failures)
 quit(1 if failures else 0)
