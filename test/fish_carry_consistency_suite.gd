extends SceneTree

## #231 fish/carry consistency: reproduction + regression on production Main/YardWorld.
## Scope: test only. Does not change Main/YardWorld/save/animal feedback.
## Every tick goes through Main._process (so the real pause gate applies).
## Controlled injection boundary (documented, nothing else is faked):
##   - randomness: seed() before each sequence; cast/bite/catch outcomes still come
##     from YardWorld's own randf() branches;
##   - after a REAL cast, _fish_timer (random 5–10 s bite wait) may be shortened to
##     0.4 s so the old-fish sequence fits inside the 20 s carry window;
##   - the player and birds are never teleported; the player only moves through
##     real request_pointer_action/request_primary_action.
## No fake Host, no mocked notices, no mocked carry results.

const DT := 1.0 / 60.0
var checks := 0
var failures: Array[String] = []
var notices: Array[String] = []
var log_lines: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


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
	store._data = store._default_data()
	main._start_holiday()
	var w = main._world
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
	_seq_no_old_fish_miss(main)
	_seq_old_fish_miss(main)
	_seq_carry_expiry(main)
	_seq_expiry_during_approach(main)
	_seq_pause_resume(main)
	_seq_repeated_clicks(main)
	_seq_odd_fish_wording(main)
	main._show_title()
	root.get_node("AudioDirector").call("release_streams")
	print("[fish-carry] ", checks, " checks ", failures)
	quit(0 if failures.is_empty() else 1)


# 1. Fresh save, no fish: a bite that is not reeled ("跑了") must not create a carry.
func _seq_no_old_fish_miss(main) -> void:
	seed(231001)
	var w = _fresh(main)
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
	_check(_count_prefix("notice.toss_fish.") == 0, "S1 tapping birds after miss never feeds")
	_log("S1 no-old-fish miss: carry before=%s after=%s chance_misses=%d notices=%s" % [before, w._fish_carry_type, r.chance_misses, notices])


# 2. Holding a fish, cast again via pond tap and let it run: the OLD fish stays.
func _seq_old_fish_miss(main) -> void:
	seed(231002)
	var w = _fresh(main)
	_check(_catch(main, w), "S2 real catch gives a carry")
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
	_check(_count("notice.fishing.miss") >= 1, "S2 miss notice emitted with old fish")
	_check(w._fish_carry_type == kind, "S2 miss keeps the legal old fish (not deleted, not replaced)")
	_check(w._fish_carry_timer > 0.0 and w._fish_carry_timer < t0, "S2 old fish timer keeps counting down (not reset by miss)")
	_check(w.primary_action_key() == "action.toss_fish", "S2 after miss the old fish can still be tossed")
	_check(w.hint_context() == "hud.hint.carrying_fish", "S2 HUD hint says a fish is still in hand")
	_check(main._notice_key == "notice.fishing.miss", "S2 last visible notice is the miss (ambiguity source)")
	_log("S2 old-fish miss path=%s kind=%s timer %.2f->%.2f (elapsed %.2f) notice=%s hint=%s" % [path, kind, t0, w._fish_carry_timer, elapsed, main._notice_key, w.hint_context()])
	_log("S2 FINDING: miss notice key is identical with or without an old fish; text '跑了。没关系。' does not say the held fish remains. Semantic fix belongs to CODEX-LEAD.")


# 3. Carry expiry at 20 s: release once, carry empty, no feed possible.
func _seq_carry_expiry(main) -> void:
	seed(231003)
	var w = _fresh(main)
	_check(_catch(main, w), "S3 real catch gives a carry")
	_check(is_equal_approx(w._fish_carry_timer, 20.0) or w._fish_carry_timer > 19.0, "S3 carry window starts near 20 s")
	_step_until(main, 21.0, func(): return w._fish_carry_type.is_empty())
	_check(w._fish_carry_type.is_empty(), "S3 carry clears at expiry")
	_check(_count("notice.fishing.release") == 1, "S3 release notice emitted exactly once")
	_step(main, 2.0)
	_check(_count("notice.fishing.release") == 1, "S3 release is not repeated after expiry")
	_check(w.primary_action_key() != "action.toss_fish", "S3 toss unavailable after expiry")
	for bird in _birds(w):
		w.request_pointer_action(bird.position)
	_step(main, 4.0)
	_check(_count_prefix("notice.toss_fish.") == 0, "S3 tapping birds after expiry never feeds")
	_check(_count_prefix("notice.pet.") == 0, "S3 bird taps produce no pet heart notice either")
	_log("S3 expiry notices=%s" % [notices])


