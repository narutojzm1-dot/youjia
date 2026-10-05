extends SceneTree
var failures:Array=[]
var notices:Array=[]
var checks:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label);push_error(label)
func run():
 var main=load("res://scenes/main.tscn").instantiate();root.add_child(main)
 await process_frame;await process_frame
 main.set_process(false);await main._start_holiday()
 var w=main._world
 w.notice_requested.connect(func(key):notices.append(key))
 w.request_pointer_action(Vector2(865,478))
 check(not w._has_walk_goal,"rail click cannot start movement")
 check(w._rejected_point==Vector2(865,478) and w._rejected_seconds>0,"feedback identifies exact rejected point")
 check(notices.back()=="notice.cannot_walk","boundary explanation accompanies point feedback")
 for i in 80:w.tick(1.0/60,Vector2.ZERO)
 check(w._rejected_seconds==0,"feedback fades without extra input")
 w.request_pointer_action(Vector2(865,478))
 w.request_pointer_action(Vector2(320,550))
 check(w._has_walk_goal and w._rejected_seconds==0,"new safe click replaces rejection immediately")
 check(not main._notice.visible,"safe destination clears obsolete rejection text")
 main._show_notice_key("notice.fed_llama")
 w.request_pointer_action(Vector2(320,550))
 check(main._notice.visible and main._notice_key=="notice.fed_llama","new walking request preserves unrelated event notice")
 w.request_pointer_action(Vector2(865,478))
 w.tick(1.0/60,Vector2.RIGHT)
 check(not main._notice.visible and w._rejected_seconds==0,"keyboard movement clears obsolete rejection")
 w.debug_place_player(Vector2(300,540))
 var before:int=notices.size()
 w.request_pointer_action(Vector2(300,540))
 check(not w._has_walk_goal and w._rejected_seconds==0,"tap own feet calmly stops pending movement")
 check(notices.size()==before,"tap own feet does not falsely warn unreachable")
 w.request_pointer_action(Vector2(865,478))
 w.input_enabled=false
 w.request_pointer_action(Vector2(300,540))
 check(w._rejected_point==Vector2(865,478),"disabled input cannot mutate rejection")
 print("[boundary-feedback-tests] ",checks," checks ",failures)
 quit(0 if failures.is_empty() else 1)
