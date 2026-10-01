extends SceneTree

# The pickup is cosmetic: inventory/feeding never waits for its 0.42s transfer.
# Run: godot --headless --path . --script res://test/grass_state_suite.gd
var _checks := 0
var _failures := PackedStringArray()
var _player_script: Script
var _patch_script: Script

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var tuning := root.get_node("TuningStore")
	tuning.call("end_run")
	tuning.call("reset_defaults")
	_player_script = load("res://scripts/entities/vacationer.gd")
	_patch_script = load("res://scripts/entities/grass_patch.gd")
	_check(_player_script.can_instantiate() and _patch_script.can_instantiate(), "grass scripts compile")
	if not _player_script.can_instantiate() or not _patch_script.can_instantiate():
		quit(1)
		return
	for fps: int in [30, 60, 120]:
		_test_transfer(fps)
	_test_repeated_feeding()
	_test_reduced_motion()
	_test_hand_attachment()
	_test_atlas_transparency()
	tuning.call("reset_defaults")
	root.get_node("AudioDirector").call("release_streams")
	for failure: String in _failures:
		push_error("[grass-state-tests] " + failure)
	print("[grass-state-tests] %s: %d checks, %d failures" % ["PASS" if _failures.is_empty() else "FAIL", _checks, _failures.size()])
	quit(0 if _failures.is_empty() else 1)

func _fixture() -> Array:
	var player = _player_script.new()
	root.add_child(player)
	player.setup(Vector2(345, 575))
	player.tick(0.0, Vector2.ZERO, Vector2(1280, 720))
	var patch = _patch_script.new()
	root.add_child(patch)
	patch.setup(Vector2(340, 600))
	return [player, patch]

func _step(player: Node2D, patch: Node2D, seconds: float, fps: int) -> void:
	var remaining := seconds
	while remaining > 0.000001:
		var delta := minf(remaining, 1.0 / float(fps))
		player.tick(delta, Vector2.ZERO, Vector2(1280, 720))
		patch.tick(delta)
		remaining -= delta

func _test_transfer(fps: int) -> void:
	var nodes := _fixture()
	var player = nodes[0]
	var patch = nodes[1]
	var start: Vector2 = player.position
	_check(patch._roots.size() == 2 and patch._roots[0].modulate.a == 1.0, "rooted tufts start visible at %dHz" % fps)
	_check(patch.harvest(player), "first harvest succeeds at %dHz" % fps)
	_check(player.carrying_grass and not player._grass.visible, "inventory is immediate while hand waits for cosmetic transfer at %dHz" % fps)
	_check(patch.growth[0] == 0.0 and patch.growth[1] == 1.0 and patch._stubble[0].modulate.a == 1.0, "only harvested tuft changes into stubble at %dHz" % fps)
	_check(patch._loose.visible and player.position == start, "loose bundle appears without moving player at %dHz" % fps)
	var drop: Vector2 = patch._loose.global_position
	_step(player, patch, 0.1, fps)
	_check(patch._loose.global_position.distance_to(drop) < 0.01, "brief loose-on-ground beat at %dHz" % fps)
	_step(player, patch, 0.18, fps)
	_check(patch._loose.global_position.distance_to(drop) > 2.0 and not player._grass.visible, "bundle transfers toward current hand at %dHz" % fps)
	_step(player, patch, 0.15, fps)
	_check(player._grass.visible and not patch._loose.visible, "one held bundle after transfer at %dHz" % fps)
	_check(player._grass.global_position.distance_to(player.grass_hand_global_position()) < 0.01, "held cut stems meet palm at %dHz" % fps)
	var revision: int = player.grass_visual_revision
	_check(not patch.harvest(player) and player.grass_visual_revision == revision, "full hands do not clip another tuft at %dHz" % fps)
	_check(player.consume_grass() and not player.carrying_grass and not player._grass.visible, "feeding removes bundle synchronously at %dHz" % fps)
	_step(player, patch, 17.0, fps)
	_check(patch.growth[0] == 1.0 and patch._roots[0].modulate.a == 1.0, "clipped tuft regrows at %dHz" % fps)
	_check(not patch._loose.visible and not player._grass.visible, "feeding never resurrects old visual at %dHz" % fps)
	player.free()
	patch.free()

