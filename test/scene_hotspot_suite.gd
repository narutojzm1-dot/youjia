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
	var shore_click := Vector2(515, 560)
	check(not YardGround.in_pond(shore_click) and shore_click.distance_to(world._fishing_point()) > 38.0, "painted bank stone is distinct from pond water and the fishing tap")
	check(YardInteraction.pointer(world, shore_click).target == "shore_stones", "tapping the real painted bank stone resolves a distinct water-touch action")
	check(not YardGround.in_pond(Vector2(510, 612)) and YardInteraction.pointer(world, Vector2(510, 612)).target == "shore_stones", "the prominent painted boulder below the stone rim is clickable too")
	check(YardInteraction.pointer(world, Vector2(445, 615)).target != "shore_stones" and YardInteraction.pointer(world, Vector2(565, 580)).target == "fishing", "expanded boulder region remains separate from grass and actual pond water")
	check(YardInteraction.pointer(world, Vector2(923, 470)).target == "fence_gate", "the painted wooden gate is a distinct yard-side observation target")
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
	check_shore_stones()
	check_fence_gate()
	root.get_node("AudioDirector").call("release_streams")
	print("[scene-hotspot-tests] %d checks, failures=%s" % [checks, failures])
	quit(0 if failures.is_empty() else 1)


func check_shore_stones() -> void:
	var world = load("res://scripts/game/yard_world.gd").new()
	root.add_child(world)
	world.setup()
	var player = world.get_player()
	var stone := Vector2(515, 560)
	var shore := YardSceneHotspots.get_hotspot("shore_stones")
	var approach: Vector2 = shore.approach_points[0]
	check(Geometry2D.is_point_in_polygon(stone, shore.hit_polygon), "only the visible west-bank rocks resolve as a shore touch")
	check(not Geometry2D.is_point_in_polygon(world._fishing_point(), shore.hit_polygon) and not Geometry2D.is_point_in_polygon(Vector2(550, 520), shore.hit_polygon), "pond fishing point and adjacent grass do not become stones")
	check(YardGround.allows(approach, YardGround.lawn(), true) and not YardGround.in_pond(stone) and YardGround.in_pond(shore.visual_anchor), "stone click, safe grass feet and painted water response each use their own coordinates")
	check(YardInteraction.pointer(world, shore.visual_anchor).target == "fishing", "water beneath the new painted ripple still means fishing")
	check(YardInteraction.pointer(world, world._grass_point()).target == "grass" and YardInteraction.pointer(world, world._plant_point()).target == "plant", "old plant and grass taps retain their owners")
	var album = world.collected.duplicate()
	var moments = world.photo_moments.duplicate(true)
	var notices: Array[String] = []
	world.notice_requested.connect(func(key: String): notices.append(key))
	for actor_id: String in world._actors:
		if not actor_id.begins_with("duck") and actor_id != "goose":
			world.debug_place_actor(actor_id, Vector2(810, 455) + Vector2(world._actors.keys().find(actor_id) * 26, 0))
	world.debug_place_player(Vector2(700, 455))
	world.request_pointer_action(stone)
	check(world._pending_interaction == "shore_stones" and world._has_walk_goal and world._walk_goal == approach, "distant rock tap approaches only the safe grass footpoint")
	check(world.primary_action().target == "shore_stones" and world.primary_action_key() == "action.touch_shore" and world.action_target_key(world.primary_action()) == "target.shore_stones", "HUD, Space and action button retain exactly the selected stone")
	check(world._scene_feedback.ripple_snapshot().is_empty(), "a far-away tap does not celebrate before the shore is reached")
	world.try_interact()
	world.request_primary_action()
	check(world._pending_interaction == "shore_stones" and world._scene_feedback.ripple_snapshot().is_empty(), "Space and button while approaching neither redirect nor falsely splash")
	for frame in 720:
		world.tick(1.0 / 60.0, Vector2.ZERO)
		if not world._scene_feedback.ripple_snapshot().is_empty():
			break
	var ripple: Dictionary = world._scene_feedback.ripple_snapshot()
	check(not ripple.is_empty() and ripple.get("anchor", Vector2.INF) == shore.visual_anchor and not world._has_walk_goal, "only successful shore arrival paints a ripple on real pond water")
	check(world._fish_state == world.FISH_IDLE and world._fish_carry_type.is_empty() and not player.carrying_grass and world.collected == album and world.photo_moments == moments, "shore touch never casts, catches, consumes or creates a photo")
	check(notices.has("notice.shore_stones") and not notices.has("notice.fishing.cast"), "shore success uses its own restrained notice, never the catch or cast copy")
	world.request_pointer_action(Vector2(440, 520))
	check(world._scene_feedback.ripple_snapshot().is_empty(), "ordinary walking cancels the transient watercolor ripple immediately")
	world.debug_place_player(Vector2(700, 455))
	world._fish_state = world.FISH_CASTING
	check(YardInteraction.pointer(world, stone).target != "shore_stones" and YardInteraction.pointer(world, world._fishing_point()).target == "fishing", "an active cast reserves the pond and cannot be stolen by the stones")
	world._fish_state = world.FISH_IDLE
	world._fish_carry_type = "small"
	check(YardInteraction.pointer(world, stone).target != "shore_stones" and YardInteraction.pointer(world, world.actor_named("duck_a").visual_hit_rect().get_center()).target.begins_with("toss_fish:"), "carried fish retains exact bird-feeding priority")
	world._fish_carry_type = ""
	world.tick(0.02, Vector2.ZERO)
	check(world._scene_feedback.dragonfly_snapshot().is_empty(), "a dragonfly does not appear at the far bank without approaching it")
	world.request_pointer_action(Vector2(515, 520)) # A normal grass walk, not the painted rock.
	check(world._pending_interaction.is_empty(), "ambient encounter needs no tap or shore success")
	for frame in 720:
		world.tick(1.0 / 60.0, Vector2.ZERO)
		if not world._scene_feedback.dragonfly_snapshot().is_empty():
			break
	var guest: Dictionary = world._scene_feedback.dragonfly_snapshot()
	check(not guest.is_empty() and world._scene_feedback.ripple_snapshot().is_empty() and notices.count("notice.shore_stones") == 1, "walking to the shoreline independently reveals a painted dragonfly, not an extra splash")
	world.cancel_scene_feedback()
	check(not world._scene_feedback.dragonfly_seen() and world._scene_feedback.dragonfly_snapshot().is_empty(), "leaving a first short sighting does not mark the dragonfly as missed or consumed")
	world.debug_place_player(Vector2(700, 455))
	world.tick(0.02, Vector2.ZERO)
	world.debug_place_player(approach + Vector2(4, 3))
	world.tick(0.02, Vector2.ZERO)
	check(not world._scene_feedback.dragonfly_snapshot().is_empty(), "returning to the same shore offers a missed first encounter again without a daily cooldown")
	world.set_weather("overcast")
	check(world._scene_feedback.modulate == world._backdrop.modulate, "dragonfly and ripple inherit the pond backdrop's overcast tint")
	root.get_node("TuningStore").set_value("ui.reduced_motion", true)
	world.tick(0.02, Vector2.ZERO)
	guest = world._scene_feedback.dragonfly_snapshot()
	check(guest.get("reduced_motion", false) and world._scene_feedback._dragonfly.texture.resource_path.ends_with("shore_dragonfly_rest.png"), "reduced motion holds a complete still dragonfly painting")
	world.tick(1.25, Vector2.ZERO)
	check(world._scene_feedback.dragonfly_seen() and world.collected == album and world.photo_moments == moments, "only genuinely witnessed dragonfly stays session-scoped, never in saved rewards")
	world.cancel_scene_feedback()
	check(world._scene_feedback.dragonfly_snapshot().is_empty() and world._scene_feedback.ripple_snapshot().is_empty(), "pause and album cancellation clear both shore paintings")
	root.get_node("TuningStore").set_value("ui.reduced_motion", false)
	world.free()

