extends SceneTree
# Real viewport input dispatch from the unmodified initial spawn.
# Simulation steps are accelerated for assertions; this is not a browser timing test.
var checks := 0
var main:Control
var failures=[]
func _initialize(): call_deferred("review")
func check(ok,label):
 checks += 1
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
func key(code, down):
 var e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down
 Input.parse_input_event(e)
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
 check(w._pending_interaction == "llama" and w._walk_goal.distance_to(w.actor_named("llama").position) < 0.01,"moving llama selection retains exact destination")
 tap(Vector2(100,100))
 check(not w._has_walk_goal and w._pending_interaction=="" and p.carrying_grass and not w._leading,"invalid newer tap cancels pending llama approach without interacting")
 tap(w.actor_named("llama").position)
 var llama_start=w.actor_named("llama").position
 for i in 1500:
  await frames(1)
  if "llama_fed_gentle" in w.collected and not p.carrying_grass:break
 check("llama_fed_gentle" in w.collected and not p.carrying_grass,"raw touch reaches llama and collects exact feeding photo")
 print("AUDIT moving llama displacement=",llama_start.distance_to(w.actor_named("llama").position)," final reach=",p.position.distance_to(w.actor_named("llama").position))
 tap(w.actor_named("llama").position+Vector2(0,-48))
 for i in 900:
  await frames(1)
  if w._leading:break
 check(w._leading,"start lead away from grass")
 tap(w._grass_point())
 for i in 1600:
  await frames(1)
  if not w._has_walk_goal:break
 print("REPRO arrival p=",p.position," llama=",w.actor_named("llama").position," grass_dist=",p.position.distance_to(w._grass_point())," holding=",p.carrying_grass," lead=",w._leading)
 check(p.carrying_grass and w._leading,"grass arrival picks grass without toggling nearby llama")
 tap(w._grass_point())
 await frames(1)
 check(p.carrying_grass and w._leading,"explicit grass tap with full hands cannot feed nearby llama")
 # Walking to the grass has naturally picked some up; feed it through a real llama touch.
 if p.carrying_grass:
  tap(w.actor_named("llama").position+Vector2(0,-48))
  for i in 900:
   await frames(1)
   if not p.carrying_grass:break
 check(not p.carrying_grass,"empty hands after feeding by grass")
 touch_button("_action_button");await frames(1)
 check(not w._leading,"release using actual HUD button")
 print("REPRO before llama tap p=",p.position," llama=",w.actor_named("llama").position," grass_dist=",p.position.distance_to(w._grass_point()))
 tap(w.actor_named("llama").position+Vector2(0,-48))
 for i in 900:
  await frames(1)
  if not w._has_walk_goal:break
 print("REPRO result holding=",p.carrying_grass," leading=",w._leading," notice=",main._notice.text," p=",p.position," llama=",w.actor_named("llama").position)
 check(w._leading and not p.carrying_grass,"explicit llama tap restarts lead instead of picking nearby grass")
 # Repeat from outside llama reach: the same intent must survive walking arrival.
 touch_button("_action_button")
 # Walk along the valid lawn, not south into its painted edge.
 # Calm release no longer moves the llama away for this fixture.
 tap(Vector2(355,545))
 for i in 240:
  await frames(1)
  if not w._has_walk_goal:break
 check(p.position.distance_to(w.actor_named("llama").position)>88,"second llama selection begins outside interaction range")
 tap(w.actor_named("llama").position+Vector2(0,-48))
 check(w._pending_interaction=="llama" and w._walk_goal.distance_to(w.actor_named("llama").position)<0.01,"explicit llama route is not snapped to nearby grass or animals")
 for i in 900:
  await frames(1)
  if not w._has_walk_goal:break
 print("ARRIVAL grass distance=",p.position.distance_to(w._grass_point()))
 check(p.position.distance_to(w._grass_point())<78,"arrival regression overlaps grass interaction range")
 check(w._leading and not p.carrying_grass,"llama intent survives arrival inside grass range")
 key(KEY_SPACE, true)
 key(KEY_SPACE, false)
 await frames(1)
 check(not w._leading and not p.carrying_grass,"Space performs the same release displayed by HUD")
 tap(w._grass_point());await frames(1)
 check(not w._leading and p.carrying_grass,"explicit grass tap picks grass after release")
 touch_button("_action_button")
 for i in 900:
  await frames(1)
  if not w._has_walk_goal:break
 check(not p.carrying_grass and not w._leading,"HUD feed selects llama near grass")
 touch_button("_action_button")
 for i in 900:
  await frames(1)
  if not w._has_walk_goal:break
 check(p.carrying_grass and not w._leading,"HUD grass selects grass near llama")
 # A plain lawn point near a noninteractive animal must stay a lawn point.
 var ground_target = Vector2.ZERO
 var llama = w.actor_named("llama")
 for actor_id in ["cow", "sheep_a", "goose"]:
  var actor = w.actor_named(actor_id)
  if actor == null:continue
  for offset in [Vector2(60,0), Vector2(-60,0)]:
   var candidate = actor.position + offset
   if YardGround.allows(candidate,YardGround.lawn(),true) and candidate.distance_to(p.position)>80 and candidate.distance_to(w._grass_point())>=45 and candidate.distance_to(llama.position)>=45 and candidate.distance_to(llama.position+Vector2(0,-48))>=50:
    ground_target=candidate
    break
  if ground_target!=Vector2.ZERO:break
 check(ground_target!=Vector2.ZERO,"natural scene provides lawn point near another animal")
 tap(ground_target)
 check(w._pending_interaction=="" and w._has_walk_goal and w._walk_goal.distance_to(ground_target)<0.01,"background destination is not re-snapped to nearby actor")
 tap(Vector2(100,100))
 await frames(1)
 check(not w._has_walk_goal and w._pending_interaction=="" and w._walk_path.is_empty(),"invalid newer pointer cancels previous route and intent")
 check(p.carrying_grass and not w._leading,"invalid pointer never consumes grass or toggles lead")
 root.get_node("AudioDirector").call("release_streams")
 print("[explicit-target-tests] checks=",checks," failures=",failures)
 quit(0 if failures.is_empty() else 1)
