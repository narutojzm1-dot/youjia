extends SceneTree
# 拾起短展示的动态音画演示：真实画卷、宿主（内存存档替身）与院景音乐/环境声，
# 从出门处沿路走到松果处停下看、带上，再走到落羽处带上，接着走。
# 用 Godot 的 Movie Maker 同时录画面和混音后的声音；需要真实渲染器（非 --headless）：
# YOUJIA_DEMO_SILENT=1 时不放拾起短音，用来和正常录制相减、单独量短音在混音里的电平。
# YOUJIA_DEMO_GET_DB=<dB> 只在这次录制里调拾起短音的播放增益，做电平对照；不改运行时默认。
# 时间戳按 --fixed-fps 30 换算：
# godot --path . --resolution 1280x720 --fixed-fps 30 --write-movie <out.avi> --script tools/record_find_reveal_demo.gd

const MemoryStore := preload("res://test/fixtures/exploration_memory_store.gd")
const L := preload("res://scripts/exploration/near_path_layout.gd")
const CLOCK := {"day": 3, "elapsed": 12.5}
const PINE := "formal.find.pine_cone"
const FEATHER := "formal.find.feather"

var scroll: Node2D


func _initialize() -> void:
	call_deferred("record")


func note(text: String) -> void:
	print("[find-reveal-demo] ", text)


## 第一个“先在 a 处遇见松果、带上后在 b 处遇见落羽”的种子
func find_route() -> Array:
	for value in 4000:
		for a: String in ExplorationRoutes.NEAR_PATH_STOPS:
			for b: String in ExplorationRoutes.NEAR_PATH_STOPS:
				if a == b:
					continue
				var store := MemoryStore.new()
				var host := ExplorationHost.new(store)
				host.restore()
				host.begin(CLOCK, value)
				host.visit(a)
				var ok: bool = str(host.view().get("offer", "")) == PINE and host.take(PINE).ok
				if ok:
					host.visit(b)
					ok = str(host.view().get("offer", "")) == FEATHER
				store.free()
				if ok:
					return [value, a, b]
	return []


func wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func walk_to(stop_id: String) -> void:
	var entry := L.stop(stop_id)
	scroll.walk_target = {"arm": entry.arm, "d": entry.d}
	var frames := 0
	while not scroll.walk_target.is_empty() and frames < 900:
		await process_frame
		frames += 1


func record() -> void:
	var route := find_route()
	if route.is_empty():
		note("no route with a pine cone then a feather")
		quit(1)
		return
	note("seed %d: pine cone at %s, feather at %s" % route)
	root.get_node("TuningStore").set_value("ui.reduced_motion", false, false)
	var audio := root.get_node("AudioDirector")
	audio.unlock_audio()
	audio.set_yard_active(true)
	var store := MemoryStore.new()
	var host := ExplorationHost.new(store)
	host.restore()
	host.begin(CLOCK, route[0])
	scroll = load("res://scripts/exploration/near_path_scroll.gd").new()
	root.add_child(scroll)
	scroll.setup(host, "sunny")
	if OS.get_environment("YOUJIA_DEMO_SILENT") == "1":
		scroll.reveal.sound = null
	var boost := OS.get_environment("YOUJIA_DEMO_GET_DB")
	if boost != "":
		scroll.reveal._player.volume_db = float(boost)
		note("get sound volume_db %s (demo only)" % boost)
	await wait(2.0)
	for pair in [[route[1], PINE], [route[2], FEATHER]]:
		await walk_to(pair[0])
		await wait(0.5)
		scroll.observe()
		await wait(1.8)
		var offer: Dictionary = scroll.pick_choice()
		note("t=%.2fs %s offers %s; take ok %s" % [Engine.get_process_frames() / 30.0, pair[0], offer, scroll.pick()])
		await wait(FindReveal.RISE + FindReveal.HOLD + FindReveal.FLY + 1.2)
		scroll.end_observe()
		await wait(0.4)
	note("carried %s" % [scroll.carried()])
	scroll.walk_target = {"arm": L.START.arm, "d": L.START.d}
	await wait(3.0)
	store.pump()
	quit(0)
