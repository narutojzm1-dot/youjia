extends SceneTree
## GROK #703: resident bark catalog cooldown / dedupe / fatigue gate.

const Barks := preload("res://scripts/presentation/resident_barks.gd")
const Bubble := preload("res://scripts/presentation/resident_bubble.gd")

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

	var barks: RefCounted = Barks.new(7)
	check(barks.i18n_key(Barks.BARK_CHICK_EGGS) == "bark.chick_eggs_hope", "chick i18n key")
	check(barks.i18n_key(Barks.BARK_PLANT_SOWN) == "bark.plant_sown", "plant i18n key")
	check(barks.i18n_key(Barks.BARK_FATIGUE) == "bark.fatigue_sleepy", "fatigue i18n key")
	check(I18n.has_key("bark.chick_eggs_hope"), "zh catalog has chick bark")
	check(I18n.has_key("bark.plant_sown"), "zh catalog has plant bark")
	check(I18n.has_key("bark.fatigue_sleepy"), "zh catalog has fatigue bark")
	check(not I18n.t("bark.plant_sown").is_empty() and I18n.t("bark.plant_sown") != "bark.plant_sown", "plant text resolves")

	check(barks.can_offer(Barks.BARK_PLANT_SOWN, 0.0, false), "fresh catalog can plant")
	check(not barks.can_offer(Barks.BARK_PLANT_SOWN, 0.0, true), "busy blocks offer")
	var planted: String = barks.try_plant_sown(1.0, false)
	check(planted == Barks.BARK_PLANT_SOWN, "plant accepts once")
	check(barks.try_plant_sown(2.0, false).is_empty(), "global cooldown blocks immediate second bark")
	check(barks.try_plant_sown(1.0 + Barks.GLOBAL_COOLDOWN + 0.1, false).is_empty(), "per-id plant cooldown still holds")
	check(barks.try_plant_sown(1.0 + float(Barks.PER_ID_COOLDOWN[Barks.BARK_PLANT_SOWN]) + 0.1, false) == Barks.BARK_PLANT_SOWN, "plant after per-id cooldown")

	barks.reset()
	var forced: String = barks.try_chick_proximity(0.0, false, true)
	check(forced == Barks.BARK_CHICK_EGGS, "forced chick bark")
	check(barks.try_chick_proximity(1.0, false, true).is_empty(), "chick respects global cooldown")
	barks.reset()
	var misses := 0
	for _i in 40:
		barks.reset()
		if barks.try_chick_proximity(0.0, false, false).is_empty():
			misses += 1
	check(misses > 0 and misses < 40, "chick chance is neither always nor never (misses=%d)" % misses)

	# Probe interval: first roll consumes probe slot; sub-interval frames must not re-roll.
	barks.reset()
	var first = barks.try_chick_proximity(10.0, false, false)
	var blocked = barks.try_chick_proximity(10.0 + Barks.CHICK_PROBE_INTERVAL * 0.5, false, false)
	check(blocked.is_empty(), "chick probe interval blocks mid-window re-roll (first=%s)" % first)
	check(Barks.CHICK_PROBE_INTERVAL >= 2.0, "chick probe interval is at least 2s (got %s)" % Barks.CHICK_PROBE_INTERVAL)

	barks.reset()
	check(barks.try_fatigue(0.0, false, false).is_empty(), "fatigue requires Leader flag")
	check(barks.try_fatigue(0.0, false, true) == Barks.BARK_FATIGUE, "fatigue accepts when flagged")
	check(barks.try_fatigue(1.0, false, true).is_empty(), "fatigue cooldown after show")

	# Bubble leaf: ignore mouse, one line, clamp, dismiss.
	var host := Control.new()
	host.size = Vector2(390, 844)
	root.add_child(host)
	var bubble: Control = Bubble.new()
	host.add_child(bubble)
	await process_frame
	check(bubble.mouse_filter == Control.MOUSE_FILTER_IGNORE, "bubble ignores input")
	check(bubble._panel.mouse_filter == Control.MOUSE_FILTER_IGNORE, "panel ignores input")
	bubble.show_bark("种下了，等它慢慢长大吧", Vector2(200, 400), 2.0)
	await process_frame
	check(bubble.visible and bubble.is_showing(), "bubble shows text")
	check(bubble.position.x >= 8.0, "bubble clamped left (>=8)")
	check(bubble.position.x + bubble._panel.size.x <= host.size.x - 8.0 + 0.5, "bubble clamped right")
	bubble.show_bark("长大后就能吃鸡蛋了", Vector2(10, 10), 2.0)
	await process_frame
	check(bubble._label.text == "长大后就能吃鸡蛋了", "second bark replaces first")
	bubble.dismiss()
	check(not bubble.visible and not bubble.is_showing(), "dismiss hides")
	bubble.show_bark("好困，不想干活", Vector2(100, 100), 1.0)
	bubble.set_suppressed(true)
	check(not bubble.visible, "suppress dismisses active bark")
	host.queue_free()
	await process_frame

	# Main wiring smoke: mount exists after holiday start.
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for _i in 3:
		await process_frame
	await main._start_holiday()
	main.set_process(false)
	check(main._resident_bubble != null, "Main mounts resident bubble")
	check(main._resident_barks != null, "Main mounts bark catalog")
	check(main.has_method("offer_fatigue_bark"), "Leader fatigue hook present")
	check(main.offer_fatigue_bark(false) == false, "fatigue false does not show")
	# Force plant bark path without SaveStore: catalog + show helper.
	main._bark_clock = 100.0
	main._resident_barks.reset()
	main._show_resident_bark(Barks.BARK_PLANT_SOWN)
	await process_frame
	check(main._resident_bubble.visible, "Main can show plant bark")
	main._pause_screen.visible = true
	main._tick_resident_barks(0.0)
	check(not main._resident_bubble.visible, "pause dismisses bark without queue")
	main.queue_free()
	await process_frame

	if failures != 0:
		push_error("[resident-barks] FAIL: %d/%d" % [failures, checks])
		quit(1)
		return
	print("[resident-barks] PASS: %d checks" % checks)
	quit(0)
