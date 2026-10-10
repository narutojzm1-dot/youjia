extends SceneTree

## REQ-20261008-070: when a new photo arrives, the print fades in over 0.2s but
## the shutter line ("旅人随手拍下了这一刻。") and its paper slip used to appear at
## full strength on the very first frame, so the words popped over the yard a
## beat before the photo. In normal motion the line (and the slip, its child)
## now fades in together with the print over the same 0.2s; the hold, fade-out,
## deadline and single completion are unchanged. Reduced motion still shows the
## print and the line at once with no fade, and switching to reduced motion in
## the middle of the fade-in shows both fully at once and keeps the deadline.
## Fixture only: temporary yard world, never loads or writes the player's save.

const VIEWPORTS := [Vector2i(1280, 720), Vector2i(390, 844), Vector2i(568, 320), Vector2i(280, 653)]
const LOCALES := ["zh-CN", "en"]
const EPS := 0.02

var checks := 0
var failures: Array[String] = []
var arrival: Control
var tucked := [0]


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.get_node("TuningStore").call("end_run")
	var locale: Node = root.get_node("I18n")
	var snapshot := _capture_snapshot()
	check(not snapshot.is_empty(), "fixture captured a genuine yard photo snapshot")
	if snapshot.is_empty():
		_finish()
		return
	arrival = load("res://scripts/ui/photo_arrival.gd").new()
	arrival.name = "PhotoArrival"
	root.add_child(arrival)
	arrival.connect("tucked_away", func() -> void: tucked[0] += 1)
	await _settle()
	for language: String in LOCALES:
		locale.call("set_locale", language)
		for dims: Vector2i in VIEWPORTS:
			root.size = dims
			await _settle()
			var tag := "%s %s" % [language, dims]
			_check_normal(snapshot, tag)
			await _settle()
			_check_reduced(snapshot, tag)
			await _settle()
	locale.call("set_locale", "zh-CN")
	root.size = Vector2i(1280, 720)
	await _settle()
	_check_motion_switch(snapshot)
	await _settle()
	_check_replay(snapshot)
	arrival.dismiss()
	arrival.free()
	_finish()


func _line() -> Label:
	return arrival.get_node("ShutterCaption") as Label


func _card() -> Control:
	return arrival.get_node("PhotoCard") as Control


func _paused_tween() -> Tween:
	var tween: Tween = arrival.get("_tween")
	if tween != null:
		tween.pause()
	return tween


func _check_normal(snapshot: Dictionary, tag: String) -> void:
	tucked[0] = 0
	check(arrival.play(snapshot, false), "%s: normal print plays" % tag)
	var tween := _paused_tween()
	check(tween != null, "%s: normal print has its tween" % tag)
	if tween == null:
		return
	var line := _line()
	var card := _card()
	var slip := arrival.get_node_or_null("ShutterCaption/ShutterPaper") as CanvasItem
	check(slip != null and slip.visible, "%s: shutter slip is present" % tag)
	check(is_zero_approx(line.modulate.a), "%s: shutter line starts hidden with the print (a=%.2f)" % [tag, line.modulate.a])
	check(is_zero_approx(card.modulate.a), "%s: print starts hidden (a=%.2f)" % [tag, card.modulate.a])
	tween.custom_step(0.10)
	check(line.modulate.a > 0.3 and line.modulate.a < 0.7, "%s: line is half way in at 0.1s (a=%.2f)" % [tag, line.modulate.a])
	check(absf(line.modulate.a - card.modulate.a) <= EPS, "%s: line and print fade in together (line %.2f, print %.2f)" % [tag, line.modulate.a, card.modulate.a])
	if slip != null:
		check(slip.get_parent() == line and is_equal_approx(slip.modulate.a, 1.0), "%s: slip rides the line's fade, not its own" % tag)
	tween.custom_step(0.11)
	check(is_equal_approx(line.modulate.a, 1.0) and is_equal_approx(card.modulate.a, 1.0), "%s: both fully shown by 0.21s (line %.2f, print %.2f)" % [tag, line.modulate.a, card.modulate.a])
	tween.custom_step(1.0)
	check(is_equal_approx(line.modulate.a, 1.0) and is_equal_approx(card.modulate.a, 1.0), "%s: both held at 1.21s" % tag)
	tween.custom_step(0.24)
	check(line.modulate.a > 0.0 and line.modulate.a < 0.9, "%s: line fades out on the original schedule (a=%.2f at 1.45s)" % [tag, line.modulate.a])
	check(arrival.visible and tucked[0] == 0, "%s: still showing before the deadline" % tag)
	tween.custom_step(0.2)
	check(not arrival.visible, "%s: print tucked away by the original 1.58s deadline" % tag)
	check(tucked[0] == 1, "%s: one completion only (%d)" % [tag, tucked[0]])


