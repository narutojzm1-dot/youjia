extends SceneTree
# REQ-20261007-065: a place button in the yard decor panel names the find that is
# saved there on a second line (屋前 / 圆石), so the player sees what stands
# where without tapping each place. Empty places and an unsaved preview keep the
# plain name; the three buttons stay the same height, inside the paper, and
# still select their place on mouse or touch.
var checks := 0
var failures: Array[String] = []
const VIEWPORTS := [Vector2(280, 653), Vector2(320, 568), Vector2(390, 844), Vector2(768, 1024), Vector2(568, 320), Vector2(844, 390), Vector2(1280, 720)]
const SPOT_IDS := ["house_edge", "fence_edge", "pond_path"]

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func tap(p: Control, b: Button) -> void:
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.position = b.get_global_rect().get_center()
	down.pressed = true
	p.handle_touch_event(down)
	var up := down.duplicate() as InputEventScreenTouch
	up.pressed = false
	p.handle_touch_event(up)

func settle() -> void:
	for i in 3: await process_frame

func texts(p: Control) -> Array:
	var out: Array = []
	for spot: String in SPOT_IDS: out.append(p.slot_buttons[spot].text)
	return out

func verify_layout(p: Control, vs: Vector2, tag: String) -> void:
	var paper: Rect2 = p.paper.get_global_rect()
	check(paper.position.x >= 7.5 and paper.position.y >= 7.5 and paper.end.x <= vs.x - 7.5 and paper.end.y <= vs.y - 7.5, tag + " paper on screen " + str(paper))
	var inner := paper.grow(-9.5)
	var height := -1.0
	for spot: String in SPOT_IDS:
		var b: Button = p.slot_buttons[spot]
		var r := b.get_global_rect()
		check(r.position.x >= inner.position.x and r.end.x <= inner.end.x, tag + " %s inside paper %s in %s" % [spot, r, inner])
		check(b.get_combined_minimum_size().x <= r.size.x + 0.5, tag + " %s text not squeezed" % spot)
		check(r.size.y >= 44.0, tag + " %s keeps 44px target" % spot)
		if height < 0.0: height = r.size.y
		check(absf(r.size.y - height) < 0.5, tag + " %s same height as other places" % spot)

func run() -> void:
	var i18n := root.get_node("I18n")
	var stone: String = ExplorationRoutes.FINDS[0]
	var cone: String = ExplorationRoutes.FINDS[1]
	var feather: String = ExplorationRoutes.FINDS[2]
	var counts := {stone: 1, cone: 1, feather: 1}
	for loc: String in ["zh-CN", "en"]:
		i18n.set_locale(loc)
		var en := loc == "en"
		var plain := ["House", "Fence", "Path"] if en else ["屋前", "篱边", "塘边小路"]
		var names := ["Stone", "Cone", "Feather"] if en else ["圆石", "松果", "落羽"]
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
			await settle()
			check(texts(p) == plain, tag + " empty yard: plain place names " + str(texts(p)))
			verify_layout(p, vs, tag + " empty")
			# An unsaved preview does not label the place.
			p.choose_spot("fence_edge")
			p.choose_find(cone)
			await settle()
			check(texts(p) == plain, tag + " preview only: still plain " + str(texts(p)))
			# One saved find.
			p.update_view({"places": {"house_edge": {"find_id": stone, "dx": 0, "dy": 0}}}, {stone: 0, cone: 1, feather: 1}, "idle", false)
			await settle()
			check(texts(p) == [plain[0] + "\n" + names[0], plain[1], plain[2]], tag + " stone at house named " + str(texts(p)))
			verify_layout(p, vs, tag + " one placed")
			# All three filled, with offsets.
			var full := {"places": {
				"house_edge": {"find_id": stone, "dx": 1, "dy": 0},
				"fence_edge": {"find_id": feather, "dx": 0, "dy": -1},
				"pond_path": {"find_id": cone, "dx": -1, "dy": 1}}}
			p.update_view(full, {stone: 0, cone: 0, feather: 0}, "idle", false)
			await settle()
			check(texts(p) == [plain[0] + "\n" + names[0], plain[1] + "\n" + names[2], plain[2] + "\n" + names[1]], tag + " all three named " + str(texts(p)))
			verify_layout(p, vs, tag + " full")
			# Saving: labels still say what is there, places greyed as before.
			p.update_view(full, {stone: 0, cone: 0, feather: 0}, "pending", true)
			await settle()
			check(texts(p)[2] == plain[2] + "\n" + names[1], tag + " busy keeps label")
			check(p.slot_buttons["pond_path"].disabled, tag + " busy still disables places")
			p.update_view(full, {stone: 0, cone: 0, feather: 0}, "idle", false)
			await settle()
			# Labelled places still select on mouse press and touch tap.
			p.slot_buttons["pond_path"].pressed.emit()
			check(p.selected == "pond_path", tag + " press selects labelled place")
			if p.scroll.get_global_rect().has_point(p.slot_buttons["fence_edge"].get_global_rect().get_center()):
				tap(p, p.slot_buttons["fence_edge"])
				check(p.selected == "fence_edge", tag + " touch tap selects labelled place")
			# Putting a find back clears its label.
			p.update_view({"places": {"house_edge": full.places.house_edge}}, {stone: 0, cone: 1, feather: 1}, "idle", false)
			await settle()
			check(texts(p) == [plain[0] + "\n" + names[0], plain[1], plain[2]], tag + " put back clears label " + str(texts(p)))
			# Unknown or broken save data falls back to the plain name.
			p.update_view({"places": {"house_edge": {"find_id": "mystery", "dx": 0, "dy": 0}, "fence_edge": {}}}, counts, "idle", false)
			await settle()
			check(texts(p) == plain, tag + " unknown find falls back " + str(texts(p)))
			host.queue_free()
			await process_frame
	if failures.is_empty():
		print("[yard-decor-place-label] PASS: %d checks" % checks)
		quit(0)
	else:
		for f: String in failures: printerr("[yard-decor-place-label] FAIL: " + f)
		printerr("[yard-decor-place-label] FAILED %d of %d checks" % [failures.size(), checks])
		quit(1)
