extends SceneTree

## #231 fish/carry consistency: reproduction + regression on production Main/YardWorld.
## WORLD-BASKET: production catch commits to basket, then withdraws to hand.
## The approved durable inventory replaces historical twenty-second expiry checks.
## Every tick goes through Main._process (so the real pause gate applies).
## Controlled injection boundary (documented, nothing else is faked):
##   - randomness: seed() before each sequence; cast/bite/catch outcomes still come
##     from YardWorld's own randf() branches;
##   - after a REAL cast, _fish_timer (random 5–10 s bite wait) may be shortened to
##     0.4 s so the old-fish sequence fits inside the 20 s carry window;
##   - the player and birds are never teleported; the player only moves through
##     real request_pointer_action/request_primary_action.
## No fake Host, no mocked notices, no mocked carry results.
##
## Save isolation: this suite drives the real Main/SaveStore, which writes
## user://youjia_save.json (+ .bak/.tmp). It refuses to run unless the Godot user
## dir sits inside an explicitly isolated XDG_DATA_HOME
## (YOUJIA_TEST_ISOLATED_DATA must equal XDG_DATA_HOME). Use either
##   bash tools/verify_daily_life.sh            (whole daily check, temp XDG)
##   bash tools/run_fish_carry_suite.sh         (this suite only, temp XDG)
## Never run it with a bare `godot --script` against a real profile.
##
## Fixture reset (per sequence): the previous world is cleared FIRST (Main's
## _clear_world writes that world's day/elapsed/plant back into SaveStore), THEN
## SaveStore data is reset to codec defaults, THEN the holiday starts. Each
## sequence asserts the new world and store still hold the default
## day/elapsed/plant, so no state leaks from the previous sequence. This is a
## test-only reset of in-memory store data; nothing in production code changes.

const DT := 1.0 / 60.0
var checks := 0
var failures: Array[String] = []
var notices: Array[String] = []
var log_lines: Array[String] = []


func _initialize() -> void:
	var refusal := _isolation_refusal()
	if not refusal.is_empty():
		printerr("[fish-carry] REFUSED: ", refusal)
		printerr("[fish-carry] run via: bash tools/run_fish_carry_suite.sh (or tools/verify_daily_life.sh)")
		quit(2)
		return
	call_deferred("_run")


## Returns "" when the save location is provably inside an isolated temp profile.
func _isolation_refusal() -> String:
	var xdg := OS.get_environment("XDG_DATA_HOME")
	var marker := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA")
	if xdg.is_empty() or marker.is_empty():
		return "XDG_DATA_HOME / YOUJIA_TEST_ISOLATED_DATA not set; would write the real user:// save"
	if marker != xdg:
		return "YOUJIA_TEST_ISOLATED_DATA (%s) != XDG_DATA_HOME (%s)" % [marker, xdg]
	var user_dir := OS.get_user_data_dir()
	if not user_dir.begins_with(xdg.rstrip("/") + "/"):
		return "user data dir %s is not inside XDG_DATA_HOME %s" % [user_dir, xdg]
	return ""


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


func _log(line: String) -> void:
	log_lines.append(line)
	print("[fish-carry] ", line)


func _count(key: String) -> int:
	var n := 0
	for k in notices:
		if k == key:
			n += 1
	return n


func _count_prefix(prefix: String) -> int:
	var n := 0
	for k in notices:
		if k.begins_with(prefix):
			n += 1
	return n


func _step(main, seconds: float) -> void:
	var frames := int(round(seconds / DT))
	for i in frames:
		main._process(DT)


func _step_until(main, seconds: float, cond: Callable) -> bool:
	var frames := int(round(seconds / DT))
	for i in frames:
		if cond.call():
			return true
		main._process(DT)
	return cond.call()


