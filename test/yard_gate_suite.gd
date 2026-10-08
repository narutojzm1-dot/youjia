extends SceneTree
const Ground := preload("res://scripts/game/yard_gate_ground.gd")
const Codec := preload("res://scripts/persistence/save_data_codec.gd")
var checks := 0
var failures: Array[String] = []
class ReceiptStore extends Node:
	signal commit_confirmed(op_id: String, kind: String)
	signal commit_rejected(op_id: String, kind: String, code: String)
	signal commit_unknown(op_id: String, kind: String, code: String)
	var requests := 0
	func request_yard_gate(_opened: bool) -> String:
		requests += 1
		return "controlled-%d" % requests
	func get_yard_gate_open() -> bool: return false
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func settle(store: Node) -> void:
	check(await store.flush_pending(), "native commit acknowledged")
	for i in 3: await process_frame
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return
	check(not Codec.project({}).yard_gate_open, "old save starts closed")
	for invalid: Variant in ["true", 1, [], {}]:
		check(not Codec.project({"yard_gate_open":invalid}).yard_gate_open, "invalid gate value stays closed")
	var radius := YardBodies.radius_for("player")
	check(YardBodies.route(Vector2(830,520), Ground.INSIDE, radius, [], Ground.outside()).is_empty(), "closed gate blocks entry")
	check(YardBodies.route(Ground.INSIDE, Ground.OUTSIDE, radius, [], Ground.inside()).is_empty(), "closed gate blocks exit")
	for endpoints: Array in [[Vector2(830,520),Vector2(1080,484)],[Vector2(1080,484),Vector2(830,520)]]:
		var path := YardBodies.route(endpoints[0],endpoints[1],radius,[],Ground.connected())
		check(not path.is_empty(), "open gate routes both ways around fence")
		var prior: Vector2 = endpoints[0]
		var crossed := false
		for point: Vector2 in path:
			check(YardBodies._ground_segment(prior,point,Ground.connected(),true), "each segment stays within connected ground")
			for i in 101:
				var sample := prior.lerp(point, float(i)/100)
				if Ground.THRESHOLD.has_point(sample): crossed = true
			prior = point
		check(crossed, "route crosses actual doorway")
	check(not YardBodies._ground_segment(Vector2(960,535),Vector2(970,465),Ground.connected(),true), "front fence is not a shortcut")
	var store = root.get_node("SaveStore")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	await settle(store)
	var world = main._world
	var receipts := ReceiptStore.new()
	root.add_child(receipts)
	var controlled = load("res://scripts/game/yard_gate.gd").new(world,receipts,false)
	root.add_child(controlled)
	controlled.toggle()
	receipts.commit_rejected.emit(controlled.pending,"yard-gate","disk-full")
	check(not controlled.opened and controlled.pending.is_empty(), "rejected receipt leaves closed geometry and allows retry")
	controlled.toggle()
	var uncertain: String = controlled.pending
	receipts.commit_unknown.emit(uncertain,"yard-gate","timeout")
	controlled.toggle()
	check(not controlled.opened and controlled.pending == uncertain and receipts.requests == 2, "unknown result retains operation and prevents a contradictory retry")
	controlled.free()
	receipts.free()
	world.debug_place_player(Ground.OUTSIDE)
	world.get_player().carrying_grass = true
	check(YardSceneHotspots.resolve(world,"fence_gate").target == "fence_gate", "explicit gate remains usable with durable carried food")
	world.get_player().carrying_grass = false
	check(world.primary_action_key() == "action.open_gate", "HUD offers opening outside")
	world._interact_with_target("fence_gate")
	check(not world.gate.opened and not world.gate.pending.is_empty(), "no optimistic geometry before receipt")
	var op: String = world.gate.pending
	world.gate.toggle()
	check(world.gate.pending == op, "double tap does not queue toggle twice")
	world.tick(1.0,Vector2.UP)
	check(world.get_player().position == Ground.OUTSIDE, "commit window freezes doorway movement")
	await settle(store)
	check(world.gate.opened and store.get_yard_gate_open(), "confirmed opening updates geometry and save")
	var moment := PhotoMoment.capture(world,ExpressionCatalog.find_rule("llama_fed_gentle"))
	check(moment.get("yard_gate",{}).get("opened",false), "photo records actual open door")
	var restored_photo := PhotoMoment.sanitize(JSON.parse_string(JSON.stringify(moment)))
	check(restored_photo.get("yard_gate",{}).get("opened",false), "photo JSON roundtrip retains open door")
	var old_photo := moment.duplicate(true)
	old_photo.erase("yard_gate")
	check(not PhotoMoment.sanitize(old_photo).has("yard_gate"), "old photo gains no invented gate state")
	world.request_pointer_action(Vector2(1000,471))
	for i in 1200:
		world.tick(1.0/60.0,Vector2.ZERO)
		if not world._has_walk_goal: break
	print("GATE_WALK feet=",world.get_player().position," path=",world._walk_path," ground=",world.get_player().walk_ground)
	check(world.get_player().position.distance_to(Vector2(1000,471)) < 12.0, "production tick walks through the doorway into the pen")
	world.debug_place_player(Vector2(914,492))
	world.gate.toggle()
	check(world.gate.opened and world.gate.pending.is_empty(), "cannot close onto player")
	world.debug_place_player(Ground.OUTSIDE)
	var sheep = world.actor_named("sheep_a")
	var original: Vector2 = sheep.position
	sheep.position = Vector2(914,492)
	world.gate.toggle()
	check(world.gate.opened and world.gate.pending.is_empty(), "cannot close onto an animal footprint")
	sheep.position = original
	world.debug_place_player(Ground.INSIDE)
	check(world.primary_action_key() == "action.close_gate", "inside approach can close gate")
	world._interact_with_target("fence_gate")
	await settle(store)
	check(not world.gate.opened and YardGround.contains(world.get_player().walk_ground,Ground.INSIDE), "closing inside preserves interior ground")
	check(world.primary_action_key() == "action.open_gate", "inside player can reopen without being trapped")
	world._interact_with_target("fence_gate")
	await settle(store)
	store._load()
	await main._start_holiday(false)
	main.set_process(false)
	check(main._world.gate.opened, "fresh world restores open gate from disk")
	check(main._world.gate_view.patch.visible, "restored geometry matches visual opening")
	main.queue_free()
	await process_frame
	root.get_node("AudioDirector").release_streams()
	print("YARD_GATE checks=%d failures=%d" % [checks,failures.size()])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
