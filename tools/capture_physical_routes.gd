extends SceneTree
# Native rendered viewport-input regression. Fixed simulation cadence is not
# a browser/device FPS measurement. No actor teleporting or forced photos.
var main: Control
var stage := 0
var since := 0
var events: Array = []
var routes := [Vector2(520,455),Vector2(310,550),Vector2(850,495),Vector2(490,526),Vector2(700,460)]
var route_index := 0
func _initialize(): call_deferred("record")
func tap_world(point: Vector2):
 for pressed in [true,false]:
  var e := InputEventScreenTouch.new(); e.position=root.get_canvas_transform()*point; e.index=0; e.pressed=pressed;root.push_input(e,true)
func button(name: String):
 var b:Control=main.get(name)
 for pressed in [true,false]:
  var e:=InputEventScreenTouch.new();e.position=b.get_global_transform_with_canvas()*(b.size*0.5);e.index=0;e.pressed=pressed;root.push_input(e,true)
func advance(label: String,frame: int):
 events.append({"frame":frame,"event":label});print("[physical-capture] ",label," ",frame);stage+=1;since=frame
func record():
 var folder:=OS.get_environment("YOUJIA_CAPTURE_DIR");DirAccess.make_dir_recursive_absolute(folder)
 seed(817)
 main=load("res://scenes/main.tscn").instantiate();root.add_child(main)
 var failed:=false
 for frame in 9000:
  if stage==0 and frame==15:button("_play_button");advance("touch start",frame)
  elif stage==1 and frame-since>20:tap_world(Vector2(340,600));advance("harvest",frame)
  elif stage==2 and main._world._player.carrying_grass:tap_world(main._world.actor_named("llama").position);advance("feed approach past residents",frame)
  elif stage==3 and not main._world._player.carrying_grass:advance("feed consumed",frame)
  elif stage==4 and frame-since>70:tap_world(main._world.actor_named("llama").position);advance("lead",frame)
  elif stage==5 and main._world._leading:tap_world(routes[0]);advance("lead route 0 upper pasture",frame)
  elif stage==6 and not main._world._has_walk_goal and frame-since>30:
   if main._world._player.position.distance_to(routes[route_index])>18:failed=true;print("ROUTE DID NOT ARRIVE ",route_index);break
   route_index+=1
   if route_index>=routes.size():button("_action_button");advance("release after five crossing routes",frame)
   else:tap_world(routes[route_index]);since=frame;events.append({"frame":frame,"event":"lead route %d"%route_index});print("[physical-capture] route ",route_index," ",frame)
  elif stage==7 and frame-since>60:tap_world(Vector2(410,535));advance("free walk in front of cow",frame)
  elif stage==8 and not main._world._has_walk_goal and frame-since>30:tap_world(Vector2(500,448));advance("free walk behind cow",frame)
  elif stage==9 and not main._world._has_walk_goal and frame-since>60:advance("multiple routes completed",frame)
  if stage>0 and frame-since>1800:failed=true;print("STAGE TIMEOUT ",stage);break
  await process_frame
  await RenderingServer.frame_post_draw
  if frame%6==0:root.get_texture().get_image().save_png(folder.path_join("%04d.png"%(frame/6)))
  if stage==10 and frame-since>90:break
 var f:=FileAccess.open(folder.path_join("events.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"stage":stage,"failed":failed,"events":events},"  "))
 root.get_node("AudioDirector").call("release_streams");quit(0 if stage==10 and not failed else 1)
