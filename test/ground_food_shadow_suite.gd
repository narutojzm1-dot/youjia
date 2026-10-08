extends SceneTree
# REQ-20261008-075（Owner GROK-CONTRIBUTOR）：地上放下的草 / 小鱼 / 小米脚下垫一圈
# 静止柔和接触影，不再像浮着的贴纸。影子随远近缩放、在食物下一层、扁椭圆、暖墨；
# 不改投放 / 拾起 / 取食 / 存档。读档重建会有影子（落地感），不搞落定动画。
var checks := 0
var failures: Array[String] = []
var Shadow: Script
var store

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)

func run() -> void:
	Shadow = load("res://scripts/inventory/ground_food_shadow.gd")
	if Shadow == null:
		failures.append("ground_food_shadow.gd missing")
		print("GROUND_FOOD_SHADOW checks=%d failures=%d" % [checks, failures.size()])
		for failure: String in failures:
			push_error(failure)
		quit(1)
		return
	_unit()
	await _integration()
	print("GROUND_FOOD_SHADOW checks=%d failures=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _unit() -> void:
	for kind: String in ["grass", "millet", "small", "medium", "odd"]:
		var r: Vector2 = Shadow.radii_for(kind)
		check(r.x > r.y * 2.0, "%s shadow is a flat oval" % kind)
		check(r.y >= 3.0 and r.y <= 5.0, "%s shadow height in band (%.1f)" % [kind, r.y])
		check(r.x >= 9.0 and r.x <= 15.0, "%s shadow width in band (%.1f)" % [kind, r.x])
		check(Shadow.radii_for(kind) == r, "%s radii_for is static" % kind)
	check(Shadow.radii_for("grass").x > Shadow.radii_for("millet").x, "grass shadow wider than millet")
	check(Shadow.radii_for("medium").x > Shadow.radii_for("small").x, "medium fish shadow wider than small")
	var node: Node2D = Shadow.new()
	root.add_child(node)
	node.configure("grass", 1.0)
	check(node.radii() == Shadow.radii_for("grass"), "depth 1 keeps base radii")
	node.configure("grass", 1.2)
	check(is_equal_approx(node.radii().x, Shadow.radii_for("grass").x * 1.2), "near ground scales shadow up")
	node.configure("grass", 0.82)
	check(is_equal_approx(node.radii().x, Shadow.radii_for("grass").x * 0.82), "far ground scales shadow down")
	node.queue_free()

func _integration() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		failures.append("isolated data missing for integration")
		return
	store = root.get_node("SaveStore")
	root.size = Vector2i(1280, 720)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for _i in 3:
		await process_frame
	await main._start_holiday()
	main.set_process(false)
	var world = main._world
	var food = world.ground_food
	check(food.shadows.is_empty(), "holiday start has no food shadows")
	# Direct sync（同帧检查）：存档回调会在下一帧用真实账本覆盖，所以几何断言不 await。
	food.sync_items([
		{"id": 11, "kind": "grass", "x": 430.0, "y": 535.0},
		{"id": 12, "kind": "small", "x": 460.0, "y": 540.0},
		{"id": 13, "kind": "millet", "x": 400.0, "y": 530.0},
	])
	check(food.shadows.size() == 3 and food.sprites.size() == 3, "each ground food gets exactly one shadow")
	for id: int in [11, 12, 13]:
		var shadow: Node2D = food.shadows[id]
		var sprite: Sprite2D = food.sprites[id]
		check(is_instance_valid(shadow) and shadow.get_script() == Shadow, "shadow %d is GroundShadow" % id)
		check(shadow.position == sprite.position, "shadow %d sits at the food" % id)
		check(not shadow.z_as_relative and shadow.z_index == sprite.z_index - 1, "shadow %d draws just under the food" % id)
		var depth := YardGround.depth_at(sprite.position.y)
		check(is_equal_approx(shadow.radii().x, Shadow.radii_for(shadow.kind).x * depth), "shadow %d uses depth scale" % id)
	food.sync_items([
		{"id": 11, "kind": "grass", "x": 430.0, "y": 535.0},
		{"id": 12, "kind": "small", "x": 460.0, "y": 540.0},
		{"id": 13, "kind": "millet", "x": 400.0, "y": 530.0},
	])
	check(food.shadows.size() == 3, "re-sync does not duplicate shadows")
	food.sync_items([
		{"id": 11, "kind": "grass", "x": 430.0, "y": 535.0},
		{"id": 13, "kind": "millet", "x": 400.0, "y": 530.0},
	])
	check(not food.shadows.has(12) and food.shadows.size() == 2, "removing food drops its shadow")
	food.sync_items([])
	check(food.shadows.is_empty() and food.sprites.is_empty(), "clearing food clears shadows")
	# 真实投放：等存档确认后影子仍在。
	var player = world.get_player()
	player.position = world._grass_point()
	world._interact_with_target("grass")
	check(await store.flush_pending(), "harvest commit")
	for _i in 3:
		await process_frame
	check(player.carrying_grass, "carrying grass after harvest")
	player.position = Vector2(430, 535)
	world.request_primary_action()
	check(await store.flush_pending(), "drop commit")
	for _i in 3:
		await process_frame
	check(food.items.size() == 1 and food.shadows.size() == 1, "confirmed drop shows food with one shadow")
	if food.items.size() == 1:
		var dropped_id: int = int(food.items[0].id)
		var sh: Node2D = food.shadows.get(dropped_id)
		check(sh != null and sh.kind == "grass", "real drop shadow is grass")
		check(sh != null and sh.z_index == food.sprites[dropped_id].z_index - 1, "real drop shadow under sprite")
	store._load()
	main._on_inventory_changed()
	await process_frame
	check(food.items.size() == 1 and food.shadows.size() == 1, "reload keeps the contact shadow")
	main.queue_free()
	for _i in 3:
		await process_frame
