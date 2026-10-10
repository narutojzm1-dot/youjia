extends SceneTree
## Real SaveStore, Coordinator and native disk; only isolated fixture counts/time.
const Codec = preload("res://scripts/persistence/save_data_codec.gd")
const STONE = "formal.find.brook_stone"
const CONE = "formal.find.pine_cone"
var store: Node
var checks := 0
var failures: Array[String] = []
var rejected: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func seed_counts(counts: Dictionary, serial := 0) -> void:
	store.request_patch("capacity_fixture", {"keepsakes": counts, "exploration_committed_serial": serial, "exploration": null})
	check(await store.flush_pending(), "fixture committed through native coordinator")

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return
	store = root.get_node("SaveStore")
	store.commit_rejected.connect(func(id: String, _kind: String, code: String): rejected[id] = code)
	await boundaries()
	await fifo()
	await host_retry()
	await domain_ui()
	print("EXPLORATION_TRIP_CAPACITY checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func boundaries() -> void:
	for finds in [PackedStringArray([STONE, CONE]), PackedStringArray([CONE, STONE]), PackedStringArray([CONE, STONE, STONE])]:
		await seed_counts({STONE: Codec.MAX_KEEPSAKE_COUNT})
		var before: PackedByteArray = FileAccess.get_file_as_bytes(store.SAVE_PATH)
		var receipt := {}
		var id: String = store.request_exploration_trip({"capacity_probe": true}, 1, finds, receipt)
		check(not id.is_empty() and receipt.is_empty(), "acceptance is not a grant")
		check(await store.flush_pending(), "typed rejection drains queue")
		check(rejected.get(id) == "EXPLORATION_KEEPSAKE_LIMIT", "overflow has exact domain reason")
		check(receipt.get("granted") == false, "refused grant is false")
		check(store.get_keepsakes() == {STONE: Codec.MAX_KEEPSAKE_COUNT}, "mixed trip grants nothing regardless of order")
		check(store.get_exploration_committed_serial() == 0 and store.get_exploration_record() == null, "refusal leaves watermark and record intact")
		check(FileAccess.get_file_as_bytes(store.SAVE_PATH) == before, "refusal never rewrites native bytes")
	await seed_counts({STONE: Codec.MAX_KEEPSAKE_COUNT - 1})
	var repeated := {}
	var op: String = store.request_exploration_trip(null, 1, PackedStringArray([STONE, STONE]), repeated)
	await store.flush_pending()
	check(rejected.get(op) == "EXPLORATION_KEEPSAKE_LIMIT" and store.get_keepsakes()[STONE] == Codec.MAX_KEEPSAKE_COUNT - 1, "aggregate repeats cannot partially fit")
	var exact := {}
	store.request_exploration_trip(null, 1, PackedStringArray([STONE, CONE]), exact)
	check(await store.flush_pending() and exact.get("granted") == true, "exact boundary fits without truncation")
	check(store.get_keepsakes() == {STONE: Codec.MAX_KEEPSAKE_COUNT, CONE: 1}, "all exact-fit finds committed")
	var duplicate := {}
	store.request_exploration_trip(null, 1, PackedStringArray([STONE, STONE]), duplicate)
	await store.flush_pending()
	check(duplicate.get("granted") == false and store.get_exploration_committed_serial() == 1, "duplicate trip skips capacity check and never regrants")
	var empty := {}
	store.request_exploration_trip(null, 2, PackedStringArray(), empty)
	await store.flush_pending()
	check(empty.get("granted") == true and store.get_exploration_committed_serial() == 2, "empty return works even with full inventory")
	store._load()
	check(store.get_keepsakes() == {STONE: Codec.MAX_KEEPSAKE_COUNT, CONE: 1} and store.get_exploration_committed_serial() == 2, "native reopen preserves exact totals and watermark")

func fifo() -> void:
	await seed_counts({STONE: Codec.MAX_KEEPSAKE_COUNT - 1})
	var first := {}
	var second := {}
	store.request_exploration_trip(null, 1, PackedStringArray([STONE]), first)
	var id: String = store.request_exploration_trip(null, 2, PackedStringArray([CONE, STONE]), second)
	await store.flush_pending()
	check(first.get("granted") == true and second.get("granted") == false and rejected.get(id) == "EXPLORATION_KEEPSAKE_LIMIT", "queued trip checks newest confirmed count")
	check(store.get_exploration_committed_serial() == 1 and store.get_keepsakes() == {STONE: Codec.MAX_KEEPSAKE_COUNT}, "second queued refusal cannot advance or partially grant")
	store.request_patch("capacity_room", {"keepsakes": {STONE: Codec.MAX_KEEPSAKE_COUNT - 1}})
	var retry := {}
	store.request_exploration_trip(null, 2, PackedStringArray([CONE, STONE]), retry)
	await store.flush_pending()
	check(retry.get("granted") == true and store.get_keepsakes() == {STONE: Codec.MAX_KEEPSAKE_COUNT, CONE: 1}, "earlier FIFO operation can make room for complete retry")

func host_retry() -> void:
	await seed_counts({})
	var host := ExplorationHost.new(store)
	host.restore()
	var find := ""
	for value in 100:
		var session := ExplorationSession.new(ExplorationRoutes.catalog(), 0)
		session.begin(ExplorationRoutes.NEAR_PATH, {"day": 1, "elapsed": 10.0}, value)
		find = str(session.get_view().get("offer", ""))
		if not find.is_empty():
			host.begin({"day": 1, "elapsed": 10.0}, value)
			break
	check(not find.is_empty() and host.take(find).ok, "real formal host carries a find")
	store.request_patch("capacity_fixture", {"keepsakes": {find: Codec.MAX_KEEPSAKE_COUNT}})
	await store.flush_pending()
	host.request_return()
	await store.flush_pending()
	check(host.last_outcome.get("state") == "deferred" and host.pending_items() == PackedStringArray([find]), "host retains refused proposal without claiming kept")
	check(store.get_exploration_committed_serial() == 0, "host refusal does not commit trip")
	store.commit_confirmed.disconnect(host._on_confirmed)
	store.commit_rejected.disconnect(host._on_rejected)
	host = null
	store._load()
	var restored := ExplorationHost.new(store)
	restored.restore()
	await store.flush_pending()
	check(restored.last_outcome.get("state") == "deferred" and restored.pending_items() == PackedStringArray([find]), "reopen retains full ungranted proposal")
	store.request_patch("capacity_room", {"keepsakes": {find: Codec.MAX_KEEPSAKE_COUNT - 1}})
	await store.flush_pending()
	restored.retry_deferred()
	await store.flush_pending()
	check(restored.last_outcome.get("state") == "committed" and restored.last_outcome.items == PackedStringArray([find]), "same host proposal retries after room exists")
	check(store.get_keepsakes() == {find: Codec.MAX_KEEPSAKE_COUNT} and store.get_exploration_committed_serial() == 1, "retry grants exactly once with watermark")
	store._load()
	check(store.get_exploration_record().session == null and store.get_exploration_committed_serial() == 1, "completed retry reopens idle without lost find")

func domain_ui() -> void:
	await seed_counts({})
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	var host: ExplorationHost = main._exploration.host
	var find := ""
	for value in 100:
		var session := ExplorationSession.new(ExplorationRoutes.catalog(), 0)
		session.begin(ExplorationRoutes.NEAR_PATH, {"day": 1, "elapsed": 10.0}, value)
		find = str(session.get_view().get("offer", ""))
		if not find.is_empty():
			host.begin({"day": 1, "elapsed": 10.0}, value)
			break
	host.take(find)
	store.request_patch("capacity_fixture", {"keepsakes": {find: Codec.MAX_KEEPSAKE_COUNT}})
	await store.flush_pending()
	host.request_return()
	await store.flush_pending()
	check(host.last_outcome.get("state") == "deferred", "Main's own host defers full return")
	check(not main._save_problem_active and main._save_problems.is_empty(), "capacity is not a phantom disk-save failure")
	check(main._save_exploration_scopes.is_empty() and main._save_exploration_coverage.is_empty(), "domain rejection releases accepted identity bookkeeping")
	var folder := OS.get_environment("YOUJIA_CAPTURE_DIR")
	if not folder.is_empty() and not DisplayServer.get_name() == "headless":
		DirAccess.make_dir_recursive_absolute(folder)
		for i in 8: await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_jpg(folder.path_join("capacity-deferred-yard.jpg"), 0.9) == OK, "GPU deferred yard capture saved")
	store.request_patch("capacity_room", {"keepsakes": {find: Codec.MAX_KEEPSAKE_COUNT - 1}})
	await store.flush_pending()
	host.retry_deferred()
	await store.flush_pending()
	check(host.last_outcome.get("state") == "committed" and not main._save_problem_active, "Main's own host retries without global phantom save UI")
	main.queue_free()
	await process_frame
	root.get_node("AudioDirector").release_streams()
