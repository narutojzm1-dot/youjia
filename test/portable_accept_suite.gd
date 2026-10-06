extends SceneTree
var failures:Array=[]
var checks:=0
func _initialize():call_deferred("run")
func run():
 for device in [0,16]:
  for code in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:
   for physical in [false,true]:
    var e:=InputEventKey.new()
    e.device=device;e.keycode=code;e.physical_keycode=code if physical else 0;e.pressed=true
    checks+=1
    if not e.is_action_pressed("ui_accept"):
     failures.append("device%s key%s physical%s"%[device,code,physical])
 var main=load("res://scenes/main.tscn").instantiate();root.add_child(main)
 await process_frame;await process_frame
 main.set_process(false)
 var store=root.get_node("SaveStore")
 for device in [0,16]:
  await main._start_holiday()
  var world=main._world
  for id:String in world._actors:world.actor_named(id).posed=true
  if world.ground_food.items.is_empty():
   world.debug_place_player(world._grass_point());world._interact_with_target("grass")
  else:
   var item:Dictionary=world.ground_food.items[0]
   world.debug_place_player(Vector2(item.x,item.y));world.ground_food.pickup(int(item.id))
  checks+=1
  if not await store.flush_pending():failures.append("real grass acquisition save failed")
  for i in 3:await process_frame
  var before:int=world.ground_food.items.size()
  world.debug_place_player(Vector2(600,540));world.debug_place_actor("llama",Vector2(680,540))
  world.request_pointer_action(Vector2(680,540))
  for down in [true,false]:
   var event:=InputEventKey.new();event.device=device;event.keycode=KEY_SPACE;event.physical_keycode=KEY_SPACE;event.pressed=down;Input.parse_input_event(event)
  await process_frame
  await store.flush_pending()
  for i in 3:await process_frame
  checks+=1
  if world._player.carrying_grass or world.ground_food.items.size()!=before+1:failures.append("raw device%s Space did not drop once"%device)
  for i in 180:world.tick(1.0/60,Vector2.ZERO)
  checks+=1
  if world._leading or not world._pending_interaction.is_empty():failures.append("raw device%s Space left a repeating action"%device)
 print("[portable-accept-tests] ",checks," checks ",failures)
 quit(0 if failures.is_empty() else 1)
