extends SceneTree

const Store := preload("res://test/fixtures/exploration_memory_store.gd")
const CLOCK := {"day": 3, "elapsed": 12.5}
const SOURCE_PCM_SHA := "936184f59a29c5d519f1d1ca831916e8fef997e373778a15a50f26adb90e443e"
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)

func seed_four() -> int:
	for value in 2000:
		var session := ExplorationSession.new(ExplorationRoutes.catalog(), 0)
		session.begin(ExplorationRoutes.NEAR_PATH, CLOCK, value)
		if session.get_view().ground_offers.size() == 4: return value
	return -1

func trigger(reveal: FindReveal, reduced: bool = false) -> void:
	reveal.play("formal.find.feather", Vector2(300, 400), Vector2(300, 240), Vector2(80, 600), 1.0, "feather", reduced)

func run() -> void:
	root.size = Vector2i(1280, 720)
	var tuning: Node = root.get_node("TuningStore")
	tuning.set_value("audio.master.muted", false, false)
	await policy(tuning)
	var seed_value := seed_four()
	check(seed_value >= 0, "real route offers all four ordinary finds")
	for size: Vector2i in [Vector2i(1280, 720), Vector2i(390, 844), Vector2i(844, 390)]:
		await events(seed_value, size)
	print("NEARBY_FIND_AUDIO checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

func policy(tuning: Node) -> void:
	var reveal := FindReveal.new()
	root.add_child(reveal)
	await process_frame
	var wav := reveal.sound as AudioStreamWAV
	check(wav != null, "approved runtime WAV loads without an alternate sound")
	if wav != null:
		check(wav.mix_rate == 48000 and not wav.stereo and is_equal_approx(wav.get_length(), 0.95), "original 48000Hz mono 0.95s format")
		check(wav.loop_mode == AudioStreamWAV.LOOP_DISABLED and wav.format == AudioStreamWAV.FORMAT_16_BITS, "one-shot uncompressed PCM16 import")
		var hashing := HashingContext.new()
		hashing.start(HashingContext.HASH_SHA256)
		hashing.update(wav.data)
		check(hashing.finish().hex_encode() == SOURCE_PCM_SHA, "import preserves approved PCM byte for byte")
	trigger(reveal, true)
	check(reveal.is_active() and reveal.calm and reveal.sound_plays == 1 and reveal.is_sounding(), "low motion retains one sound and the visual reveal")
	check(reveal._player.bus == &"SFX", "uses the existing SFX mix bus")
	reveal.settle()
	check(not reveal.is_active() and reveal.is_sounding(), "walking settles the visual without stopping the tail")
	reveal.settle(true)
	check(not reveal.is_sounding(), "silence also stops a tail after the visual settled")

	tuning.set_value("audio.master.muted", true, false)
	var before := reveal.sound_plays
	trigger(reveal)
	check(reveal.is_active() and reveal.sound_plays == before and not reveal.is_sounding(), "muted pickup keeps its reveal but never queues sound")
	tuning.set_value("audio.master.muted", false, false)
	await process_frame
	check(reveal.sound_plays == before and not reveal.is_sounding(), "unmuting cannot replay a skipped pickup")
	trigger(reveal)
	check(reveal.is_sounding(), "a fresh accepted pickup can sound after unmute")
	tuning.set_value("audio.master.muted", true, false)
	check(not reveal.is_sounding(), "master mute stops an active one-shot immediately")
	tuning.set_value("audio.master.muted", false, false)
	await process_frame
	check(not reveal.is_sounding(), "unmute cannot resurrect a stopped tail")

	var sfx := AudioServer.get_bus_index("SFX")
	var original_db := AudioServer.get_bus_volume_db(sfx)
	AudioServer.set_bus_volume_db(sfx, -80.0)
	before = reveal.sound_plays
	trigger(reveal)
	check(reveal.sound_plays == before and not reveal.is_sounding(), "zero-output SFX bus skips sound")
	AudioServer.set_bus_volume_db(sfx, original_db)
	await process_frame
	check(not reveal.is_sounding(), "raising the SFX bus cannot replay skipped sound")
	AudioServer.set_bus_mute(sfx, true)
	trigger(reveal)
	check(reveal.sound_plays == before and not reveal.is_sounding(), "muted SFX bus skips sound")
	AudioServer.set_bus_mute(sfx, false)

	for pair: Vector2i in [Vector2i(Node.NOTIFICATION_APPLICATION_FOCUS_OUT, Node.NOTIFICATION_APPLICATION_FOCUS_IN), Vector2i(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT, Node.NOTIFICATION_WM_WINDOW_FOCUS_IN), Vector2i(Node.NOTIFICATION_APPLICATION_PAUSED, Node.NOTIFICATION_APPLICATION_RESUMED)]:
		trigger(reveal)
		check(reveal.is_sounding(), "fresh sound before lifecycle stop %s" % pair)
		reveal.notification(pair.x)
		before = reveal.sound_plays
		check(not reveal.is_active() and not reveal.is_sounding(), "lifecycle stop settles visual and audio %s" % pair)
		trigger(reveal)
		check(reveal.sound_plays == before and not reveal.is_sounding(), "inactive pickup has no deferred voice %s" % pair)
		reveal.notification(pair.y)
		await process_frame
		check(not reveal.is_sounding() and reveal.sound_plays == before, "lifecycle return does not replay %s" % pair)

	trigger(reveal)
	paused = true
	check(not reveal.is_sounding(), "actual tree pause stops rather than suspends the one-shot")
	before = reveal.sound_plays
	trigger(reveal)
	check(reveal.sound_plays == before, "paused event cannot queue a voice")
	paused = false
	await process_frame
	check(not reveal.is_sounding(), "actual resume never restarts the pickup")
	reveal.sound = null
	trigger(reveal)
	check(reveal.is_active() and reveal.sound_plays == before and not reveal.is_sounding(), "missing file remains a visual-only reveal without synthesised replacement")
	reveal.free()

func events(seed_value: int, size: Vector2i) -> void:
	root.size = size
	var tag := str(size) + " "
	var store := Store.new()
	root.add_child(store)
	var host := ExplorationHost.new(store)
	host.restore()
	host.begin(CLOCK, seed_value)
	store.pump()
	var scroll: Node2D = load("res://scripts/exploration/near_path_scroll.gd").new()
	root.add_child(scroll)
	scroll.setup(host, "sunny")
	scroll.set_process(false)
	await process_frame
	var reveal: FindReveal = scroll.reveal
	check(not scroll.pick() and reveal.sound_plays == 0, tag + "no observation cannot play")
	for stop_id: String in ["gate", "brook", "shade"]:
		scroll.end_observe()
		scroll.place_at(stop_id)
		check(scroll.observe() and not reveal.is_sounding(), tag + "look is quiet at " + stop_id)
		var before := reveal.sound_plays
		check(scroll.pick() and reveal.sound_plays == before + 1 and reveal.is_sounding(), tag + "accepted take plays once at " + stop_id)
		store.pump()
		reveal.settle(true)
		for repeat in 3: scroll._collect_at_stop(stop_id)
		check(reveal.sound_plays == before + 1, tag + "repeated ground collection cannot replay an accepted find")
	scroll.end_observe()
	scroll.place_at("slope")
	var before := reveal.sound_plays
	scroll._collect_at_stop("slope")
	check(scroll.carried().size() == 3 and reveal.sound_plays == before, tag + "full direct pickup leaves the fourth find quiet")
	check(scroll.observe() and scroll.pick_choice().kind == "swap", tag + "explicit swap remains available")
	check(scroll.pick() and reveal.sound_plays == before + 1, tag + "accepted swap plays exactly one new-find sound")
	store.pump()
	reveal.settle(true)
	before = reveal.sound_plays
	check(scroll.pick_choice().kind == "release" and scroll.pick() and reveal.sound_plays == before, tag + "release never sounds as a get")
	store.pump()
	check(scroll.pick(), tag + "new successful take after release is still allowed")
	before = reveal.sound_plays
	store.fail_kind_once = "exploration"
	store.pump()
	check(not str(host.view().get("last_save_failure", "")).is_empty(), tag + "fixture actually rejects the accepted pickup record")
	check(reveal.sound_plays == before, tag + "save acknowledgement or rejection cannot add a sound")
	scroll._pause_button.pressed.emit()
	check(not reveal.is_sounding(), tag + "real scene pause entry silences the one-shot")
	host.request_return()
	store.pump()
	check(not scroll.pick() and reveal.sound_plays == before, tag + "returned session rejects another pickup without sound")
	scroll.release()
	check(not reveal.is_sounding(), tag + "leaving stops an already settled reveal's audio")
	var restored := ExplorationHost.new(store)
	restored.restore()
	store.pump()
	check(reveal.sound_plays == before, tag + "restoring and returning never replay success events")
	scroll.free()
	store.free()
