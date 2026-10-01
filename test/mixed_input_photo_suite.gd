extends SceneTree
var checks:=0
var failures:Array=[]
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label);push_error(label)
func run():
 var main=load("res://scenes/main.tscn").instantiate();root.add_child(main)
 await process_frame;await process_frame
 main.set_process(false);main._start_holiday()
 var w=main._world
 w.debug_place_player(Vector2(600,540));w.debug_place_actor("llama",Vector2(680,540));w._player.pick_grass()
 w.request_pointer_action(Vector2(680,540))
 check(w._pending_interaction=="llama","pointer approach pending before keyboard action")
 var e:=InputEventKey.new();e.device=0;e.physical_keycode=KEY_SPACE;e.keycode=KEY_SPACE;e.pressed=true;Input.parse_input_event(e)
 e=InputEventKey.new();e.device=0;e.physical_keycode=KEY_SPACE;e.keycode=KEY_SPACE;e.pressed=false;Input.parse_input_event(e)
 await process_frame
 check(not w._player.carrying_grass,"ordinary Space feeds during approach")
 check(w._pending_interaction.is_empty() and not w._has_walk_goal,"successful contextual feed consumes old approach intent")
 for i in 180:w.tick(1.0/60,Vector2.ZERO)
 check(not w._leading,"feeding is not followed by unintended automatic leading")
 # Keep the old rope on the left, then trigger an event that flips the llama right.
 w.photo_moments.erase("llama_overcast_goose_annoyed")
 w.debug_place_player(Vector2(590,525));w.debug_place_actor("llama",Vector2(650,510));w.debug_place_actor("goose",Vector2(725,510))
 var llama=w.actor_named("llama")
 llama.spit(Vector2(550,480));w._leading=true;w._update_lead_rope()
 var old_end:Vector2=w._lead_rope.points[-1]
 w.debug_force_rule("llama_overcast_goose_annoyed")
 var collar:Vector2=w.to_local(llama.to_global(Vector2(875,665)-llama._ground_anchor))
 check(old_end.distance_to(collar)>30,"event fixture actually changes facing and rope attachment")
 var moment:Dictionary=w.photo_moments.get("llama_overcast_goose_annoyed",{})
 var saved_end:=Vector2.INF
 for item:Dictionary in moment.get("items",[]):
  if item.kind=="line":saved_end=Vector2(item.points[-1][0],item.points[-1][1])
 check(saved_end.distance_to(collar)<0.01,"stored event photo rope attaches to post-reaction collar")
 print("[mixed-input-photo-tests] ",checks," checks ",failures)
 quit(0 if failures.is_empty() else 1)
