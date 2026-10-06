extends SceneTree

# Controlled Main/World integration fixture, not ordinary browser evidence.
# Also runs against the old production scripts: coverage assertions must fail
# there, without depending on any newly added helper/property being present.
const STEP := 1.0 / 60.0
const EPS := 0.08
var checks := 0
var failed_checks := 0
var failures: Array[String] = []
var main
var store: Node
var tuning: Node
var case_name := ""
var focus_events: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if ok:
		return
	failed_checks += 1
	var message := case_name + ": " + label
	if not failures.has(message):
		failures.append(message)
		push_error(message)


func settle_layout() -> void:
	await process_frame
	await process_frame


func record_focus(at: Vector2, zoom: float) -> void:
	focus_events.append({"phase": main._world._goose_mount_phase, "quiet": main._world._quiet_sky_active, "point": at, "zoom": zoom})


func fresh(dims: Vector2i, reduced: bool):
	root.size = dims
	await settle_layout()
	store._data = store._default_data()
	await main._start_holiday(false)
	tuning.set_value("ui.reduced_motion", reduced)
	var w = main._world
	w._day_elapsed = 0.0
	w._weather_timer = 10000.0
	w._pulse = -10000.0
	w.debug_place_actor("horse", Vector2(620, 480))
	w.debug_place_actor("goose", Vector2(745, 505))
	w.debug_place_player(Vector2(695, 510))
	for actor_id in w._actors:
		var actor = w.actor_named(actor_id)
		actor.state = "graze"
		actor._idle_time = 10000.0
		actor._velocity = Vector2.ZERO
	focus_events.clear()
	w.camera_focus_requested.connect(record_focus)
	main._process(0.0)
	check(main.size.is_equal_approx(Vector2(dims)), "Main uses the resized real viewport")
	return w


func tick(moving := false) -> void:
	if moving:
		Input.action_press("move_right")
	main._process(STEP)
	Input.action_release("move_right")
	main._camera.force_update_scroll()


# Oracle describes the existing unfocused composition, not the new clamp.
func baseline_position() -> Vector2:
	var dims: Vector2 = main.size
	var zoom: float = main._camera.zoom.x
	var hud := 140.0 if dims.x < 700.0 else 76.0
	var center := Vector2(640, 360)
	var follow: Vector2 = (main._world.get_player().position - center) * 0.08
	if dims.x < 700.0 and dims.y > dims.x:
		center.x = main._portrait_camera_x
		follow = Vector2.ZERO
	return center + follow + Vector2(0, hud / (2.0 * zoom))


func actual_art_rect() -> Rect2:
	var w = main._world
	return w.transform * (w._backdrop.transform * w._backdrop.get_rect())


func assert_frame_coverage() -> void:
	var dims: Vector2 = main.size
	var z: float = main._camera.zoom.x
	var art := actual_art_rect()
	var hud := 140.0 if dims.x < 700.0 else 76.0
	var reference := Rect2((art.position - baseline_position()) * z + dims * 0.5, art.size * z)
	var needed := reference.intersection(Rect2(Vector2.ZERO, Vector2(dims.x, maxf(0.0, dims.y - hud))))
	var actual := Rect2((art.position - main._camera.position) * z + dims * 0.5, art.size * z)
	check(actual.grow(EPS).encloses(needed), "real camera introduces no paper outside baseline coverage")
	check(is_equal_approx(main._cam_zoom, 1.0) and is_equal_approx(main._cam_target_zoom, 1.0), "quiet never adds magnification")
	# Real Camera2D canvas update and unchanged Main inverse input mapping.
	var p: Vector2 = main._world.get_player().position
	var projected: Vector2 = (p - main._camera.position) * z + dims * 0.5
	check((root.get_canvas_transform() * p).distance_to(projected) < EPS, "real canvas transform follows the bounded camera")
	check(main._screen_to_world(projected).distance_to(p) < EPS / z, "screen input maps back to the actual resident world point")


func advance_covered(count: int, moving := false) -> void:
	for _i in count:
		tick(moving)
		assert_frame_coverage()


func trace(stage: String) -> void:
	print("CAMERA400_BOUNDS_TRACE ", JSON.stringify({"case": case_name, "stage": stage, "viewport": str(main.size), "position": str(main._camera.position), "offset": str(main._cam_offset), "target": str(main._cam_target_offset), "zoom": str(main._camera.zoom), "quiet": main._world._quiet_sky_active, "phase": main._world._goose_mount_phase}))


