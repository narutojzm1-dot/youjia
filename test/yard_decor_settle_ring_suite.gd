extends SceneTree
# REQ-20261008-069（Owner GROK-CONTRIBUTOR）：小物在院里放好、存档确认后，脚下泛一圈很淡的
# 暖墨落定圈，0.5 秒内扩大淡出后自己移除。读档重建、重复刷新、同一处只微调都不泛圈；
# 换另一样小物会泛圈；收回时圈立即撤掉。小物本身的位置 / 大小 / 透明度不变（遮挡与照片不受影响），
# 圈不是照片会记录的节点类型；布置编辑暂停小院时圈照常走完；低动效下圈不扩大只淡出。
var checks := 0
var failures: Array[String] = []
# 运行时再 load：SceneTree 脚本编译时自动加载（TuningStore 等）还不存在
var View: Script
var Ring: Script
var Model: Script
const STONE := "formal.find.brook_stone"
const PINE := "formal.find.pine_cone"
const FEATHER := "formal.find.feather"
var store

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func decor(places: Dictionary, revision: int) -> Dictionary:
	return {"schema": 1, "revision": revision, "places": places}

func entry(id: String, dx: int = 0, dy: int = 0) -> Dictionary:
	return {"find_id": id, "dx": dx, "dy": dy}

func rings(view: Node) -> Array:
	return view.get_children().filter(func(c: Node) -> bool: return c.get_script() == Ring and not c.is_queued_for_deletion())

func photo_type(node: Node) -> bool:
	return node is YardPropVisual or node is Sprite2D or node is AnimatedSprite2D or node is Line2D

func unit() -> void:
	var tuning := root.get_node("TuningStore")
	tuning.set_value("ui.reduced_motion", false, false)
	var yard := Node2D.new()
	root.add_child(yard)
	var view = View.new()
	yard.add_child(view)
	view.sync(decor({"house_edge": entry(STONE)}, 1))
	check(rings(view).is_empty(), "first sync (saved placement rebuilt) does not announce")
	view.sync(decor({"house_edge": entry(STONE)}, 1))
	check(rings(view).is_empty(), "unchanged re-sync stays quiet")
	view.sync(decor({"house_edge": entry(STONE, 1, 0)}, 2))
	check(rings(view).is_empty(), "nudging the same keepsake at the same spot stays quiet")
	view.sync(decor({"house_edge": entry(STONE, 1, 0), "fence_edge": entry(PINE)}, 3))
	var found := rings(view)
	check(found.size() == 1, "newly placed keepsake gets exactly one ring")
	if found.size() != 1: return
	var ring = found[0]
	var prop: YardPropVisual = view.visuals.fence_edge
	check(view.settle_rings.get("fence_edge") == ring, "ring tracked under its spot")
	check(ring.position == prop.position and ring.scale == prop.scale, "ring sits at the keepsake with the same depth scale")
	check(not ring.z_as_relative and ring.z_index == prop.z_index - 1, "ring draws just under the keepsake")
	check(ring.process_mode == Node.PROCESS_MODE_ALWAYS, "ring keeps running while the editor pauses the yard")
	check(not photo_type(ring), "ring is not a node type photos record")
	check(prop.modulate == Color.WHITE and prop.position == Model.position_for("fence_edge", entry(PINE)), "keepsake itself keeps its colour and position")
	check(prop.scale == Vector2.ONE * YardGround.depth_at(prop.position.y), "keepsake keeps its depth scale")
	check(ring.radii() == Ring.START_RADII and is_equal_approx(ring.fade(), 1.0), "ring starts small and fully visible")
	check(not ring.reduced, "normal motion ring grows")
	view.sync(decor({"house_edge": entry(STONE, 1, 0), "fence_edge": entry(PINE)}, 3))
	await process_frame
	check(is_instance_valid(ring) and rings(view).size() == 1, "panel refresh keeps the running ring and adds none")
	paused = true
	await create_timer(0.22, true, false, true).timeout
	check(is_instance_valid(ring) and ring.radii().x > Ring.START_RADII.x and ring.radii().x <= Ring.END_RADII.x, "ring widens while the yard is paused")
	check(is_instance_valid(ring) and ring.fade() < 1.0 and ring.fade() > 0.0, "ring fades while widening")
	await create_timer(0.5, true, false, true).timeout
	await process_frame
	check(not is_instance_valid(ring), "ring removes itself after its half second")
	paused = false
	view.sync(decor({"house_edge": entry(STONE, 1, 0), "fence_edge": entry(PINE)}, 3))
	check(view.settle_rings.is_empty() and rings(view).is_empty(), "finished ring forgotten, re-sync quiet")
	view.sync(decor({"house_edge": entry(FEATHER, 1, 0), "fence_edge": entry(PINE)}, 4))
	found = rings(view)
	check(found.size() == 1 and view.settle_rings.has("house_edge"), "swapping to another keepsake at a spot announces it")
	view.sync(decor({"fence_edge": entry(PINE)}, 5))
	await process_frame
	check(rings(view).is_empty() and view.settle_rings.is_empty(), "returning the keepsake drops its ring at once")
	view.sync(decor({}, 6))
	view.sync(decor({"fence_edge": entry(PINE)}, 7))
	view.sync(decor({}, 8))
	view.sync(decor({"fence_edge": entry(PINE)}, 9))
	check(rings(view).size() == 1, "quick place / return / place keeps a single ring")
	tuning.set_value("ui.reduced_motion", true, false)
	view.sync(decor({"fence_edge": entry(PINE), "pond_path": entry(STONE)}, 10))
	var calm = view.settle_rings.get("pond_path")
	check(calm != null and calm.reduced, "low-motion ring is marked calm")
	if calm != null:
		var start: Vector2 = calm.radii()
		calm.elapsed = 0.3
		check(calm.radii() == start and calm.radii() == Ring.CALM_RADII, "low-motion ring does not grow")
		check(calm.fade() < 1.0, "low-motion ring still fades out")
	tuning.set_value("ui.reduced_motion", false, false)
	view.show_preview("house_edge", entry(FEATHER))
	view.sync(decor({"fence_edge": entry(PINE), "pond_path": entry(STONE)}, 10))
	check(is_instance_valid(view.preview), "decor preview still survives sync")
	view.clear_preview()
	yard.queue_free()
	await process_frame

