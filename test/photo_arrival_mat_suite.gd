extends SceneTree

## REQ-20261006-037: the new-photo print (PhotoArrival) draws the polaroid frame
## texture, whose transparent window (≈210×212 card px) is larger than the
## 184×184 picture. Over the live yard the gap let the scene (house, notices,
## buttons) show through as a ring around the photo. A paper mat must fill the
## whole window under the frame, tuck its edges under the opaque border, and
## leave picture, caption, card size and fit layout unchanged.
## Fixture only: temporary yard world, never loads or writes the player's save.

const CARD_SIZE := Vector2(240, 300)
const PICTURE_RECT := Rect2(28, 28, 184, 184)
const CAPTION_RECT := Rect2(24, 227, 192, 56)
const OPAQUE_ALPHA := 0.78
const VIEWPORTS := [
	Vector2i(1280, 720), Vector2i(390, 844), Vector2i(360, 640), Vector2i(320, 568),
	Vector2i(844, 390), Vector2i(667, 375), Vector2i(568, 320), Vector2i(640, 300),
]
const EPS := 0.5

var checks := 0
var failures: Array[String] = []
var arrival: Control
var frame_image: Image
var window_texels := Rect2i()


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
	frame_image = (load("res://assets/holiday/ui/polaroid_frame.png") as Texture2D).get_image()
	if frame_image.is_compressed():
		frame_image.decompress()
	window_texels = _flood_window()
	check(window_texels.size.x > 250 and window_texels.size.y > 250, "fixture found the frame's transparent window %s" % window_texels)
	var snapshot := _capture_snapshot()
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
			_check_mat(dims, "reduced=%s" % reduced)
			arrival.dismiss()
	root.size = Vector2i(1280, 720)
	await _settle()
	arrival.play(snapshot, true)
	await _settle()
	for dims: Vector2i in [Vector2i(640, 300), Vector2i(390, 844), Vector2i(1280, 720)]:
		root.size = dims
		await _settle()
		_check_mat(dims, "resized while showing")
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


## Bounding box of the see-through window, flood-filled from the picture centre.
func _flood_window() -> Rect2i:
	var w := frame_image.get_width()
	var h := frame_image.get_height()
	var start := Vector2i(w / 2, h / 3)
	var seen := {}
	var stack: Array[Vector2i] = [start]
	var lo := start
	var hi := start
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or seen.has(p):
			continue
		if frame_image.get_pixelv(p).a >= OPAQUE_ALPHA:
			continue
		seen[p] = true
		lo = Vector2i(mini(lo.x, p.x), mini(lo.y, p.y))
		hi = Vector2i(maxi(hi.x, p.x), maxi(hi.y, p.y))
		stack.append(p + Vector2i.RIGHT)
		stack.append(p + Vector2i.LEFT)
		stack.append(p + Vector2i.DOWN)
		stack.append(p + Vector2i.UP)
	return Rect2i(lo, hi - lo + Vector2i.ONE)


## Same mapping the TextureRect uses for STRETCH_KEEP_ASPECT_CENTERED in a 240×300 card.
func _texel_to_card(texel: Vector2) -> Vector2:
	var tex := Vector2(frame_image.get_width(), frame_image.get_height())
	var factor := minf(CARD_SIZE.x / tex.x, CARD_SIZE.y / tex.y)
	return (CARD_SIZE - tex * factor) * 0.5 + texel * factor


func _card_to_texel(point: Vector2) -> Vector2i:
	var tex := Vector2(frame_image.get_width(), frame_image.get_height())
	var factor := minf(CARD_SIZE.x / tex.x, CARD_SIZE.y / tex.y)
	var t := (point - (CARD_SIZE - tex * factor) * 0.5) / factor
	return Vector2i(clampi(int(floor(t.x)), 0, frame_image.get_width() - 1), clampi(int(floor(t.y)), 0, frame_image.get_height() - 1))


