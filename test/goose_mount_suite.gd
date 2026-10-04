extends SceneTree

# Exercise the real event, input entry points and saved scene, without force_rule.
const EVENT := "goose_horse_mount"
var checks := 0
var failures: Array[String] = []
var main: Control
var store: Node

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func fresh():
	store._data = store._default_data()
	main._start_holiday()
	var w = main._world
	w._day_elapsed = 46.0
	w._weather_timer = 10000.0
	w._pulse = -10000.0
	w.debug_place_actor("horse", Vector2(620, 480))
	w.debug_place_actor("goose", Vector2(745, 505))
	w.debug_place_player(Vector2(695, 510))
	for id in w._actors:
		var actor = w.actor_named(id)
		actor.state = "graze"
		actor._idle_time = 10000.0
		actor._velocity = Vector2.ZERO
	return w

func advance(w, seconds: float) -> void:
	for i in ceili(seconds * 60.0):
		w.tick(1.0 / 60.0, Vector2.ZERO)

func close_up(w) -> void:
	var goose_scale: float = w.actor_named("goose")._base_scale
	var horse_scale: float = w.actor_named("horse")._base_scale
	advance(w, 3.6)
	check(main._cam_target_zoom == 1.0, "wide observation keeps normal camera scale")
	advance(w, 1.3)
	check(main._cam_target_zoom == 1.0, "first person observation keeps normal camera scale")
	advance(w, 1.4)
	check(main._cam_target_zoom == 1.0, "mounted encounter keeps normal camera scale")
	check(w._goose_mount_phase == 2, "a genuine nearby observation reaches close-up")
	check(not w.get_player().visible, "traveler is behind the camera at close-up")
	check(is_equal_approx(w.actor_named("goose")._base_scale, goose_scale) and is_equal_approx(w.actor_named("horse")._base_scale, horse_scale), "close-up preserves measured painted sizes instead of inflating PNG canvases")
	check(w.actor_named("goose").z_index > w.actor_named("horse").z_index, "mounted goose is drawn above the horse's painted body")

func has_subject(moment: Dictionary, id: String) -> bool:
	for item: Dictionary in moment.get("items", []):
		if item.get("kind", "") == "sprite" and item.get("subject", "") == id:
			return true
	return false

func same_saved_value(a: Variant, b: Variant) -> bool:
	# JSON numbers can change int/float type and lose sub-ULP precision on disk.
	if (a is float or a is int) and (b is float or b is int):
		return absf(float(a) - float(b)) < 0.00001
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size(): return false
		for key in a:
			if not b.has(key) or not same_saved_value(a[key], b[key]): return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size(): return false
		for i in a.size():
			if not same_saved_value(a[i], b[i]): return false
		return true
	return a == b

func restored(w, label: String) -> void:
	check(w._goose_mount_phase == -1 and w.get_player().visible, label + " restores player and event state")
	check(not w.actor_named("goose").posed and not w.actor_named("horse").posed, label + " releases both animals")
	check(YardGround.allows(w.actor_named("goose").position, w.actor_named("goose").walk_ground, w.actor_named("goose").avoid_pond), label + " returns goose to walkable ground")
	check(main._cam_target_zoom == 1.0 and main._cinematic_top_bar.color.a == 0.0, label + " releases focus and black bars")
	check(EVENT not in w.collected and EVENT not in store.get_album(), label + " never creates a photo")

