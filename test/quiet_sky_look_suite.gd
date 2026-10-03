extends SceneTree
# REQ-012 切片 C：安静抬头微推——无道具、可打断、不写相册。

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var tuning := root.get_node("TuningStore")
	tuning.reset_defaults()
	var world = load("res://scripts/game/yard_world.gd").new()
	root.add_child(world)
	world.setup()
	# 把动物挪开，避免鹅马静坐演出抢镜头。
	for actor_id: String in world._actors:
		world.debug_place_actor(actor_id, Vector2(1100, 520))
	world.debug_place_player(Vector2(420, 548))
	world._has_walk_goal = false
	world._pending_interaction = ""
	world._selected_target = ""
	world._weather_timer = 10000.0
	var focuses: Array = []
	var releases := 0
	world.camera_focus_requested.connect(func(point: Vector2, zoom: float): focuses.append({"point": point, "zoom": zoom}))
	world.camera_release_requested.connect(func(): releases += 1)
	var album = world.collected.duplicate()
	# 前 5 秒不应抬头（阈值 5.5s）。
	for _i: int in 300:
		world.tick(1.0 / 60.0, Vector2.ZERO)
	_check(focuses.is_empty() and not world._quiet_sky_active, "sky look waits past the fence-leaf window")
	# 再静站越过阈值。
	for _i: int in 60:
		world.tick(1.0 / 60.0, Vector2.ZERO)
	_check(world._quiet_sky_active and focuses.size() == 1, "quiet stay lifts the camera toward the sky")
	_check(is_equal_approx(float(focuses[0]["zoom"]), world.QUIET_SKY_ZOOM), "sky look uses the soft prototype zoom")
	_check(focuses[0]["point"].y < world._player.position.y - 80.0, "sky focus sits above the traveler")
	_check(world.collected == album, "sky look does not write the album")
	# 走动立刻取消。
	world.tick(0.05, Vector2(1, 0))
	_check(not world._quiet_sky_active and releases >= 1, "walking cancels the sky look immediately")
	# 鹅马接管：直接验证 yield 不清 release（动物远离时 wait 会被鹅马逻辑清零，不能靠 wait 测）。
	releases = 0
	world._quiet_sky_active = true
	world._focus_seconds = world.QUIET_SKY_HOLD_SECONDS
	world._yield_quiet_sky_look_to_encounter()
	_check(not world._quiet_sky_active and releases == 0 and is_equal_approx(world._focus_seconds, 0.0), "goose-mount yield clears sky look without camera release")
	world.free()
	if failures.is_empty():
		print("QUIET SKY LOOK PASS ", checks)
		quit(0)
	for failure: String in failures:
		push_error(failure)
	quit(1)


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