func _test_repeated_feeding() -> void:
	var nodes := _fixture()
	var player = nodes[0]
	var patch = nodes[1]
	for index: int in 12:
		_check(patch.harvest(player), "harvest %d has no cooldown or depleted-grass gate" % index)
		var revision: int = player.grass_visual_revision
		_check(player.consume_grass(), "feed %d succeeds during pickup animation" % index)
		_check(player.grass_visual_revision > revision and not player._grass.visible, "feed %d cancels pending hand visual" % index)
		patch.tick(0.0)
		_check(not patch._loose.visible, "feed %d cancels stale loose visual" % index)
	_check(patch.harvest(player), "new pickup after rapid feeding succeeds")
	_step(player, patch, 0.43, 60)
	_check(player._grass.visible and not patch._loose.visible, "latest bundle alone survives repeated feeding")
	player.consume_grass()
	patch.harvest(player)
	player.consume_grass()
	player.pick_grass()
	patch.tick(0.01)
	_check(player._grass.visible and not patch._loose.visible, "new direct pickup invalidates an older patch transfer")
	player.free()
	patch.free()

func _test_reduced_motion() -> void:
	var tuning := root.get_node("TuningStore")
	tuning.call("set_value", "ui.reduced_motion", true, false)
	var nodes := _fixture()
	var player = nodes[0]
	var patch = nodes[1]
	patch.harvest(player)
	_check(player.carrying_grass and player._grass.visible and not patch._loose.visible, "reduced motion picks directly into hand")
	_check(patch.growth[0] == 0.0, "reduced motion still clips grounded tuft")
	player.consume_grass()
	_check(not player._grass.visible and not player.carrying_grass, "reduced motion feeding clears immediately")
	tuning.call("set_value", "ui.reduced_motion", false, false)
	patch.harvest(player)
	tuning.call("set_value", "ui.reduced_motion", true, false)
	_step(player, patch, 0.02, 60)
	_check(player._grass.visible and not patch._loose.visible, "enabling reduced motion during pickup immediately settles one bundle")
	player.free()
	patch.free()
	tuning.call("set_value", "ui.reduced_motion", false, false)

func _test_hand_attachment() -> void:
	var nodes := _fixture()
	var player = nodes[0]
	var patch = nodes[1]
	player.pick_grass()
	var tuning := root.get_node("TuningStore")
	for face: float in [-1.0, 1.0]:
		for depth: float in [0.84, 1.12]:
			for visual: float in [0.8, 1.2]:
				tuning.call("set_value", "player.visual.scale", visual, false)
				player.picture_depth = depth
				player._gait.face = face
				player._sequence_walker.scale = Vector2(face, 1.0) * 0.25 * depth * visual
				for frame: int in 16:
					player._sequence_walker.animation = &"walk"
					player._sequence_walker.frame = frame
					player._update_grass_visual()
					var expected: Vector2 = player._sequence_walker.to_global(player._sequence_walker.offset + player.GRASS_SEQUENCE_HAND[frame])
					_check(player._grass.global_position.distance_to(expected) < 0.01, "frame %d palm anchor mirrors/scales (face %.0f depth %.2f scale %.1f)" % [frame, face, depth, visual])
					_check(signf(player._grass.scale.x) == face and is_equal_approx(absf(player._grass.scale.x), player._grass.scale.y), "bundle uses uniform mirrored scaling")
	player.free()
	patch.free()

func _test_atlas_transparency() -> void:
	var art: Script = load("res://scripts/entities/grass_art.gd")
	var atlas: Image = art.ATLAS.get_image()
	_check(art.ROOTED.size.y > art.ROOTED.size.x * 1.5, "rooted blade silhouette is upright rather than mound-shaped")
	for point: Vector2i in [Vector2i(40, 40), Vector2i(560, 600), Vector2i(900, 650), Vector2i(1500, 450)]:
		_check(atlas.get_pixelv(point).a == 0.0, "atlas halo RGB remains fully transparent at %s" % point)
	for region: Rect2 in [art.ROOTED, art.STUBBLE, art.LOOSE]:
		for corner: Vector2 in [region.position, Vector2(region.end.x - 1, region.position.y), Vector2(region.position.x, region.end.y - 1), region.end - Vector2.ONE]:
			_check(atlas.get_pixelv(Vector2i(corner)).a == 0.0, "atlas crop corner is fully transparent at %s" % corner)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
