extends SceneTree
## REQ-20261008-075: Minecraft-style hold hotbar syncs to real yard_inventory.held,
## tap toggles place-armed on the held slot, and HoldPlaceIntent resolves
## select-then-tap-ground into existing drop/place transaction args without
## deducting on cancel/illegal. Does not edit main.gd / yard_world.gd.
## On unmodified main the scripts are absent → suite fails.

const HotbarPath := "res://scripts/ui/hold_hotbar.gd"
const IntentPath := "res://scripts/inventory/hold_place_intent.gd"
const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const Decor := preload("res://scripts/inventory/yard_decor.gd")
const VIEWPORTS := [Vector2i(390, 844), Vector2i(1280, 720), Vector2i(568, 320)]

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


func run() -> void:
	var hotbar_script = load(HotbarPath)
	var intent_script = load(IntentPath)
	check(hotbar_script != null, "hold_hotbar.gd exists")
	check(intent_script != null, "hold_place_intent.gd exists")
	if hotbar_script == null or intent_script == null:
		_finish()
		return
	_intent_food(intent_script)
	_intent_decor(intent_script)
	_intent_no_deduct_on_illegal(intent_script)
	await _hotbar_ui(hotbar_script)
	_finish()


func _inv(held: String = "", fish: Dictionary = {}, grass: int = 0, millet: int = 0, revision: int = 1) -> Dictionary:
	var clean_fish := {}
	for kind: Variant in fish:
		var n := int(fish[kind])
		if n > 0:
			clean_fish[kind] = n
	return {
		"schema": 3,
		"revision": revision,
		"fish": clean_fish,
		"grass": grass,
		"millet": millet,
		"held": held,
		"ground": [],
		"next_food_id": 1,
	}


func _snapshot(held: String = "medium") -> Dictionary:
	var inventory := _inv(held, {"medium": 0}, 0, 0, 3)
	return {Inventory.FIELD: inventory, "keepsakes": {}}


func _intent_food(Intent) -> void:
	var lawn := Vector2(400, 520)
	var water := YardGround.POND_CENTER
	var ok: Dictionary = Intent.food_drop_at("medium", lawn, [])
	check(ok.get("action", "") == "drop" and ok.get("kind", "") == "medium", "lawful lawn drop names drop/medium")
	check(ok.has("details") and is_equal_approx(float(ok.details.x), lawn.x) and is_equal_approx(float(ok.details.y), lawn.y), "lawful drop keeps the tapped point")
	check(Intent.food_drop_at("", lawn, []).get("error", "") == "EMPTY_HAND", "empty hand cannot drop")
	check(Intent.food_drop_at("medium", water, []).get("error", "") == "ILLEGAL_SPOT", "pond tap is illegal and does not invent a drop")
	check(Intent.food_drop_at("rock", lawn, []).get("error", "") == "BASKET_INVALID", "unknown kind rejected")
	var near: Dictionary = Intent.food_drop_near_player("small", Vector2(400, 520), 1.0, [])
	check(near.get("action", "") == "drop" and near.get("kind", "") == "small", "near-player helper finds a lawful offset")
	var blocked: Dictionary = Intent.food_drop_near_player("small", Vector2(10, 10), 1.0, [])
	check(blocked.get("error", "") == "ILLEGAL_SPOT", "off-lawn player gets illegal, not a silent deduct")


