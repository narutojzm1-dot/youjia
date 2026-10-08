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
 var i18n=root.get_node("I18n")
 await create_timer(0.5).timeout
 var start=p.position
 w.debug_place_actor("sheep_b", Vector2(1090, 505))
 w.debug_place_player(w.actor_named("cow").position + Vector2(-50, 20))
 w.tick(0.016, Vector2.ZERO)
 main._refresh_hud()
 check(main._hint_label.text.contains("奶牛") and main._hint_label.text.contains("打个招呼") and main._action_button.text == i18n.t("action.pet"), "Chinese HUD names the marked cow and the same pet action as the button")
 check(w._effects_overlay.pet_pos.distance_to(w.actor_named("cow").position) < 0.1, "HUD's marked cow is the actual action target")
 i18n.set_locale("en")
 main._refresh_hud()
 check(main._hint_label.text.contains("Cow") and main._hint_label.text.contains("Say hello"), "English HUD names the same target and action")
 i18n.set_locale("zh-CN")
 w.debug_place_player(Vector2(500, 518))
 tap(Vector2(285, 275))
 await frames(1)
 main._refresh_hud()
 check(w._pending_interaction == "windowbox" and main._hint_label.text.contains("窗台花箱") and main._action_button.text == i18n.t("action.observe_windowbox"), "raw touch targets the painted window flowers and Chinese HUD names the same action")
 i18n.set_locale("en")
 main._refresh_hud()
 check(main._hint_label.text.contains("Window flowers") and main._action_button.text == i18n.t("action.observe_windowbox"), "English HUD retains the exact touched windowbox target")
 i18n.set_locale("zh-CN")
 touch_button("_action_button")
 await frames(1)
 check(w._pending_interaction == "windowbox" and w._scene_feedback.active_snapshot().is_empty(), "real touch action button keeps the flower-box approach without celebrating early")
 w.debug_place_player(Vector2(700, 455))
 tap(Vector2(515, 560))
 await frames(1)
 main._refresh_hud()
 check(w._pending_interaction == "shore_stones" and main._hint_label.text.contains("水塘岸石") and main._hint_label.text.contains("拨一拨水") and main._action_button.text == i18n.t("action.touch_shore"), "raw touch chooses the painted bank stone and Chinese HUD/button describe water-touch, not fishing")
 i18n.set_locale("en")
 main._refresh_hud()
 check(main._hint_label.text.contains("Pond-side stones") and main._action_button.text == i18n.t("action.touch_shore"), "English HUD keeps the exact bank stone rather than silently changing to the pond")
 i18n.set_locale("zh-CN")
 touch_button("_action_button")
 await frames(1)
 check(w._pending_interaction == "shore_stones" and w._scene_feedback.ripple_snapshot().is_empty(), "real touch action button retains the bank route without splashing early")
 w.debug_place_player(Vector2(500, 518))
 tap(Vector2(923, 470))
 await frames(1)
 main._refresh_hud()
 check(w._pending_interaction == "fence_gate" and main._hint_label.text.contains("木栅栏边") and main._action_button.text == i18n.t("action.open_gate"), "raw touch selects the painted gate; Chinese HUD and action button agree")
 i18n.set_locale("en")
 main._refresh_hud()
 check(main._hint_label.text.contains("Wooden fence") and main._action_button.text == i18n.t("action.open_gate"), "English HUD keeps the touched wooden fence rather than suggesting entry")
 i18n.set_locale("zh-CN")
 touch_button("_action_button")
 await frames(1)
 check(w._pending_interaction == "fence_gate" and w._scene_feedback.fence_snapshot().is_empty(), "actual action button retains the safe fence route without an early breeze")
 w.debug_place_player(Vector2(500, 518)) # Preserve the old distant-pond HUD precondition.
 w.request_pointer_action(w._fishing_point())
 main._refresh_hud()
 check(main._hint_label.text.contains("水塘") and main._hint_label.text.contains("垂钓") and main._action_button.text == i18n.t("action.fish"), "pond selection names its fishing action rather than nearby animal")
 w.request_pointer_action(Vector2(100, 100))
 w.debug_place_player(start)
 await create_timer(0.45).timeout # Existing touch-to-mouse dedupe window is 400 ms.
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
 await frames(300)
 check(p.carrying_grass,"walking toward an animal does not hand-feed it")
 touch_button("_action_button")
 await root.get_node("SaveStore").flush_pending()
 await frames(3)
 check(not p.carrying_grass and w.ground_food.items.size()==1,"raw action button creates one durable ground grass bundle")
 print("AUDIT ground food position=",w.ground_food.items)
 var pause_origin=main._pause_button.get_global_transform_with_canvas().origin
 check(pause_origin.x>=0 and pause_origin.y>=0 and pause_origin.x+main._pause_button.size.x<=1280,"pause remains inside viewport after dropping food")
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
 # Produce two additional genuine yard snapshots instead of manufacturing page slots.
 w.holiday_day=3
 w.debug_place_actor("goose",Vector2(765,510))
 w.debug_place_actor("duck_a",Vector2(773,538))
 w.debug_place_player(Vector2(748,518))
 var goose=w.actor_named("goose")
 goose.state="rest";goose._idle_time=10;goose._velocity=Vector2.ZERO;goose._gait.weight=0
 w.tick(1.0/60.0,Vector2.ZERO)
 w._evaluate_expressions()
 check("goose_pond_rest" in w.collected and w.actor_named("goose")._posture_id=="rest","real painted goose rest supplies a photograph for page browsing")
 w.debug_place_player(Vector2(339,505))
 w.debug_place_actor("sheep_a",Vector2(305,508))
 w.debug_place_actor("sheep_b",Vector2(354,504))
 w.tick(1.0/60.0,Vector2.ZERO)
 w._evaluate_expressions()
 check("sheep_pair_near" in w.collected and not w.photo_moments.get("sheep_pair_near",{}).is_empty(),"real close sheep supply another page, not a fabricated page counter")
 touch_button("_album_chip");await frames(1)
 check(main._album_screen.visible and not w.input_enabled and not main._hud.visible,"actual album button opens a clean book without yard HUD controls")
 check(main._album_two_pages and main._album_spread.get_child_count()==3 and main._album_entries.size()>=3,"wide album shows two paper pages and a spine, with only saved moments")
 touch_button("_album_next_button");await frames(1)
 check(main._album_index==2,"touching next turns one double-page spread")
 var arrow=InputEventKey.new();arrow.keycode=KEY_LEFT;arrow.pressed=true;root.push_input(arrow,true)
 await frames(1)
 check(main._album_index==0,"left arrow turns back without moving the traveler")
 arrow=InputEventKey.new();arrow.keycode=KEY_RIGHT;arrow.pressed=true;root.push_input(arrow,true)
 await frames(1)
 check(main._album_index==2,"right arrow turns forward while the album is modal")
 root.size=Vector2i(390,844);await frames(2);main._layout();await frames(1)
 check(not main._album_two_pages and main._album_spread.get_child_count()==1 and main._album_index==2,"portrait viewport keeps the current photo on a single readable page")
 var starting_page:int=main._album_index
 var left_touch=InputEventScreenTouch.new();left_touch.index=0;left_touch.position=Vector2(285,375);left_touch.pressed=true;root.push_input(left_touch,true)
 left_touch=InputEventScreenTouch.new();left_touch.index=0;left_touch.position=Vector2(90,379);left_touch.pressed=false;root.push_input(left_touch,true)
 await frames(1)
 check(main._album_index==starting_page+1,"horizontal touch swipe advances one portrait page")
 var remembered:int=main._album_index
 i18n.set_locale("en");await frames(1)
 check(main._album_index==remembered and main._album_next_button.text=="Later →","language switch retains the selected photo and translates controls")
 i18n.set_locale("zh-CN")
 touch_button("_album_previous_button");await frames(1)
 check(main._album_index==remembered-1,"portrait touch previous button returns one page")
 touch_button("_album_back_button");await frames(1)
 check(not main._album_screen.visible and w.input_enabled and main._hud.visible,"actual album close restores yard HUD and walking")
 root.size=Vector2i(1280,720);await frames(2);main._layout()
 root.get_node("TuningStore").set_value("ui.reduced_motion", true)
 var before=w._backdrop.texture
 var before_scale=w._backdrop.scale
 var walk=w._player.walk_ground.duplicate()
 w.toggle_weather()
 check(w.weather=="overcast" and w._weather_backdrop_blend.texture==w.OVERCAST and is_equal_approx(w._weather_mix,1.0) and w._backdrop.texture==before,"overcast uses the painted overcast yard")
 check(before_scale==w._backdrop.scale and walk==w._player.walk_ground,"weather preserves backdrop scale and collision")
 # 云带 B：阴天换阴云帧，且不改碰撞。
 check(w._weather_cloud_pair()[0]!=null and w._weather_cloud_pair()[0].texture==w.CLOUD_OVERCAST,"overcast swaps the overcast cloud band")
 w.toggle_weather()
 w._day_elapsed = w.DAY_DURATION_SECONDS * 0.40
 w._apply_weather_art()
 check(w.weather=="sun" and w._backdrop.texture==w.SUNNY,"sun restores the painted sunny yard")
 check(w._weather_cloud_pair()[0].texture==w.CLOUD_SUNNY,"sun restores the sunny cloud band")
 # 早晨薄云：晴天 TOD dawn/morning；阴天不抢。
 w._day_elapsed = w.DAY_DURATION_SECONDS * 0.18
 w._apply_weather_art()
 check(w._weather_cloud_pair()[0].texture==w.CLOUD_MORNING,"sunny morning uses the thinner morning cloud band")
 w._day_elapsed = 0.0
 w._apply_weather_art()
 check(w._weather_cloud_pair()[0].texture==w.CLOUD_MORNING,"sunny dawn uses the morning cloud band")
 w.toggle_weather()
 check(w.weather=="overcast" and w._weather_cloud_pair()[0].texture==w.CLOUD_OVERCAST,"overcast morning keeps the overcast cloud band")
 w.toggle_weather()
 w._day_elapsed = w.DAY_DURATION_SECONDS * 0.40
 w._apply_weather_art()
 check(w.weather=="sun" and w._weather_cloud_pair()[0].texture==w.CLOUD_SUNNY,"sunny noon restores the bright cloud band after morning")
 # 晴天云带 modulate 应偏亮，不跟院子暖滤色一起变脏。
 check(w._weather_cloud_pair()[0].modulate.r >= 1.0 and w._weather_cloud_pair()[0].modulate.g >= 1.0,"sunny cloud band stays bright instead of dirty warm tint")
 # 傍晚暖云：只在晴天 TOD evening 窗口换帧；阴天不抢。
 w._day_elapsed = w.DAY_DURATION_SECONDS * (13.0 / 24.0) # 19:00 local time
 w._apply_weather_art()
 check(w._weather_cloud_pair()[0].texture==w.CLOUD_SUNSET,"sunny evening uses the warm sunset cloud band")
 w.toggle_weather()
 check(w.weather=="overcast" and w._weather_cloud_pair()[0].texture==w.CLOUD_OVERCAST,"overcast evening keeps the overcast cloud band")
 w.toggle_weather()
 w._day_elapsed = w.DAY_DURATION_SECONDS * 0.40
 w._apply_weather_art()
 check(w.weather=="sun" and w._weather_cloud_pair()[0].texture==w.CLOUD_SUNNY,"sunny noon restores the bright cloud band")
 # 夜里仍用晴天云形，但 modulate 压暗偏冷，不把正午暖白带到夜空。
 w._day_elapsed = w.DAY_DURATION_SECONDS * 0.92
 w._apply_weather_art()
 check(w._weather_cloud_pair()[0].texture==w.CLOUD_SUNNY,"sunny night keeps the daytime cloud shape")
 var night_mod: Color = w._weather_cloud_pair()[0].modulate
 check(night_mod.r < 1.0 and night_mod.b > night_mod.r,"sunny night clouds are cooler and dimmer than noon")
 w.toggle_weather()
 check(w.weather=="overcast" and w._weather_cloud_pair()[0].texture==w.CLOUD_OVERCAST,"overcast night keeps the overcast cloud band")
 w.toggle_weather()
 w._day_elapsed = w.DAY_DURATION_SECONDS * 0.40
 w._apply_weather_art()
 check(w._weather_cloud_pair()[0].modulate.r >= 1.0,"sunny noon after night restores the bright cloud band")
 # 低动效：云带保持可读静止帧（滚动偏移不再增加）。
 # 本套件以 SceneTree 运行，须经 root 取 TuningStore 节点。
 var scroll_before=w._cloud_scroll
 var tuning=root.get_node("TuningStore")
 tuning.set_value("ui.reduced_motion", true)
 w.tick(2.0, Vector2.ZERO)
 check(is_equal_approx(w._cloud_scroll, scroll_before),"reduced motion keeps cloud band static")
 tuning.set_value("ui.reduced_motion", false)
 w.tick(2.0, Vector2.ZERO)
 check(w._cloud_scroll>scroll_before,"cloud band drifts when motion is allowed")
 w.debug_place_player(YardSceneHotspots.get_hotspot("windowbox").approach_points[0] + Vector2(5, 5))
 w.request_pointer_action(Vector2(285, 275))
 check(not w._scene_feedback.active_snapshot().is_empty(), "real windowbox observation paints a temporary world response")
 touch_button("_pause_button");await frames(1)
 check(main._pause_screen.visible and w._scene_feedback.active_snapshot().is_empty(), "real pause button clears painted windowbox encounter immediately")
 touch_button("_resume_button");await frames(1)
 w.debug_place_player(YardSceneHotspots.get_hotspot("shore_stones").approach_points[0] + Vector2(5, 3))
 for id in w._actors:
  if w.actor_named(id).visual_hit_rect().grow(5.0).has_point(Vector2(515, 560)):
   w.debug_place_actor(id, Vector2(900, 465))
 w.request_pointer_action(Vector2(515, 560))
 check(not w._scene_feedback.ripple_snapshot().is_empty(), "actual pond-side stone action paints a ripple, never an unearned fish")
 touch_button("_pause_button");await frames(1)
 check(main._pause_screen.visible and w._scene_feedback.ripple_snapshot().is_empty(), "actual pause button clears a successful shore ripple immediately")
 touch_button("_resume_button");await frames(1)
 w.debug_place_player(YardSceneHotspots.get_hotspot("fence_gate").approach_points[0] + Vector2(4, 3))
 for id in w._actors:
  if w.actor_named(id).visual_hit_rect().grow(5.0).has_point(Vector2(923, 470)):
   w.debug_place_actor(id, Vector2(700, 455))
 w.request_pointer_action(Vector2(923, 470))
 check(not w.gate.pending.is_empty() and not w.gate.opened, "real gate action waits for durable confirmation")
 await root.get_node("SaveStore").flush_pending()
 check(w.gate.opened, "real gate action opens after persistence confirmation")
 touch_button("_pause_button");await frames(1)
 check(main._pause_screen.visible and w._scene_feedback.fence_snapshot().is_empty(), "actual pause button clears the painted fence breeze")
 touch_button("_resume_button");await frames(1)
 root.get_node("AudioDirector").call("release_streams")
 print("[ui-interaction-tests] checks=",checks," failures=",failures)
 quit(0 if failures.is_empty() else 1)
