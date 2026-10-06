extends SceneTree
## Controlled native render fixture, not ordinary random gameplay.
## Run with an isolated user-data override; never use --headless.
const Moment := preload("res://scripts/ui/photo_moment.gd")
var output := ""
var records: Array = []
var world

func _initialize() -> void:
	call_deferred("run")

func save_frame(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	assert(frame != null and not frame.is_empty(), "No rendered image")
	assert(frame.get_size() == Vector2i(1280, 720), "Unexpected capture dimensions")
	var distinct := false
	var first := frame.get_pixel(10, 10)
	for y in range(20, 720, 40):
		for x in range(20, 1280, 40):
			var pixel := frame.get_pixel(x, y)
			if absf(pixel.r - first.r) + absf(pixel.g - first.g) + absf(pixel.b - first.b) > 0.08: distinct = true
	assert(distinct, "Blank/flat frame rejected")
	var path := output.path_join(label + ".png")
	assert(frame.save_png(path) == OK, "PNG save failed")
	records.append({"file": label + ".png", "sha256": FileAccess.get_sha256(path),
		"weather_mix": world._weather_mix, "cloud_weights": world._weather_cloud_weights.duplicate(),
		"cloud_scroll": world._cloud_scroll})

func run() -> void:
	assert(DisplayServer.get_name() != "headless", "Fixture needs a native rendering device")
	output = ProjectSettings.globalize_path("res://../producer-recovery/overcast-runtime-visual-v2")
	assert(DirAccess.make_dir_recursive_absolute(output) == OK)
	root.size = Vector2i(1280, 720)
	var tuning := root.get_node("TuningStore")
	tuning.reset_defaults()
	seed(168)
	world = load("res://scripts/game/yard_world.gd").new()
	root.add_child(world)
	world.setup()
	world._weather_timer = 10000.0
	world._day_elapsed = world.DAY_DURATION_SECONDS * 0.4
	# Real YardWorld tick initializes resident and actor perspective/pose.
	# setup alone leaves source-sized sprites; do not manually rescale them.
	world.tick(1.0 / 60.0, Vector2.ZERO)
	# Lock cast/time/drift for a meaningful same-state reversal comparison.
	# Only weather helper advances; this is explicitly a controlled fixture.
	tuning.set_value("ui.reduced_motion", true)
	world._apply_weather_art()
	tuning.set_value("ui.reduced_motion", false)
	await save_frame("sunny")
	world.set_weather("overcast")
	world._tick_weather_transition(1.5)
	await save_frame("half-before-reverse")
	world.set_weather("sun")
	await save_frame("half-after-reverse")
	# Capture actual midpoint state, round-trip JSON, then render PhotoMoment.
	var snapshot: Dictionary = Moment.capture(world, ExpressionCatalog.find_rule("llama_fed_gentle"))
	assert(not snapshot.is_empty())
	var json_path := output.path_join("midpoint-photo.json")
	var json_file := FileAccess.open(json_path, FileAccess.WRITE)
	json_file.store_string(JSON.stringify(snapshot, "\t"))
	json_file.close()
	var card := Moment.new()
	card.position = Vector2.ZERO
	card.size = Vector2(1280, 720)
	root.add_child(card)
	card.setup(Moment.sanitize(JSON.parse_string(JSON.stringify(snapshot))))
	world.hide()
	await save_frame("half-photo-replay")
	card.free()
	world.show()
	world.set_weather("overcast")
	world._tick_weather_transition(3.0)
	await save_frame("overcast")
	world.set_weather("sun")
	world._tick_weather_transition(1.5)
	await save_frame("reverse-half")
	var manifest := FileAccess.open(output.path_join("manifest.json"), FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"scope": "controlled native Godot rendered weather/PhotoMoment fixture; no random play, no mobile input validation", "frames": records}, "\t"))
	manifest.close()
	world.free()
	tuning.reset_defaults()
	root.get_node("AudioDirector").release_streams()
	print("OVERCAST VISUAL CAPTURE PASS: %d nonempty rendered frames" % records.size())
	quit()
