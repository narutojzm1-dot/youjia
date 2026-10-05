extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
 checks += 1
 if not ok:
  failures.append(label)
  push_error(label)
func run():
 var store = root.get_node("SaveStore")
 store._data = store._default_data()
 var main = load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 await process_frame
 main.set_process(false)
 await main._start_holiday()
 var world = main._world
 world.set_process(false)
 world.actor_named("sheep_a").position = Vector2(230, 420)
 world.actor_named("sheep_b").position = Vector2(340, 450)
 var rule = ExpressionCatalog.find_rule("sheep_pet_gentle")
 var photo: Dictionary = PhotoMoment.capture(world, rule)
 check(not photo.is_empty(), "production sheep sprites produce a valid snapshot")
 var frame: Rect2 = PhotoMoment._event_frame(rule, world._actors, photo.items)
 check(frame.position != Vector2(630, 470), "species owner does not use generic no-subject frame")
 var view = Rect2(frame.position - frame.size * 0.5, frame.size)
 for id in ["sheep_a", "sheep_b"]:
  var recorded := false
  for item: Dictionary in photo.items:
   if item.kind == "sprite" and item.subject == id:
    recorded = true
    var texture = PhotoMoment._load_texture(item.texture)
    var extent: Vector2 = texture.get_size() / Vector2(item.frames[0], item.frames[1])
    var origin = Vector2(item.offset[0], item.offset[1]) - (extent * 0.5 if item.centered else Vector2.ZERO)
    var m: Array = item.transform
    var transform = Transform2D(Vector2(m[0],m[1]),Vector2(m[2],m[3]),Vector2(m[4],m[5]))
    check(view.encloses(transform * Rect2(origin, extent)), "recorded %s body is inside event frame" % id)
  check(recorded, "snapshot contains %s" % id)
 var before = photo.duplicate(true)
 PhotoMoment._event_frame(rule, world._actors, photo.items)
 check(photo == before, "framing does not mutate historical snapshot data")
 var missing: Rect2 = PhotoMoment._event_frame({"id":"unknown", "owner":"missing"},world._actors,photo.items)
 check(missing.position == Vector2(630,470), "truly missing owners preserve fallback")
 var cow: Rect2 = PhotoMoment._event_frame(ExpressionCatalog.find_rule("cow_pet_gentle"),world._actors,photo.items)
 check(cow.position != Vector2(630,470), "single-ID cow framing remains anchored to cow")
 main.queue_free()
 await process_frame
 print("PHOTO_SPECIES_FRAME checks=",checks," failures=",failures.size())
 quit(0 if failures.is_empty() else 1)
