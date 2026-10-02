extends SceneTree

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func run() -> void:
	seed(129)
	var world = load("res://scripts/game/yard_world.gd").new()
	root.add_child(world)
	world.setup()
	var player = world.get_player()
	var spot := YardSceneHotspots.get_hotspot("windowbox")
	var picture := Vector2(285, 275)
	var approach: Vector2 = spot.approach_points[0]
	check(Geometry2D.is_point_in_polygon(picture, spot.hit_polygon), "visible flower box lies inside its authored polygon")
	check(not Geometry2D.is_point_in_polygon(Vector2(285, 225), spot.hit_polygon), "upper window glass does not falsely count as painted flowers")
	check(not Geometry2D.is_point_in_polygon(Vector2(295, 311), spot.hit_polygon), "painted door below the flower box is not a false hotspot")
	check(YardGround.allows(approach, YardGround.lawn(), true) and not YardGround.in_pond(approach), "approach is a walkable footpoint outside the house and water")
	check(not YardGround.allows(spot.visual_anchor, YardGround.lawn(), true) and spot.visual_anchor.distance_to(approach) > 200.0, "visual flower anchor is independent of walking destination")
	check(YardInteraction.pointer(world, picture).target == "windowbox", "click resolves the visible flower box")
	check(YardInteraction.pointer(world, Vector2(295, 311)).target != "windowbox", "clicking the house door does not promise entering a room")
	check(YardInteraction.pointer(world, world._fishing_point()).target == "fishing", "pond still owns the fishing tap")
	check(YardInteraction.pointer(world, world._plant_point()).target == "plant", "garden bed still owns planting tap")
	check(YardInteraction.pointer(world, world._grass_point()).target == "grass", "grass still owns pickup tap")
	# Start away from the cottage, with animals outside the route. Real tick()
	# advances the route; teleportation is only used to prepare the fixture.
	for actor_id: String in world._actors:
		world.debug_place_actor(actor_id, Vector2(630, 490) + Vector2(world._actors.keys().find(actor_id) * 34, 0))
	world.debug_place_player(Vector2(500, 518))
	var photos = world.collected.duplicate()
	var moments = world.photo_moments.duplicate(true)
	world.request_pointer_action(picture)
	check(world._pending_interaction == "windowbox" and world._has_walk_goal, "distant tap starts a route for the exact selected flower box")
	check(world._walk_goal == approach and world._scene_feedback.active_snapshot().is_empty(), "selected flower box approaches safe grass without celebrating early")
	check(world.primary_action().target == "windowbox" and world.primary_action_key() == "action.observe_windowbox" and world.action_target_key(world.primary_action()) == "target.windowbox", "HUD and keyboard retain the same selected target/verb")
	world.try_interact()
	check(world._pending_interaction == "windowbox", "Space retains the exact flower box while approaching")
	world.request_primary_action()
	check(world._pending_interaction == "windowbox", "action button retains the exact flower box while approaching")
	for frame in 480:
		world.tick(1.0 / 60.0, Vector2.ZERO)
		if frame % 60 == 0:
			check(player.position.y > 425.0, "player never climbs into the painted balcony")
		if not world._scene_feedback.active_snapshot().is_empty():
			break
	var first: Dictionary = world._scene_feedback.active_snapshot()
	check(not first.is_empty() and not world._has_walk_goal and world._pending_interaction.is_empty(), "route completes at the grass before painted response begins")
	check(first.get("butterfly", false) and first.get("anchor", Vector2.INF) == spot.visual_anchor, "first close observation paints a butterfly at the real flower box")
	check(world.collected == photos and world.photo_moments == moments and not player.carrying_grass, "flower response never grants items or new album entries")
	world.tick(0.12, Vector2.ZERO)
	world.request_pointer_action(Vector2(332, 550))
	check(world._scene_feedback.active_snapshot().is_empty() and not world._scene_feedback.butterfly_seen(), "walking away before seeing the butterfly removes it without forfeiting discovery")
	world.debug_place_player(approach + Vector2(2, 4))
	world.request_pointer_action(picture)
	check(world._scene_feedback.active_snapshot().get("butterfly", false), "an interrupted first encounter can be rediscovered")
	world.tick(1.4, Vector2.ZERO)
	check(world._scene_feedback.butterfly_seen(), "a genuinely viewed butterfly is marked only in this session")
	world.set_weather("overcast")
	check(world._scene_feedback.modulate == world._backdrop.modulate, "local watercolors follow the same overcast tint as the background")
	world.tick(2.0, Vector2.ZERO)
	check(world._scene_feedback.active_snapshot().is_empty(), "scene animation expires without a world-state residue")
	world.request_pointer_action(picture)
	check(not world._scene_feedback.active_snapshot().get("butterfly", true), "later visits get a distinct petal response instead of an endlessly repeated surprise")
	root.get_node("TuningStore").set_value("ui.reduced_motion", true)
	check(world._scene_feedback.active_snapshot().get("reduced_motion", false), "reduced motion preserves a visible static painted response")
	world.cancel_scene_feedback()
	check(world._scene_feedback.active_snapshot().is_empty(), "pause/album cancellation removes the painted response immediately")
	root.get_node("TuningStore").set_value("ui.reduced_motion", false)
	player.carrying_grass = true
	check(YardInteraction.pointer(world, picture).target != "windowbox" and world.primary_action_key() == "action.feed", "carried grass retains feeding priority over the new environment hotspot")
	player.carrying_grass = false
	world._fish_carry_type = "small"
	check(YardInteraction.pointer(world, picture).target != "windowbox" and world.primary_action_key() == "action.toss_fish", "carried fish retains bird feeding priority")
	world._fish_carry_type = ""
	world._fish_state = world.FISH_CASTING
	check(YardInteraction.pointer(world, picture).target != "windowbox", "active fishing does not lose its cast to background scenery")
	world._fish_state = world.FISH_IDLE
	world.debug_place_player(Vector2(500, 518))
	world.request_pointer_action(picture)
	check(world._pending_interaction == "windowbox", "another explicit tap can approach from afar")
	world.request_pointer_action(Vector2(395, 530))
	check(world._pending_interaction.is_empty() and world._scene_feedback.active_snapshot().is_empty(), "new walk cancels an unfinished flower-box approach without a false bloom")
	world.free()
	root.get_node("AudioDirector").call("release_streams")
	print("[scene-hotspot-tests] %d checks, failures=%s" % [checks, failures])
	quit(0 if failures.is_empty() else 1)