func run() -> void:
	seed(14003)
	root.size = Vector2i(1280, 720)
	store = root.get_node("SaveStore")
	root.get_node("TuningStore").call("reset_defaults")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	var w = fresh()
	w._day_elapsed = 0.0
	w._evaluate_expressions()
	check(EVENT not in w.collected and EVENT not in store.get_album(), "ordinary expression scanning never fabricates the mounted event")

	w = fresh()
	w._day_elapsed = 0.0
	advance(w, 4.0)
	check(w._goose_mount_phase == -1, "arrival grace period does not trigger a cinematic")
	w._day_elapsed = 46.0
	w._fish_state = w.FISH_CASTING
	w._fish_timer = 10000.0
	advance(w, 4.0)
	check(w._goose_mount_phase == -1, "fishing is never interrupted by observation")
	w = fresh()
	w.get_player().pick_grass()
	advance(w, 4.0)
	check(w._goose_mount_phase == -1, "carrying grass reserves the player's interaction")
	w = fresh()
	w._fish_carry_type = "small"
	w._fish_carry_timer = 20.0
	advance(w, 4.0)
	check(w._goose_mount_phase == -1, "carrying fish reserves the feeding interaction")

	w = fresh()
	close_up(w)
	w.tick(1.0 / 60.0, Vector2.LEFT)
	restored(w, "keyboard interruption")
	w = fresh()
	close_up(w)
	w.request_pointer_action(w.get_player().position)
	restored(w, "tap at own feet")
	w = fresh()
	advance(w, 3.7)
	check(w._goose_mount_phase == 0, "observation first enters the wide shot")
	w.tick(1.0 / 60.0, Vector2.LEFT)
	restored(w, "wide-shot interruption")
	w = fresh()
	close_up(w)
	w.request_primary_action()
	restored(w, "keyboard/HUD primary command")
	w = fresh()
	close_up(w)
	w.debug_place_player(w.actor_named("horse").position + Vector2(-45, 15))
	w.request_pointer_action(w.actor_named("horse").visual_hit_rect().get_center())
	restored(w, "nearby pet command")
	w = fresh()
	close_up(w)
	main._show_album()
	restored(w, "opening album")
	main._hide_album()
	w = fresh()
	close_up(w)
	main._toggle_pause()
	restored(w, "pause")
	main._toggle_pause()

	w = fresh()
	var goose_scale: float = w.actor_named("goose")._base_scale
	var horse_scale: float = w.actor_named("horse")._base_scale
	advance(w, 10.0)
	var moment: Dictionary = store.get_photo_moment(EVENT)
	check(EVENT in store.get_album() and not moment.is_empty(), "completed encounter persists a genuine scene")
	check(has_subject(moment, "goose") and has_subject(moment, "horse"), "saved photograph contains both actual painted subjects")
	check(moment.get("day", 0) == w.holiday_day, "saved event retains actual vacation day")
	check(w.get_player().visible and w._goose_mount_phase == -1, "completion restores the traveler")
	check(is_equal_approx(w.actor_named("goose")._base_scale, goose_scale) and is_equal_approx(w.actor_named("horse")._base_scale, horse_scale), "completion preserves both original painted scales")
	check(YardGround.allows(w.actor_named("goose").position, w.actor_named("goose").walk_ground, w.actor_named("goose").avoid_pond), "completion returns goose to grass instead of leaving it floating above horse")
	var caption := PhotoDiary.caption(moment)
	store._load()
	check(same_saved_value(store.get_photo_moment(EVENT), moment) and PhotoDiary.caption(store.get_photo_moment(EVENT)) == caption, "real disk reload preserves pose, date and stable caption")
	main._start_holiday()
	w = main._world
	w._day_elapsed = 46.0
	w.debug_place_actor("horse", Vector2(620, 480))
	w.debug_place_actor("goose", Vector2(745, 505))
	w.debug_place_player(Vector2(695, 510))
	advance(w, 4.0)
	check(w._goose_mount_phase == -1, "reloaded recorded event does not replay")

	w = fresh()
	root.size = Vector2i(390, 844)
	main._layout()
	root.get_node("TuningStore").call("set_value", "ui.reduced_motion", true)
	advance(w, 8.0)
	check(EVENT in store.get_album() and w._goose_mount_phase == -1, "reduced motion completes with a real still photograph")
	root.get_node("AudioDirector").call("release_streams")
	print("[goose-mount] ", "PASS" if failures.is_empty() else "FAIL", ": ", checks, " checks ", failures)
	quit(0 if failures.is_empty() else 1)