func _fresh(main):
	var store = root.get_node("SaveStore")
	var prev_elapsed := -1.0
	if main._world != null:
		prev_elapsed = float(main._world._day_elapsed)
	# 1) clear the old world first: Main._clear_world -> YardWorld._save_progress
	#    writes the previous sequence's day/elapsed/plant into the store;
	main._clear_world()
	# 2) only then reset the store to codec defaults;
	await store.flush_pending()
	_check(store._commit_candidate(store._default_data()), "fresh reset is durably accepted")
	var want_day: int = store.get_holiday_day()
	var want_elapsed: float = store.get_holiday_day_elapsed()
	var want_plant: Dictionary = store.get_plant_state()
	# 3) start the holiday from the clean store (its own _clear_world is a no-op now).
	await main._start_holiday()
	var w = main._world
	_check(store.get_holiday_day() == want_day and w.holiday_day == want_day, "fresh: holiday_day is the default (%d), not the previous sequence's" % want_day)
	_check(is_equal_approx(store.get_holiday_day_elapsed(), want_elapsed) and is_equal_approx(float(w._day_elapsed), want_elapsed), "fresh: day elapsed is the default (%.1f), not written back (prev %.1f)" % [want_elapsed, prev_elapsed])
	_check(store.get_plant_state() == want_plant and int(w._plant_state) == int(want_plant.state) and int(w._plant_day_planted) == int(want_plant.day_planted) and int(w._plant_watered_day) == int(want_plant.watered_day), "fresh: plant state is the default, not written back")
	_log("fresh reset: prev_elapsed=%.1f -> day=%d elapsed=%.1f plant=%s" % [prev_elapsed, w.holiday_day, w._day_elapsed, want_plant])
	if not w.notice_requested.is_connected(_on_notice):
		w.notice_requested.connect(_on_notice)
	notices.clear()
	return w


func _on_notice(key: String) -> void:
	notices.append(key)


## Walk to the pond through the real pointer path and cast. Returns true once CASTING.
func _cast(main, w) -> bool:
	w.request_pointer_action(w._fishing_point())
	return _step_until(main, 25.0, func(): return w._fish_state == w.FISH_CASTING)


## Cast repeatedly (real code) until a bite; chance-misses are recorded.
func _cast_until_bite(main, w, shorten_wait: bool) -> Dictionary:
	var chance_misses := 0
	for attempt in 12:
		if not _cast(main, w):
			return {"ok": false, "chance_misses": chance_misses}
		if shorten_wait:
			w._fish_timer = 0.4
		_step_until(main, 12.0, func(): return w._fish_state != w.FISH_CASTING)
		if w._fish_state == w.FISH_BITE:
			return {"ok": true, "chance_misses": chance_misses}
		chance_misses += 1
	return {"ok": false, "chance_misses": chance_misses}


## Real catch: bite, then the same primary action the HUD/keyboard uses.
func _catch(main, w) -> bool:
	var r := _cast_until_bite(main, w, true)
	if not r.ok:
		return false
	w.request_primary_action()
	await root.get_node("SaveStore").flush_pending()
	var fish: Dictionary = main._inventory.view().fish
	if fish.is_empty(): return false
	main._inventory.request("withdraw", str(fish.keys()[0]))
	await root.get_node("SaveStore").flush_pending()
	return not w._fish_carry_type.is_empty()


func _birds(w) -> Array:
	var out := []
	for id in w._actors:
		var a = w.actor_named(id)
		if a.species in ["duck", "goose"]:
			out.append(a)
	return out


func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.set_process(false)
	await _seq_no_old_fish_miss(main)
	await _seq_old_fish_miss(main)
	await _seq_carry_expiry(main)
	await _seq_expiry_during_approach(main)
	await _seq_pause_resume(main)
	await _seq_repeated_clicks(main)
	await _seq_odd_fish_wording(main)
	await main._show_title()
	root.get_node("AudioDirector").call("release_streams")
	print("[fish-carry] ", checks, " checks ", failures)
	quit(0 if failures.is_empty() else 1)


# 1. Fresh save, no fish: a bite that is not reeled ("跑了") must not create a carry.
func _seq_no_old_fish_miss(main) -> void:
	seed(231001)
	var w = await _fresh(main)
	_check(w._fish_carry_type.is_empty(), "S1 fresh save starts without carry")
	var r := _cast_until_bite(main, w, false)
	_check(r.ok, "S1 real cast reaches a bite")
	var before := str(w._fish_carry_type)
	_step(main, 6.2)
	_check(w._fish_state == w.FISH_IDLE, "S1 unreeled bite returns to idle")
	_check(_count("notice.fishing.miss") >= 1, "S1 miss notice key notice.fishing.miss emitted")
	_check(main._notice_key == "notice.fishing.miss", "S1 HUD shows the miss notice")
	_check(w._fish_carry_type.is_empty() and w._fish_carry_timer <= 0.0, "S1 miss with no old fish leaves carry empty")
	_check(w.primary_action_key() != "action.toss_fish", "S1 primary action is not toss_fish after miss")
	_check(w.hint_context() != "hud.hint.carrying_fish", "S1 hint is not carrying_fish after miss")
	for bird in _birds(w):
		_check(YardInteraction.selected(w, "toss_fish:" + bird.actor_id).is_empty(), "S1 toss_fish:%s unavailable without carry" % bird.actor_id)
		w.request_pointer_action(bird.position)
	_step(main, 4.0)
	_check(_count("notice.food_dropped") == 0, "S1 tapping birds after miss never feeds")
	_log("S1 no-old-fish miss: carry before=%s after=%s chance_misses=%d notices=%s" % [before, w._fish_carry_type, r.chance_misses, notices])


