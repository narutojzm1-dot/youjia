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
func descendants(node:Node)->Array:
 var result:Array=[]
 for child in node.get_children():
  result.append(child)
  result.append_array(descendants(child))
 return result
func feed_naturally(world):
 world.request_pointer_action(world._grass_point())
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
 main.set_process(false);await main._start_holiday()
 var world=main._world
 feed_naturally(world)
 await store.flush_pending()
 var fed_id:="llama_fed_gentle"
 var moment:Dictionary=store.get_photo_moment(fed_id)
 check(fed_id in store.get_album(),"new photo ID is saved")
 check(not moment.is_empty() and moment.get("rule_id")==fed_id,"real encounter scene is saved with its photo ID")
 check(moment.get("day",0)==world.holiday_day,"new travel photograph retains the real in-game day")
 check(moment.has("caption_variant") and int(moment.caption_variant) in [0,1],"new photo chooses a bounded caption variant at capture time")
 check(main._cam_target_zoom==1.0,"new travel photograph is explained by a visible print instead of an unexplained camera zoom")
 var photo_arrival:Node=main._ui_layer.get_node_or_null("PhotoArrival")
 check(photo_arrival!=null and photo_arrival.visible,"new travel photograph shows its real captured image before tucking into the album")
 check(photo_arrival.mouse_filter==Control.MOUSE_FILTER_IGNORE and photo_arrival._picture.mouse_filter==Control.MOUSE_FILTER_IGNORE,"the print and its true picture never block walking or touch input")
 check(photo_arrival!=null and photo_arrival._caption.text.contains("假期第1天") and photo_arrival._caption.text.contains("草泥马"),"the first print names the real vacation day and photographed animal")
 var i18n:Node=root.get_node("I18n")
 var original_caption:=PhotoDiary.caption(moment)
 i18n.set_locale("en")
 check(photo_arrival!=null and photo_arrival._caption.text.contains("Holiday day 1") and photo_arrival._caption.text.contains("llama"),"existing first print changes to the same English day and event without inventing a new encounter")
 check(PhotoDiary.caption(moment)!=original_caption and PhotoDiary.caption(moment).contains("llama"),"English uses the same saved event/variant rather than drawing a new caption")
 i18n.set_locale("zh-CN")
 check(PhotoDiary.caption(moment)==original_caption,"switching back to Chinese restores the exact saved caption")
 var old_moment:Dictionary=moment.duplicate(true);old_moment.erase("day");old_moment.erase("caption_variant")
 check(not PhotoMoment.sanitize(old_moment).is_empty() and not PhotoMoment.sanitize(old_moment).has("day"),"a version-one photograph without a date remains valid without a fake first day")
 check(PhotoDiary.caption(old_moment)==i18n.t("photo.llama_fed.title"),"legacy undated photographs retain their original title")
 var dated_legacy:=moment.duplicate(true);dated_legacy.erase("caption_variant")
 check(PhotoDiary.caption(dated_legacy)==i18n.t("photo.diary.day",{"day":str(moment.day),"moment":i18n.t("photo.diary.llama_fed_gentle")}),"legacy dated photos retain original title and do not retroactively change wording")
 var bad_variant:=moment.duplicate(true);bad_variant.caption_variant=3
 check(PhotoMoment.sanitize(bad_variant).is_empty(),"out-of-range caption variant cannot enter saved photo")
 bad_variant.caption_variant=2
 check(PhotoMoment.sanitize(bad_variant).is_empty(),"a two-sentence photo rejects variant two even though other events allow it")
 bad_variant.caption_variant=1.5
 check(PhotoMoment.sanitize(bad_variant).is_empty(),"fractional caption variant cannot enter saved photo")
 var wrong_day:Dictionary=moment.duplicate(true);wrong_day.day=0
 check(PhotoMoment.sanitize(wrong_day).is_empty(),"an invalid photo day never survives snapshot validation")
 photo_arrival.dismiss()
 check(photo_arrival.play(moment,true),"reduced motion still presents the genuine saved print")
 check(photo_arrival.get_node("PhotoCard").scale == Vector2.ONE,"photo display does not shrink toward the album icon")
 var still_pos:Vector2=photo_arrival._card.position
 await create_timer(0.25).timeout
 check(photo_arrival.visible and photo_arrival._card.position==still_pos and photo_arrival._card.scale==Vector2.ONE,"reduced motion holds a readable still photograph rather than shrinking it")
 photo_arrival.dismiss()
 check(photo_arrival.play(moment,false),"standard motion presents the same captured print")
 var normal_pos:Vector2=photo_arrival._card.position
 await create_timer(0.35).timeout
 check(photo_arrival.visible and photo_arrival._card.position==normal_pos and photo_arrival._card.scale==Vector2.ONE,"standard photo development keeps the card centered at full size")
 await create_timer(1.0).timeout
 check(photo_arrival.visible and photo_arrival._card.position==normal_pos and photo_arrival._card.scale==Vector2.ONE,"photo fade-out stays centered at full size instead of flying and shrinking")
 main._toggle_pause()
 check(not photo_arrival.visible and main._pause_screen.visible,"pausing immediately dismisses the print without blocking the menu")
 main._toggle_pause()
 check(main._world.input_enabled,"dismissing the print restores ordinary yard controls")
 var pose:=player_pose(moment)
 check(pose.size()==6,"photo includes the accepted hero frame and pose")
 for i in 180:world.tick(1.0/60,Vector2.LEFT)
 check(same_numbers(pose,player_pose(store.get_photo_moment(fed_id))),"saved moment does not follow later player movement")
 await store.flush_pending()
 store._load()
 check(fed_id in store.get_album() and same_numbers(pose,player_pose(store.get_photo_moment(fed_id))),"photo pose and progress survive reload")
 check(store.get_photo_moment(fed_id).get("caption_variant",-1)==moment.caption_variant and PhotoDiary.caption(store.get_photo_moment(fed_id))==original_caption,"saved variant and Chinese sentence survive real disk reload")
 main._show_album();await process_frame
 var scene_cards:=0
 var matching_diary:=false
 for child in descendants(main._album_spread):
  if child is PhotoMoment and child._snapshot.get("rule_id")==fed_id:scene_cards+=1
  if child is Label and child.text==PhotoDiary.caption(moment):matching_diary=true
 check(scene_cards>=1,"album actually uses event-scene cards")
 check(matching_diary,"the album presents the exact same day and sentence as the newly captured print")
 main._hide_album()
 world.tick(6.1,Vector2.ZERO)
 world.holiday_day=3
 world.set_weather("sun")
 world.debug_place_actor("horse",Vector2(880,480))
 world.debug_place_player(Vector2(837,492))
 world._interact_with_target("pet:horse")
 await store.flush_pending()
 var horse_id:="horse_pet_sunny"
 var horse_photo:Dictionary=store.get_photo_moment(horse_id)
 check(horse_id in store.get_album() and horse_photo.get("day",0)==3,"a real third-day sunny horse pet produces a saved dated photograph")
 var horse_in_queue:=false
 for waiting:Dictionary in main._photo_arrival_queue:
  if waiting.get("rule_id","")==horse_id:horse_in_queue=true
 check(main._photo_arrival._snapshot.get("rule_id","")==horse_id or horse_in_queue,"if another yard event is photographed in the same tick, the horse print waits rather than being overwritten")
 for step in 4:
  if main._photo_arrival._snapshot.get("rule_id","")==horse_id:break
  if main._photo_arrival._tween!=null:main._photo_arrival._tween.kill()
  main._photo_arrival._finish()
 check(main._photo_arrival.visible and main._photo_arrival._caption.text==PhotoDiary.caption(horse_photo) and not main._photo_arrival._caption.text.contains("生气"),"the horse print uses its saved truthful sentence, never invents an angry horse")
 check(PhotoMoment.has_event_subject(horse_photo,horse_id),"the horse diary entry contains the captured subject and not just a fabricated title")
 # Existing version3 progress remains earned; missing images are captured only
 # when those events actually occur again, silently, without a new camera jump.
 var old_ids:Array=Array(ExpressionCatalog.all_ids())
 await store.flush_pending()
 # Independent old-version profile: discard only this disposable test profile.
 for path in [store.SAVE_PATH,store.BACKUP_PATH,store.TEMP_PATH,store.SAVE_PATH+".legacy-sources.json"]:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 var file:=FileAccess.open(store.SAVE_PATH,FileAccess.WRITE)
 file.store_string(JSON.stringify({"version":3,"locale":"zh-CN","album":old_ids}));file.close()
 await store.flush_pending()
 store._load()
 check(store.get_album()==old_ids and store.get_photo_moments().is_empty(),"version3 album survives migration without invented scenes")
 await main._start_holiday();world=main._world
 check(world.collected.size()==old_ids.size() and world.photo_moments.is_empty(),"old earned IDs remain on new yard start")
 var focus_calls:Array=[]
 world.camera_focus_requested.connect(func(point:Vector2,_zoom:float):focus_calls.append(point))
 feed_naturally(world)
 await store.flush_pending()
 check(store.get_album()==old_ids,"capturing a legacy scene never resets or duplicates progress")
 check(not store.get_photo_moment(fed_id).is_empty(),"legacy feeding portrait gains a real scene on the next feeding")
 check(focus_calls.is_empty(),"legacy scene upgrades do not replay unlock camera jumps")
 # Corrupt scene data cannot wipe the earned album.
 await store.flush_pending()
 for path in [store.SAVE_PATH,store.BACKUP_PATH,store.TEMP_PATH,store.SAVE_PATH+".legacy-sources.json"]:
  DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 file=FileAccess.open(store.SAVE_PATH,FileAccess.WRITE)
 file.store_string(JSON.stringify({"version":4,"locale":"zh-CN","album":old_ids,"photo_moments":{fed_id:{"version":1,"rule_id":fed_id,"items":[]}}}));file.close()
 await store.flush_pending()
 store._load()
 check(store.get_album()==old_ids and store.get_photo_moments().is_empty(),"bad scene metadata is discarded without losing collected IDs")
 if original==null:DirAccess.remove_absolute(ProjectSettings.globalize_path(store.SAVE_PATH))
 else:
  file=FileAccess.open(store.SAVE_PATH,FileAccess.WRITE);file.store_buffer(original);file.close()
 root.get_node("AudioDirector").call("release_streams")
 print("[photo-moment-save-tests] ","PASS" if failures.is_empty() else "FAIL",": ",checks," checks ",failures)
 quit(0 if failures.is_empty() else 1)
