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

	var leaf: Node = MealAudioScript.new()
	leaf.name = "MealAudioUnderTest"
	root.add_child(leaf)
	for _i in 2:
		await process_frame

	leaf.ensure_registered()
	audio.call("unlock_audio")

	check(not leaf.is_cooking(), "starts not cooking")
	check(not leaf.is_cook_playing(), "starts not playing")

	leaf.set_cooking(true)
	await process_frame
	check(leaf.is_cooking(), "set_cooking true")
	check(leaf.is_cook_playing(), "cook loop playing after start")
	var players_after_start: int = int(leaf.debug_snapshot()["child_players"])
	check(players_after_start == 1, "exactly one cook player after start")

	# Repeat true is no-op: no restart stacking, still one player.
	leaf.set_cooking(true)
	await process_frame
	check(int(leaf.debug_snapshot()["child_players"]) == 1, "repeat set_cooking true keeps one player")
	check(leaf.is_cook_playing(), "still playing after repeat true")

	# Spoon while cooking.
	check(bool(leaf.play_spoon_now()), "spoon plays while cooking")
	check(int(leaf.spoon_play_count) == 1, "spoon count 1")

	# Pause stops loop; cooking flag stays.
	leaf.set_paused(true)
	await process_frame
	check(leaf.is_paused(), "paused true")
	check(leaf.is_cooking(), "cooking flag kept while paused")
	check(not leaf.is_cook_playing(), "cook stopped while paused")
	check(not bool(leaf.play_spoon_now()), "spoon blocked while paused")
	check(not bool(leaf.play_hunger()), "hunger blocked while paused")
	check(int(leaf.hunger_play_count) == 0, "hunger count stays 0 while paused")

	# Idempotent pause.
	leaf.set_paused(true)
	await process_frame
	check(not leaf.is_cook_playing(), "repeat pause stays stopped")

	# Resume cooking sound.
	leaf.set_paused(false)
	await process_frame
	check(leaf.is_cook_playing(), "cook resumes after unpause")
	check(int(leaf.debug_snapshot()["child_players"]) == 1, "still one player after resume")
	check(bool(leaf.play_hunger()), "hunger plays after unpause")
	check(int(leaf.hunger_play_count) == 1, "hunger count 1 after unpause")
	await _wait_ms(int(ceil((MealAudioScript.HUNGER_MIN_GAP + 0.05) * 1000.0)))

	# Stop cooking.
	leaf.set_cooking(false)
	await process_frame
	check(not leaf.is_cooking(), "cooking false")
	check(not leaf.is_cook_playing(), "cook stopped after false")
	leaf.set_cooking(false)
	await process_frame
	check(not leaf.is_cook_playing(), "idempotent stop")
	check(int(leaf.debug_snapshot()["child_players"]) == 1, "stop does not free/stack players")

	# Hunger cue (independent of cooking; pause already exercised above).
	check(bool(leaf.play_hunger()), "hunger plays while not cooking")
	check(int(leaf.hunger_play_count) == 2, "hunger count 2")
	check(not bool(leaf.play_hunger()), "hunger debounce blocks immediate second")
	await _wait_ms(int(ceil((MealAudioScript.HUNGER_MIN_GAP + 0.05) * 1000.0)))
	check(bool(leaf.play_hunger()), "hunger plays after gap")
	check(int(leaf.hunger_play_count) == 3, "hunger count 3")
	# Leaf must not unlock; suite host already unlocked once for headless play_cue.
	check(audio.has_method("stop_cue"), "AudioDirector exposes stop_cue for leaf ownership")

	leaf.queue_free()
	await process_frame

	if failures == 0:
		print("[meal-audio] PASS: %d checks" % checks)
	else:
		print("[meal-audio] FAIL: %d/%d" % [failures, checks])
	quit(0 if failures == 0 else 1)