# 4. Auto-approach to a bird that is still walking when the fish expires.
func _seq_expiry_during_approach(main) -> void:
	seed(231004)
	var w = _fresh(main)
	_check(_catch(main, w), "S4 real catch gives a carry")
	var birds := _birds(w)
	_check(not birds.is_empty(), "S4 yard has a duck or goose")
	if birds.is_empty():
		return
	# Approach the bird farthest from the pond; nothing is teleported.
	var bird = birds[0]
	for b in birds:
		if w.get_player().position.distance_to(b.position) > w.get_player().position.distance_to(bird.position):
			bird = b
	_log("S4 birds=%s" % [birds.map(func(b): return "%s@%s" % [b.actor_id, b.position])])
	# Start the approach with 0.5 s left, by ticking the real 20 s window down.
	_step_until(main, 20.0, func(): return w._fish_carry_timer <= 0.5)
	var gap: float = w.get_player().position.distance_to(bird.position)
	_check(gap > YardInteraction.FEED_REACH, "S4 chosen bird is outside feed reach (approach needed)")
	w.request_pointer_action(bird.position)
	_check(w._pending_interaction == "toss_fish:" + bird.actor_id, "S4 approach is pending toward the bird")
	_step_until(main, 2.0, func(): return w._fish_carry_type.is_empty())
	_check(w._fish_carry_type.is_empty(), "S4 fish expires mid-approach")
	_check(w._pending_interaction.is_empty() and w._selected_target.is_empty(), "S4 expiry cancels the toss approach")
	_check(not w._has_walk_goal, "S4 player stops instead of walking on to the bird")
	_step(main, 6.0)
	_check(_count_prefix("notice.toss_fish.") == 0, "S4 no feed happens after mid-approach expiry")
	_check(_count("notice.fishing.release") == 1, "S4 release notice once")
	_log("S4 approach gap=%.0f notices=%s" % [gap, notices])


# 5. Pause freezes the carry window; input is ignored while paused.
func _seq_pause_resume(main) -> void:
	seed(231005)
	var w = _fresh(main)
	_check(_catch(main, w), "S5 real catch gives a carry")
	var t0 := float(w._fish_carry_timer)
	main._toggle_pause()
	_check(main._pause_screen.visible and not w.input_enabled, "S5 pause screen open and input disabled")
	_step(main, 30.0)
	_check(is_equal_approx(w._fish_carry_timer, t0), "S5 carry timer frozen while paused")
	_check(not w._fish_carry_type.is_empty(), "S5 fish still held after 30 s paused")
	w.request_primary_action()
	_check(not w._fish_carry_type.is_empty() and _count_prefix("notice.toss_fish.") == 0, "S5 primary action ignored while paused")
	main._toggle_pause()
	_step(main, 1.0)
	_check(w._fish_carry_timer < t0 and w._fish_carry_timer > t0 - 1.2, "S5 carry resumes counting after unpause")
	paused_reset(main)
	_log("S5 pause t0=%.2f after_resume=%.2f" % [t0, w._fish_carry_timer])


func paused_reset(main) -> void:
	if main._pause_screen.visible:
		main._toggle_pause()


# 6. Feed succeeds once; extra clicks do not double-consume or fake a second feed.
func _seq_repeated_clicks(main) -> void:
	seed(231006)
	var w = _fresh(main)
	_check(_catch(main, w), "S6 real catch gives a carry")
	w.request_primary_action()
	_step_until(main, 15.0, func(): return w._fish_carry_type.is_empty())
	var fed := _count_prefix("notice.toss_fish.")
	_check(fed == 1, "S6 primary action walks over and feeds exactly once")
	_check(w._fish_carry_type.is_empty() and w._fish_carry_timer == 0.0, "S6 feeding consumes the carry")
	var key: String = main._notice_key
	_check(key.begins_with("notice.toss_fish."), "S6 visible notice is the toss, not a pet heart")
	for i in 3:
		w.request_primary_action()
		main._process(DT)
	for bird in _birds(w):
		w.request_pointer_action(bird.position)
		main._process(DT)
	_step(main, 3.0)
	_check(_count_prefix("notice.toss_fish.") == 1, "S6 repeated clicks do not feed again")
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
		w = _fresh(main)
		if _catch(main, w) and w._fish_carry_type == "odd":
			found = true
			break
	_check(found, "S7 real catch can produce the odd fish")
	if not found:
		return
	var i18n = root.get_node("I18n")
	var text: String = i18n.t("notice.fishing.caught.odd")
	_check(_count("notice.fishing.caught.odd") >= 1, "S7 odd catch emits notice.fishing.caught.odd")
	_check(main._notice_key == "notice.fishing.caught.odd", "S7 HUD shows the odd-catch notice")
	_check(w._fish_carry_type == "odd" and w._fish_carry_timer > 19.0, "S7 odd fish is carried for the full window")
	_check(w.primary_action_key() == "action.toss_fish", "S7 odd fish can be tossed")
	w.request_primary_action()
	_step_until(main, 15.0, func(): return w._fish_carry_type.is_empty())
	_check(_count_prefix("notice.toss_fish.") == 1, "S7 odd fish feeds a bird once")
	_log("S7 odd catch text='%s' carry=odd fed=%s" % [text, notices.filter(func(k): return k.begins_with("notice.toss_fish."))])
	_log("S7 FINDING: zh text says the fish slipped away ('溜走了') while it is carried and feedable; matches the report '鱼溜走后仍可喂鹅'.")
