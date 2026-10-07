extends SceneTree
# REQ-20261007-060: in the yard decor panel an arrow that can no longer move the
# preview (offset already at the ±1 step the model allows) must read as
# unavailable instead of staying lit and silently doing nothing. Arrows that can
# still move stay enabled, nothing on the panel moves, and touch taps on a
# greyed arrow change nothing.
var checks := 0
var failures: Array[String] = []
const VIEWPORTS := [Vector2(280, 653), Vector2(320, 568), Vector2(390, 844), Vector2(568, 320), Vector2(844, 390), Vector2(1280, 720)]
const L := 0
const R := 1
const U := 2
const D := 3

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func enabled(p: Control) -> Array:
	var out: Array = []
	for b: Button in p.nudge_buttons: out.append(not b.disabled)
	return out

func layout_of(p: Control) -> Array:
	var rects: Array = [p.paper.get_global_rect()]
	for b: Button in p.buttons:
		rects.append(b.get_global_rect() if b.is_visible_in_tree() else Rect2())
	return rects

func press(p: Control, i: int) -> void:
	p.nudge_buttons[i].pressed.emit()

func tap(p: Control, b: Button) -> void:
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.position = b.get_global_rect().get_center()
	down.pressed = true
	p.handle_touch_event(down)
	var up := down.duplicate() as InputEventScreenTouch
	up.pressed = false
	p.handle_touch_event(up)

func run() -> void:
	var i18n := root.get_node("I18n")
	var counts := {ExplorationRoutes.FINDS[0]: 2, ExplorationRoutes.FINDS[1]: 1, ExplorationRoutes.FINDS[2]: 1}
	for loc: String in ["zh-CN", "en"]:
		i18n.set_locale(loc)
		for vs: Vector2 in VIEWPORTS:
			var tag := "%s %dx%d" % [loc, vs.x, vs.y]
			root.size = Vector2i(vs)
			var host := Control.new()
			root.add_child(host)
			host.size = vs
			var p: Control = load("res://scripts/ui/yard_decor_panel.gd").new()
			host.add_child(p)
			await process_frame
			p.size = vs
			p.update_view({"places": {}}, counts, "idle", false)
			await process_frame
			await process_frame
			check(enabled(p) == [false, false, false, false], tag + " no preview: every arrow unavailable")
			p.choose_find(ExplorationRoutes.FINDS[0])
			await process_frame
			await process_frame
			check(enabled(p) == [true, true, true, true], tag + " centred preview: all four arrows available")
			var before := layout_of(p)
			press(p, R)
			check(p.draft.dx == 1 and p.draft.dy == 0, tag + " right moves one step")
			check(enabled(p) == [true, false, true, true], tag + " at right edge only the right arrow greys out")
			press(p, R)
			check(p.draft.dx == 1, tag + " pressing a greyed arrow is still a no-op")
			await process_frame
			await process_frame
			check(layout_of(p) == before, tag + " greying an arrow moves nothing on the panel")
			# A touch tap on the greyed arrow changes nothing; on a live one it moves.
			tap(p, p.nudge_buttons[R])
			check(p.draft.dx == 1, tag + " touch tap on greyed right arrow does nothing")
			tap(p, p.nudge_buttons[L])
			check(p.draft.dx == 0 and enabled(p)[R], tag + " touch tap on left arrow moves back and re-enables right")
			press(p, L)
			check(p.draft.dx == -1 and enabled(p) == [false, true, true, true], tag + " at left edge only the left arrow greys out")
			press(p, U)
			check(p.draft.dy == -1 and enabled(p) == [false, true, false, true], tag + " top-left corner greys left and up")
			press(p, D)
			press(p, D)
			check(p.draft.dy == 1 and enabled(p) == [false, true, true, false], tag + " bottom-left corner greys left and down")
			press(p, D)
			check(p.draft.dy == 1, tag + " down past the edge stays put")
			var greyed: Button = p.nudge_buttons[D]
			check(greyed.get_theme_stylebox("disabled") != greyed.get_theme_stylebox("normal"), tag + " greyed arrow uses the panel's distinct disabled look")
			# Pending save: everything is unavailable regardless of position.
			p.update_view({"places": {}}, counts, "idle", true)
			check(enabled(p) == [false, false, false, false], tag + " busy greys every arrow")
			# An already placed item at a corner offset opens with those two arrows greyed.
			var placed := {"places": {"house_edge": {"find_id": ExplorationRoutes.FINDS[0], "dx": 1, "dy": -1}}}
			p.update_view(placed, counts, "idle", false)
			p.choose_spot("house_edge")
			check(enabled(p) == [true, false, false, true], tag + " placed item at top-right opens with right and up greyed")
			check(p.confirm_button.disabled, tag + " unchanged placement still cannot be re-confirmed")
			press(p, L)
			check(p.draft.dx == 0 and not p.confirm_button.disabled and enabled(p) == [true, true, false, true], tag + " moving it back re-enables right and allows confirm")
			host.queue_free()
			await process_frame
	if failures.is_empty():
		print("[yard-decor-nudge-limit] PASS: %d checks" % checks)
		quit(0)
	else:
		for f in failures.slice(0, 20): push_error(f)
		print("[yard-decor-nudge-limit] FAIL: %d/%d" % [failures.size(), checks])
		quit(1)
