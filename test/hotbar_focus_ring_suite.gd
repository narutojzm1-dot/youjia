extends SceneTree
## 快捷栏格子的键盘焦点圈：画在格子外、不盖住选中 / 武装 / 落点描边，
## 在快捷栏纸面上对比度 >= 3:1，不压到相邻格、不出纸面和视口。

const HotbarPath := "res://scripts/ui/hold_hotbar.gd"
const VIEWPORTS := [Vector2i(390, 844), Vector2i(844, 390), Vector2i(1280, 720)]
const RING_MIN := 3.0
const EPS := 0.51

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


static func _lum(c: Color) -> float:
	var l := Color(c.r, c.g, c.b).srgb_to_linear()
	return 0.2126 * l.r + 0.7152 * l.g + 0.0722 * l.b


static func contrast(a: Color, b: Color) -> float:
	var la := _lum(a)
	var lb := _lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func run() -> void:
	var script = load(HotbarPath)
	check(script != null, "hold_hotbar.gd loads")
	if script != null:
		for vs: Vector2i in VIEWPORTS:
			await _viewport(script, vs)
	_finish()


func _inv(held: String) -> Dictionary:
	return {"schema": 3, "revision": 1, "fish": {"medium": 2}, "grass": 3, "millet": 0, "held": held, "ground": [], "next_food_id": 1}


func _viewport(script, vs: Vector2i) -> void:
	root.size = vs
	var host := Control.new()
	host.size = Vector2(vs)
	root.add_child(host)
	var bar = script.new()
	host.add_child(bar)
	await process_frame
	bar.set_slots(["medium", "grass", "millet", "", ""])
	var rect: Rect2 = script.preferred_rect(Vector2(vs), vs.x < 700.0)
	bar.position = rect.position
	bar.size = rect.size
	await process_frame
	var tag := "%dx%d" % [vs.x, vs.y]
	bar.update_view(_inv(""), {}, "idle", false)
	await process_frame
	_ring_checks(bar, "%s idle" % tag)
	bar.update_view(_inv("grass"), {}, "idle", false)
	await process_frame
	_ring_checks(bar, "%s grass selected" % tag)
	bar.update_view(_inv("medium"), {}, "idle", false)
	await process_frame
	check(bar.is_place_armed(), "%s held fish arms its slot" % tag)
	_ring_checks(bar, "%s fish armed" % tag)
	bar.set_configuring(true)
	bar.set_drop_hint(3)
	await process_frame
	_ring_checks(bar, "%s drop hint" % tag)
	bar.set_drop_hint(-1)
	bar.set_configuring(false)
	host.queue_free()
	await process_frame


func _ring_checks(bar, tag: String) -> void:
	var paper := (bar.get_node("Paper") as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
	var paper_rect: Rect2 = (bar.get_node("Paper") as Control).get_global_rect()
	var view := Rect2(Vector2.ZERO, Vector2(root.size))
	var backs: Array[Color] = [Color(paper.bg_color.r, paper.bg_color.g, paper.bg_color.b)]
	var a := paper.bg_color.a
	backs.append(Color(paper.bg_color.r * a, paper.bg_color.g * a, paper.bg_color.b * a))
	for index in bar.slot_cells.size():
		var cell: Button = bar.slot_cells[index]
		var name := "%s slot %d" % [tag, index]
		var ring := cell.get_theme_stylebox("focus") as StyleBoxFlat
		var normal := cell.get_theme_stylebox("normal") as StyleBoxFlat
		check(ring != null and normal != null, "%s: flat focus and normal styles" % name)
		if ring == null or normal == null:
			continue
		check(not ring.draw_center or ring.bg_color.a <= 0.01, "%s: ring has no fill, the slot still shows" % name)
		check(ring.border_color.a >= 0.99, "%s: ring opaque" % name)
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			var width := ring.get_border_width(side)
			var outset := ring.get_expand_margin(side)
			check(width >= 2, "%s: ring side %d >= 2px (got %d)" % [name, side, width])
			check(outset >= width + 1.0 - EPS, "%s: ring side %d sits outside the slot edge with a paper gap (outset %.1f, width %d)" % [name, side, outset, width])
			check(outset <= bar.GAP / 2.0 + EPS, "%s: ring side %d does not reach the next slot (outset %.1f)" % [name, side, outset])
		for bg: Color in backs:
			var r := contrast(ring.border_color, bg)
			check(r >= RING_MIN, "%s: ring #%s on paper #%s contrast %.2f >= %.1f" % [name, ring.border_color.to_html(false), bg.to_html(false), r, RING_MIN])
		var drawn := cell.get_global_rect().grow_individual(ring.expand_margin_left, ring.expand_margin_top, ring.expand_margin_right, ring.expand_margin_bottom)
		check(paper_rect.grow(EPS).encloses(drawn), "%s: ring %s stays on the hotbar paper %s" % [name, drawn, paper_rect])
		check(view.grow(EPS).encloses(drawn), "%s: ring %s inside viewport %s" % [name, drawn, view])
		cell.grab_focus()
		check(cell.has_focus(), "%s: focus lands" % name)
		cell.release_focus()


func _finish() -> void:
	check(checks >= 300, "suite ran enough checks (%d)" % checks)
	if root.has_node("AudioDirector"):
		root.get_node("AudioDirector").release_streams()
	if failures.is_empty():
		print("HOTBAR_FOCUS_RING checks=%d failures=0" % checks)
		quit(0)
	else:
		for failure: String in failures.slice(0, 30):
			printerr("[hotbar-focus-ring] " + failure)
		print("HOTBAR_FOCUS_RING checks=%d failures=%d" % [checks, failures.size()])
		quit(1)
