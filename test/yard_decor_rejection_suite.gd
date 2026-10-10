extends SceneTree
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok: failures.append(label)
func capture(label:String, main:Node) -> void:
 var folder=OS.get_environment("YOUJIA_CAPTURE_DIR")
 if folder.is_empty(): return
 DirAccess.make_dir_recursive_absolute(folder)
 main._process(0.0)
 for i in 6: await process_frame
 await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_jpg(folder.path_join(label+".jpg"),0.88)==OK)
func run() -> void:
 var isolated=OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
 if isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated):
  quit(2)
  return
 var store=root.get_node("SaveStore")
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 for i in 3: await process_frame
 await main._start_holiday()
 main.set_process(false)
 var id=ExplorationRoutes.FIND_PINE_CONE
 store.request_exploration_trip(null,1,PackedStringArray([id,ExplorationRoutes.FIND_STONE]),{})
 check(await store.flush_pending(),"real trip flush")
 main._show_basket()
 var details={"find_id":id,"dx":0,"dy":0}
 var revision=int(store.get_yard_decor().revision)
 # Another valid FIFO intent wins after the basket selected this revision.
 check(not store.request_decor_action(revision,"place","house_edge",{"find_id":ExplorationRoutes.FIND_STONE,"dx":0,"dy":0}).is_empty(),"competing placement queued")
 main._place_from_basket(id,"fence_edge")
 check(main._decor.busy(),"own intent waits behind competitor")
 check(await store.flush_pending(),"FIFO drains after terminal domain refusal")
 for i in 3: await process_frame
 check(main._decor.state=="blocked" and main._decor.error=="DECOR_CHANGED","real stale revision classified")
 check(not main._decor.busy() and main._decor.pending.is_empty(),"terminal refusal releases controller")
 check(main._basket_drop.is_empty(),"basket releases refused selection")
 check(not main._save_problem_active and main._save_problems.is_empty(),"domain refusal is not a phantom disk failure")
 check(store.get_yard_decor().places.size()==1 and store.get_keepsakes()[id]==1,"winning placement retains exactly one item")
 check(store.get_available_keepsakes()[id]==1,"refused pine cone stays available")
 await capture("stale-selection-released",main)
 main._place_from_basket(id,"house_edge")
 check(await store.flush_pending(),"FIFO drains after occupied spot refusal")
 for i in 3: await process_frame
 check(main._decor.error=="DECOR_OCCUPIED" and not main._decor.busy(),"occupied selection can be changed")
 main._on_decor_recall("house_edge")
 check(await store.flush_pending(),"recall works without reload after refusal")
 check(store.get_available_keepsakes()[id]==1 and store.get_yard_decor().places.is_empty(),"recall returns single owned find")
 main._place_from_basket(id,"fence_edge")
 check(await store.flush_pending(),"new selection can save at current revision")
 check(main._decor.state=="idle" and not main._decor.busy(),"new request completes normally")
 check(store.get_yard_decor().places.get("fence_edge",{}).get("find_id","")==id,"new place is durable")
 store._load()
 check(store.get_yard_decor().places.size()==1 and store.get_available_keepsakes()[id]==0,"reopen preserves exactly one reservation")
 check(not main._save_problem_active,"new actions never require global phantom retry")
 await capture("replaced-without-reload",main)
 main._hide_basket()
 main.queue_free()
 await process_frame
 root.get_node("AudioDirector").release_streams()
 print("YARD_DECOR_REJECTION checks=%d failures=%d" % [checks,failures.size()])
 for failure in failures: push_error(failure)
 quit(0 if failures.is_empty() else 1)
