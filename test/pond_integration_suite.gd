extends SceneTree
const Controller := preload("res://scripts/game/world_residents_controller.gd")
var checks := 0
var failures := 0
var output := ""
func _initialize() -> void: call_deferred("run")
func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(why)
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		push_error("Isolated profile required"); quit(2); return
	output = OS.get_environment("YOUJIA_CAPTURE_DIR")
	if not output.is_empty(): DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	var store := root.get_node("SaveStore")
	if not store.is_initialized(): await store.initialized
	var legacy := {"schema": 1, "revision": 2, "beibei": {"stage": "grown", "adopted_clock": {"day": 1, "elapsed": 0.0}}}
	store.request_patch("pond-fixture", {"world_residents": legacy, "holiday_day": 4, "holiday_day_elapsed": 100.0})
	check(await store.flush_pending(), "legacy grown dog persists")
	var controller := Controller.new(store)
	var context := {"nearby": ["beibei"], "rope": ""}
	var seed_value := 0
	while AnimalCompanions.choose(context, str(seed_value)).is_empty(): seed_value += 1
	var host := ExplorationHost.new(store)
	host.restore()
	check(host.begin({"day": 4, "elapsed": 100.0}, seed_value, context).ok, "formal trip begins")
	check(await store.flush_pending(), "companion trip persists")
	check(host.view().companion.actor_id == "beibei", "deterministic fixture selects adult through production choice")
	var scene: Node2D = load("res://scripts/exploration/near_path_scroll.gd").new()
	root.add_child(scene)
	scene.setup(host, "sunny", controller)
	scene.set_process(false)
	scene.spot = {"arm": "lane", "d": 0.0}
	check(scene.cross_page(), "village crossed on same trip")
	scene.place_at("village_lake")
	scene.observe()
	check(await store.flush_pending(), "water stop confirmed")
	scene._update_turtle()
	check(scene._search_started and scene.turtle == null, "search begins before any turtle appears")
	check(not scene.pick(), "cannot take invisible turtle")
	for i in 6:
		scene.walk(Vector2.ZERO, 0.1)
		scene._update_turtle()
	scene.end_observe()
	check(scene.companion.search_spot.is_empty() and not controller.busy() and controller.view().turtle.stage == "unmet", "interrupted search grants nothing")
	root.get_node("TuningStore").set_value("ui.reduced_motion", true, false)
	scene.observe()
	check(await store.flush_pending(), "reduced motion observation confirmed")
	for i in 20:
		scene.walk(Vector2.ZERO, 0.05)
		scene._update_turtle()
	check(not controller.busy() and controller.view().turtle.stage == "unmet", "reduced motion does not skip discovery time")
	scene._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(scene.companion.search_spot.is_empty() and not scene._search_started, "focus loss cancels unfinished search")
	scene.end_observe()
	root.get_node("TuningStore").set_value("ui.reduced_motion", false, false)
	scene.observe()
	check(await store.flush_pending(), "second observation confirmed")
	var captured_search := false
	for i in 150:
		scene.walk(Vector2.ZERO, 0.05)
		scene._update_turtle()
		if not captured_search and scene.companion.search_elapsed >= 1.0 and not controller.busy():
			captured_search = true
			check(scene.companion.search_cel.visible and scene.turtle == null, "visible pose precedes reveal request")
			await capture("searching-1280")
		if controller.busy(): break
	check(controller.busy() and controller.pending.action == "find_turtle", "only completed physical search requests discovery")
	check(scene.companion.search_cel.visible and scene.companion.search_cel.texture.resource_path.ends_with("beibei/search.png"), "whole dog search painting used")
	check(scene.turtle == null and controller.view().turtle.stage == "unmet", "queued discovery is still invisible")
	await capture("discovery-saving-1280")
	check(await store.flush_pending(), "discovery durable")
	scene._update_turtle()
	scene._refresh()
	check(scene.turtle != null and scene.turtle.visible and scene.pick_choice().kind == "turtle_adopt", "confirmed turtle appears with adoption choice")
	check(scene.companion.actor.visible and not scene.companion.search_cel.visible, "dog returns to ordinary whole cel after discovery")
	await capture("found-1280")
	for locale: String in ["zh-CN", "en"]:
		root.get_node("I18n").set_locale(locale)
		for size: Vector2i in [Vector2i(390, 844), Vector2i(568, 320)]:
			root.size = size
			await process_frame
			scene.walk(Vector2.ZERO, 0.0)
			scene._update_turtle()
			scene._refresh()
			check(scene._caption.get_rect().end.y < scene._pick_button.position.y, "pond caption above actions %s/%d" % [locale, size.x])
			check(scene._pick_button.get_rect().end.x < scene._go_button.position.x, "pond actions separated")
			await capture("found-%s-%d" % [locale, size.x])
	root.get_node("I18n").set_locale("zh-CN")
	root.size = Vector2i(1280, 720)
	await process_frame
	var before_basket: Array = host.view().carried.duplicate()
	check(scene.pick(), "take confirmed turtle through actual scene")
	check(not scene.pick(), "duplicate adoption blocked")
	check(controller.view().turtle.stage == "found", "acceptance does not preempt confirmation")
	check(await store.flush_pending(), "take turtle commits")
	scene._update_turtle()
	scene._refresh()
	check(not scene.turtle.visible and scene.pick_choice().kind == "none", "only confirmed adoption removes wild turtle")
	check(host.view().carried == before_basket, "unique resident consumes no item slot")
	host.request_return("player")
	check(await store.flush_pending(), "return uses existing inventory transaction")
	scene.release()
	root.remove_child(scene)
	scene.queue_free()
	store._load()
	var world: Node2D = load("res://scripts/game/yard_world.gd").new()
	root.add_child(world)
	world.setup()
	world.sync_residents(controller.view())
	world.tick(0.0, Vector2.ZERO)
	check(world.actor_named("beibei") != null and world.actor_named("turtle") != null, "native reopen spawns both residents")
	var turtle: Node2D = world.actor_named("turtle")
	world.sync_residents(controller.view())
	check(world.actor_named("turtle") == turtle, "repeated sync never clones turtle")
	check(turtle._sprite.texture.resource_path == TurtleArt.TEXTURE, "pond uses original turtle whole painting")
	var camera := Camera2D.new()
	world.add_child(camera)
	camera.position = Vector2(640, 360)
	camera.make_current()
	world.debug_place_player(Vector2(455, 610))
	world.tick(0.0, Vector2.ZERO)
	await capture("pond-reopened-1280")
	var photo: Dictionary = load("res://scripts/ui/photo_moment.gd").capture(world, {"id": "pond-fixture"})
	check(not photo.is_empty(), "yard with resident remains photographable")
	var contains_turtle := false
	for item: Dictionary in photo.get("items", []):
		if item.get("subject", "") == "turtle" and item.get("texture", {}).get("path", "") == TurtleArt.TEXTURE: contains_turtle = true
	check(contains_turtle, "inert photo keeps actual turtle pose texture")
	world.queue_free()
	print("POND_INTEGRATION checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
func capture(label: String) -> void:
	if output.is_empty(): return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg(output + "/" + label + ".jpeg", 0.9)
