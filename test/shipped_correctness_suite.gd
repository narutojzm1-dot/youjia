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
 main.set_process(false);await main._start_holiday()
 var w = main._world
 for i in 600: w.tick(1.0/60, Vector2.ZERO)
 var elapsed: float = w._day_elapsed
 check(elapsed > 9.9, "fixture advances partial holiday day")
 main._show_title();await process_frame
 check(is_equal_approx(store.get_holiday_day_elapsed(), elapsed), "title flushes partial day")
 store._load()
 check(is_equal_approx(store.get_holiday_day_elapsed(), elapsed), "partial day survives disk reload")
 await main._start_holiday()
 check(is_equal_approx(main._world._day_elapsed, elapsed), "resume restores partial day")
 main._world.tick(2.0, Vector2.ZERO)
 elapsed = main._world._day_elapsed
 await main._start_holiday();await process_frame
 check(is_equal_approx(main._world._day_elapsed, elapsed), "restart flushes before rebuilding world")
 check(main._world.holiday_day == 1, "flush does not advance holiday day")
 check(main._world._plant_visual.position == main._world._plant_point(), "plant node uses its actual world position")
 check(main._world._fishing_visual.position == main._world._fishing_point(), "fishing node uses its actual world position")
 check(main._world._plant_visual.get_parent() == main._world and main._world._fishing_visual.get_parent() == main._world, "world props own independent draw transforms")
 main._show_title();root.get_node("AudioDirector").call("release_streams")
 print("[shipped-correctness] ", checks, " checks ", failures)
 quit(0 if failures.is_empty() else 1)
