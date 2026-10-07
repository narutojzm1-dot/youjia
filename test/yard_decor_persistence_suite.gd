extends SceneTree
const Controller := preload("res://scripts/inventory/yard_decor_controller.gd")
var checks := 0
var failures: Array[String] = []
var store

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func settle() -> void:
	check(await store.flush_pending(), "native FIFO flush acknowledged")
	for frame in 3: await process_frame

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		push_error("Decor persistence requires an isolated player profile")
		quit(2)
		return
	store = root.get_node("SaveStore")
	var id: String = ExplorationRoutes.FIND_FEATHER
	# Fixture: use the production atomic trip grant, without pretending this is
	# an ordinary player's exploration session or a Web/physical-device test.
	var receipt := {}
	store.request_exploration_trip(null, 1, PackedStringArray([id]), receipt)
	await settle()
	check(receipt.granted and store.get_keepsakes()[id] == 1, "trip grants one owned keepsake")
	var controller := Controller.new(store)
	check(controller.request("place", "fence_edge", {"find_id": id, "dx": -1, "dy": 1}), "production placement accepted")
	await settle()
	check(not controller.busy(), "production placement confirmed")
	store._load()
	check(store.get_yard_decor().places.fence_edge.find_id == id, "reopened real file retains placement")
	check(store.get_available_keepsakes()[id] == 0 and store.get_keepsakes()[id] == 1, "reopen preserves reservation without copy")
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(store.SAVE_PATH))
	check(raw is Dictionary and raw.yard_decor.places.fence_edge.dy == 1, "actual disk bytes contain adjustment")
	check(controller.request("move", "fence_edge", {"dx": 1, "dy": 0}), "adjust accepted after load")
	await settle()
	store._load()
	check(store.get_yard_decor().places.fence_edge.dx == 1, "adjustment survives second load")
	controller.request("remove", "fence_edge")
	await settle()
	store._load()
	check(store.get_yard_decor().places.is_empty() and store.get_available_keepsakes()[id] == 1, "return persists without second grant")
	var duplicate_receipt := {}
	store.request_exploration_trip(null, 1, PackedStringArray([id]), duplicate_receipt)
	await settle()
	check(not duplicate_receipt.granted and store.get_keepsakes()[id] == 1, "decor cycle cannot reset exploration deduplication")
	controller = null
	print("YARD_DECOR_PERSISTENCE checks=%d failures=%d" % [checks, failures.size()])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