func _intent_decor(Intent) -> void:
	var stone: String = ExplorationRoutes.FIND_STONE
	var available := {stone: 1, ExplorationRoutes.FIND_PINE_CONE: 0, ExplorationRoutes.FIND_FEATHER: 0}
	var empty_decor := {"schema": 1, "revision": 0, "places": {}}
	var at_house: Vector2 = Decor.SPOTS["house_edge"] + Vector2(5, -3)
	var hit: Dictionary = Intent.decor_place_at(stone, at_house, empty_decor, available)
	check(hit.get("action", "") == "place" and hit.get("spot", "") == "house_edge", "tap near house picks the empty house spot")
	check(hit.get("details", {}).get("find_id", "") == stone and int(hit.details.dx) == 0, "decor place reuses find_id with zero nudge")
	var full := {"schema": 1, "revision": 2, "places": {
		"house_edge": {"find_id": stone, "dx": 0, "dy": 0},
		"fence_edge": {"find_id": stone, "dx": 0, "dy": 0},
		"pond_path": {"find_id": stone, "dx": 0, "dy": 0},
	}}
	check(Intent.decor_place_at(stone, at_house, full, available).get("error", "") in ["DECOR_OCCUPIED", "ILLEGAL_SPOT"], "full yard rejects without placing")
	check(Intent.decor_place_at(stone, at_house, empty_decor, {stone: 0}).get("error", "") == "DECOR_EMPTY", "zero available does not place")
	check(Intent.decor_place_at("mystery", at_house, empty_decor, available).get("error", "") == "DECOR_INVALID", "unknown find rejected")
	var far: Dictionary = Intent.decor_place_at(stone, Vector2(20, 20), empty_decor, available, 40.0)
	check(far.get("error", "") == "ILLEGAL_SPOT", "far tap outside max distance is illegal, not a deduct")


func _intent_no_deduct_on_illegal(Intent) -> void:
	var snap := _snapshot("medium")
	var before: Dictionary = Inventory.read(snap)
	var bad: Dictionary = Intent.would_commit_food_drop(snap, "medium", YardGround.POND_CENTER, [])
	check(bad.has("error"), "illegal tap yields an error intent")
	var after_bad: Dictionary = Inventory.read(snap)
	check(not before.is_empty(), "fixture inventory is readable")
	check(int(after_bad.get("revision", -1)) == int(before.get("revision", -2)) and str(after_bad.get("held", "")) == "medium", "illegal intent does not mutate the snapshot")
	var good_point := Vector2(400, 520)
	var good: Dictionary = Intent.would_commit_food_drop(snap, "medium", good_point, [])
	check(good.has("candidate"), "lawful tap builds a candidate via Inventory.transition")
	if good.has("candidate"):
		var next: Dictionary = Inventory.read(good.candidate)
		check(str(next.get("held", "x")).is_empty() and next.get("ground", []).size() == 1, "lawful drop clears hand and adds one ground item")
		check(int(next.get("revision", -1)) == int(before.get("revision", -2)) + 1, "lawful drop advances revision once")
		check(is_equal_approx(float(next.get("ground", [{}])[0].get("x", -1.0)), good_point.x), "ground item sits on the tapped point")
	# Cancel path: empty hand / mismatch must not consume
	var cancel: Dictionary = Intent.would_commit_food_drop(snap, "", good_point, [])
	check(cancel.get("error", "") == "EMPTY_HAND", "cancel / empty hand never builds a candidate")