func begin_quiet(w, frames := 350) -> void:
	advance_covered(frames)
	check(w._quiet_sky_active and w._focus_seconds > 0.0, "quiet begins by real idle ticks before day-45 encounter eligibility")
	check(w._day_elapsed < 45.0 and focus_events.size() == 1 and focus_events[0]["phase"] < 0, "one natural quiet request in controlled day-zero fixture")
	var expected_target_y := -150.0 if main.size.x < 700.0 and main.size.y > main.size.x else -52.5
	check(is_equal_approx(main._cam_target_offset.y, expected_target_y) and main._cam_offset.length() > 1.0, "original upward intention and interpolation remain present")
	trace("quiet_started")


func accessor_and_projection_edges(w) -> void:
	# Old production intentionally skips new API-only cases. Its red evidence
	# comes from the same real Main frame assertions above, not missing methods.
	if not w.has_method("get_backdrop_bounds") or not main.has_method("_bound_quiet_camera"):
		print("CAMERA400_BOUNDS_API_CASES unavailable in old production; real-frame checks still execute")
		return
	var sprite: Sprite2D = w._backdrop
	var old_position := sprite.position
	var old_scale := sprite.scale
	var old_offset := sprite.offset
	var old_centered := sprite.centered
	var old_world: Vector2 = w.position
	w.position = Vector2(17, 9)
	sprite.centered = true
	sprite.offset = Vector2(23, -11)
	sprite.position = Vector2(31, 18)
	sprite.scale = Vector2(0.5, 0.7)
	var rect := sprite.get_rect()
	var tl: Vector2 = w.position + sprite.position + rect.position * sprite.scale
	var expected := Rect2(tl, rect.size * sprite.scale)
	check(w.get_backdrop_bounds().is_equal_approx(expected), "painted bounds include parent position, sprite center/offset/scale")
	w.position = old_world
	sprite.position = old_position
	sprite.scale = old_scale
	sprite.offset = old_offset
	sprite.centered = old_centered
	var art := actual_art_rect()
	var baseline := baseline_position()
	var request := baseline + Vector2(-300, -300)
	for z in [0.5, 0.98, 1.4]:
		var result: Vector2 = main._bound_quiet_camera(request, baseline, art, Vector2(390, 844), z, 140.0)
		var needed := Rect2((art.position - baseline) * z + Vector2(195, 422), art.size * z).intersection(Rect2(0, 0, 390, 704))
		var actual := Rect2((art.position - result) * z + Vector2(195, 422), art.size * z)
		check(actual.grow(EPS).encloses(needed), "pure projection preserves coverage with legal zoom %s" % z)
	check(main._bound_quiet_camera(request, baseline, Rect2(), Vector2(390, 844), 1.0, 140.0) == baseline, "missing art keeps baseline")
	check(main._bound_quiet_camera(request, baseline, Rect2(0, 0, -20, 20), Vector2(390, 844), 1.0, 140.0) == baseline, "invalid art keeps baseline")
	check(main._bound_quiet_camera(request, baseline, art, Vector2(390, 844), 0.0, 140.0) == baseline, "invalid zoom keeps baseline")
	check(main._bound_quiet_camera(request, baseline, art, Vector2(390, 100), 1.0, 140.0) == baseline, "no playable area keeps baseline")
	var old_texture := sprite.texture
	sprite.texture = null
	check(not w.get_backdrop_bounds().has_area(), "missing backdrop has explicit empty bounds")
	sprite.texture = old_texture


