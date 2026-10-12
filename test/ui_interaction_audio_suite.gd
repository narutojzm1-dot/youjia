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


func _close_cue_count(sfx: Variant) -> int:
	var holder: Object = sfx as Object
	return int(holder.get("close_cue_count"))


# 防抖看 Time.get_ticks_msec。headless --script 里首个 create_timer 可能同帧结束。
func _wait_past_gap() -> void:
	var start := Time.get_ticks_msec()
	var need := int(ceil((UiSfx.MIN_GAP + 0.03) * 1000.0))
	while Time.get_ticks_msec() - start < need:
		await process_frame


func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return

	# --script 入口在自动加载注册前编译，不能直接写 AudioDirector 全局名。
	var audio: Node = root.get_node("AudioDirector")
	var cue_ids: Array = audio.call("get_cue_ids")
	check(cue_ids.has("ui.page"), "ui.page cue exists in AudioDirector")
	check(ResourceLoader.exists(UiSfx.OPEN_PATH), "open tres exists")
	check(ResourceLoader.exists(UiSfx.CLOSE_PATH), "close tres exists")
	check(ResourceLoader.exists(UiSfx.PAGE_PATH), "page tres exists")

	var sfx: RefCounted = UiSfx.new()
	sfx.ensure_registered()
	audio.call("unlock_audio")

	# Headless play_cue returns true when stream registered.
	check(bool(sfx.play_open()), "open cue plays once")
	check(not bool(sfx.play_open()), "debounce blocks immediate second open")
	await _wait_past_gap()
	check(bool(sfx.play_close()), "close cue plays after gap")
	await _wait_past_gap()
	check(bool(sfx.play_page()), "page cue plays after gap")

	# game.pause stays empty so set_game_paused does not invent a second UI voice.
	var streams: Dictionary = audio.get("_streams")
	var pause_stream: Variant = streams.get("game.pause")
	check(pause_stream == null, "game.pause left unregistered to avoid double-fire")

	# Negative: missing .tres on a *known* cue must quiet-degrade.
	# Use real CUES id (ui.page): AudioDirector.register_cue unregisters on missing path.
	# Old ProceduralSfx.tone fallback would re-register_stream a tone → this assert fails.
	# Vacuous ui.suite_missing is NOT in CUES, so both quiet-degrade and old fallback leave null.
	var bogus := "res://assets/holiday/audio/ui_grok/__missing_for_suite__.tres"
	check(not ResourceLoader.exists(bogus), "bogus path does not exist")
	var streams_before: Dictionary = audio.get("_streams")
	var page_before: Variant = streams_before.get("ui.page")
	check(page_before != null, "ui.page stream registered before missing-path attempt")
	var sfx_neg: RefCounted = UiSfx.new()
	sfx_neg.try_register_path(UiSfx.CUE_PAGE, bogus)
	var streams_neg: Dictionary = audio.get("_streams")
	var page_after_missing: Variant = streams_neg.get("ui.page")
	check(page_after_missing == null, "missing path on known cue leaves stream empty (no tone fallback)")
	# Restore approved page asset; other approved cues stay intact.
	sfx_neg.try_register_path(UiSfx.CUE_PAGE, UiSfx.PAGE_PATH)
	var streams_restored: Dictionary = audio.get("_streams")
	var page_restored: Variant = streams_restored.get("ui.page")
	check(page_restored != null, "approved ui.page restored after missing-path attempt")
	var open_stream: Variant = streams_restored.get("ui.confirm")
	check(open_stream != null, "approved open cue still registered after missing-path attempt")

	# Main wiring smoke: holiday start mounts helper and hooks do not throw.
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for _i in 3:
		await process_frame
	await main._start_holiday()
	main.set_process(false)
	check(main.get("_ui_sfx") != null, "Main mounts UiInteractionAudio")
	var mounted_sfx: Variant = main.get("_ui_sfx")
	if mounted_sfx != null:
		mounted_sfx.ensure_registered()
	# Successful album flip path: rebuild with two entries then flip.
	main.set("_album_entries", PackedStringArray(["a", "b", "c", "d"]))
	main.set("_album_index", 0)
	main.set("_album_two_pages", true)
	var before: int = int(main.get("_album_index"))
	main.call("_flip_album", 1)
	check(int(main.get("_album_index")) != before, "album flip advances index")
	# Boundary flip does not advance and must not require a sound.
	var at_end: int = int(main.get("_album_index"))
	main.call("_flip_album", 1)
	check(int(main.get("_album_index")) == at_end, "album flip at end is no-op")

	# 幂等 hide：面板已经不可见时不得增加关闭音次数。
	# 先等到去抖窗口过去，避免上一次翻页音把误播的关闭音挡掉。
	await _wait_past_gap()
	var close_before: int = _close_cue_count(mounted_sfx)
	var basket: Control = main.get("_basket_panel") as Control
	var album: Control = main.get("_album_screen") as Control
	check(basket != null and not basket.visible, "basket starts hidden before idempotent hide")
	check(album != null and not album.visible, "album starts hidden before idempotent hide")
	main.call("_hide_basket")
	check(_close_cue_count(mounted_sfx) == close_before, "hide basket while hidden does not play close")
	main.call("_hide_album")
	check(_close_cue_count(mounted_sfx) == close_before, "hide album while hidden does not play close")

	# 真正打开再关闭：各播一次关闭音；随后再 hide 仍是静音清理。
	main.call("_show_basket")
	check(basket.visible, "show basket makes panel visible")
	await _wait_past_gap()
	main.call("_hide_basket")
	check(not basket.visible, "hide basket after open closes panel")
	check(_close_cue_count(mounted_sfx) == close_before + 1, "open then hide basket plays close once")
	await _wait_past_gap()
	main.call("_hide_basket")
	check(_close_cue_count(mounted_sfx) == close_before + 1, "second basket hide stays silent")

	main.call("_show_album")
	check(album.visible, "show album makes panel visible")
	await _wait_past_gap()
	main.call("_hide_album")
	check(not album.visible, "hide album after open closes panel")
	check(_close_cue_count(mounted_sfx) == close_before + 2, "open then hide album plays close once")
	await _wait_past_gap()
	main.call("_hide_album")
	check(_close_cue_count(mounted_sfx) == close_before + 2, "second album hide stays silent")

	main.queue_free()
	await process_frame

	if failures == 0:
		print("[ui-interaction-audio] PASS: %d checks" % checks)
	else:
		print("[ui-interaction-audio] FAIL: %d/%d" % [failures, checks])
	quit(0 if failures == 0 else 1)