func _check_reduced(snapshot: Dictionary, tag: String) -> void:
	tucked[0] = 0
	check(arrival.play(snapshot, true), "%s: reduced print plays" % tag)
	var tween := _paused_tween()
	check(is_equal_approx(_line().modulate.a, 1.0) and is_equal_approx(_card().modulate.a, 1.0), "%s reduced: line and print shown at once" % tag)
	if tween == null:
		check(false, "%s reduced: has its hold timer" % tag)
		return
	tween.custom_step(0.10)
	check(is_equal_approx(_line().modulate.a, 1.0) and is_equal_approx(_card().modulate.a, 1.0), "%s reduced: no fade at 0.1s" % tag)
	tween.custom_step(1.55)
	check(not arrival.visible and tucked[0] == 1, "%s reduced: tucked away once after the 1.6s hold" % tag)


func _check_motion_switch(snapshot: Dictionary) -> void:
	tucked[0] = 0
	check(arrival.play(snapshot, false), "switch: normal print plays")
	var tween := _paused_tween()
	if tween == null:
		check(false, "switch: has its tween")
		return
	tween.custom_step(0.08)
	check(_line().modulate.a < 0.9, "switch: line mid fade-in before the switch (a=%.2f)" % _line().modulate.a)
	arrival.call("_on_motion_changed", "ui.reduced_motion", true, true)
	check(is_equal_approx(_line().modulate.a, 1.0) and is_equal_approx(_card().modulate.a, 1.0), "switch: reduced motion mid fade-in shows line and print fully at once")
	var hold: Tween = _paused_tween()
	check(hold != null and hold != tween, "switch: fade replaced by a static hold")
	if hold == null:
		return
	hold.custom_step(1.40)
	check(arrival.visible and is_equal_approx(_line().modulate.a, 1.0), "switch: line stays fully shown during the hold")
	hold.custom_step(0.15)
	check(not arrival.visible and tucked[0] == 1, "switch: tucked away once at the original deadline")


func _check_replay(snapshot: Dictionary) -> void:
	check(arrival.play(snapshot, false), "replay: first print plays")
	var tween := _paused_tween()
	if tween != null:
		tween.custom_step(1.45)
	check(arrival.play(snapshot, false), "replay: second print replaces the fading one")
	_paused_tween()
	check(is_zero_approx(_line().modulate.a) and is_zero_approx(_card().modulate.a), "replay: a new print restarts the line hidden with the print, no leftover alpha")
	arrival.dismiss()
	check(not arrival.visible, "replay: dismiss hides the print")


func _capture_snapshot() -> Dictionary:
	seed(3303)
	var world = load("res://scripts/game/yard_world.gd").new()
	root.add_child(world)
	world.setup()
	world.holiday_day = 2
	world._weather_timer = 10000.0
	world.debug_place_player(Vector2(830, 530))
	world.tick(1.0 / 60.0, Vector2.ZERO)
	world.debug_force_rule("duck_pond_chorus")
	var found: Dictionary = world.photo_moments.get("duck_pond_chorus", {}).duplicate(true)
	root.remove_child(world)
	world.free()
	return found


func _settle() -> void:
	for i in 4:
		await process_frame


func _finish() -> void:
	if failures.is_empty():
		print("[photo-arrival-fade-in] PASS: %d checks" % checks)
	else:
		for failure in failures:
			printerr("[photo-arrival-fade-in] " + failure)
		print("[photo-arrival-fade-in] FAIL: %d failures across %d checks" % [failures.size(), checks])
	root.get_node("AudioDirector").call("release_streams")
	quit(0 if failures.is_empty() else 1)
