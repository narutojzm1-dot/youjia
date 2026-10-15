extends SceneTree
## GROK #745: meal cooking loop + hunger cue registration / idempotence.

const MealAudioScript := preload("res://scripts/presentation/meal_audio.gd")

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(why)


func _wait_ms(ms: int) -> void:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < ms:
		await process_frame


func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return

	var audio: Node = root.get_node("AudioDirector")
	var cue_ids: Array = audio.call("get_cue_ids")
	check(cue_ids.has("meal.spoon"), "meal.spoon cue slot exists")
	check(cue_ids.has("meal.hunger"), "meal.hunger cue slot exists")
	check(ResourceLoader.exists(MealAudioScript.COOK_LOOP_PATH), "cook_loop tres exists")
	check(ResourceLoader.exists(MealAudioScript.SPOON_PATH), "cook_spoon tres exists")
	check(ResourceLoader.exists(MealAudioScript.HUNGER_PATH), "hunger tres exists")
	check(audio.has_method("stop_cue"), "AudioDirector exposes stop_cue for leaf ownership")
	check(audio.has_method("get_stop_cue_count"), "AudioDirector exposes get_stop_cue_count")
	check(audio.has_method("is_cue_voice_active"), "AudioDirector exposes is_cue_voice_active")
	check(audio.has_method("get_cue_stream"), "AudioDirector exposes get_cue_stream")

	var leaf: Node = MealAudioScript.new()
	leaf.name = "MealAudioUnderTest"
	root.add_child(leaf)
	for _i in 2:
		await process_frame

	leaf.ensure_registered()
	# The approved PCM/loop remains identical when the Web renderer changes.
	var cook: Node = leaf._cook_player
	check(cook.get_script().resource_path.ends_with("browser_bgm_player.gd"), "cook uses the shipped browser/native renderer")
	var loop: AudioStreamWAV = cook.stream
	check(loop != null and loop.mix_rate == 22050 and loop.loop_mode == AudioStreamWAV.LOOP_FORWARD, "approved mono PCM loop metadata survives renderer selection")
	var loop_bounds: Dictionary = cook.call("_loop_settings")
	check(bool(loop_bounds.enabled) and is_equal_approx(float(loop_bounds.begin), 0.0) and is_equal_approx(float(loop_bounds.end), 2.6), "browser renderer uses authored 2.6 second loop boundaries")
	for locked: Array in [[MealAudioScript.COOK_LOOP_PATH, "2e9824a0be6cd199d4383d9593a4e184fb41ca9c558b5f91f340d7ef52f5ce1b"], [MealAudioScript.SPOON_PATH, "b72eab1b9bf06842928aea36183a10f277b828cef21bfada150108b3ad700414"]]:
		check(FileAccess.get_sha256(locked[0]) == locked[1], "approved source bytes unchanged: " + str(locked[0]))
	# #704 explicitly opts approved UI cues into the shared Web renderer.
	# Inspect its separate bus, then retire this fixture channel so the meal
	# ownership checks below still start from an empty browser-channel pool.
	var ui_channel: Node = audio.call("_browser_cue_player", "ui.confirm")
	check(ui_channel != null and ui_channel.bus == &"UI", "UI adapter stays on its own bus, separate from meal SFX")
	audio.call("_release_browser_cue", "ui.confirm")
	check(audio.call("_browser_cue_player", "meal.hunger") == null, "unapproved hunger keeps its old non-production route")
	var master := AudioServer.get_bus_index("Master")
	var sfx := AudioServer.get_bus_index("SFX")
	var old_master_mute := AudioServer.is_bus_mute(master)
	var old_sfx_mute := AudioServer.is_bus_mute(sfx)
	var old_sfx_db := AudioServer.get_bus_volume_db(sfx)
	AudioServer.set_bus_mute(master, true)
	check(is_zero_approx(float(cook.call("_effective_gain"))), "cook Web gain follows Master mute")
	AudioServer.set_bus_mute(master, false)
	AudioServer.set_bus_mute(sfx, true)
	check(is_zero_approx(float(cook.call("_effective_gain"))), "cook Web gain follows SFX mute")
	AudioServer.set_bus_mute(sfx, false)
	AudioServer.set_bus_volume_db(sfx, old_sfx_db - 6.0)
	var quiet_gain := float(cook.call("_effective_gain"))
	AudioServer.set_bus_volume_db(sfx, old_sfx_db)
	check(is_equal_approx(quiet_gain, float(cook.call("_effective_gain")) * db_to_linear(-6.0)), "cook Web gain retains the existing SFX volume scale")
	AudioServer.set_bus_mute(master, old_master_mute)
	AudioServer.set_bus_mute(sfx, old_sfx_mute)
	audio.call("unlock_audio")
	check(not leaf.is_playback_allowed(), "playback starts denied")
	check(not leaf.is_cooking(), "starts not cooking")
	check(not leaf.is_cook_playing(), "starts not playing")

	leaf.set_cooking(true)
	await process_frame
	check(leaf.is_cooking(), "set_cooking true")
	check(not leaf.is_cook_playing(), "cook silent without playback permission")
	check(not bool(leaf.play_spoon_now()), "spoon blocked without permission")
	check(not bool(leaf.play_hunger()), "hunger blocked without permission")

	var hunger_before_allow: int = int(leaf.hunger_play_count)
	var spoon_before_allow: int = int(leaf.spoon_play_count)
	leaf.set_playback_allowed(true)
	await process_frame
	check(leaf.is_playback_allowed(), "playback allowed")
	check(leaf.is_cook_playing(), "cook loop playing after permission")
	check(int(leaf.hunger_play_count) == hunger_before_allow, "allow does not replay hunger")
	check(int(leaf.spoon_play_count) == spoon_before_allow, "allow does not replay spoon")
	var players_after_start: int = int(leaf.debug_snapshot()["child_players"])
	check(players_after_start == 1, "exactly one cook player after start")

	leaf.set_cooking(true)
	await process_frame
	check(int(leaf.debug_snapshot()["child_players"]) == 1, "repeat set_cooking true keeps one player")
	check(leaf.is_cook_playing(), "still playing after repeat true")

	check(bool(leaf.play_spoon_now()), "spoon plays while cooking")
	check(int(leaf.spoon_play_count) == 1, "spoon count 1")

	leaf.set_playback_allowed(false)
	await process_frame
	check(not leaf.is_playback_allowed(), "permission revoked")
	check(leaf.is_cooking(), "cooking flag kept without permission")
	check(not leaf.is_paused(), "pause flag independent of permission revoke")
	check(not leaf.is_cook_playing(), "cook stopped without permission")
	check(not bool(leaf.play_spoon_now()), "spoon blocked without permission after revoke")
	check(not bool(leaf.play_hunger()), "hunger blocked without permission after revoke")

	leaf.set_playback_allowed(true)
	await process_frame
	check(leaf.is_cook_playing(), "cook rebuilds after re-allow")
	check(not leaf.is_paused(), "still unpaused after re-allow")

	leaf.set_paused(true)
	await process_frame
	check(leaf.is_paused(), "paused true")
	check(leaf.is_cooking(), "cooking flag kept while paused")
	check(leaf.is_playback_allowed(), "permission kept while paused")
	check(not leaf.is_cook_playing(), "cook stopped while paused")
	check(not bool(leaf.play_spoon_now()), "spoon blocked while paused")
	check(not bool(leaf.play_hunger()), "hunger blocked while paused")
	check(int(leaf.hunger_play_count) == 0, "hunger count stays 0 while paused")

	leaf.set_playback_allowed(false)
	leaf.set_playback_allowed(true)
	await process_frame
	check(leaf.is_paused(), "pause survives permission toggle")
	check(not leaf.is_cook_playing(), "paused+allowed still silent")

	leaf.set_paused(true)
	await process_frame
	check(not leaf.is_cook_playing(), "repeat pause stays stopped")

	leaf.set_paused(false)
	await process_frame
	check(leaf.is_cook_playing(), "cook resumes after unpause")
	check(int(leaf.debug_snapshot()["child_players"]) == 1, "still one player after resume")
	check(bool(leaf.play_hunger()), "hunger plays after unpause")
	check(int(leaf.hunger_play_count) == 1, "hunger count 1 after unpause")
	await _wait_ms(int(ceil((MealAudioScript.HUNGER_MIN_GAP + 0.05) * 1000.0)))

	leaf.set_cooking(false)
	await process_frame
	check(not leaf.is_cooking(), "cooking false")
	check(not leaf.is_cook_playing(), "cook stopped after false")
	leaf.set_cooking(false)
	await process_frame
	check(not leaf.is_cook_playing(), "idempotent stop")
	check(int(leaf.debug_snapshot()["child_players"]) == 1, "stop does not free/stack players")

	check(bool(leaf.play_hunger()), "hunger plays while not cooking")
	check(int(leaf.hunger_play_count) == 2, "hunger count 2")
	check(not bool(leaf.play_hunger()), "hunger debounce blocks immediate second")
	await _wait_ms(int(ceil((MealAudioScript.HUNGER_MIN_GAP + 0.05) * 1000.0)))
	check(bool(leaf.play_hunger()), "hunger plays after gap")
	check(int(leaf.hunger_play_count) == 3, "hunger count 3")

	# Plant a real Autoload SFX voice using the Director's registered stream reference
	# so stop_cue can match and clear it (headless play_cue does not start voices).
	var hunger_stream: AudioStream = audio.call("get_cue_stream", "meal.hunger") as AudioStream
	check(hunger_stream != null, "hunger cue stream registered")
	var planted := false
	for child in audio.get_children():
		if child is AudioStreamPlayer and str(child.name).begins_with("Sfx"):
			child.stream = hunger_stream
			child.play()
			planted = child.playing or child.stream_paused or child.stream == hunger_stream
			break
	check(planted, "planted hunger stream on an SFX player for exit stop proof")
	check(bool(audio.call("is_cue_voice_active", "meal.hunger")), "hunger voice active before leaf exit")

	var stops_spoon_before: int = int(audio.call("get_stop_cue_count", "meal.spoon"))
	var stops_hunger_before: int = int(audio.call("get_stop_cue_count", "meal.hunger"))
	leaf.set_cooking(true)
	check(bool(leaf.play_spoon_now()), "spoon before exit for stop ownership")

	# Exercise the exact opted-in adapter on native fallback too, so stop/exit
	# cannot merely pass via headless play_cue's early true return.
	var spoon_player: Node = audio.call("_browser_cue_player", "meal.spoon")
	check(spoon_player == audio.call("_browser_cue_player", "meal.spoon"), "one logical browser channel reused per meal spoon cue")
	spoon_player.stream = audio.call("get_cue_stream", "meal.spoon")
	spoon_player.play()
	check(bool(audio.call("is_cue_voice_active", "meal.spoon")), "opted-in spoon holds a real native fallback voice")
	check(spoon_player.bus == &"SFX" and not bool(spoon_player.call("_loop_settings").enabled), "spoon preserves SFX bus and one-shot metadata")
	leaf.queue_free()
	for _j in 3:
		await process_frame

	check(int(audio.call("get_stop_cue_count", "meal.spoon")) > stops_spoon_before, "exit stop_cue spoon invoked")
	check(int(audio.call("get_stop_cue_count", "meal.hunger")) > stops_hunger_before, "exit stop_cue hunger invoked")
	check(not bool(audio.call("is_cue_voice_active", "meal.hunger")), "hunger voice cleared after leaf exit")
	check(not bool(audio.call("is_cue_voice_active", "meal.spoon")), "owned browser spoon voice cleared after leaf exit")
	check(audio._browser_cue_players.is_empty(), "leaf exit releases its browser cue channel")

	# Use a known cue: unknown IDs are rejected before asset loading and would
	# make this negative test pass even with the old fallback implementation.
	var missing := "res://assets/holiday/audio/meal_grok/__missing_suite__.tres"
	var quiet: Node = MealAudioScript.new()
	check(quiet.call("_load_cook_stream", missing) == null, "missing cook asset stays silent")
	check(quiet.call("_load_cook_stream", "res://scripts/presentation/meal_audio.gd") == null, "non-audio cook resource stays silent")
	check(quiet.call("_load_cook_stream") != null, "approved cook asset remains loadable")
	check(bool(audio.call("register_cue", "meal.spoon", MealAudioScript.SPOON_PATH)), "seed known approved cue before negative check")
	quiet.call("_register", "meal.spoon", missing)
	check(audio.call("get_cue_stream", "meal.spoon") == null, "missing known cue unregisters without fallback tone")
	quiet.call("_register", "meal.spoon", MealAudioScript.SPOON_PATH)
	check(audio.call("get_cue_stream", "meal.spoon") != null, "approved cue restores after resource recovery")
	quiet.free()
	var replace_player: Node = audio.call("_browser_cue_player", "meal.spoon")
	replace_player.stream = audio.call("get_cue_stream", "meal.spoon")
	replace_player.play()
	var unrelated: AudioStreamPlayer = audio._sfx_players[0]
	unrelated.stream = audio.call("get_cue_stream", "meal.hunger")
	unrelated.play()
	audio.call("stop_cue", "meal.spoon")
	check(audio._browser_cue_players.is_empty() and not bool(audio.call("is_cue_voice_active", "meal.spoon")), "stop_cue retires the opted-in browser channel")
	check(bool(audio.call("is_cue_voice_active", "meal.hunger")), "stopping spoon preserves another owned cue voice")
	var missing_player: Node = audio.call("_browser_cue_player", "meal.spoon")
	missing_player.stream = audio.call("get_cue_stream", "meal.spoon")
	missing_player.play()
	check(not bool(audio.call("register_cue", "meal.spoon", missing)), "known missing cue rejects after a real adapter start")
	check(audio._browser_cue_players.is_empty() and not bool(audio.call("is_cue_voice_active", "meal.spoon")), "missing replacement also disposes active browser voice")
	check(bool(audio.call("register_cue", "meal.spoon", MealAudioScript.SPOON_PATH)), "restore approved spoon after adapter negative test")
	# Use a real adapter voice, not headless cue counts: interruptions must discard
	# short sounds before Host.sync runs, and recovery must not recreate them.
	for interruption: String in ["background", "pause", "master_mute", "sfx_mute", "backend_interrupted"]:
		var voice: Node = audio.call("_browser_cue_player", "meal.spoon")
		voice.stream = audio.call("get_cue_stream", "meal.spoon")
		voice.play()
		check(bool(audio.call("is_cue_voice_active", "meal.spoon")), interruption + " starts with a real voice")
		match interruption:
			"background": audio.call("set_application_active", false)
			"pause": audio.call("set_game_paused", true)
			"master_mute": root.get_node("TuningStore").call("set_value", "audio.master.muted", true)
			"sfx_mute":
				AudioServer.set_bus_mute(sfx, true)
				await process_frame
			"backend_interrupted":
				audio._yard_active = true
				audio.call("_on_browser_resume_settled", [JSON.stringify({"state": "interrupted", "token": audio._resume_token})])
		check(audio._browser_cue_players.is_empty() and not bool(audio.call("is_cue_voice_active", "meal.spoon")), interruption + " immediately discards the short voice")
		match interruption:
			"background": audio.call("set_application_active", true)
			"pause": audio.call("set_game_paused", false)
			"master_mute": root.get_node("TuningStore").call("set_value", "audio.master.muted", false)
			"sfx_mute": AudioServer.set_bus_mute(sfx, false)
			"backend_interrupted":
				audio._yard_active = false
				audio._awaiting_gesture = false
				audio._backend_state = "native"
		check(audio._browser_cue_players.is_empty() and not bool(audio.call("is_cue_voice_active", "meal.spoon")), interruption + " recovery never replays a stale spoon")
	var release_player: Node = audio.call("_browser_cue_player", "meal.spoon")
	release_player.stream = audio.call("get_cue_stream", "meal.spoon")
	release_player.play()

	# The suite deliberately starts real native AudioStreamPlayers even headless.
	# Match yard_audio_suite teardown: release fixture references and allow the
	# mixer to retire stopped playback before terminating the test process.
	check(not is_instance_valid(leaf), "leaf freed before process teardown")
	hunger_stream = null
	audio.call("release_streams")
	check(audio.call("get_cue_stream", "meal.hunger") == null, "fixture cue references released")
	check(audio._browser_cue_players.is_empty(), "release_streams releases the opted-in adapter channel")
	await create_timer(0.25).timeout
	if failures == 0:
		print("[meal-audio] PASS: %d checks" % checks)
	else:
		print("[meal-audio] FAIL: %d/%d" % [failures, checks])
	quit(0 if failures == 0 else 1)
