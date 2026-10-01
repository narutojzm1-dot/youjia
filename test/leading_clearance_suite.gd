extends SceneTree
var checks:=0
var failures:Array=[]
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label);push_error(label)
func run():
 for fps in [30,60,120]:
  seed(1102026)
  var world=load("res://scripts/game/yard_world.gd").new();root.add_child(world);world.setup()
  world.debug_place_player(Vector2(466,469));world._leading=true;world._player.leading=true
  var llama=world.actor_named("llama")
  var start:Vector2=llama.position
  var obs:Array=world.physical_obstacles("llama").filter(func(item):return item.id!="player")
  check(YardBodies.clear_at(world._player.position,world._player.body_radius*YardGround.depth_at(469),obs),"person fits beside natural cow")
  check(not YardBodies.clear_at(world._player.position,llama.body_radius*YardGround.depth_at(500),obs),"larger llama cannot occupy exact player footprint")
  var minimum:=INF
  var on_ground:=true
  for i in fps*8:
   world.tick(1.0/fps,Vector2.ZERO)
   on_ground=on_ground and YardGround.allows(llama.position,YardGround.lawn(),true)
   var radius:Vector2=llama.body_radius*YardGround.depth_at(llama.position.y)
   for item:Dictionary in world.physical_obstacles("llama"):
    minimum=minf(minimum,((llama.position-item.position)/(radius+item.radius)).length())
  check(llama.position.distance_to(start)>150,"llama makes real progress at %sHz"%fps)
  check(llama.position.distance_to(world._player.position)<78,"llama reaches trailing range instead of remaining stranded at %sHz"%fps)
  check(minimum>=0.995,"trailing route never crosses resident footprints at %sHz gap %s"%[fps,minimum])
  check(on_ground,"trailing route stays off pond/fence at %sHz"%fps)
  world.free()
 print("[leading-clearance-tests] ",checks," checks ",failures)
 quit(0 if failures.is_empty() else 1)
