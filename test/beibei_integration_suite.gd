extends SceneTree
const Controller := preload("res://scripts/game/world_residents_controller.gd")
var checks := 0
var failures := 0
var output := ""
var saw_growth_pending := false
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
	check(not store.prepare_resident_intent(0, "adopt_beibei").is_valid(), "yard cannot prepare an encounter")
	var controller := Controller.new(store)
	controller.changed.connect(func() -> void:
		if controller.pending.get("action", "") == "grow_beibei" and controller.view().beibei.stage == "puppy": saw_growth_pending = true)
	var host := ExplorationHost.new(store)
	host.restore()
	check(host.begin({"day": 1, "elapsed": 0.0}, 7, {"nearby": [], "rope": "llama"}).ok, "begin production trip")
	check(await store.flush_pending(), "trip confirmed")
	var scene: Node2D = load("res://scripts/exploration/near_path_scroll.gd").new()
	root.add_child(scene)
	scene.setup(host, "sunny", controller)
	scene.set_process(false)
	check(not scene.cross_page(), "cannot jump to village from yard end")
	scene.spot = {"arm": "lane", "d": 0.0}
	check(scene.cross_page() and scene.village, "walked page boundary opens village")
	check(scene.stray != null and scene.stray.actor.actor_id == "beibei", "unmet puppy exists in actual village page")
	check(scene.companion.choice.actor_id == "llama", "original companion remains on page crossing")
	scene.place_at("village_stray")
	scene.observe()
	check(await store.flush_pending(), "village encounter stop is durable")
	scene._update_resident()
	scene._refresh()
	await capture("meeting-1280")
	for locale: String in ["zh-CN", "en"]:
		root.get_node("I18n").set_locale(locale)
		for size: Vector2i in [Vector2i(390, 844), Vector2i(568, 320)]:
			root.size = size
			await process_frame
			scene.walk(Vector2.ZERO, 0.0)
			scene._show_caption(scene._observe_caption(), 0.0)
			scene._refresh()
			check(scene._caption.get_rect().end.y < scene._pick_button.position.y, "meeting text leaves both actions accessible %s/%d" % [locale, size.x])
			check(scene._pick_button.get_rect().end.x < scene._go_button.position.x, "adopt and continue do not overlap")
			await capture("meeting-%s-%d" % [locale, size.x])
	root.get_node("I18n").set_locale("zh-CN")
	root.size = Vector2i(1280, 720)
	await process_frame
	scene.walk(Vector2.ZERO, 0.0)
	var frozen_retry: Callable = store.prepare_resident_intent(0, "adopt_beibei")
	check(frozen_retry.is_valid(), "only confirmed encounter can freeze rescue intent")
	check(scene.pick(), "adopt through production scene and controller")
	check(controller.view().beibei.stage == "unmet" and not scene._rescued_here, "acceptance is not a rescued puppy")
	check(not scene.pick(), "double click while saving cannot duplicate acquisition")
	check(await store.flush_pending(), "adoption commits")
	scene._update_resident()
	scene._refresh()
	check(scene._rescued_here and controller.view().beibei.stage == "puppy", "confirmed puppy follows")
	check(host.view().carried.is_empty(), "puppy uses no basket slot")
	await capture("adopted-1280")
	for size: Vector2i in [Vector2i(390, 844), Vector2i(568, 320)]:
		root.size = size
		await process_frame
		scene.walk(Vector2.ZERO, 0.0)
		scene._refresh()
		check(scene._go_button.get_rect().end.x <= size.x and scene._caption.get_rect().end.y < scene._go_button.position.y, "encounter caption fits above controls at %d" % size.x)
		await capture("adopted-%d" % size.x)
	root.size = Vector2i(1280, 720)
	scene.end_observe()
	var puppy_before: Vector2 = scene.stray.actor.position
	scene.walk_target = {"arm": "lane", "d": 0.0}
	for i in 80: scene.walk(Vector2.ZERO, 0.1)
	check(scene.stray.actor.position.distance_to(puppy_before) > 40, "rescued puppy moves with walker")
	check(scene.cross_page() and not scene.village and scene.stray != null, "puppy follows back across page")
	check(scene.companion != null, "rescue does not replace rope companion")
	host.request_return("player")
	check(await store.flush_pending(), "return settles existing ledger")
	var retry_snapshot: Dictionary = store._data.duplicate(true)
	retry_snapshot.erase("world_residents")
	retry_snapshot.erase("exploration")
	retry_snapshot.other_feature = {"value": 77}
	var retry_result: Variant = frozen_retry.call(retry_snapshot)
	check(retry_result is Dictionary and retry_result.world_residents.beibei.stage == "puppy", "frozen confirmed encounter can retry after return cleanup")
	check(not retry_result.has("exploration") and retry_result.other_feature.value == 77, "retry never restores obsolete trip or overwrites concurrent data")
	var duplicate_result: Variant = frozen_retry.call(store._data)
	check(duplicate_result is SaveCoordinator.IntentRejection, "confirmed adoption cannot be reissued through old intent")
	scene.release()
	root.remove_child(scene)
	scene.queue_free()
	store._load()
	check(store.get_world_residents().beibei.stage == "puppy", "actual native reopen retains adopted dog")
	var world: Node2D = load("res://scripts/game/yard_world.gd").new()
	root.add_child(world)
	world.setup()
	world.sync_residents(controller.view())
	var puppy: Node2D = world.actor_named("beibei")
	world.sync_residents(controller.view())
	check(puppy != null and world.actor_named("beibei") == puppy, "repeated sync creates exactly one yard puppy")
	world.debug_place_player(puppy.position + Vector2(45, 0))
	check("beibei" not in world.companion_context().nearby, "puppy is not eligible for random later trips yet")
	check(YardInteraction.selected(world, "pet:beibei").get("target", "") == "pet:beibei", "puppy can be petted")
	world.tick(0.0, Vector2.ZERO)
	check(YardInteraction.pointer(world, puppy.visual_hit_rect().get_center()).get("target", "") == "pet:beibei", "ordinary pointer can select puppy silhouette")
	var camera := Camera2D.new()
	world.add_child(camera)
	camera.position = Vector2(640, 360)
	camera.make_current()
	world.tick(0.0, Vector2.ZERO)
	await capture("yard-puppy-1280")
	store.request_patch("yard", {"holiday_day": 4, "holiday_day_elapsed": 0.0})
	check(await store.flush_pending(), "controlled game-clock fixture commits")
	await process_frame
	check(saw_growth_pending, "growth request waits for own confirmation")
	check(await store.flush_pending(), "growth commits after confirmed game clock")
	world.sync_residents(controller.view())
	var adult: Node2D = world.actor_named("beibei")
	check(adult != puppy and adult.get_meta("resident_stage") == "grown", "growth swaps whole cel for same resident")
	world.debug_place_player(adult.position + Vector2(45, 0))
	check("beibei" in world.companion_context().nearby, "grown nearby beibei may accompany next trip")
	check(AnimalCompanions.valid_choice({"actor_id": "beibei", "mode": "nearby"}), "grown companion persists in trip contract")
	var path_dog: Node2D = load("res://scripts/exploration/path_companion.gd").new()
	world.add_child(path_dog)
	path_dog.setup({"actor_id": "beibei", "mode": "nearby"}, NearPathLayout.START)
	check(path_dog.actor._sprite.texture.resource_path.ends_with("beibei/grown.png"), "later trips use the mature whole-body artwork")
	world.remove_child(path_dog)
	path_dog.queue_free()
	world.tick(0.0, Vector2.ZERO)
	await capture("yard-grown-1280")
	store._load()
	check(store.get_world_residents().beibei.stage == "grown", "native reload cannot shrink adult")
	world.sync_residents(controller.view())
	check(world.actor_named("beibei") == adult, "native reload does not duplicate adult")
	root.remove_child(world)
	world.queue_free()
	print("BEIBEI_INTEGRATION checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func capture(label: String) -> void:
	if output.is_empty(): return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg(output + "/" + label + ".jpeg", 0.9)