func run() -> void:
	var data := OS.get_environment("XDG_DATA_HOME")
	if data.is_empty() or OS.get_environment("YOUJIA_TEST_ISOLATED_DATA") != data:
		push_error("camera400 backdrop requires isolated XDG_DATA_HOME")
		quit(2)
		return
	seed(14004)
	store = root.get_node("SaveStore")
	tuning = root.get_node("TuningStore")
	tuning.reset_defaults()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await settle_layout()
	main.set_process(false)
	for reduced: bool in [false, true]:
		for dims: Vector2i in [Vector2i(390, 844), Vector2i(360, 640), Vector2i(568, 320), Vector2i(1280, 720)]:
			case_name = "idle_move/%s/reduced=%s" % [dims, reduced]
			var w = await fresh(dims, reduced)
			begin_quiet(w)
			w.weather = "overcast"
			w._apply_weather_art()
			advance_covered(20)
			check(actual_art_rect().is_equal_approx(Rect2(0, 0, 1280, 720)), "overcast uses the same painted bounds")
			advance_covered(240, true)
			check(not w._quiet_sky_active and main._cam_target_offset.is_zero_approx() and main._cam_offset.length() < 0.01, "ordinary movement releases and settles the retained intention")
			trace("returned")
		for edge_x in [90.0, 1190.0]:
			case_name = "world_edge/%s/reduced=%s" % [edge_x, reduced]
			var edge_world = await fresh(Vector2i(390, 844), reduced)
			edge_world.debug_place_player(Vector2(edge_x, 510))
			begin_quiet(edge_world)
			advance_covered(240, true)
		case_name = "natural_expiry_and_resize/reduced=%s" % reduced
		var w = await fresh(Vector2i(390, 844), reduced)
		begin_quiet(w)
		for dims: Vector2i in [Vector2i(568, 320), Vector2i(390, 844), Vector2i(1280, 720), Vector2i(360, 640)]:
			root.size = dims
			await settle_layout()
			advance_covered(1)
			check(w._quiet_sky_active, "live resize preserves quiet ownership")
		advance_covered(490)
		check(not w._quiet_sky_active and main._cam_target_offset.is_zero_approx() and main._cam_offset.length() < 0.01, "natural hold and return finish before cooldown can restart quiet")
		trace("natural_expiry")
		accessor_and_projection_edges(w)
		if main.get_property_list().any(func(property: Dictionary) -> bool: return property["name"] == "_cam_effective_offset"):
			case_name = "new_holiday_resets_camera_source/reduced=%s" % reduced
			w = await fresh(Vector2i(1280, 720), reduced)
			begin_quiet(w)
			check(main._cam_quiet_bounds and main._cam_effective_offset.length() > 1.0, "previous world actually has quiet ownership and visible displacement")
			await main._start_holiday(false)
			check(not main._cam_quiet_bounds and main._cam_effective_offset.is_zero_approx(), "new holiday synchronously clears both new camera fields")
			check(main._cam_offset.is_zero_approx() and main._cam_target_offset.is_zero_approx(), "new holiday retains the original camera reset")
			tick()
			assert_frame_coverage()
		for resize_at_takeover: bool in [false, true]:
			case_name = "real_goose_takeover/reduced=%s/resize=%s" % [reduced, resize_at_takeover]
			w = await fresh(Vector2i(390, 844), reduced)
			begin_quiet(w, 336)
			w._day_elapsed = 46.0 # Explicit eligibility fixture, not ordinary play.
			tick()
			for _i in 240:
				if w._goose_mount_wait + STEP >= 3.5 or w._goose_mount_phase >= 0:
					break
				tick()
			check(w._goose_mount_phase == -1 and w._quiet_sky_active and w._focus_seconds > 0.0, "quiet truly still owns the hold one tick before real takeover")
			var effective_before: Vector2 = main._camera.position - baseline_position()
			var camera_before: Vector2 = main._camera.position
			var canvas_before: Transform2D = root.get_canvas_transform()
			trace("last_quiet_frame")
			if resize_at_takeover:
				root.size = Vector2i(568, 320)
				await settle_layout()
			tick()
			var follow_rate := 12.0 if reduced else 3.0
			var expected_first: Vector2 = baseline_position() + effective_before.lerp(main._cam_target_offset, 1.0 - exp(-STEP * follow_rate))
			check(main._camera.position.distance_to(expected_first) < EPS, "new focus starts from last visible displacement without revealing hidden quiet offset")
			print("CAMERA400_TAKEOVER_CONTINUITY ", JSON.stringify({"case": case_name, "before_camera": str(camera_before), "before_canvas": str(canvas_before), "effective_before": str(effective_before), "after_camera": str(main._camera.position), "after_canvas": str(root.get_canvas_transform()), "expected_first": str(expected_first), "new_target": str(main._cam_target_offset)}))
			trace("first_encounter_frame")
			check(w._goose_mount_phase == 0 and not w._quiet_sky_active, "real World emits encounter focus before same-tick quiet yield")
			check(focus_events.back()["phase"] == 0 and focus_events.back()["quiet"], "source is distinguished during emission, before quiet flag clears")
			check(main._camera.position.is_equal_approx(baseline_position() + main._cam_offset), "new encounter focus immediately keeps its original unconstrained projection")
			for _i in 170:
				tick()
				check(main._camera.position.is_equal_approx(baseline_position() + main._cam_offset), "all encounter frames retain the previous projection")
			check(w._goose_mount_phase == 2, "real first-person then close focus reach phase two")
			tick(true)
			for _i in 240:
				tick(true)
			check(main._cam_offset.length() < 0.01 and main._cam_target_offset.is_zero_approx(), "encounter cancellation still returns")
			trace("encounter_return")
	Input.action_release("move_right")
	tuning.reset_defaults()
	root.get_node("AudioDirector").release_streams()
	print("CAMERA400_BOUNDS_FAILED_CHECKS ", failed_checks)
	print("[camera400-backdrop] ", "PASS" if failures.is_empty() else "FAIL", ": ", checks, " checks ", JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