# 2. Holding a fish, cast again via pond tap and let it run: the OLD fish stays.
func _seq_old_fish_miss(main) -> void:
	seed(231002)
	var w = await _fresh(main)
	_check(await _catch(main, w), "S2 real catch stored and withdrawn")
	var kind := str(w._fish_carry_type)
	var t0 := float(w._fish_carry_timer)
	var caught := _count_prefix("notice.fishing.caught")
	_check(caught >= 1, "S2 catch notice emitted")
	# Pond tap while carrying: pointer path still resolves fishing and casts.
	var casted := _cast(main, w)
	_log("S2 pond tap while carrying casts=%s primary_while_carrying=%s" % [casted, w.primary_action_key()])
	_check(casted, "S2 pond tap while carrying starts a new cast (characterised)")
	w._fish_timer = 0.4
	_step_until(main, 2.0, func(): return w._fish_state != w.FISH_CASTING)
	var path := "chance_miss" if w._fish_state == w.FISH_IDLE else "bite_timeout"
	if w._fish_state == w.FISH_BITE:
		_step(main, 6.2)
	var elapsed := t0 - float(w._fish_carry_timer)
	_check(_count("notice.fishing.miss_with_carry") >= 1, "S2 miss notice distinguishes the held old fish")
	_check(w._fish_carry_type == kind, "S2 miss keeps the legal old fish (not deleted, not replaced)")
	_check(w._fish_carry_timer == 0.0, "S2 durable held fish has no expiry")
	_check(w.primary_action_key() == "action.drop_food", "S2 after miss the old fish can still be tossed")
	_check(w.hint_context() == "hud.hint.carrying_fish", "S2 HUD hint says a fish is still in hand")
	_check(main._notice_key == "notice.fishing.miss_with_carry", "S2 last visible notice says the old fish remains")
	_log("S2 old-fish miss path=%s kind=%s timer %.2f->%.2f (elapsed %.2f) notice=%s hint=%s" % [path, kind, t0, w._fish_carry_timer, elapsed, main._notice_key, w.hint_context()])
	_log("S2 historical FINDING fixed by #231 Assistant feedback slice: distinct miss_with_carry says the held old fish remains; original reports retain their baseline.")


# User-authorized WORLD-BASKET replaces the old twenty-second expiry contract.
# Preserve the old report in repository history; production now keeps fish.
func _seq_carry_expiry(main) -> void:
	seed(231003)
	var w = await _fresh(main)
	_check(await _catch(main, w), "S3 real catch stored and withdrawn")
	var kind: String = w._fish_carry_type
	_step(main, 23.0)
	_check(w._fish_carry_type == kind, "S3 held fish survives former expiry window")
	_check(_count("notice.fishing.release") == 0, "S3 no false release notice")
	_check(root.get_node("SaveStore").get_yard_inventory().held == kind, "S3 durable ledger retains held fish")


func _seq_expiry_during_approach(main) -> void:
	seed(231004)
	var w = await _fresh(main)
	_check(await _catch(main, w), "S4 real catch stored and withdrawn")
	var birds := _birds(w)
	_check(not birds.is_empty(), "S4 yard has a duck or goose")
	if birds.is_empty(): return
	var bird = birds[0]
	for candidate in birds:
		if w.get_player().position.distance_to(candidate.position) > w.get_player().position.distance_to(bird.position):
			bird = candidate
	_step(main, 19.5)
	w.request_pointer_action(bird.position)
	_step(main, 25.0)
	_check(not w._fish_carry_type.is_empty(), "S4 walking with fish does not automatically feed a target")
	w.request_primary_action()
	await root.get_node("SaveStore").flush_pending()
	_check(_count("notice.fishing.release") == 0, "S4 approach does not expire the fish")
	_check(_count("notice.food_dropped") == 1, "S4 explicit ground drop happens once beyond former expiry")
	_check(w._fish_carry_type.is_empty(), "S4 confirmed ground drop clears hand")


