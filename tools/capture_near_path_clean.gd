extends SceneTree
# 近郊清底换图的体验证据：优先在离清底区（画面 x1256–1428, y761–841）最近的“门口”停下看、带上，
# 门口不给的拾物换别的停处；截取到达、看时与带上后的画面，检查画里不再有与可拾松果/落羽重复的旧画物。
# 需要真实渲染器（非 --headless）。
# YOUJIA_CAPTURE_DIR=<dir> YOUJIA_CAPTURE_TAG=<tag> godot --path . --resolution 1280x720 --script tools/capture_near_path_clean.gd

const MemoryStore := preload("res://test/fixtures/exploration_memory_store.gd")
const CLOCK := {"day": 3, "elapsed": 12.5}
const STOP := "gate"
const WANTS := [ExplorationRoutes.FIND_PINE_CONE, ExplorationRoutes.FIND_FEATHER]

var folder := ""
var tag := ""
var log_lines: PackedStringArray = []


func _initialize() -> void:
	call_deferred("record")


func note(text: String) -> void:
	print("[near-path-clean-capture] ", text)
	log_lines.append(text)


func find_seed(want: String) -> Dictionary:
	var stops: Array = [STOP]
	for stop_id in ExplorationRoutes.NEAR_PATH_STOPS:
		if stop_id != STOP:
			stops.append(stop_id)
	for stop_id in stops:
		for value in 4000:
			var session := ExplorationSession.new(ExplorationRoutes.catalog(), 0)
			session.begin(ExplorationRoutes.NEAR_PATH, CLOCK, value)
			session.visit(stop_id)
			if str(session.get_view().get("offer", "")) == want:
				return {"stop": stop_id, "seed": value}
	return {}


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("%s/%s-%s.png" % [folder, tag, name])


func capture(want: String) -> void:
	var found := find_seed(want)
	var short_name := want.get_slice(".", 2)
	if found.is_empty():
		note("%s: no stop offers it" % short_name)
		return
	var seed_value: int = found.seed
	var stop_id: String = found.stop
	var store := MemoryStore.new()
	var host := ExplorationHost.new(store)
	host.restore()
	host.begin(CLOCK, seed_value)
	var scroll: Node2D = load("res://scripts/exploration/near_path_scroll.gd").new()
	root.add_child(scroll)
	scroll.setup(host, "sunny")
	scroll.place_at(stop_id)
	for i in 10:
		await process_frame
	await shot("%s-0-arrive" % short_name)
	scroll.observe()
	for i in 6:
		await process_frame
	await shot("%s-1-look" % short_name)
	var ok: bool = scroll.pick()
	scroll.reveal.settle()
	for i in 6:
		await process_frame
	await shot("%s-2-carried" % short_name)
	var size := root.get_visible_rect().size
	note("%s view %dx%d stop %s seed %d picked %s carried %s" % [short_name, size.x, size.y, stop_id, seed_value, ok, scroll.carried()])
	scroll.queue_free()
	store.free()
	await process_frame


func record() -> void:
	folder = OS.get_environment("YOUJIA_CAPTURE_DIR")
	tag = OS.get_environment("YOUJIA_CAPTURE_TAG")
	DirAccess.make_dir_recursive_absolute(folder)
	await process_frame
	var art: Texture2D = load(NearPathLayout.ART)
	note("%s art %s %dx%d" % [tag, NearPathLayout.ART, art.get_width(), art.get_height()])
	for want in WANTS:
		await capture(want)
	var file := FileAccess.open("%s/%s-capture-log.txt" % [folder, tag], FileAccess.WRITE)
	file.store_string("\n".join(log_lines) + "\n")
	file.close()
	quit(0)
