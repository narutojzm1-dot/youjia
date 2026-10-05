extends SceneTree

# Focused fixtures exercise overlapping action contexts and old photo records.
# Natural travel and viewport dispatch remain covered by the other suites.
var checks := 0
var failures: Array[String] = []
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
 checks += 1
 if not ok: failures.append(label); push_error(label)
func prop(snapshot: Dictionary, subject: String) -> Dictionary:
 for item: Dictionary in snapshot.get("items", []):
  if item.kind == "prop" and item.subject == subject: return item
 return {}
func run():
 seed(129)
 var world = load("res://scripts/game/yard_world.gd").new()
 root.add_child(world);world.setup()
 var player = world.get_player()
 # The painted balcony flowers are a background hotspot, not the walk goal.
 var box_action := YardInteraction.pointer(world, Vector2(285, 275))
 check(box_action.get("target", "") == "windowbox", "painted balcony flowers resolve to their own interaction target")
 check(YardGround.allows(box_action.get("point", Vector2.ZERO), YardGround.lawn(), true), "windowbox approach stays on the safe painted lawn")
 world.debug_place_player(world._fishing_point() + Vector2(0, 5))
 world.debug_place_actor("llama", Vector2(500,540))
 player.carrying_grass = true
 check(world.primary_action_key() == "action.feed", "carried grass has feed priority beside pond")
 world.try_interact()
 check(world._pending_interaction == "llama" and world._fish_state == world.FISH_IDLE, "Space feeds instead of casting beside pond")
 world.request_primary_action()
 check(world._pending_interaction == "llama", "HUD carries the same feed intent")
 player.carrying_grass = false
 world._leading = true; player.leading = true
 world.actor_named("llama").begin_lead(player)
 world.debug_place_player(world._plant_point() + Vector2(40, 0))
 check(world.primary_action_key() == "action.release", "leading has release priority at flowerbed")
 world.try_interact()
 check(not world._leading and not player.leading and world._plant_state == world.PLANT_EMPTY, "Space releases without planting")
 world._leading = true; player.leading = true
 world.request_primary_action()
 check(not world._leading and world._plant_state == world.PLANT_EMPTY, "HUD releases without planting")
 # Two sheep have distinct IDs: a distant click must retain its exact subject.
 var sheep = world.actor_named("sheep_b")
 var click = sheep.visual_hit_rect().get_center()
 check(YardInteraction.pointer(world, click).target == "pet:sheep_b", "pointer resolves the selected sheep silhouette")
 world.request_pointer_action(click)
 check(world._pending_interaction == "pet:sheep_b", "walk approach retains selected sheep ID")
 check(YardInteraction.primary(world).target == "pet:sheep_b", "Space and HUD retain the clicked sheep while approaching")
 check(world.action_target_key(YardInteraction.primary(world)) == "target.sheep_b", "HUD names the second sheep rather than a different nearby animal")
 world.try_interact()
 check(world._pending_interaction == "pet:sheep_b", "Space acts on the same clicked sheep during approach")
 world.request_primary_action()
 check(world._pending_interaction == "pet:sheep_b", "HUD button acts on the same clicked sheep during approach")
 world.tick(0.016, Vector2.ZERO)
 check(world._effects_overlay.pet_pos.distance_to(sheep.position) < 0.1 and world._effects_overlay.pet_alpha > 0.5, "orange marker follows the selected sheep even from a distance")
 world.request_pointer_action(Vector2(100,100))
 check(not world._has_walk_goal and world._pending_interaction.is_empty(), "invalid newer pointer cancels approach")
 check(YardInteraction.primary(world).target != "pet:sheep_b", "invalid tap clears the selected target as well as its route")
 world.request_pointer_action(world._fishing_point())
 check(YardInteraction.primary(world).target == "fishing" and world.primary_action_key() == "action.fish", "pond tap and Space/HUD agree on fishing during approach")
 world.request_pointer_action(Vector2(100,100))
 world.debug_place_player(world.actor_named("cow").position + Vector2(-50,20))
 world.tick(0.016, Vector2.ZERO)
 var overlay = world._effects_overlay
 check(overlay.pet_alpha > 0.5, "available pet action has a visible indicator")
 check(overlay.z_index > player.z_index, "indicator renders above the player")
 for id: String in world._actors:
  check(overlay.z_index > world.actor_named(id).z_index, "indicator renders above " + id)
 player.carrying_grass = true
 world.tick(0.016, Vector2.ZERO)
 check(overlay.pet_alpha == 0.0, "feed priority suppresses an unrelated pet indicator")
 player.carrying_grass = false
 # Real day transition blooms the plant, repairing an already earned legacy ID.
 var bloom_id = "plant_first_bloom"
 world.collected.append(bloom_id)
 world._plant_state = world.PLANT_SPROUTING
 world._plant_day_planted = 1;world._plant_watered_day = 1;world.holiday_day = 4
 world._on_new_day()
 var bloom = world.photo_moments.get(bloom_id, {})
 var flower = prop(bloom, "plant")
 check(not flower.is_empty() and flower.state.plant_state == world.PLANT_BLOOMED, "old earned bloom receives actual flowers on next bloom")
 check(world.collected.count(bloom_id) == 1, "repair preserves collected IDs without duplicating rewards")
 var record = JSON.stringify(bloom)
 world._plant_state = world.PLANT_EMPTY;world.tick(1.0, Vector2.ZERO)
 check(JSON.stringify(bloom) == record, "live harvest cannot change the recorded flower state")
 check(not PhotoMoment.sanitize(JSON.parse_string(record)).is_empty(), "flower photograph survives JSON reload")
 var bad = bloom.duplicate(true)
 for item: Dictionary in bad.items:
  if item.kind == "prop" and item.subject == "plant": item.state.plant_state = 999
 check(PhotoMoment.sanitize(bad).is_empty(), "out-of-range prop state rejects the photograph")
 # A subsequent real reel repairs a legacy fish snapshot and freezes the catch.
 var fish_id = "fish_first_catch"
 world._first_fish_polaroid_done = true;world.collected.append(fish_id)
 world.debug_place_player(world._fishing_point() + Vector2(0,30))
 world._fish_state = world.FISH_BITE
 world._reel_in_fish()
 var catch_photo = world.photo_moments.get(fish_id,{})
 var fish = prop(catch_photo, "fishing")
 check(not fish.is_empty() and fish.state.fish_state == world.FISH_CAUGHT, "old earned catch receives the actual caught-fish visual")
 check(not fish.is_empty() and fish.state.fish_type == world._fish_carry_type, "photograph records the caught fish type")
 var catch_record = JSON.stringify(catch_photo)
 world.tick(4.0, Vector2.ZERO)
 check(JSON.stringify(catch_photo) == catch_record, "celebration expiry cannot change the photograph")
 var album = PhotoMoment.new();root.add_child(album);album.setup(catch_photo)
 var found := false
 for child in album._stage.get_children():
  if child is YardPropVisual and child.subject == "fishing":
   found = child.state.fish_state == world.FISH_CAUGHT
 check(found, "album instantiates the same frozen fishing prop")
 # A fish can slip away while walking toward a bird. Cancel only that
 # impossible feed route, not an unrelated walk in progress.
 world.debug_place_player(Vector2(400, 540))
 world.debug_place_actor("goose", Vector2(700, 470))
 world._fish_carry_type = "small"
 world._fish_carry_timer = 0.01
 world.request_pointer_action(world.actor_named("goose").visual_hit_rect().get_center())
 check(world._pending_interaction == "toss_fish:goose" and world._has_walk_goal, "fish feed begins an approach toward the selected bird")
 world.tick(0.02, Vector2.ZERO)
 check(world._fish_carry_type.is_empty() and world._pending_interaction.is_empty() and not world._has_walk_goal and world._walk_path.is_empty(), "expired fish cancels its impossible feeding approach")
 check(YardInteraction.primary(world).target != "toss_fish:goose", "expired fish also removes the stale bird from the HUD and keyboard target")
 check(overlay.bird_feedback_snapshot().is_empty(), "fish expiry alone cannot create a success heart")
 world._fish_carry_type = "small"
 world._fish_carry_timer = 0.01
 world.request_pointer_action(Vector2(310, 535))
 check(world._pending_interaction.is_empty() and world._has_walk_goal, "ordinary walk starts while carrying fish")
 world.tick(0.02, Vector2.ZERO)
 check(world._fish_carry_type.is_empty() and world._has_walk_goal, "fish expiry preserves an unrelated walk")
 # A successful fish gift belongs to the bird that actually received it,
 # not a generic HUD toast or a different duck drifting nearby.
 world.debug_place_actor("duck_a", Vector2(690, 580))
 world.debug_place_actor("duck_b", Vector2(830, 590))
 world.debug_place_actor("duck_c", Vector2(850, 590))
 world.debug_place_actor("goose", Vector2(800, 470))
 world.debug_place_player(Vector2(690, 520))
 var duck = world.actor_named("duck_a")
 world._fish_carry_type = "small"; world._fish_carry_timer = 8.0
 var duck_hit = duck.visual_hit_rect().get_center()
 check(YardInteraction.pointer(world, duck_hit).target == "toss_fish:duck_a", "pointer resolves the particular duck to feed")
 var previous_photos = world.collected.duplicate()
 world.request_pointer_action(duck_hit)
 check(world._fish_carry_type.is_empty() and world._fish_carry_timer == 0.0, "a successful duck feed consumes exactly one carried fish")
 check(world.collected == previous_photos, "a fish gift does not change collected album entries")
 check(duck._posture_id == "attend", "a real duck feed creates recipient attention posture")
 if overlay.has_method("bird_feedback_snapshot"):
  check(overlay.bird_feedback_snapshot().is_empty() and duck._ack_left > 0.0 and world.actor_named("duck_b")._ack_cel != "attend", "duck recipient responds without default heart or another duck")
  duck.position += Vector2(13.0, 0.0)
  duck.tick(0.016, Vector2(1280,720))
  check(duck._ack_cel == "" and overlay.bird_feedback_snapshot().is_empty(), "moving duck cancels posture without a following heart")
  world.tick(2.0, Vector2.ZERO)
  check(overlay.bird_feedback_snapshot().is_empty(), "heart response ends without persisting in the game state")
  world._interact_with_target("toss_fish:duck_a")
  check(overlay.bird_feedback_snapshot().is_empty(), "no fish cannot trigger a success heart")
  var goose = world.actor_named("goose")
  world.debug_place_player(Vector2(350, 540))
  world._fish_carry_type = "small"; world._fish_carry_timer = 0.01
  world.request_pointer_action(goose.visual_hit_rect().get_center())
  check(overlay.bird_feedback_snapshot().is_empty() and world._fish_carry_type == "small", "approaching a bird does not celebrate before feeding succeeds")
  world.tick(0.02, Vector2.ZERO)
  check(overlay.bird_feedback_snapshot().is_empty() and world._fish_carry_type.is_empty(), "expired fish during approach cannot fake bird approval")
  world.debug_place_player(goose.position + Vector2(-45, 30))
  world._fish_carry_type = "medium"; world._fish_carry_timer = 8.0
  world.request_pointer_action(goose.visual_hit_rect().get_center())
  check(overlay.bird_feedback_snapshot().get("actor_id", "") == "goose", "goose feeding reacts on the goose, not an earlier duck")
  root.get_node("TuningStore").set_value("ui.reduced_motion", true)
  check(bool(overlay.bird_feedback_snapshot().get("reduced_motion", false)), "reduced-motion feed keeps a readable still reaction")
  root.get_node("TuningStore").set_value("ui.reduced_motion", false)
 # Petting must be acknowledged by the actual touched animal, not a generic
 # toast or a different sheep that the player happened to walk past.
 world.debug_place_actor("cow", Vector2(530, 490))
 world.debug_place_actor("sheep_b", Vector2(360, 500))
 world.debug_place_player(Vector2(300, 535))
 world._interact_with_target("pet:cow")
 check(overlay.pet_feedback_snapshot().is_empty(), "distant pet cannot create a success heart")
 for eligible: String in ["cow", "sheep_b", "horse"]:
  var animal = world.actor_named(eligible)
  world.debug_place_actor(eligible, Vector2(570, 470))
  world.debug_place_player(Vector2(520, 485))
  world._interact_with_target("pet:" + eligible)
  check(animal.facing == -1.0, "pet faces the nearby player: " + eligible)
  check(animal._posture_id == ("glance" if eligible == "cow" else "idle"), "pet avoids mismatched tail/shake sizes: " + eligible)
  check(animal._ack_left > 0.0, "a successful pet acknowledges the selected " + eligible)
  check(overlay.pet_feedback_snapshot().is_empty(), "pet uses posture without a default heart: " + eligible)
  animal.tick(0.5, Vector2(1280, 720))
  var remaining: float = animal._ack_left
  world._interact_with_target("pet:" + eligible)
  check(is_equal_approx(animal._ack_left, remaining), "repeat input does not extend the pose: " + eligible)
  root.get_node("TuningStore").set_value("ui.reduced_motion", true)
  check(animal._ack_cel != "", "low motion retains a readable posture: " + eligible)
  root.get_node("TuningStore").set_value("ui.reduced_motion", false)
  for _frame in 150:
   animal.tick(1.0 / 60.0, Vector2(1280, 720))
   world._interact_with_target("pet:" + eligible)
  check(animal._ack_left == 0.0, "continuous petting releases the animal: " + eligible)
  for _frame in 150:
   animal.tick(1.0 / 60.0, Vector2(1280, 720))
  world.debug_place_player(animal.position + Vector2(30, 0))
  world._interact_with_target("pet:" + eligible)
  check(animal._ack_left > 0.0, "later pet can respond again: " + eligible)
 # A scheduled wandering turn must not override an active acknowledgement.
 var horse = world.actor_named("horse")
 horse._pet_ack_cooldown = 0.0
 horse.state = "wander"
 horse.daily_routine = true
 horse._turn_pause = 0.55
 horse._target = horse.position + Vector2(100, 0)
 world.debug_place_player(horse.position + Vector2(-30, 0))
 world._interact_with_target("pet:horse")
 horse.tick(0.1, Vector2(1280, 720))
 check(horse.facing == -1.0 and horse._ack_left > 0.0, "scheduled turn cannot face away during pet response")
 check(is_equal_approx(horse._turn_pause, 0.55), "pet response preserves scheduled turn time")
 for _frame in 140:
  horse.tick(1.0 / 60.0, Vector2(1280, 720))
 check(horse.facing == 1.0 and horse._turn_pause < 0.55, "scheduled turn resumes after acknowledgement")
 # Watering is meaningful once per day. A repeated attempt must not counterfeit
 # a success effect or alter the recorded planted/watered day.
 world.debug_place_player(Vector2(700, 540))
 world._plant_state = world.PLANT_PLANTED
 world._plant_watered_day = -1
 check(overlay.has_method("plant_feedback_snapshot"), "watering has an inspectable plant-bed visual response")
 if overlay.has_method("plant_feedback_snapshot"):
  world._interact_plant()
  check(world._plant_watered_day == -1 and overlay.plant_feedback_snapshot().is_empty(), "distant flowerbed cannot falsely celebrate watering")
  world.debug_place_player(world._plant_point() + Vector2(-38, 10))
  world._interact_plant()
  check(world._plant_watered_day == world.holiday_day and overlay.plant_feedback_snapshot().get("position", Vector2.INF) == world._plant_point(), "first real watering reacts at the flower bed")
  world.tick(2.0, Vector2.ZERO)
  check(overlay.plant_feedback_snapshot().is_empty(), "watercolor splash ends without entering saved plant state")
  world._interact_plant()
  check(overlay.plant_feedback_snapshot().is_empty(), "already-watered flowerbed cannot replay the success splash")
  world.holiday_day += 1
  world._plant_state = world.PLANT_SPROUTING
  world._interact_plant()
  check(overlay.plant_feedback_snapshot().get("position", Vector2.INF) == world._plant_point(), "new day real sprout watering also acknowledges the bed")
 var still_plant := YardPropVisual.pose_motion("plant", 1.4, true)
 var live_plant := YardPropVisual.pose_motion("plant", 1.4, false)
 check(float(still_plant.lean) == 0.0 and float(still_plant.sway) == 0.0 and is_equal_approx(float(still_plant.bloom_alpha), 0.42) and bool(still_plant.harvest_still), "reduced motion holds the flowerbed still and readable")
 check(absf(float(live_plant.lean)) > 0.2 and absf(float(live_plant.sway)) > 0.2 and not bool(live_plant.harvest_still), "ordinary flowerbed still sways")
 var still_fish := YardPropVisual.pose_motion("fishing", 0.4, true)
 var live_bite_a := YardPropVisual.pose_motion("fishing", 0.0, false)
 var live_bite_b := YardPropVisual.pose_motion("fishing", 0.3, false)
 check(int(still_fish.ripple_count) == 1 and is_equal_approx(float(still_fish.bite_alpha), 0.42), "reduced motion keeps one still ripple and a steady bite halo")
 check(int(live_bite_a.ripple_count) == 3 and not is_equal_approx(float(live_bite_a.bite_alpha), float(live_bite_b.bite_alpha)), "ordinary water and bite halo keep moving")
 test_motion_snapshots(world)
 album.free();world.free()
 root.get_node("AudioDirector").call("release_streams")
 print("[interaction-photo-tests] %d checks, failures=%s" % [checks, failures])
 quit(0 if failures.is_empty() else 1)