func _check_mat(dims: Vector2i, tag: String) -> void:
	var card: Control = arrival.get_node("PhotoCard")
	var frame: Control = arrival.get_node("PhotoCard/Frame")
	var picture: Control = arrival.get_node("PhotoCard/Picture")
	var caption: Control = arrival.get_node("PhotoCard/Caption")
	var mat := arrival.get_node_or_null("PhotoCard/PhotoMat") as ColorRect
	check(mat != null, "%s %s: print has a paper mat under the frame window" % [dims, tag])
	# Unchanged parts of the print.
	check(card.size.is_equal_approx(CARD_SIZE), "%s %s: card stays 240×300" % [dims, tag])
	check(frame.position == Vector2.ZERO and frame.size.is_equal_approx(CARD_SIZE), "%s %s: frame unchanged" % [dims, tag])
	check(Rect2(picture.position, picture.size).is_equal_approx(PICTURE_RECT), "%s %s: picture rect unchanged %s" % [dims, tag, Rect2(picture.position, picture.size)])
	check(Rect2(caption.position, caption.size).is_equal_approx(CAPTION_RECT), "%s %s: caption rect unchanged" % [dims, tag])
	check(picture.get_index() > frame.get_index() and caption.get_index() > frame.get_index(), "%s %s: picture and caption still draw above the frame" % [dims, tag])
	if mat == null:
		return
	check(mat.visible and mat.is_visible_in_tree() == card.is_visible_in_tree(), "%s %s: mat shows exactly when the card shows" % [dims, tag])
	check(mat.get_index() < frame.get_index(), "%s %s: mat draws beneath the frame" % [dims, tag])
	check(mat.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s %s: mat never blocks input" % [dims, tag])
	check(is_equal_approx(mat.color.a, 1.0), "%s %s: mat is opaque" % [dims, tag])
	check(mat.color.get_luminance() > 0.8 and mat.color.r >= mat.color.b, "%s %s: mat is warm light paper %s" % [dims, tag, mat.color.to_html(false)])
	check(is_equal_approx(mat.scale.x, 1.0) and is_equal_approx(mat.rotation, 0.0), "%s %s: mat follows card scale only" % [dims, tag])
	var rect := Rect2(mat.position, mat.size)
	var win_lo := _texel_to_card(Vector2(window_texels.position))
	var win_hi := _texel_to_card(Vector2(window_texels.end))
	check(rect.position.x <= win_lo.x + 0.01 and rect.position.y <= win_lo.y + 0.01 and rect.end.x >= win_hi.x - 0.01 and rect.end.y >= win_hi.y - 0.01,
		"%s %s: mat %s covers the whole see-through window %s" % [dims, tag, rect, Rect2(win_lo, win_hi - win_lo)])
	check(rect.encloses(PICTURE_RECT), "%s %s: mat sits behind the whole picture" % [dims, tag])
	check(rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= CARD_SIZE.x and rect.end.y <= CARD_SIZE.y, "%s %s: mat stays inside the card" % [dims, tag])
	# Every mat edge must be hidden under opaque frame paper (never peeks past the border).
	var hidden := true
	var inset := 0.4
	for i in 41:
		var t := float(i) / 40.0
		for point: Vector2 in [
			Vector2(lerpf(rect.position.x, rect.end.x, t), rect.position.y + inset),
			Vector2(lerpf(rect.position.x, rect.end.x, t), rect.end.y - inset),
			Vector2(rect.position.x + inset, lerpf(rect.position.y, rect.end.y, t)),
			Vector2(rect.end.x - inset, lerpf(rect.position.y, rect.end.y, t)),
		]:
			if frame_image.get_pixelv(_card_to_texel(point)).a < OPAQUE_ALPHA:
				hidden = false
	check(hidden, "%s %s: mat edges tuck under the opaque frame border" % [dims, tag])
	# The ring between picture and window must now be mat, sampled in screen space.
	var to_screen := card.get_global_transform()
	var gap_points := [Vector2(20, 120), Vector2(220, 120), Vector2(120, 20), Vector2(120, 220)]
	for gp: Vector2 in gap_points:
		var screen_point: Vector2 = to_screen * gp
		check(mat.get_global_rect().has_point(screen_point), "%s %s: gap %s is covered by the mat on screen" % [dims, tag, gp])
		check(frame_image.get_pixelv(_card_to_texel(gp)).a < OPAQUE_ALPHA, "%s %s: fixture gap %s really is see-through frame" % [dims, tag, gp])
		check(not Rect2(picture.position, picture.size).has_point(gp), "%s %s: fixture gap %s is outside the picture" % [dims, tag, gp])


func _finish() -> void:
	if failures.is_empty():
		print("[photo-arrival-mat] PASS: %d checks" % checks)
	else:
		for failure in failures:
			printerr("[photo-arrival-mat] " + failure)
		print("[photo-arrival-mat] FAIL: %d failures across %d checks" % [failures.size(), checks])
	root.get_node("AudioDirector").call("release_streams")
	quit(0 if failures.is_empty() else 1)
