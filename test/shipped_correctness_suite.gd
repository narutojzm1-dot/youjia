extends SceneTree
var failures: Array[String] = []
var checks := 0
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
 checks += 1
 if not ok: failures.append(label);push_error(label)
func run():
 var store = root.get_node("SaveStore")
 store._data = store._default_data()
 var main = load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame;await process_frame
 main.set_process(false);main._start_holiday()
 var w = main._world
 for i in 600: w.tick(1.0/60, Vector2.ZERO)
 var elapsed: float = w._day_elapsed
 check(elapsed > 9.9, "fixture advances partial holiday day")
 main._show_title();await process_frame
 check(is_equal_approx(store.get_holiday_day_elapsed(), elapsed), "title flushes partial day")
 store._load()
 check(is_equal_approx(store.get_holiday_day_elapsed(), elapsed), "partial day survives disk reload")
 main._start_holiday()
 check(is_equal_approx(main._world._day_elapsed, elapsed), "resume restores partial day")
 main._world.tick(2.0, Vector2.ZERO)
 elapsed = main._world._day_elapsed
 main._start_holiday();await process_frame
 check(is_equal_approx(main._world._day_elapsed, elapsed), "restart flushes before rebuilding world")
 check(main._world.holiday_day == 1, "flush does not advance holiday day")
 var source := FileAccess.get_file_as_string("res://scripts/game/yard_world.gd")
 var draw_start := source.find("func _draw()")
 var shadow := source.find("_draw_contact_shadow(actor.position,extent)",draw_start)
 var reset := source.find("draw_set_transform(Vector2.ZERO)",shadow)
 var plant := source.find("_draw_plant_bed()",shadow)
 var fish := source.find("_draw_fishing_spot()",shadow)
 check(shadow >= 0 and reset > shadow and reset < plant and reset < fish, "world-coordinate props reset shadow transform before drawing")
 main._show_title();root.get_node("AudioDirector").call("release_streams")
 print("[shipped-correctness] ", checks, " checks ", failures)
 quit(0 if failures.is_empty() else 1)
