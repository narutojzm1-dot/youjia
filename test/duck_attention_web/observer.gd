extends Node
# Test-only readback: observes the real Main/YardWorld without writes or callbacks.
func _process(_delta: float) -> void:
 if not OS.has_feature("web"): return
 var main = get_tree().root.get_node_or_null("Main")
 if main == null: return
 if main._world == null:
  if main._play_button != null:
   var play: Vector2 = main._play_button.get_global_rect().get_center()
   JavaScriptBridge.eval("window.duckTitle="+JSON.stringify([play.x,play.y]),true)
  return
 var world = main._world
 var ducks := []
 for id in ["duck_a","duck_b","duck_c"]:
  var actor = world.actor_named(id)
  var hit: Vector2 = world.get_global_transform_with_canvas() * actor.visual_hit_rect().get_center()
  var feet: Vector2 = actor._sprite.to_global(actor._sprite.offset+actor._ground_anchor-actor._sprite.texture.get_size()*0.5)
  ducks.append({"id":id,"posture":actor._posture_id,"texture":actor._sprite.texture.resource_path,"posed":actor.posed,"facing":actor.facing,"ack_left":actor._ack_left,"cooldown":actor._feed_ack_cooldown,"foot_error":feet.distance_to(actor.global_position),"click":[hit.x,hit.y]})
 var pond: Vector2 = world.get_global_transform_with_canvas() * world._fishing_point()
 var value := {"ducks":ducks,"fish_state":world._fish_state,"carry":world._fish_carry_type,"pond":[pond.x,pond.y],"heart":world._effects_overlay.bird_feedback_snapshot(),"viewport":[get_viewport().get_visible_rect().size.x,get_viewport().get_visible_rect().size.y]}
 JavaScriptBridge.eval("window.duckReadback="+JSON.stringify(value),true)