func _hotbar_ui(HotbarScript) -> void:
	var i18n := root.get_node("I18n")
	for loc: String in ["zh-CN", "en"]:
		i18n.set_locale(loc)
		for vs: Vector2i in VIEWPORTS:
			var tag := "%s %dx%d" % [loc, vs.x, vs.y]
			root.size = vs
			var host := Control.new()
			host.size = Vector2(vs)
			root.add_child(host)
			var bar = HotbarScript.new()
			host.add_child(bar)
			await process_frame
			# #597：五格不预设；这里先替玩家配好这五样，再测取用与武装
			bar.set_slots(["small", "medium", "odd", "grass", "millet"])
			var rect: Rect2 = HotbarScript.preferred_rect(Vector2(vs), vs.x < 700.0)
			bar.position = rect.position
			bar.size = rect.size
			await process_frame
			check(rect.position.y > 0.0 and rect.end.y <= vs.y - 60.0, tag + " hotbar sits above the bottom chip row")
			check(bar.custom_minimum_size.x >= 5.0 * 52.0, tag + " five Minecraft-style slots")
			# Empty hand
			bar.update_view(_inv(), {}, "idle", false)
			await process_frame
			check(bar.selected_kind().is_empty() and not bar.is_place_armed(), tag + " empty hand: no selection, not armed")
			check(bar.cells["medium"].disabled, tag + " empty medium slot disabled")
			# Basket has fish but hand empty: slots lit, tap emits withdraw
			var emitted: Array = []
			bar.withdraw_requested.connect(func(k: String) -> void: emitted.append(k))
			bar.update_view(_inv("", {"medium": 2, "small": 1}, 1, 0), {}, "idle", false)
			await process_frame
			check(not bar.cells["medium"].disabled and bar.counts["medium"] == 2, tag + " basket counts show on slots")
			bar.cells["medium"].pressed.emit()
			await process_frame
			check(emitted == ["medium"], tag + " tap stocked slot requests withdraw (no second inventory)")
			# Holding medium: selected + armed, count at least 1
			bar.update_view(_inv("medium", {"medium": 0}, 0, 0), {}, "idle", false)
			await process_frame
			check(bar.selected_kind() == "medium" and bar.is_place_armed(), tag + " held fish selects and arms place")
			check(bar.counts["medium"] >= 1 and not bar.cells["medium"].disabled, tag + " held fish stays visible on the hotbar")
			check(bar.cells["medium"].button_pressed, tag + " held slot shows selected state")
			# Tap held slot clears place-arm (clear selected placement mode)
			bar.cells["medium"].pressed.emit()
			await process_frame
			check(bar.selected_kind() == "medium" and not bar.is_place_armed(), tag + " retap held slot clears place-arm, hand unchanged")
			bar.update_view(_inv("medium", {"medium": 0}, 0, 0), {}, "idle", false)
			check(not bar.is_place_armed(), tag + " basket refresh preserves canceled placement for the same held item")
			bar.arm_placement(true)
			check(bar.is_place_armed(), tag + " arm_placement restores place mode")
			# Busy: no withdraw
			emitted.clear()
			bar.update_view(_inv("", {"odd": 1}, 0, 0), {}, "saving", true)
			await process_frame
			bar.cells["odd"].pressed.emit()
			await process_frame
			check(emitted.is_empty() and bar.cells["odd"].disabled, tag + " busy blocks slot actions")
			# Touch press_at
			bar.update_view(_inv("grass", {}, 0, 0), {}, "idle", false)
			await process_frame
			check(bar.selected_kind() == "grass" and not bar.is_place_armed(), tag + " held grass selects but does not auto-arm")
			check(bar.press_at(bar.cells["grass"].get_global_rect().get_center()), tag + " touch press_at hits the grass slot")
			check(bar.is_place_armed(), tag + " first touch arms grass place")
			check(bar.press_at(bar.cells["grass"].get_global_rect().get_center()), tag + " second touch hits grass slot")
			check(not bar.is_place_armed(), tag + " touch retap clears place-arm on held grass")
			# Hand occupied blocks switching via hotbar (must return first)
			emitted.clear()
			bar.update_view(_inv("small", {"medium": 3}, 0, 0), {}, "idle", false)
			await process_frame
			bar.cells["medium"].pressed.emit()
			await process_frame
			check(emitted.is_empty() and bar.selected_kind() == "small", tag + " holding something blocks switching slots")
			host.queue_free()
			await process_frame


func _finish() -> void:
	check(checks >= 40, "suite ran enough checks (%d)" % checks)
	if root.has_node("AudioDirector"):
		root.get_node("AudioDirector").release_streams()
	if failures.is_empty():
		print("[hold-hotbar] PASS: %d checks" % checks)
		quit(0)
	else:
		for failure: String in failures.slice(0, 30):
			printerr("[hold-hotbar] " + failure)
		print("[hold-hotbar] FAIL: %d of %d" % [failures.size(), checks])
		quit(1)
