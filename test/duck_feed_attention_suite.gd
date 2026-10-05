extends SceneTree
var failures: Array[String] = []
var checks := 0
func _initialize(): call_deferred("run")
func check(value: bool, label: String):
 checks += 1
 if not value: failures.append(label); push_error(label)
func run():
 var world = load("res://scripts/game/yard_world.gd").new()
 root.add_child(world)
 world.setup()
 var duck = world.actor_named("duck_a")
 check(not duck.posed, "normal world setup leaves duck available for response")
 world.debug_place_player(duck.position + Vector2(200,0))
 world._fish_carry_type = "small"
 world._fish_carry_timer = 20.0
 world._interact_with_target("toss_fish:duck_a")
 check(duck._ack_cel == "" and world._fish_carry_type == "small", "out of reach does not consume or acknowledge")
 world.debug_place_player(duck.position + Vector2(-25,0))
 world._fish_carry_type = ""
 world._interact_with_target("toss_fish:duck_a")
 check(duck._ack_cel == "", "missing/expired carried fish does not acknowledge")
 world._fish_carry_type = "small"
 world._interact_with_target("toss_fish:duck_a")
 check(world._fish_carry_type == "" and duck._posture_id == "attend", "successful fish consumed then attention shown")
 check(world._effects_overlay.bird_feedback_snapshot().is_empty(), "successful duck feed has no default heart")
 duck.tick(0.1, Vector2(1280,720))
 check(duck._posture_id == "attend" and duck._sprite.texture.resource_path.ends_with("duck_attend.png"), "normal setup attention texture persists after tick 0.1")
 check(duck.facing == -1.0 and duck.scale.x < 0.0, "attention persists facing the actual observer")
 check(duck._sprite.to_global(duck._sprite.offset + duck._ground_anchor - duck._sprite.texture.get_size()*0.5).distance_to(duck.global_position) < 0.01, "rendered attention foot remains on actor world anchor after tick")
 check(duck._ground_anchor == duck._idle_ground_anchor, "attention retains idle foot anchor")
 var snapshot: Dictionary = PhotoMoment.capture(world, {"id":"duck_test", "owner":"duck"})
 var recorded := false
 for item: Dictionary in snapshot.get("items",[]):
  if str(item.get("subject","")) == "duck_a" and str(item.get("texture",{}).get("path", "")).ends_with("duck_attend.png"): recorded = true
 check(recorded, "live attention painting captured without reinterpretation")
 check(not PhotoMoment.sanitize(snapshot).is_empty(), "attention snapshot survives production sanitizer")
 var view := PhotoMoment.new()
 root.add_child(view)
 view.setup(snapshot)
 check(not view._snapshot.is_empty(), "attention snapshot rebuilds production photo view")
 view.free()
 var left: float = duck._ack_left
 world._fish_carry_type = "small"
 world._interact_with_target("toss_fish:duck_a")
 check(world._fish_carry_type == "" and duck._ack_left == left, "valid repeated feeding consumes but does not extend visual")
 check(world._effects_overlay.bird_feedback_snapshot().is_empty(), "repeated valid duck feed has no default heart")
 duck._velocity = Vector2(20,0)
 duck.tick(0.016,Vector2(1280,720))
 check(duck._ack_cel == "", "movement cancels attention")
 check(not duck.acknowledge_feed(Vector2.ZERO), "visual interval survives cancellation")
 duck._feed_ack_cooldown = 0
 duck.acknowledge_feed(Vector2.ZERO)
 duck.set_pose(duck.position,duck._base_scale,duck.facing)
 check(duck._ack_cel == "" and duck._posture_id == "idle", "posed actor clears attention")
 check(not duck.acknowledge_feed(Vector2.ZERO), "posed actor refuses attention")
 duck.posed = false
 duck._feed_ack_cooldown = 0
 duck.acknowledge_feed(Vector2.ZERO)
 for i in 140: duck.tick(1.0/60.0,Vector2(1280,720))
 check(duck._ack_cel == "", "attention ends after bounded interval")
 for i in 180: duck.tick(1.0/60.0,Vector2(1280,720))
 check(duck.acknowledge_feed(Vector2.ZERO), "later attention allowed after five seconds")
 duck.position += Vector2(3,0)
 duck.tick(0.016,Vector2(1280,720))
 check(duck._ack_cel == "", "external displacement cancels attention")
 check(not world.actor_named("goose").acknowledge_feed(Vector2.ZERO), "goose does not reuse duck resource")
 duck._feed_ack_cooldown = 0
 duck.acknowledge_feed(Vector2.ZERO)
 world.remove_child(duck)
 check(duck._ack_cel == "" and duck._feed_ack_cooldown == 0, "exit clears transient state")
 duck.free()
 var goose = world.actor_named("goose")
 world.debug_place_player(goose.position + Vector2(25,0))
 world._fish_carry_type = "small"
 world._interact_with_target("toss_fish:goose")
 check(world._fish_carry_type == "" and not world._effects_overlay.bird_feedback_snapshot().is_empty(), "existing goose success feedback remains intact")
 world.free()
 print("DUCK ATTENTION ", "PASS" if failures.is_empty() else "FAIL", " ", checks)
 quit(0 if failures.is_empty() else 1)
