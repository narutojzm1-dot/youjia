extends SceneTree
var checks := 0
var failed := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		printerr(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var data := OS.get_environment("XDG_DATA_HOME")
	if data.is_empty() or data != OS.get_environment("YOUJIA_TEST_ISOLATED_DATA"):
		quit(2)
		return
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	await main._start_holiday(false)
	await root.get_node("SaveStore").flush_pending()
	var w = main._world
	var residents: Dictionary = load("res://scripts/game/world_residents.gd").empty()
	residents.beibei = {"stage": "grown", "adopted_clock": {"day": 1, "elapsed": 0.0}}
	residents.chicken = {"stage": "hen", "settled_clock": {"day": 1, "elapsed": 0.0}}
	residents.turtle = {"stage": "pond", "found_trip": "fixture-trip"}
	# Persist the controlled resident fixture too: later album acknowledgements
	# must not restore a different chick over the test's grown actor.
	root.get_node("SaveStore").request_patch("pond-story-residents-fixture", {"world_residents": residents})
	check(await root.get_node("SaveStore").flush_pending(), "controlled residents fixture commits")
	for i in 3: await process_frame
	w.sync_residents(root.get_node("SaveStore").get_world_residents())
	var hen = w.actor_named("chicken")
	var turtle = w.actor_named("turtle")
	var goose = w.actor_named("goose")
	w.debug_place_player(Vector2(410, 490))
	w.get_player().tick(0.0, Vector2.ZERO, w.WORLD_SIZE)
	w.debug_place_actor("goose", Vector2(345, 500))
	hen.position = Vector2(460, 530)
	turtle.set_pose(Vector2(480, 545), turtle._base_scale, 1.0)
	var story = w.pond_story
	story.sequence.cooldown = 0.0
	story.tick(0.1, Vector2.ZERO)
	check(story.busy(), "confirmed adult residents can start")
	check(story.borrowed.size() == 3, "exactly three existing identities reserved")
	for actor in [hen, turtle, goose]: check(actor.has_meta("pond_story"), "actor reserved")
	story.tick(0.1, Vector2.ZERO)
	check(story.sequence.phase == "greet", "arrival precedes greeting")
	for i in range(13): story.tick(0.25, Vector2.ZERO)
	check(story.sequence.phase == "ride", "greeting reaches ride")
	check(story.stage.visible and not hen.visible and not turtle.visible, "one whole ride cel replaces live pair")
	var moment: Dictionary = load("res://scripts/ui/photo_moment.gd").capture(w, {"id": "pond_hen_ride", "owner": "turtle"})
	check(not moment.is_empty(), "actual scene can be recorded")
	var ride_count := 0
	var duplicate_count := 0
	for item in moment.get("items", []):
		if str(item.get("texture", {}).get("path", "")).ends_with("turtle-hen-ride.png"): ride_count += 1
		if str(item.get("texture", {}).get("path", "")).ends_with("/hen.png") or str(item.get("texture", {}).get("path", "")).ends_with("/pond/turtle.png"): duplicate_count += 1
	check(ride_count == 1 and duplicate_count == 0, "photo preserves whole cel without duplicate animals")
	var hen_position: Vector2 = hen.position
	story.tick(0.1, Vector2.RIGHT)
	check(not story.busy() and not story.stage.visible, "player movement interrupts")
	for actor in [hen, turtle, goose]: check(actor.visible and not actor.has_meta("pond_story"), "interruption returns visibility and ownership")
	check(hen.position == hen_position and not hen.posed, "release retains reached position")
	story.cancel()
	check(story.borrowed.is_empty(), "repeated cancellation is harmless")
	# Exercise actual movement from the resident's bank, not only pre-arrived
	# poses. A state-machine-only test cannot catch a blocked walking route.
	turtle.set_pose(Vector2(470, 650), turtle._base_scale, 1.0)
	hen.position = Vector2(435, 515)
	w.debug_place_actor("goose", Vector2(370, 530))
	for id: String in w._actors:
		var animal = w.actor_named(id)
		if id not in ["chicken", "goose"]:
			# set_pose also sets state="pose". Merely setting posed=true still
			# lets a graze/wander actor move, randomly blocking the goose on CI.
			animal.set_pose(animal.position, animal._base_scale, animal.facing)
		else:
			animal.posed = false
			animal.state = "graze"
			animal._idle_time = 100.0
	story.sequence.cooldown = 0.0
	var phases: Array[String] = []
	check(YardBodies.clear_at(hen.position, hen.body_radius * YardGround.depth_at(hen.position.y), w.physical_obstacles("chicken")), "walking fixture begins outside other animals")
	check(YardBodies.clear_at(goose.position, goose.body_radius * YardGround.depth_at(goose.position.y), w.physical_obstacles("goose")), "goose fixture begins outside other animals")
	check(YardBodies.clear_at(story.GOOSE_POINT, goose.body_radius * YardGround.depth_at(YardGround.NEAR_Y), w.physical_obstacles("goose")), "controlled goose destination is reachable before the arc")
	var capture_dir := OS.get_environment("YOUJIA_CAPTURE_DIR")
	if not capture_dir.is_empty(): DirAccess.make_dir_recursive_absolute(capture_dir)
	for i in range(900):
		w.tick(0.1, Vector2.ZERO)
		var phase: String = story.sequence.phase
		if phases.is_empty() or phases.back() != phase:
			phases.append(phase)
			print("POND_PHASE %s turtle=%s hen=%s goose=%s" % [phase, turtle.position, hen.position, goose.position])
			if not capture_dir.is_empty():
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(capture_dir + "/" + phase + ".png")
		if not story.busy() and i > 0: break
	check(phases == ["approach_hen", "greet", "ride", "dismount", "approach_goose", "refuse", "peck_attempt", "retreat", "idle"], "actual bank approach completes ordered relationship arc")
	check(story.borrowed.is_empty(), "completed arc releases every actor")
	check(turtle.position.distance_to(story.HOME) < 2.0, "turtle actually walks back to its pond after refusing goose")
	for event_id in ["pond_hen_ride", "pond_goose_refused"]:
		check(event_id in w.collected, "observed pond story enters album")
		check(PhotoMoment.has_event_subject(w.photo_moments.get(event_id, {}), event_id), "album contains the actual relationship cel")
	check(await root.get_node("SaveStore").flush_pending(), "relationship photos finish durable save")
	root.get_node("SaveStore")._load()
	for event_id in ["pond_hen_ride", "pond_goose_refused"]:
		check(event_id in root.get_node("SaveStore").get_album() and PhotoMoment.has_event_subject(root.get_node("SaveStore").get_photo_moment(event_id), event_id), "real relationship photo survives native reload")
	var story_counts := [w.collected.count("pond_hen_ride"), w.collected.count("pond_goose_refused")]
	story.sequence.cooldown = 0.0
	w._millet_held = true
	story.tick(0.1, Vector2.ZERO)
	check(not story.busy(), "held millet keeps animal encounter available for feeding")
	w._millet_held = false
	w.debug_place_actor("goose", Vector2(800, 490))
	goose.state = "graze"
	goose._idle_time = 100.0
	hen.state = "graze"
	hen._idle_time = 100.0
	root.get_node("TuningStore").set_value("ui.reduced_motion", true, false)
	var distant_phases: Array[String] = []
	for i in range(1600):
		w.tick(0.1, Vector2.ZERO)
		var phase: String = story.sequence.phase
		if distant_phases.is_empty() or distant_phases.back() != phase: distant_phases.append(phase)
		if phase == "ride": check(turtle.position == story.MEET, "reduced motion removes decorative ride sway")
		if not story.busy() and i > 0: break
	check("peck_attempt" in distant_phases and not story.busy(), "goose can approach from the ordinary far side of the lawn")
	print("POND_DISTANT phases=%s goose=%s" % [distant_phases, goose.position])
	check([w.collected.count("pond_hen_ride"), w.collected.count("pond_goose_refused")] == story_counts, "repeat story does not duplicate its album rewards")
	root.get_node("TuningStore").set_value("ui.reduced_motion", false, false)
	# A genuinely occupied destination must time out and release ownership,
	# rather than teleport the goose through the blocker or reward a missed act.
	w.debug_place_actor("goose", Vector2(800, 490))
	story.sequence.cooldown = 0.0
	hen.state = "graze"
	goose.state = "graze"
	story.tick(0.1, Vector2.ZERO)
	check(story.busy(), "blocked route fixture starts a new real encounter")
	story.sequence.phase = "approach_goose"
	story.sequence.elapsed = 0.0
	w.actor_named("beibei").set_pose(story.GOOSE_POINT, w.actor_named("beibei")._base_scale, 1.0)
	var blocked_start: Vector2 = goose.position
	for i in range(355): story.tick(0.25, Vector2.ZERO)
	check(story.sequence.phase == "approach_goose", "blocked goose never advances to refusal or peck before arriving")
	for i in range(10): story.tick(0.25, Vector2.ZERO)
	check(not story.busy() and story.borrowed.is_empty(), "occupied route times out and releases every participant")
	check(goose.position == blocked_start, "blocked goose is not teleported onto another animal")
	check([w.collected.count("pond_hen_ride"), w.collected.count("pond_goose_refused")] == story_counts, "blocked encounter creates no additional photos")
	print("POND_STORY_INTEGRATION: %d checks, %d failures" % [checks, failed])
	quit(0 if failed == 0 else 1)
