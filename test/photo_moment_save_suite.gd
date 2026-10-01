extends SceneTree
var main:Control
var checks:=0
var failures:Array=[]
var store:Node
var original:Variant
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label);push_error(label)
func player_pose(moment:Dictionary)->Array:
 for item:Dictionary in moment.get("items",[]):
  if str(item.get("subject",""))=="player":return item.transform.duplicate()
 return []
func same_numbers(a:Array,b:Array)->bool:
 if a.size()!=b.size():return false
 for i in a.size():
  if absf(float(a[i])-float(b[i]))>0.00001:return false
 return true
func feed_naturally(world):
 world.request_primary_action()
 for i in 2400:
  world.tick(1.0/60,Vector2.ZERO)
  if world._player.carrying_grass:break
 check(world._player.carrying_grass,"normal grass command harvests before recording a feeding photo")
 world.request_primary_action()
 for i in 3000:
  world.tick(1.0/60,Vector2.ZERO)
  if not world._player.carrying_grass:break
 check(not world._player.carrying_grass and world._player.just_fed_seconds>0,"normal approach really feeds")
func run():
 root.size=Vector2i(1280,720);seed(831)
 store=root.get_node("SaveStore")
 original=FileAccess.get_file_as_bytes(store.SAVE_PATH) if FileAccess.file_exists(store.SAVE_PATH) else null
 store._data=store._default_data()
 main=load("res://scenes/main.tscn").instantiate();root.add_child(main)
 await process_frame;await process_frame
 main.set_process(false);main._start_holiday()
 var world=main._world
 feed_naturally(world)
 var fed_id:="llama_fed_gentle"
 var moment:Dictionary=store.get_photo_moment(fed_id)
 check(fed_id in store.get_album(),"new photo ID is saved")
 check(not moment.is_empty() and moment.get("rule_id")==fed_id,"real encounter scene is saved with its photo ID")
 var pose:=player_pose(moment)
 check(pose.size()==6,"photo includes the accepted hero frame and pose")
 for i in 180:world.tick(1.0/60,Vector2.LEFT)
 check(same_numbers(pose,player_pose(store.get_photo_moment(fed_id))),"saved moment does not follow later player movement")
 store._load()
 check(fed_id in store.get_album() and same_numbers(pose,player_pose(store.get_photo_moment(fed_id))),"photo pose and progress survive reload")
 main._show_album();await process_frame
 var scene_cards:=0
 for card in main._album_grid.get_children():
  for child in card.get_children():
   if child is PhotoMoment:scene_cards+=1
 check(scene_cards>=1,"album actually uses event-scene cards")
 main._hide_album()
 # Existing version3 progress remains earned; missing images are captured only
 # when those events actually occur again, silently, without a new camera jump.
 var old_ids:Array=Array(ExpressionCatalog.all_ids())
 var file:=FileAccess.open(store.SAVE_PATH,FileAccess.WRITE)
 file.store_string(JSON.stringify({"version":3,"locale":"zh-CN","album":old_ids}));file.close()
 store._load()
 check(store.get_album()==old_ids and store.get_photo_moments().is_empty(),"version3 album survives migration without invented scenes")
 main._start_holiday();world=main._world
 check(world.collected.size()==old_ids.size() and world.photo_moments.is_empty(),"old earned IDs remain on new yard start")
 var focus_calls:Array=[]
 world.camera_focus_requested.connect(func(point:Vector2,_zoom:float):focus_calls.append(point))
 feed_naturally(world)
 check(store.get_album()==old_ids,"capturing a legacy scene never resets or duplicates progress")
 check(not store.get_photo_moment(fed_id).is_empty(),"legacy feeding portrait gains a real scene on the next feeding")
 check(focus_calls.is_empty(),"legacy scene upgrades do not replay unlock camera jumps")
 # Corrupt scene data cannot wipe the earned album.
 file=FileAccess.open(store.SAVE_PATH,FileAccess.WRITE)
 file.store_string(JSON.stringify({"version":4,"locale":"zh-CN","album":old_ids,"photo_moments":{fed_id:{"version":1,"rule_id":fed_id,"items":[]}}}));file.close()
 store._load()
 check(store.get_album()==old_ids and store.get_photo_moments().is_empty(),"bad scene metadata is discarded without losing collected IDs")
 if original==null:DirAccess.remove_absolute(ProjectSettings.globalize_path(store.SAVE_PATH))
 else:
  file=FileAccess.open(store.SAVE_PATH,FileAccess.WRITE);file.store_buffer(original);file.close()
 root.get_node("AudioDirector").call("release_streams")
 print("[photo-moment-save-tests] ","PASS" if failures.is_empty() else "FAIL",": ",checks," checks ",failures)
 quit(0 if failures.is_empty() else 1)
