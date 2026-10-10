extends SceneTree
const Slots := preload("res://scripts/persistence/hotbar_slots.gd")
const Codec := preload("res://scripts/persistence/save_data_codec.gd")
const Controller := preload("res://scripts/persistence/hotbar_save_controller.gd")
var checks := 0
var failures: Array[String] = []
class FakeStore extends Node:
	signal commit_confirmed(op_id: String, kind: String)
	signal commit_rejected(op_id: String, kind: String, code: String)
	var saved: Array = ["", "", "", "", ""]
	var present := false
	var accept := true
	var requests: Array = []
	func has_hotbar_slots() -> bool: return present
	func get_hotbar_slots() -> Array: return saved.duplicate()
	func request_hotbar_slots(slots: Array) -> String:
		if not accept: return ""
		requests.append(slots.duplicate())
		return str(requests.size())
	func confirm(id: String) -> void:
		saved = requests[int(id)-1].duplicate()
		present = true
		commit_confirmed.emit(id,"hotbar-slots")
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return
	check(Slots.clean(["grass","grass",123,{},"corn","wheat"]) == ["grass","","","","corn"],"bounded references, type filtering and deduplication")
	check(Slots.clean(null) == ["","","","",""],"malformed means empty")
	check(not Codec.project({}).has("hotbar_slots"),"old save remains migration eligible")
	check(Codec.project({"hotbar_slots":[]}).hotbar_slots == Slots.clean([]),"explicit empty is authoritative")
	var source := {"hotbar_slots":["grass","wheat"]}
	var projection := Codec.project(source)
	projection.hotbar_slots[0] = "corn"
	check(source.hotbar_slots == ["grass","wheat"],"projection cannot mutate raw evidence")
	var fake := FakeStore.new()
	root.add_child(fake)
	var controller := Controller.new()
	root.add_child(controller)
	controller.initialize(fake,["corn"])
	check(controller.state == "pending" and not fake.present,"legacy migration waits for confirmation")
	controller.change(["grass"])
	controller.change(["wheat","corn"])
	check(fake.requests.size() == 1,"rapid edits coalesce behind unresolved identity")
	fake.confirm("1")
	check(fake.requests.size() == 2 and controller.active == "2", "latest preference follows confirmed migration")
	fake.confirm("2")
	check(fake.saved == Slots.clean(["wheat","corn"]) and controller.state == "ready","last choice wins")
	controller.change(["millet"])
	fake.commit_rejected.emit("3","hotbar-slots","WRITE_FAILED")
	check(controller.state == "failed" and fake.saved == Slots.clean(["wheat","corn"]),"failed write does not publish candidate")
	controller.change(["small"])
	check(fake.requests.size() == 3,"failure does not silently requeue")
	check(controller.retry() == "4","explicit retry creates new identity only after rejection")
	fake.confirm("4")
	check(fake.saved == Slots.clean(["small"]),"retry preserves latest choice")
	controller.change(["odd"])
	controller.change(["medium"])
	check(controller.active == "5" and controller.retry().is_empty(),"unresolved write cannot be replaced")
	fake.confirm("5")
	fake.confirm("6")
	check(fake.saved == Slots.clean(["medium"]),"resolved old receipt then latest proposal")
	controller.queue_free()
	await process_frame
	controller = Controller.new()
	root.add_child(controller)
	fake.saved = Slots.clean([])
	controller.initialize(fake,["grass"])
	check(controller.desired == Slots.clean([]) and fake.requests.size() == 6,"saved empty slots must not resurrect native cfg")
	fake.accept = false
	controller.change(["corn"])
	check(controller.state == "failed" and controller.active.is_empty(),"unavailable store remains unsaved")
	controller.queue_free()
	fake.queue_free()
	var store = root.get_node("SaveStore")
	var original: Dictionary = store._data.duplicate(true)
	var op: String = store.request_hotbar_slots(["grass", "wheat", "corn"])
	check(not op.is_empty() and not store.has_hotbar_slots(),"acceptance is not durability")
	check(await store.flush_pending(),"native shared transaction confirmed")
	check(store.get_hotbar_slots() == Slots.clean(["grass","wheat","corn"]),"confirmed getters expose choices")
	var disk: Variant = JSON.parse_string(FileAccess.get_file_as_string(store.SAVE_PATH))
	check(disk.hotbar_slots == Slots.clean(["grass","wheat","corn"]),"real file contains slot references")
	for key in original:
		check(store._data.get(key) == original[key],"preferences preserve other state: "+str(key))
	store._load()
	check(store.get_hotbar_slots() == Slots.clean(["grass","wheat","corn"]),"real reread restores configured slots")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	check(main._hold_hotbar.slots == Slots.clean(["grass","wheat","corn"]),"production mount reads shared slots")
	main._hold_hotbar.assign("millet",4)
	check(await store.flush_pending(),"production assignment shares writer")
	check(store.get_hotbar_slots()[4] == "millet","production signal persisted")
	main.queue_free()
	await process_frame
	for failure in failures: push_error(failure)
	print("HOTBAR_PERSISTENCE checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
