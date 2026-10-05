extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
 checks += 1
 if not ok: failures.append(label); push_error(label)
func run():
 var world = load("res://scripts/game/yard_world.gd").new()
 root.add_child(world)
 world.setup()
 for id in ["sheep_a", "sheep_b"]:
  var sheep = world.actor_named(id)
  var expected := "sheep_clingy_attend_v2.png" if id == "sheep_a" else "sheep_dull_glance_v3.png"
  var idle_path: String = sheep._sprite.texture.resource_path
  var original_scale: float = sheep._base_scale
  world.debug_place_player(sheep.position + Vector2(200,0))
  world._interact_with_target("pet:"+id)
  check(sheep._ack_cel == "", id+" distant rejected pet has no response")
  for side in [-1.0, 1.0]:
   sheep._pet_ack_cooldown = 0
   world.debug_place_player(sheep.position + Vector2(side*30,0))
   world._interact_with_target("pet:"+id)
   check(sheep._ack_cel == "attend" and sheep._sprite.texture.resource_path.ends_with(expected), id+" successful pet uses own approved painting")
   check(is_equal_approx(sheep._ack_left,2.2) and is_equal_approx(sheep._pet_ack_cooldown,5), id+" existing timing retained")
   sheep.tick(0.1,Vector2(1280,720))
   check(sheep.facing == side and is_equal_approx(sheep._base_scale,original_scale) and is_equal_approx(absf(sheep.scale.x),original_scale * float(sheep.get_meta("visual_scale",1.0)) * YardGround.depth_at(sheep.position.y)), id+" observer facing without per-cel size change")
   check(sheep._ground_anchor == sheep._idle_ground_anchor, id+" preserves canonical foot anchor")
   check(sheep._sprite.to_global(sheep._sprite.offset + sheep._ground_anchor - sheep._sprite.texture.get_size()*0.5).distance_to(sheep.global_position)<0.01,id+" mirrored rendered foot at world anchor")
   var left: float = sheep._ack_left
   world._interact_with_target("pet:"+id)
   check(sheep._ack_left == left,id+" repeat success does not extend pose")
   root.get_node("TuningStore").set_value("ui.reduced_motion",true)
   sheep.tick(0.1,Vector2(1280,720))
   check(sheep._sprite.texture.resource_path.ends_with(expected),id+" reduced motion retains readable cel")
   root.get_node("TuningStore").set_value("ui.reduced_motion",false)
   var snap: Dictionary = PhotoMoment.capture(world,{"id":"sheep_test", "owner":"sheep"})
   var found := false
   for item: Dictionary in snap.get("items",[]):
    if item.get("subject","") == id and str(item.get("texture",{}).get("path","")).ends_with(expected): found = true
   check(found,id+" photograph records actual response texture")
   check(not PhotoMoment.sanitize(snap).is_empty(),id+" response survives production sanitizer")
   var view := PhotoMoment.new()
   root.add_child(view); view.setup(snap)
   check(not view._snapshot.is_empty(),id+" response photograph reconstructs")
   view.free()
   for item: Dictionary in snap.get("items",[]):
    if item.get("subject","") == id: item["texture"]={"path":idle_path}
   check(not PhotoMoment.sanitize(snap).is_empty(),id+" historical idle texture remains readable")
   sheep.set_pose(sheep.position,sheep._base_scale,sheep.facing)
   check(sheep._ack_cel == "" and sheep._posture_id == "idle",id+" pose interruption restores idle")
   sheep.acknowledge_pet(Vector2.ZERO)
   check(sheep._ack_cel == "",id+" posed actor cannot acknowledge")
   sheep.posed = false; sheep.state = "wander"
  sheep._pet_ack_cooldown = 0
  sheep.acknowledge_pet(sheep.position+Vector2(30,0))
  for i in 140: sheep.tick(1.0/60.0,Vector2(1280,720))
  check(sheep._ack_cel == "",id+" bounded pose expires")
 world.free()
 print("SHEEP ATTENTION ", "PASS" if failures.is_empty() else "FAIL", " ", checks)
 quit(0 if failures.is_empty() else 1)
