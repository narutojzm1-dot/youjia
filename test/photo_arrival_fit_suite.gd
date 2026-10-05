extends SceneTree

## REQ-20261005-033: the new-photo print (PhotoArrival) is a 240×300 polaroid
## centred on screen with its "shutter" caption 46px above the card. On short
## landscape screens (844×390, 667×375, 568×320, 640×300 …) the caption sat
## above the top edge of the screen and the card touched or crossed the edges.
## The caption+card stack must stay inside the screen with an 8px margin; sizes
## that already fit keep the original full-size centred layout unchanged.
## Fixture only: temporary yard world, never loads or writes the player's save.

const CARD_SIZE := Vector2(240, 300)

const VIEWPORTS := [
	Vector2i(320, 568), Vector2i(360, 640), Vector2i(390, 844), Vector2i(412, 915),
	Vector2i(1280, 720), Vector2i(1024, 600), Vector2i(844, 390), Vector2i(700, 400),
	Vector2i(667, 375), Vector2i(844, 340), Vector2i(568, 320), Vector2i(640, 300),
]
## Sizes whose original full-size layout already fits with the margin.
const UNCHANGED := [
	Vector2i(320, 568), Vector2i(360, 640), Vector2i(390, 844), Vector2i(412, 915),
	Vector2i(1280, 720), Vector2i(1024, 600),
]
const MARGIN := 8.0
const EPS := 0.75

var checks := 0
var failures: Array[String] = []
var snapshot: Dictionary = {}
var arrival: Control


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
	snapshot = _capture_snapshot()
	check(not snapshot.is_empty(), "fixture captured a genuine yard photo snapshot")
	if snapshot.is_empty():
		_finish()
		return
	arrival = load("res://scripts/ui/photo_arrival.gd").new()
	arrival.name = "PhotoArrival"
	root.add_child(arrival)
	await _settle()
	for dims: Vector2i in VIEWPORTS:
		for reduced: bool in [true, false]:
			root.size = dims
			await _settle()
			check(arrival.play(snapshot, reduced), "%s reduced=%s: print plays" % [dims, reduced])
			await _settle()
			_check_fit(dims, "open reduced=%s" % reduced)
			arrival.dismiss()
	await _check_resize_while_showing()
	arrival.dismiss()
	_finish()


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


func _card_rect() -> Rect2:
	var card: Control = arrival.get_node("PhotoCard")
	var s: Vector2 = card.scale
	var top_left: Vector2 = card.position + card.pivot_offset * (Vector2.ONE - s)
	return Rect2(top_left, card.size * s)


func _shutter_rect() -> Rect2:
	var label: Control = arrival.get_node("ShutterCaption")
	return Rect2(label.position, label.size)


func _inside(rect: Rect2, viewport: Vector2, margin: float) -> bool:
	return rect.position.x >= margin - EPS and rect.position.y >= margin - EPS \
		and rect.end.x <= viewport.x - margin + EPS and rect.end.y <= viewport.y - margin + EPS


func _check_fit(dims: Vector2i, tag: String) -> void:
	var viewport := Vector2(dims)
	var actual_view: Vector2 = arrival.get_viewport_rect().size
	check(actual_view.is_equal_approx(viewport), "%s %s: viewport really resized (got %s)" % [dims, tag, actual_view])
	var card := _card_rect()
	var shutter := _shutter_rect()
	var card_node: Control = arrival.get_node("PhotoCard")
	check(arrival.visible, "%s %s: print visible" % [dims, tag])
	check(_inside(card, viewport, MARGIN), "%s %s: card %s inside screen with %dpx margin" % [dims, tag, card, MARGIN])
	check(_inside(shutter, viewport, MARGIN), "%s %s: shutter caption %s inside screen with %dpx margin" % [dims, tag, shutter, MARGIN])
	check(shutter.end.y <= card.position.y + EPS, "%s %s: shutter caption stays above the card, not over the photo" % [dims, tag])
	check(absf(card.get_center().x - viewport.x * 0.5) <= EPS, "%s %s: card horizontally centred" % [dims, tag])
	check(absf(card_node.scale.x - card_node.scale.y) <= 0.0001, "%s %s: card keeps its polaroid aspect" % [dims, tag])
	check(card_node.scale.x >= 0.5 - 0.0001 and card_node.scale.x <= 1.0001, "%s %s: card scale stays within 0.5..1" % [dims, tag])
	var label: Label = arrival.get_node("ShutterCaption")
	check(not label.text.is_empty(), "%s %s: shutter caption text present" % [dims, tag])
	var caption: Label = arrival.get_node("PhotoCard/Caption")
	check(not caption.text.is_empty(), "%s %s: photo caption text present" % [dims, tag])
	check(arrival.mouse_filter == Control.MOUSE_FILTER_IGNORE and card_node.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s %s: print never blocks input" % [dims, tag])
	if dims in UNCHANGED:
		var original_pos := viewport * 0.5 - CARD_SIZE * 0.5
		check(card_node.scale == Vector2.ONE, "%s %s: roomy screen keeps full-size print" % [dims, tag])
		check(card_node.position.is_equal_approx(original_pos), "%s %s: roomy screen keeps original centred position" % [dims, tag])
		check(label.position.is_equal_approx(Vector2(maxf(12.0, (viewport.x - 360.0) * 0.5), original_pos.y - 46.0)), "%s %s: roomy screen keeps original caption position" % [dims, tag])
	else:
		check(card.position.y - shutter.position.y <= 46.0 + EPS, "%s %s: caption and print move together as one stack" % [dims, tag])
		check(card.size.y >= 200.0, "%s %s: scaled print stays readable (%.0fpx tall)" % [dims, tag, card.size.y])


func _check_resize_while_showing() -> void:
	root.size = Vector2i(1280, 720)
	await _settle()
	check(arrival.play(snapshot, true), "resize: print plays at desktop size")
	await _settle()
	_check_fit(Vector2i(1280, 720), "resize start")
	for dims: Vector2i in [Vector2i(568, 320), Vector2i(640, 300), Vector2i(390, 844), Vector2i(1280, 720)]:
		root.size = dims
		await _settle()
		_check_fit(dims, "resized while showing")


func _finish() -> void:
	if failures.is_empty():
		print("[photo-arrival-fit] PASS: %d checks" % checks)
	else:
		for failure in failures:
			printerr("[photo-arrival-fit] " + failure)
		print("[photo-arrival-fit] FAIL: %d failures across %d checks" % [failures.size(), checks])
	quit(0 if failures.is_empty() else 1)