func settle_save() -> void:
	check(await store.flush_pending(), "production save confirmed")
	for frame in 3: await process_frame

func integration() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		push_error("Settle ring integration requires isolated data")
		failures.append("isolated data missing")
		return
	store = root.get_node("SaveStore")
	root.size = Vector2i(390, 844)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for frame in 3: await process_frame
	await main._start_holiday()
	var id: String = ExplorationRoutes.FIND_PINE_CONE
	store.request_exploration_trip(null, 1, PackedStringArray([id]), {})
	await settle_save()
	var view = main._world.decor_view
	check(view.settle_rings.is_empty(), "starting the holiday shows no ring")
	main._show_basket()
	main._basket_panel.decor_button.pressed.emit()
	main._decor_panel.choose_spot("house_edge")
	main._decor_panel.choose_find(id)
	check(rings(view).is_empty(), "preview alone shows no ring")
	main._decor_panel.commit()
	check(rings(view).is_empty(), "no ring before the save confirms")
	await settle_save()
	var ring = view.settle_rings.get("house_edge")
	check(ring != null and is_instance_valid(ring), "confirmed placement in the real yard shows the ring")
	check(ring != null and ring.position == view.visuals.house_edge.position, "real ring sits at the placed keepsake")
	var moment := PhotoMoment.capture(main._world, {"id": "sheep_pair_near"})
	var keepsakes: Array = moment.items.filter(func(item: Dictionary) -> bool: return item.get("subject") == "keepsake")
	check(keepsakes.size() == 1, "photo taken during the ring still records exactly one keepsake")
	await create_timer(0.7, true, false, true).timeout
	await process_frame
	check(not is_instance_valid(ring) and rings(view).is_empty(), "real ring finishes while the editor pauses the yard")
	main._hide_decor()
	main._hide_basket()
	store._load()
	main._on_decor_changed()
	check(rings(view).is_empty(), "reloading the same placement stays quiet")
	await settle_save()
	main.queue_free()
	for frame in 3: await process_frame

func run() -> void:
	View = load("res://scripts/inventory/yard_decor_view.gd")
	Ring = load("res://scripts/inventory/yard_decor_settle_ring.gd")
	Model = load("res://scripts/inventory/yard_decor.gd")
	await unit()
	await integration()
	print("YARD_DECOR_SETTLE_RING checks=%d failures=%d" % [checks, failures.size()])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
