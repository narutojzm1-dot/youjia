extends SceneTree
# 拾起短展示的体验证据：真实画卷与宿主（内存存档替身），在溪声近处停下看、带上，
# 按固定时刻截取展示帧；另截低动效一组。需要真实渲染器（非 --headless）。
# YOUJIA_CAPTURE_DIR=<dir> godot --path . --resolution 1280x720 --script tools/capture_find_reveal.gd

const MemoryStore := preload("res://test/fixtures/exploration_memory_store.gd")
const CLOCK := {"day": 3, "elapsed": 12.5}
const MOMENTS := [0.0, 0.18, 0.36, 0.8, 1.3, 1.5, 1.62]

var folder := ""
var log_lines: PackedStringArray = []


func _initialize() -> void:
	call_deferred("record")


func note(text: String) -> void:
	print("[find-reveal-capture] ", text)
	log_lines.append(text)


## 第一个在某个停留点给出 want 的种子与停留点；want 为空时只找溪声处有东西的
func find_seed(want: String = "") -> Array:
	var stops := ["brook"] if want == "" else ["brook", "gate", "shade", "slope"]
	for value in 4000:
		for stop: String in stops:
			var session := ExplorationSession.new(ExplorationRoutes.catalog(), 0)
			session.begin(ExplorationRoutes.NEAR_PATH, CLOCK, value)
			session.visit(stop)
			var offer := str(session.get_view().get("offer", ""))
			if offer != "" and (want == "" or offer == want):
				return [value, stop]
	return [-1, "brook"]


func capture(tag: String, reduced: bool, want: String = "") -> void:
	root.get_node("TuningStore").set_value("ui.reduced_motion", reduced, false)
	var store := MemoryStore.new()
	var host := ExplorationHost.new(store)
	host.restore()
	var found := find_seed(want)
	host.begin(CLOCK, found[0])
	var scroll: Node2D = load("res://scripts/exploration/near_path_scroll.gd").new()
	root.add_child(scroll)
	scroll.setup(host, "sunny")
	scroll.place_at(found[1])
	scroll.observe()
	for i in 10:
		await process_frame
	var size := root.get_visible_rect().size
	note("%s view %dx%d offer %s" % [tag, size.x, size.y, scroll.pick_choice()])
	root.get_texture().get_image().save_png("%s/%s-00-look.png" % [folder, tag])
	scroll.pick()
	var reveal: FindReveal = scroll.reveal
	reveal.process_mode = Node.PROCESS_MODE_DISABLED
	var moments: Array = MOMENTS if not reduced else [0.15, 0.4, 0.8, 1.05]
	for i in moments.size():
		reveal.elapsed = moments[i]
		reveal.modulate.a = reveal.pose().alpha
		reveal.queue_redraw()
		await process_frame
		await process_frame
		var path := "%s/%s-%02d-t%.2f.png" % [folder, tag, i + 1, moments[i]]
		root.get_texture().get_image().save_png(path)
		note("%s t=%.2f at=%s size=%.2f alpha=%.2f" % [tag, moments[i], reveal.pose().at, reveal.pose().size, reveal.pose().alpha])
	note("%s carried %s, sound file present %s" % [tag, scroll.carried(), ResourceLoader.exists(FindReveal.SOUND_PATH)])
	scroll.queue_free()
	store.free()
	await process_frame


func record() -> void:
	folder = OS.get_environment("YOUJIA_CAPTURE_DIR")
	DirAccess.make_dir_recursive_absolute(folder)
	await process_frame
	await capture("motion", false)
	await capture("calm", true)
	await capture("pine", false, "formal.find.pine_cone")
	await capture("feather", false, "formal.find.feather")
	root.get_node("TuningStore").set_value("ui.reduced_motion", false, false)
	var file := FileAccess.open(folder + "/capture-log.txt", FileAccess.WRITE)
	file.store_string("\n".join(log_lines) + "\n")
	file.close()
	quit(0)
