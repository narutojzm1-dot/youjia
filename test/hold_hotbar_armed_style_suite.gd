extends SceneTree
## REQ-20261009-076: hold hotbar selected+armed shows ink bottom accent;
## selected+!armed keeps hot fill without accent; grass starts unarmed;
## fish starts armed; tooltips carry place cues. Does not edit main.gd.
## Integrator should register this suite in verify_daily_life / completions.tsv.

const HotbarPath := "res://scripts/ui/hold_hotbar.gd"
const VIEWPORTS := [Vector2i(390, 844), Vector2i(1280, 720)]

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
	check(hotbar_script != null, "hold_hotbar.gd exists")
	if hotbar_script == null:
		_finish()
		return
	await _styles(hotbar_script)
	_finish()


func _inv(held: String = "", fish: Dictionary = {}, grass: int = 0, millet: int = 0) -> Dictionary:
	var clean_fish := {}
	for kind: Variant in fish:
		var n := int(fish[kind])
		if n > 0:
			clean_fish[kind] = n
	return {
		"schema": 3,
		"revision": 1,
		"fish": clean_fish,
		"grass": grass,
		"millet": millet,
		"held": held,
		"ground": [],
		"next_food_id": 1,
	}


func _styles(HotbarScript) -> void:
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
			var rect: Rect2 = HotbarScript.preferred_rect(Vector2(vs), vs.x < 700.0)
			bar.position = rect.position
			bar.size = rect.size
			await process_frame

			# Fish held: selected + armed + accent + tooltip cue
			bar.update_view(_inv("medium", {"medium": 0}, 0, 0), {}, "idle", false)
			await process_frame
			check(bar.selected_kind() == "medium" and bar.is_place_armed(), tag + " held fish selects and arms")
			check(bar.slot_has_armed_accent("medium"), tag + " selected+armed fish has ink accent")
			check(not bar.slot_has_armed_accent("grass"), tag + " non-selected slot has no accent")
			var tip_armed: String = bar.cells["medium"].tooltip_text
			if loc == "en":
				check(tip_armed.contains("tap ground to place"), tag + " en armed tooltip cue")
			else:
				check(tip_armed.contains("点地放下"), tag + " zh armed tooltip cue")

			# Disarm via clear_selection: keep selected look, lose accent
			bar.clear_selection()
			await process_frame
			check(bar.selected_kind() == "medium" and not bar.is_place_armed(), tag + " clear_selection disarms, hand stays")
			check(not bar.slot_has_armed_accent("medium"), tag + " selected+!armed lacks accent")
			var tip_disarmed: String = bar.cells["medium"].tooltip_text
			if loc == "en":
				check(tip_disarmed.contains("tap again to arm place"), tag + " en disarmed tooltip cue")
			else:
				check(tip_disarmed.contains("再点一次可武装投放"), tag + " zh disarmed tooltip cue")

			# arm_placement restores accent
			bar.arm_placement(true)
			await process_frame
			check(bar.is_place_armed() and bar.slot_has_armed_accent("medium"), tag + " arm_placement restores accent")

			# Toggle off via retap held slot
			bar.cells["medium"].pressed.emit()
			await process_frame
			check(not bar.is_place_armed() and not bar.slot_has_armed_accent("medium"), tag + " retap clears accent")

			# Grass held starts unarmed (no auto-arm), selected without accent
			bar.update_view(_inv("grass", {}, 0, 0), {}, "idle", false)
			await process_frame
			check(bar.selected_kind() == "grass" and not bar.is_place_armed(), tag + " held grass selects but unarmed")
			check(not bar.slot_has_armed_accent("grass"), tag + " grass unarmed has no accent")
			var tip_grass: String = bar.cells["grass"].tooltip_text
			if loc == "en":
				check(tip_grass.contains("tap again to arm place"), tag + " en grass unarmed tooltip")
			else:
				check(tip_grass.contains("再点一次可武装投放"), tag + " zh grass unarmed tooltip")

			# Manual arm grass: accent appears
			bar.arm_placement(true)
			await process_frame
			check(bar.is_place_armed() and bar.slot_has_armed_accent("grass"), tag + " grass armed gains accent")
			if loc == "en":
				check(bar.cells["grass"].tooltip_text.contains("tap ground to place"), tag + " en grass armed tooltip")
			else:
				check(bar.cells["grass"].tooltip_text.contains("点地放下"), tag + " zh grass armed tooltip")

			# Millet held starts armed like fish
			bar.update_view(_inv("millet", {}, 0, 1), {}, "idle", false)
			await process_frame
			check(bar.selected_kind() == "millet" and bar.is_place_armed(), tag + " held millet selects and arms")
			check(bar.slot_has_armed_accent("millet"), tag + " millet armed has accent")

			# Empty hand: no selection, no accents
			bar.update_view(_inv(), {}, "idle", false)
			await process_frame
			check(bar.selected_kind().is_empty() and not bar.is_place_armed(), tag + " empty hand clears")
			for kind: String in ["small", "medium", "odd", "grass", "millet"]:
				check(not bar.slot_has_armed_accent(kind), tag + " empty " + kind + " has no accent")

			host.queue_free()
			await process_frame


func _finish() -> void:
	check(checks >= 40, "suite ran enough checks (%d)" % checks)
	if root.has_node("AudioDirector"):
		root.get_node("AudioDirector").release_streams()
	if failures.is_empty():
		print("[hold-hotbar-armed-style] PASS: %d checks" % checks)
		quit(0)
	else:
		for failure: String in failures.slice(0, 30):
			printerr("[hold-hotbar-armed-style] " + failure)
		print("[hold-hotbar-armed-style] FAIL: %d of %d" % [failures.size(), checks])
		quit(1)
