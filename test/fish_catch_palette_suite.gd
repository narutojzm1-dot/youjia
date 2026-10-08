extends SceneTree
# REQ-20261008-071: the fish-catch celebration is painted in the yard's palette
# (warm gold, muted pond tone, cream, paper badge with a small ink fish) instead
# of neon cyan / blue / violet rings around an empty navy disc. Radii, alphas,
# timing and the low-motion pose are unchanged.

const OLD_COLORS := {
	"small": Color(0.35, 0.78, 0.95),
	"medium": Color(0.28, 0.58, 0.95),
	"odd": Color(0.55, 0.40, 0.92),
}
const OLD_BADGE := Color(0.12, 0.22, 0.38)
const PAPER := Color("fff6e8")
const INK := Color("5b4637")

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var overlay_script = load("res://scripts/game/world_effects_overlay.gd")
	_check(overlay_script.has_method("catch_palette") or _has_static(overlay_script, "catch_palette"), "overlay exposes catch_palette")
	if not failures.is_empty():
		_finish()
		return
	var waters: Array[Color] = []
	for kind: String in ["small", "medium", "odd"]:
		var p: Dictionary = overlay_script.catch_palette(kind)
		for key: String in ["outer", "water", "inner", "core", "speck", "badge_fill", "badge_edge", "fish_fill", "fish_ink"]:
			_check(p.has(key) and p[key] is Color, "%s palette has %s" % [kind, key])
		var water: Color = p.water
		waters.append(water)
		_check(OLD_COLORS[kind].s > 0.5, "%s old ring was neon (s=%.2f)" % [kind, OLD_COLORS[kind].s])
		_check(water.s <= 0.4, "%s ring is a muted pond tone (s=%.2f)" % [kind, water.s])
		_check(Color(p.speck).s <= 0.4, "%s specks are muted (s=%.2f)" % [kind, Color(p.speck).s])
		_check(Color(p.fish_fill).s <= 0.4, "%s badge fish is muted" % kind)
		_check(not water.is_equal_approx(OLD_COLORS[kind]), "%s ring no longer uses the old neon colour" % kind)
		_check(Color(p.outer).h < 0.17 and Color(p.outer).r > 0.85, "%s outer ring stays warm gold" % kind)
		_check(Color(p.inner).is_equal_approx(PAPER), "%s inner ring is paper cream, not icy blue-white" % kind)
		_check(Color(p.badge_fill).is_equal_approx(PAPER), "%s badge is paper" % kind)
		_check(not Color(p.badge_fill).is_equal_approx(OLD_BADGE), "%s badge is no longer navy" % kind)
		_check(Color(p.badge_edge).is_equal_approx(INK) and Color(p.fish_ink).is_equal_approx(INK), "%s badge edge and fish outline are Main ink" % kind)
		_check(_contrast(INK, PAPER) >= 4.5, "%s fish ink reads on paper (%.1f:1)" % [kind, _contrast(INK, PAPER)])
		_check(_contrast(water, PAPER) >= 1.5, "%s fish body separates from badge paper (%.2f:1)" % [kind, _contrast(water, PAPER)])
	for i: int in waters.size():
		for j: int in range(i + 1, waters.size()):
			var a := waters[i]
			var b := waters[j]
			_check(absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.08, "fish kinds keep distinct ring tones %d/%d" % [i, j])
	var fallback: Dictionary = overlay_script.catch_palette("")
	_check(Color(fallback.water).is_equal_approx(waters[0]), "unknown fish type falls back to small fish tone")
	# The badge now holds a fish, inside its circle.
	for radius: float in [22.0, 16.0]:
		var center := Vector2(300, 200)
		var fish: Dictionary = overlay_script.catch_badge_fish(center, radius)
		var body: PackedVector2Array = fish.body
		var tail: PackedVector2Array = fish.tail
		_check(body.size() >= 12 and tail.size() == 3, "badge fish has a body and a tail (r=%s)" % radius)
		var inside := true
		for point: Vector2 in body + tail:
			if point.distance_to(center) > radius * 0.8:
				inside = false
		_check(inside, "badge fish stays inside the badge with a margin (r=%s)" % radius)
		var body_left := INF
		var body_right := -INF
		for point: Vector2 in body:
			body_left = minf(body_left, point.x)
			body_right = maxf(body_right, point.x)
		_check(body_right - body_left >= radius * 0.8, "badge fish body is wide enough to read (r=%s)" % radius)
		_check(tail[1].x > body_right - 0.01 and tail[2].x > body_right - 0.01, "tail fins sit past the body (r=%s)" % radius)
		_check(Geometry2D.is_point_in_polygon(fish.eye, body), "eye sits on the body (r=%s)" % radius)
		_check(Vector2(fish.eye).x < center.x, "eye is at the head end, away from the tail (r=%s)" % radius)
		_check(float(fish.eye_radius) >= 1.2, "eye is a visible dot (r=%s)" % radius)
	# Pose (size, alpha, timing, low motion) is unchanged.
	var still: Dictionary = overlay_script.celebration_pose("catch", 0.3, true)
	_check(is_equal_approx(float(still.outer_radius), 64.0) and is_equal_approx(float(still.outer_alpha), 0.78), "low-motion catch ring pose unchanged")
	_check(int(still.particle_count) == 0 and bool(still.show_banner), "low motion still drops specks and keeps the badge")
	var early: Dictionary = overlay_script.celebration_pose("catch", 0.1, false)
	var late: Dictionary = overlay_script.celebration_pose("catch", 0.9, false)
	_check(is_equal_approx(float(early.outer_radius), lerpf(16.0, 110.0, 0.1)), "ordinary ring still expands on the same curve")
	_check(int(early.particle_count) == 12 and int(late.particle_count) == 0, "specks still fly only at the start")
	_check(bool(early.show_banner) and not bool(late.show_banner), "badge still shows only during the opening")
	# Real draw pass for each fish type, time and motion mode.
	var overlay: Node2D = overlay_script.new()
	root.add_child(overlay)
	var drawn := [0]
	overlay.draw.connect(func() -> void: drawn[0] += 1)
	for reduced: bool in [false, true]:
		root.get_node("TuningStore").set_value("ui.reduced_motion", reduced, false)
		for kind: String in ["small", "medium", "odd"]:
			for remaining: float in [3.1, 2.4, 1.2, 0.2]:
				overlay.fish_ring_time = remaining
				overlay.fish_ring_type = kind
				overlay.fish_ring_pos = Vector2(640, 420)
				var before: int = drawn[0]
				overlay.queue_redraw()
				await process_frame
				await process_frame
				_check(drawn[0] > before, "catch rings draw (%s, %.1fs, reduced=%s)" % [kind, remaining, reduced])
	root.get_node("TuningStore").set_value("ui.reduced_motion", false, false)
	overlay.queue_free()
	_finish()


func _has_static(script: Script, method: String) -> bool:
	for entry: Dictionary in script.get_script_method_list():
		if str(entry.get("name", "")) == method:
			return true
	return false


func _luminance(c: Color) -> float:
	var channel := func(v: float) -> float:
		return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * channel.call(c.r) + 0.7152 * channel.call(c.g) + 0.0722 * channel.call(c.b)


func _contrast(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _finish() -> void:
	if failures.is_empty():
		print("[fish-catch-palette] PASS: ", checks, " checks")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	print("[fish-catch-palette] FAIL: ", failures.size(), " of ", checks)
	quit(1)


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
