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
 main.queue_free()
 await process_frame
 print("SAVE FEEDBACK ", checks, " checks, failures ", failures)
 quit(1 if failures else 0)