func check_fence_gate() -> void:
	var world = load("res://scripts/game/yard_world.gd").new()
	root.add_child(world)
	world.setup()
	var player = world.get_player()
	var gate := Vector2(923, 470)
	var fence := YardSceneHotspots.get_hotspot("fence_gate")
	var approach: Vector2 = fence.approach_points[0]
	check(Geometry2D.is_point_in_polygon(gate, fence.hit_polygon), "the actual painted wooden gate is in the authored hit polygon")
	check(not Geometry2D.is_point_in_polygon(Vector2(1070, 430), fence.hit_polygon) and not Geometry2D.is_point_in_polygon(Vector2(830, 470), fence.hit_polygon) and not Geometry2D.is_point_in_polygon(Vector2(895, 480), fence.hit_polygon), "shed wall, old non-walkable rail, and bare lawn are not mislabeled as a gate")
	check(not YardGround.allows(gate, YardGround.lawn(), true) and YardGround.allows(approach, YardGround.lawn(), true) and approach.distance_to(gate) > 75.0, "gate art is outside the lawn but its observation footpoint is safely inside")
	check(fence.ambient_anchor.x - approach.x <= 190.0, "shed-feather encounter remains within the actual portrait camera beside the yard-side approach")
	check(YardInteraction.pointer(world, world._fishing_point()).target == "fishing" and YardInteraction.pointer(world, world._plant_point()).target == "plant", "existing pond and garden clicks still keep priority")
	for actor_id: String in world._actors:
		world.debug_place_actor(actor_id, Vector2(330, 445) + Vector2(world._actors.keys().find(actor_id) * 32, 0))
	world.debug_place_player(Vector2(500, 518))
	var album = world.collected.duplicate()
	var moments = world.photo_moments.duplicate(true)
	var notices: Array[String] = []
	world.notice_requested.connect(func(key: String): notices.append(key))
	world.request_pointer_action(gate)
	check(world._pending_interaction == "fence_gate" and world._has_walk_goal and world._walk_goal == approach, "distant gate click starts only a safe yard-side route")
	check(world.primary_action().target == "fence_gate" and world.primary_action_key() == "action.observe_fence" and world.action_target_key(world.primary_action()) == "target.fence_gate", "HUD, keyboard and action button retain the selected wooden fence")
	world.try_interact()
	world.request_primary_action()
	check(world._pending_interaction == "fence_gate" and world._scene_feedback.fence_snapshot().is_empty(), "Space and button while approaching do not falsely move any painted grass")
	for frame in 960:
		world.tick(1.0 / 60.0, Vector2.ZERO)
		if not world._scene_feedback.fence_snapshot().is_empty():
			break
	var response: Dictionary = world._scene_feedback.fence_snapshot()
	check(not response.is_empty() and response.get("anchor", Vector2.INF) == fence.visual_anchor and not world._has_walk_goal, "only real arrival within the yard paints the gate-side grass")
	check(YardGround.allows(player.position, YardGround.lawn(), true) and player.position.distance_to(approach) < 64.0, "player stays inside the fence instead of passing through the painted gate")
	check(notices.count("notice.fence_gate") == 1 and not notices.has("notice.fishing.cast"), "fence success has its own one-time line and does not fish")
	check(world.collected == album and world.photo_moments == moments and not player.carrying_grass, "observing the gate never changes items, photo moments or saved album")
	world.request_pointer_action(Vector2(650, 515))
	check(world._scene_feedback.fence_snapshot().is_empty() and world._scene_feedback.feather_snapshot().is_empty(), "moving away cancels both grass and shed-feather paintings immediately")
	world.debug_place_player(Vector2(500, 518))
	world.request_pointer_action(gate)
	check(world._pending_interaction == "fence_gate" and world._scene_feedback.fence_snapshot().is_empty(), "a second distant gate tap waits for another genuine arrival")
	world.request_pointer_action(Vector2(650, 515))
	check(world._pending_interaction.is_empty() and world._scene_feedback.fence_snapshot().is_empty(), "new grass walk cancels a pending gate observation without a false response")
	player.carrying_grass = true
	check(YardInteraction.pointer(world, gate).target != "fence_gate", "grass held for the llama cannot be stolen by a gate tap")
	player.carrying_grass = false
	world._fish_carry_type = "small"
	check(YardInteraction.pointer(world, gate).target != "fence_gate", "fish held for a bird cannot be stolen by a gate tap")
	world._fish_carry_type = ""
	world._fish_state = world.FISH_CASTING
	check(YardInteraction.pointer(world, gate).target != "fence_gate", "an active cast cannot be replaced by looking at the fence")
	world._fish_state = world.FISH_IDLE
	world.free()

	var ambient = load("res://scripts/game/yard_world.gd").new()
	root.add_child(ambient)
	ambient.setup()
	var guest_album = ambient.collected.duplicate()
	var guest_moments = ambient.photo_moments.duplicate(true)
	for actor_id: String in ambient._actors:
		ambient.debug_place_actor(actor_id, Vector2(340, 455) + Vector2(ambient._actors.keys().find(actor_id) * 32, 0))
	ambient.debug_place_player(Vector2(695, 510))
	ambient.tick(0.02, Vector2.ZERO)
	check(ambient._scene_feedback.feather_snapshot().is_empty(), "shed feather does not appear far from the gate")
	ambient.request_pointer_action(Vector2(830, 510)) # Ordinary grass walk, not the gate.
	check(ambient._pending_interaction.is_empty(), "ambient breeze never requires tapping the gate or spending a resource")
	for frame in 720:
		ambient.tick(1.0 / 60.0, Vector2.ZERO)
		if not ambient._scene_feedback.feather_snapshot().is_empty():
			break
	var guest: Dictionary = ambient._scene_feedback.feather_snapshot()
	check(not guest.is_empty() and guest.get("anchor", Vector2.INF) == fence.ambient_anchor and ambient._scene_feedback.fence_snapshot().is_empty(), "an independent feather drifts from the actual shed eave while walking nearby")
	ambient.cancel_scene_feedback()
	check(not ambient._scene_feedback.feather_seen() and ambient._scene_feedback.feather_snapshot().is_empty(), "a first brief glimpse can be seen again after walking away")
	ambient.debug_place_player(Vector2(695, 510))
	ambient.tick(0.02, Vector2.ZERO)
	ambient.debug_place_player(approach + Vector2(3, 2))
	ambient.tick(0.02, Vector2.ZERO)
	check(not ambient._scene_feedback.feather_snapshot().is_empty(), "returning to the same fence restores a missed encounter without a daily cooldown")
	ambient.set_weather("overcast")
	check(ambient._scene_feedback.modulate == ambient._backdrop.modulate, "feather and grass follow the painted overcast tint")
	root.get_node("TuningStore").set_value("ui.reduced_motion", true)
	ambient.tick(0.02, Vector2.ZERO)
	guest = ambient._scene_feedback.feather_snapshot()
	check(guest.get("reduced_motion", false) and ambient._scene_feedback._feather.texture.resource_path.ends_with("shed_feather.png"), "reduced motion shows a full still feather painting at the shed")
	ambient.tick(1.25, Vector2.ZERO)
	check(ambient._scene_feedback.feather_seen() and ambient.collected == guest_album and ambient.photo_moments == guest_moments, "only a viewed feather is remembered for this session, never stored as a reward")
	ambient.cancel_scene_feedback()
	check(ambient._scene_feedback.feather_snapshot().is_empty(), "pause or album removes the transient feather immediately")
	root.get_node("TuningStore").set_value("ui.reduced_motion", false)
	ambient.free()
