extends SceneTree
# Real viewport input dispatch from the unmodified initial spawn.
# Simulation steps are accelerated for assertions; this is not a browser timing test.
var main:Control
var failures=[]
func _initialize(): call_deferred("review")
func check(ok,label):
 print("AUDIT ","PASS " if ok else "FAIL ",label)
 if not ok: failures.append(label)
func mouse(p):
 for down in [true,false]:
  var e=InputEventMouseButton.new();e.position=p;e.global_position=p;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;root.push_input(e,true)
func tap(p):
 for down in [true,false]:
  var e=InputEventScreenTouch.new();e.position=root.get_canvas_transform()*p;e.pressed=down;e.index=0;root.push_input(e,true)
func touch_button(name):
 var b=main.get(name)
 for down in [true,false]:
  var e=InputEventScreenTouch.new();e.position=b.get_global_transform_with_canvas()*(b.size*0.5);e.pressed=down;e.index=0;root.push_input(e,true)
func button(name):
 var b=main.get(name);mouse(b.get_global_transform_with_canvas()*(b.size*0.5))
func frames(count):
 for i in count:
  main._process(1.0/60)
  await process_frame
func review():
 seed(129)
 root.size=Vector2i(1280,720)
 main=load("res://scenes/main.tscn").instantiate();root.add_child(main)
 await process_frame;await process_frame
 main.set_process(false)
 touch_button("_play_button")
 await frames(2)
 check(main._screen=="game","title button dispatch starts game")
 var w=main._world;var p=w._player
 await create_timer(0.5).timeout
 var start=p.position
 mouse(root.get_canvas_transform()*Vector2(320,555))
 await frames(30)
 check(p.position.distance_to(start)>2,"raw mouse moves initial player through GUI")
 tap(Vector2(340,600))
 for i in 900:
  await frames(1)
  if p.carrying_grass:break
 check(p.carrying_grass,"raw touch reaches grass and picks it up without teleport")
 for i in 1800:
  await frames(1)
  if w.actor_named("llama").state=="wander" and w.actor_named("llama")._velocity.length()>10:break
 check(w.actor_named("llama")._velocity.length()>10,"target is naturally moving before approach")
 tap(w.actor_named("llama").position)
 var llama_start=w.actor_named("llama").position
 for i in 1500:
  await frames(1)
  if "llama_fed_gentle" in w.collected and not p.carrying_grass:break
 check("llama_fed_gentle" in w.collected and not p.carrying_grass,"raw touch reaches llama and collects exact feeding photo")
 print("AUDIT moving llama displacement=",llama_start.distance_to(w.actor_named("llama").position)," final reach=",p.position.distance_to(w.actor_named("llama").position))
 var pause_origin=main._pause_button.get_global_transform_with_canvas().origin
 check(pause_origin.x>=0 and pause_origin.y>=0 and pause_origin.x+main._pause_button.size.x<=1280,"pause inside viewport during photo zoom")
 var screen=root.get_canvas_transform()*Vector2(350,520)
 check(main._screen_to_world(screen).distance_to(Vector2(350,520))<0.01,"zoom screen-to-world roundtrip")
 tap(w.actor_named("llama").position)
 for i in 900:
  await frames(1)
  if w._leading:break
 check(w._leading,"tap llama starts lead")
 tap(Vector2(100,100))
 await frames(1)
 check(w._leading,"rejected empty tap does not toggle lead")
 tap(Vector2(780,480));await frames(240)
 check(w._leading and w.actor_named("llama").state=="lead","touch walks while lead remains active")
 touch_button("_action_button");await frames(1)
 check(not w._leading,"actual action button releases lead")
 touch_button("_pause_button")
 button("_pause_button") # Paired emulated mouse must not undo the touch.
 await frames(1)
 check(main._pause_screen.visible and paused,"actual pause button pauses")
 touch_button("_resume_button");await frames(1)
 check(not main._pause_screen.visible and not paused,"actual resume button resumes")
 touch_button("_album_chip");await frames(1)
 check(main._album_screen.visible and not w.input_enabled,"actual album button opens")
 touch_button("_album_back_button");await frames(1)
 check(not main._album_screen.visible and w.input_enabled,"actual album close returns to yard")
 var before=w._backdrop.texture
 var walk=w._player.walk_ground.duplicate()
 w.toggle_weather()
 check(before==w._backdrop.texture and walk==w._player.walk_ground,"weather preserves backdrop geometry and collision")
 root.get_node("AudioDirector").call("release_streams")
 print("[ui-interaction-tests] failures=",failures)
 quit(0 if failures.is_empty() else 1)
