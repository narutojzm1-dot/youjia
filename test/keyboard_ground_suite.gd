extends SceneTree
var main: Control
var checks:=0
var failures:Array=[]
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok: failures.append(label);push_error(label)
func key(code:int,down:bool,echo:bool=false,logical_only:bool=false):
 var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=0 if logical_only else code;e.device=0;e.pressed=down;e.echo=echo;Input.parse_input_event(e)
func frames(count:int):
 for i in count:
  main._process(1.0/60)
  await process_frame
func run():
 root.size=Vector2i(1280,720);seed(817)
 main=load("res://scenes/main.tscn").instantiate();root.add_child(main);await process_frame;await process_frame
 main.set_process(false);main._start_holiday();await frames(3)
 var w=main._world;var p=w._player
 for code in [KEY_A,KEY_D,KEY_W,KEY_S,KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:
  var start:Vector2=p.position
  var logical_only:bool=code in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]
  key(code,true,false,logical_only);await frames(24);key(code,false,false,logical_only);await frames(30)
  check(p.position.distance_to(start)>3,"ordinary device0 key moves player: %s"%code)
  check(p._velocity.length()<0.5,"released key settles: %s"%code)
 check(main._pause_button.focus_mode==Control.FOCUS_NONE,"HUD never steals gameplay keyboard focus")
 main._weather_chip.pressed.emit()
 key(KEY_ESCAPE,true);key(KEY_ESCAPE,false);await frames(1)
 check(paused and main._pause_screen.visible,"Esc pauses after HUD focus")
 var frozen:Vector2=p.position;await frames(20)
 check(p.position.distance_to(frozen)<0.001,"paused player stays still")
 key(KEY_ESCAPE,true,true);await frames(1)
 check(paused,"echoed Esc does not resume")
 key(KEY_ESCAPE,false);key(KEY_ESCAPE,true);key(KEY_ESCAPE,false);await frames(1)
 check(not paused and not main._pause_screen.visible,"Esc resumes")
 main._album_chip.pressed.emit();await frames(1)
 key(KEY_ESCAPE,true);key(KEY_ESCAPE,false);await frames(1)
 check(not main._album_screen.visible and w.input_enabled,"Esc closes album")
 main._pause_button.pressed.emit();main._restart_button.pressed.emit();await frames(1)
 check(main._confirm_screen.visible,"restart confirmation fixture opens")
 key(KEY_ESCAPE,true);key(KEY_ESCAPE,false);await frames(1)
 check(not main._confirm_screen.visible and main._pause_screen.visible and main._world==w,"Esc cancels restart without resetting")
 key(KEY_ESCAPE,true);key(KEY_ESCAPE,false);await frames(1)
 check(not paused,"Esc exits remaining pause")
 for point in [Vector2(810,430),Vector2(850,455),Vector2(895,480),Vector2(865,478),Vector2(758,442)]:
  check(not YardGround.allows(point,YardGround.lawn(),true),"painted rail is not walkable %s"%point)
  w.request_pointer_action(point)
  check(not w._has_walk_goal,"rail tap never starts a walk %s"%point)
 for point in [Vector2(740,480),Vector2(790,510),Vector2(840,535),Vector2(850,540)]:
  check(YardGround.allows(point,YardGround.lawn(),true),"foreground grass remains reachable %s"%point)
 w.request_pointer_action(w.actor_named("llama").position)
 for i in 2400:
  await frames(1)
  if w._leading:break
 check(w._leading,"normal approach starts lead")
 check(w._lead_rope.visible and w._lead_rope.points.size()==17,"held rope is rendered")
 check(w._lead_rope.z_index>maxi(p.z_index,w.actor_named("llama").z_index),"rope stays visible above wearers")
 check(w.to_global(w._lead_rope.points[0]).distance_to(p.grass_hand_global_position())<0.01,"rope starts at actual hand")
 key(KEY_LEFT,true,false,true);await frames(4);key(KEY_LEFT,false,false,true);await frames(4)
 check(not main._album_chip.has_focus(),"arrow movement cannot focus album HUD")
 key(KEY_SPACE,true);key(KEY_SPACE,false);await frames(1)
 check(not w._leading and not main._album_screen.visible,"Space has exactly one gameplay action after arrow input")
 root.get_node("AudioDirector").call("release_streams")
 print("[keyboard-ground-tests] ","PASS" if failures.is_empty() else "FAIL",": ",checks," checks ",failures)
 quit(0 if failures.is_empty() else 1)
