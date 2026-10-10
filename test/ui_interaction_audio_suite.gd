extends SceneTree
## GROK #704: UI interaction audio registration, debounce, successful album page cue.

const UiSfx := preload("res://scripts/presentation/ui_interaction_audio.gd")

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(why)


func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return

	check(AudioDirector.get_cue_ids().has("ui.page"), "ui.page cue exists in AudioDirector")
	check(ResourceLoader.exists(UiSfx.OPEN_PATH), "open tres exists")
	check(ResourceLoader.exists(UiSfx.CLOSE_PATH), "close tres exists")
	check(ResourceLoader.exists(UiSfx.PAGE_PATH), "page tres exists")

	var sfx: RefCounted = UiSfx.new()
	sfx.ensure_registered()
	AudioDirector.unlock_audio()

	# Headless play_cue returns true when stream registered.
	check(bool(sfx.play_open()), "open cue plays once")
	check(not bool(sfx.play_open()), "debounce blocks immediate second open")
	await create_timer(UiSfx.MIN_GAP + 0.03).timeout
	check(bool(sfx.play_close()), "close cue plays after gap")
	await create_timer(UiSfx.MIN_GAP + 0.03).timeout
	check(bool(sfx.play_page()), "page cue plays after gap")

	# game.pause stays empty so set_game_paused does not invent a second UI voice.
	var pause_stream = AudioDirector.get("_streams").get("game.pause")
	check(pause_stream == null, "game.pause left unregistered to avoid double-fire")

	# Main wiring smoke: holiday start mounts helper and hooks do not throw.
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for _i in 3:
		await process_frame
	await main._start_holiday()
	main.set_process(false)
	check(main._ui_sfx != null, "Main mounts UiInteractionAudio")
	main._ui_sfx.ensure_registered()
	# Successful album flip path: rebuild with two entries then flip.
	main._album_entries = PackedStringArray(["a", "b", "c", "d"])
	main._album_index = 0
	main._album_two_pages = true
	var before := main._album_index
	main._flip_album(1)
	check(main._album_index != before, "album flip advances index")
	# Boundary flip does not advance and must not require a sound.
	var at_end := main._album_index
	main._flip_album(1)
	check(main._album_index == at_end, "album flip at end is no-op")

	main.queue_free()
	await process_frame

	if failures == 0:
		print("[ui-interaction-audio] PASS: %d checks" % checks)
	else:
		print("[ui-interaction-audio] FAIL: %d/%d" % [failures, checks])
	quit(0 if failures == 0 else 1)
