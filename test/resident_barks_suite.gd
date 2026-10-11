extends SceneTree
## GROK #703: resident bark catalog cooldown / dedupe / fatigue gate.

const Barks := preload("res://scripts/presentation/resident_barks.gd")
const Bubble := preload("res://scripts/presentation/resident_bubble.gd")
const YardInteract := preload("res://scripts/game/yard_interaction.gd")
## SceneTree --script 不能把自动加载当裸标识符；用脚本类型承接 /root/I18n。
const I18nAutoload := preload("res://autoload/i18n.gd")

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
	# SceneTree --script 模式下裸标识符 I18n 不存在，必须从根节点取自动加载。
	var i18n: I18nAutoload = root.get_node_or_null("/root/I18n") as I18nAutoload
	check(i18n != null, "I18n autoload present at /root/I18n")
	if i18n == null:
		push_error("[resident-barks] FAIL: I18n missing")
		quit(1)
		return
	check(i18n.has_key("bark.chick_eggs_hope"), "zh catalog has chick bark")
	check(i18n.has_key("bark.plant_sown"), "zh catalog has plant bark")
	check(i18n.has_key("bark.fatigue_sleepy"), "zh catalog has fatigue bark")
	var plant_text: String = str(i18n.t("bark.plant_sown"))
	check(not plant_text.is_empty() and plant_text != "bark.plant_sown", "plant text resolves")

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
	var first: String = barks.try_chick_proximity(10.0, false, false)
	var blocked: String = barks.try_chick_proximity(10.0 + Barks.CHICK_PROBE_INTERVAL * 0.5, false, false)
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
	# 无头：空床 / 非作物确认不冒播种成功句。
	var store = root.get_node_or_null("/root/SaveStore")
	check(store != null, "SaveStore autoload present")
	if store == null:
		push_error("[resident-barks] FAIL: SaveStore missing")
		quit(1)
		return
	main._bark_clock = 20.0
	main._resident_barks.reset()
	main._crop_kind_watch = ""
	var bed_before = store.get_yard_crops()
	check(str(bed_before.get("kind", "")) == "", "holiday bed starts unsown")
	main._on_crops_confirmed_for_bark("inventory")
	check(not main._resident_bubble.visible, "non-crop confirm does not bark")
	main._on_crops_confirmed_for_bark("crops")
	check(not main._resident_bubble.visible, "empty bed confirm does not bark")
	# 无头：真实播种、浇水、占用失败、重开读档。没有窗口，不能当画面体验通过。
	main._world.get_player().position = main._world._plant_point()
	main._world._interact_plant()
	check(main._crop_panel.visible, "plant interaction opens crop panel")
	main._crop_panel._request("plant", "wheat")
	check(await store.flush_pending(), "production sow persists")
	await process_frame
	var sown = store.get_yard_crops()
	check(str(sown.get("kind", "")) == "wheat", "sow landed wheat")
	check(main._resident_bubble.visible, "real sow shows plant bark")
	check(str(main._resident_bubble._label.text) == plant_text, "real sow uses catalog plant line")
	main._resident_bubble.dismiss()
	main._crop_panel._request("water")
	check(await store.flush_pending(), "production water persists")
	await process_frame
	var watered = store.get_yard_crops()
	check(int(watered.get("watered_day", -2)) >= 0, "water landed")
	check(not main._resident_bubble.visible, "water does not replay plant bark")
	main._crop_panel._request("plant", "corn")
	check(await store.flush_pending(), "occupied sow attempt settles")
	await process_frame
	check(str(store.get_yard_crops().get("kind", "")) == "wheat", "failed sow keeps wheat")
	check(not main._resident_bubble.visible, "failed sow does not bark success")
	store._load()
	await process_frame
	check(str(store.get_yard_crops().get("kind", "")) == "wheat", "reopen keeps sown wheat")
	check(int(store.get_yard_crops().get("watered_day", -2)) >= 0, "reopen keeps watering")
	check(not main._resident_bubble.visible, "reopen does not replay bark")
	main._on_crops_confirmed_for_bark("crops")
	check(not main._resident_bubble.visible, "reopen confirm does not repeat plant bark")
	check(not main._crop_panel.is_saving(), "crop panel idle before close")
	main._hide_crops()
	check(not main._crop_panel.visible, "crop panel closed after sow checks")
	# 无头：近郊画面硬阻断，关掉后不补播。
	main._screen = "game"
	main._pause_screen.visible = false
	main._show_resident_bark(Barks.BARK_PLANT_SOWN)
	await process_frame
	check(main._resident_bubble.visible, "bark visible before explore suppress")
	main._screen = "exploring"
	main._tick_resident_barks(0.0)
	check(not main._resident_bubble.visible, "explore dismisses bark without queue")
	main._screen = "game"
	main._tick_resident_barks(0.0)
	check(not main._resident_bubble.visible, "leaving explore does not replay dismissed bark")
	# 无头：390 宽数值夹紧与旅人锚点。没有开窗口，不能当截图体验通过。
	# 气泡挂在 CanvasLayer 上，夹紧看视口而不是图层 size。
	root.size = Vector2i(390, 844)
	main.size = Vector2(390, 844)
	main._layout()
	await process_frame
	var traveler: Vector2 = main._world.get_player().position
	main._resident_barks.reset()
	main._bark_clock = 400.0
	main._show_resident_bark(Barks.BARK_CHICK_EGGS)
	await process_frame
	var narrow = main._resident_bubble
	var area: Vector2 = narrow._bark_host_size()
	check(area.x > 0.0 and area.x <= 390.0 + 0.5, "390 parent width (got %s)" % area)
	check(narrow.visible, "390 viewport shows bark")
	check(narrow._anchor_world.distance_to(traveler) <= 0.01, "390 bark anchors on traveler")
	check(narrow.position.x >= 8.0, "390 anchor clamped left (x=%s)" % narrow.position.x)
	check(narrow.position.x + narrow.size.x <= area.x - 8.0 + 0.5, "390 anchor clamped right (x=%s w=%s area=%s)" % [narrow.position.x, narrow.size.x, area.x])
	# Force plant bark path: catalog + show helper, then pause dismisses without replay.
	main._screen = "game"
	main._bark_clock = 500.0
	main._resident_barks.reset()
	main._show_resident_bark(Barks.BARK_PLANT_SOWN)
	await process_frame
	check(main._resident_bubble.visible, "Main can show plant bark")
	main._pause_screen.visible = true
	main._tick_resident_barks(0.0)
	check(not main._resident_bubble.visible, "pause dismisses bark without queue")
	main._pause_screen.visible = false
	main._tick_resident_barks(0.0)
	check(not main._resident_bubble.visible, "closing pause does not replay bark")
	# 无头：睡眠/阳台导演互斥。house.busy 或旅人不可见时不投小鸡骰；进屋关掉且不补播。
	main._screen = "game"
	main._pause_screen.visible = false
	main._album_screen.visible = false
	main._confirm_screen.visible = false
	main._crop_panel.visible = false
	main._chick_panel.visible = false
	main._basket_panel.visible = false
	check(await store.flush_pending(), "house mutex waits for resident commit")
	await process_frame
	var chick_actor = main._world.actor_named("chicken")
	var chick_growth: Dictionary = store.get_chick_growth()
	check(chick_actor != null and str(chick_growth.get("stage", "")) == "chick", "yard chick exists for house mutex")
	var traveler = main._world.get_player()
	traveler.visible = true
	main._world.house.stage = ""
	if chick_actor != null:
		traveler.position = chick_actor.position
	check(chick_actor != null and traveler.position.distance_to(chick_actor.position) <= YardInteract.PET_REACH, "player stands on chick yard coordinates")
	main._resident_barks.reset()
	main._bark_clock = 900.0
	main._show_resident_bark(Barks.BARK_PLANT_SOWN)
	await process_frame
	check(main._resident_bubble.visible, "bark visible before house entry")
	main._world.house.stage = "porch"
	check(main._world.house.busy() and traveler.visible, "entering house is busy while traveler still drawn")
	check(main._resident_bark_hard_blocked(), "house busy hard-blocks barks")
	main._tick_resident_barks(0.0)
	check(not main._resident_bubble.visible and not main._resident_bubble.is_showing(), "entering house closes bark")
	check(not main._resident_bubble._follow.is_valid(), "closed bark is not queued for replay")
	# 人已藏进睡眠/阳台，一楼坐标仍贴着小鸡。
	traveler.visible = false
	main._world.house.stage = "sleep"
	check(main._world.house.busy() and not traveler.visible, "sleep director hides traveler")
	main._resident_barks.reset()
	main._bark_clock = 1200.0
	main._tick_resident_barks(0.0)
	main._try_chick_bark()
	check(main._resident_barks._last_chick_probe_at == -INF, "busy hidden traveler does not roll chick probe")
	check(not main._resident_bubble.visible, "house busy suppresses chick bark")
	main._world.house.stage = ""
	check(not main._world.house.busy() and not traveler.visible, "traveler stays hidden after director stage clears")
	check(main._resident_bark_hard_blocked(), "invisible traveler hard-blocks barks")
	main._resident_barks.reset()
	main._bark_clock = 1400.0
	main._tick_resident_barks(0.0)
	main._try_chick_bark()
	check(main._resident_barks._last_chick_probe_at == -INF, "invisible traveler does not roll chick probe")
	check(not main._resident_bubble.visible, "invisible traveler suppresses chick bark")
	traveler.visible = true
	if chick_actor != null:
		traveler.position = chick_actor.position + Vector2(400.0, 0.0)
	main._tick_resident_barks(0.0)
	check(not main._resident_bubble.visible, "leaving house does not replay dismissed bark")
	traveler.visible = true
	main._world.house.stage = ""
	main.queue_free()
	await process_frame

	if failures != 0:
		push_error("[resident-barks] FAIL: %d/%d" % [failures, checks])
		quit(1)
		return
	print("[resident-barks] PASS: %d checks" % checks)
	quit(0)