# 5. Pause freezes the carry window; input is ignored while paused.
func _seq_pause_resume(main) -> void:
	seed(231005)
	var w = await _fresh(main)
	_check(await _catch(main, w), "S5 real catch stored and withdrawn")
	var t0 := float(w._fish_carry_timer)
	main._toggle_pause()
	_check(main._pause_screen.visible and not w.input_enabled, "S5 pause screen open and input disabled")
	_step(main, 30.0)
	_check(is_equal_approx(w._fish_carry_timer, t0), "S5 carry timer frozen while paused")
	_check(not w._fish_carry_type.is_empty(), "S5 fish still held after 30 s paused")
	w.request_primary_action()
	_check(not w._fish_carry_type.is_empty() and _count("notice.food_dropped") == 0, "S5 primary action ignored while paused")
	main._toggle_pause()
	_step(main, 1.0)
	_check(w._fish_carry_timer == 0.0 and not w._fish_carry_type.is_empty(), "S5 durable fish remains after unpause")
	paused_reset(main)
	_log("S5 pause t0=%.2f after_resume=%.2f" % [t0, w._fish_carry_timer])


func paused_reset(main) -> void:
	if main._pause_screen.visible:
		main._toggle_pause()


# 6. WORLD-GROUND-FOOD: drop succeeds once; walking is no longer targeted feeding.
# Autonomous eating and ground restoration are covered by yard_ground_food_runtime.
func _seq_repeated_clicks(main) -> void:
	seed(231006)
	var w = await _fresh(main)
	_check(await _catch(main, w), "S6 real catch stored and withdrawn")
	w.request_primary_action()
	_step_until(main, 15.0, func(): return w._fish_carry_type.is_empty())
	await root.get_node("SaveStore").flush_pending()
	var fed := _count("notice.food_dropped")
	_check(fed == 1, "S6 primary action drops once at the player location")
	_check(w._fish_carry_type.is_empty() and w._fish_carry_timer == 0.0, "S6 confirmed ground transfer clears the carry")
	var key: String = main._notice_key
	_check(key == "notice.food_dropped", "S6 visible notice describes the ground drop")
	for i in 3:
		w.request_primary_action()
		main._process(DT)
	for bird in _birds(w):
		w.request_pointer_action(bird.position)
		main._process(DT)
	_step(main, 3.0)
	_check(_count("notice.food_dropped") == 1, "S6 repeated clicks do not duplicate the ground drop")
	_check(_count("notice.fishing.release") == 0, "S6 consumed fish never emits a later release")
	_check(_count_prefix("notice.pet.duck") + _count_prefix("notice.pet.goose") == 0, "S6 no bird pet notice mistaken for feeding")
	_log("S6 fed notice=%s notices=%s" % [key, notices])


# 7. "奇怪的鱼…溜走了" is a CATCH: the odd fish is carried and can still be fed.
# Characterises the strongest candidate for the player report; wording/semantics
# stay with CODEX-LEAD, so this asserts current behaviour and logs the finding.
func _seq_odd_fish_wording(main) -> void:
	var w = null
	var found := false
	for i in 40:
		seed(231700 + i)
		w = await _fresh(main)
		if await _catch(main, w) and w._fish_carry_type == "odd":
			found = true
			break
	_check(found, "S7 real catch can produce the odd fish")
	if not found:
		return
	var i18n = root.get_node("I18n")
	var text: String = i18n.t("notice.fishing.caught.odd")
	var en_text := str(i18n._load_catalog("res://localization/en.json").get("notice.fishing.caught.odd", ""))
	_check(_count("notice.fishing.caught.odd") >= 1, "S7 odd catch emits notice.fishing.caught.odd")
	_check(main._notice_key == "notice.fishing.caught.odd", "S7 HUD shows the odd-catch notice")
	_check(w._fish_carry_type == "odd" and w._fish_carry_timer == 0.0, "S7 odd fish is durably held without expiry")
	_check(w.primary_action_key() == "action.drop_food", "S7 odd fish can be tossed")
	w.request_primary_action()
	_step_until(main, 15.0, func(): return w._fish_carry_type.is_empty())
	await root.get_node("SaveStore").flush_pending()
	_check(_count("notice.food_dropped") == 1, "S7 odd fish can be dropped exactly once")
	_log("S7 odd catch current text zh='%s' en='%s' carry=odd fed=%s" % [text, en_text, notices.filter(func(k): return k == "notice.food_dropped")])
	var says_gone := text.contains("溜走") or en_text.to_lower().contains("slipped away")
	if says_gone:
		_log("S7 FINDING (current text): the odd-catch notice says the fish got away while it is carried and feedable; matches the report '鱼溜走后仍可喂鹅'.")
	else:
		_log("S7 NOTE: baseline 6e7435c wording said '…溜走了。'/'…slipped away.' (original finding); current wording above no longer says the fish left. WORLD-GROUND-FOOD now verifies drop instead of direct targeted feeding; autonomous consumption has separate runtime coverage.")