func test_motion_snapshots(world) -> void:
 var tuning := root.get_node("TuningStore")
 var moment_script = load("res://scripts/ui/photo_moment.gd")
 world._plant_state = world.PLANT_BLOOMED
 world._fish_state = world.FISH_BITE
 world._day_seconds = 1.4
 for reduced: bool in [false, true]:
  tuning.set_value("ui.reduced_motion", reduced, false)
  world._refresh_prop_visuals()
  check(world._plant_visual._reduced() == reduced and world._fishing_visual._reduced() == reduced, "live prop state follows current preference")
  var captured: Dictionary = moment_script.capture(world, ExpressionCatalog.find_rule("plant_first_bloom"))
  var saved: Dictionary = moment_script.sanitize(JSON.parse_string(JSON.stringify(captured)))
  check(prop(saved, "plant").get("state", {}).get("reduced_motion") == reduced and prop(saved, "fishing").get("state", {}).get("reduced_motion") == reduced, "actual photo retains both captured prop preferences across JSON")
  tuning.set_value("ui.reduced_motion", not reduced, false)
  world._refresh_prop_visuals()
  var card = moment_script.new()
  root.add_child(card)
  card.setup(saved)
  var found := 0
  for node in card._stage.get_children():
   if node is YardPropVisual:
    found += 1
    check(node._reduced() == reduced and is_equal_approx(float(node.state.phase), 1.4), "reopened real photo ignores later settings and preserves phase")
  check(found == 2, "photo reconstructs both static props")
  card.free()
  var legacy: Dictionary = saved.duplicate(true)
  for item: Dictionary in legacy.items:
   if item.kind == "prop": item.state.erase("reduced_motion")
  tuning.set_value("ui.reduced_motion", true, false)
  card = moment_script.new()
  root.add_child(card)
  card.setup(moment_script.sanitize(legacy))
  for node in card._stage.get_children():
   if node is YardPropVisual: check(not node._reduced(), "legacy prop photo retains its original ordinary pose")
  card.free()
 var malformed := {"nearby": true, "phase": 1.4, "plant_state": 3, "soil_reveal": 1.0, "harvest_flash": 0.0, "reduced_motion": "yes"}
 check(YardPropVisual.sanitize_state("plant", malformed).is_empty(), "invalid captured preference is rejected")
 tuning.set_value("ui.reduced_motion", false, false)
