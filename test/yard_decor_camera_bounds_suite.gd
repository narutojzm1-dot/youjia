extends SceneTree
# The yard decor editor zooms toward the chosen place. Its view must stay on the
# painted yard (no blank paper band past the edge) while the chosen place stays
# inside the preview area beside or above the decor paper. Switching places,
# choosing a find or nudging must not move the view (#595).
var DecorPanel: GDScript
const Model := preload("res://scripts/inventory/yard_decor.gd")
const VIEWPORTS := [Vector2(1280, 720), Vector2(1920, 1080), Vector2(1024, 768), Vector2(844, 390), Vector2(640, 300), Vector2(568, 320), Vector2(390, 844), Vector2(360, 640), Vector2(320, 568), Vector2(768, 1024)]
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func frame_ok(tag: String, vs: Vector2, fit: Rect2, shown: Rect2) -> void:
	var world := Vector2(1280, 720)
	for spot: Vector2 in Model.SPOTS.values():
		var f: Dictionary = DecorPanel.camera_frame(spot, vs, fit, shown, world)
		var zoom := float(f.zoom)
		var view := Rect2(f.center - vs * 0.5 / zoom, vs / zoom)
		var seen := Rect2(Vector2.ZERO, vs) if vs.x > vs.y else shown.grow(8.0).intersection(Rect2(Vector2.ZERO, vs))
		var seen_world := Rect2(f.center + (seen.position - vs * 0.5) / zoom, seen.size / zoom)
		check(Rect2(Vector2(-0.5, -0.5), world + Vector2.ONE).encloses(seen_world), "%s visible area on the yard %s" % [tag, seen_world])
		for other: Vector2 in Model.SPOTS.values():
			check(fit.grow(-23.9).has_point(vs * 0.5 + (other - f.center) * zoom), "%s every place fits the preview" % tag)
		var first: Dictionary = DecorPanel.camera_frame(Model.SPOTS.values()[0], vs, fit, shown, world)
		check(first.center.is_equal_approx(f.center) and is_equal_approx(float(first.zoom), zoom), "%s frame independent of selected place" % tag)

func helper_checks() -> void:
	var vs := Vector2(1280, 720)
	var preview := Rect2(8, 8, 760, 704)
	var spot := Vector2(290, 575)
	var unclamped := spot + (vs * 0.5 - preview.get_center()) / 1.6
	check(unclamped.y + vs.y * 0.5 / 1.6 > 720.0, "old centring ran past the yard bottom at 1280x720")
	frame_ok("helper 1280x720", vs, preview, preview)
	frame_ok("helper 390x844", Vector2(390, 844), Rect2(8, 8, 374, 500), Rect2(8, 8, 374, 513))
	frame_ok("helper 2560x1440", Vector2(2560, 1440), Rect2(8, 8, 2226, 1424), Rect2(8, 8, 2226, 1424))

func run() -> void:
	DecorPanel = load("res://scripts/ui/yard_decor_panel.gd")
	helper_checks()
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		push_error("Decor camera suite requires isolated data")
		quit(2)
		return
	root.size = Vector2i(1280, 720)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for frame in 3: await process_frame
	await main._start_holiday()
	var store = root.get_node("SaveStore")
	store.request_exploration_trip(null, 1, PackedStringArray([ExplorationRoutes.FINDS[0]]), {})
	check(await store.flush_pending(), "find stocked for preview")
	var world := Vector2(1280, 720)
	for vs: Vector2 in VIEWPORTS:
		root.size = Vector2i(vs)
		for frame in 3: await process_frame
		main._show_basket()
		main._basket_panel.decor_button.pressed.emit()
		for frame in 2: await process_frame
		var steady_zoom: Vector2 = main._camera.zoom
		var steady_center: Vector2 = main._camera.get_screen_center_position()
		for spot: String in Model.SPOTS:
			main._decor_panel.choose_spot(spot)
			for frame in 2: await process_frame
			var tag0 := "%dx%d %s" % [vs.x, vs.y, spot]
			check(main._camera.zoom.is_equal_approx(steady_zoom) and main._camera.get_screen_center_position().distance_to(steady_center) < 0.01, "%s switching place keeps the view still" % tag0)
			main._decor_panel.choose_find(ExplorationRoutes.FINDS[0])
			check(not main._decor_panel.draft.is_empty(), "%s preview drafted" % tag0)
			main._decor_panel.nudge(Vector2i(1, 1))
			for frame in 2: await process_frame
			check(main._camera.get_screen_center_position().distance_to(steady_center) < 0.01, "%s choosing and nudging keeps the view still" % tag0)
			var tag := "%dx%d %s" % [vs.x, vs.y, spot]
			var cam: Camera2D = main._camera
			var center: Vector2 = cam.get_screen_center_position()
			var view := Rect2(center - vs * 0.5 / cam.zoom, vs / cam.zoom)
			var preview: Rect2 = main._decor_panel.preview_rect()
			var on_screen: Vector2 = vs * 0.5 + (Vector2(Model.SPOTS[spot]) - center) * cam.zoom
			check(preview.grow(-20.0).has_point(on_screen), "%s place visible in preview %s" % [tag, on_screen])
			var paper: Rect2 = main._decor_panel.paper.get_global_rect()
			var bare := 0
			for gx in 17:
				for gy in 17:
					var at := Vector2(vs.x * gx / 16.0, vs.y * gy / 16.0)
					# The paper keeps an 8 px gutter to the screen edge; that strip is page, not view.
					if paper.grow(9.0).has_point(at): continue
					var w := center + (at - vs * 0.5) / cam.zoom
					if w.x < -0.5 or w.y < -0.5 or w.x > world.x + 0.5 or w.y > world.y + 0.5: bare += 1
			check(bare == 0, "%s %d uncovered screen samples outside the paper, view %s" % [tag, bare, view])
		main._hide_decor()
		main._basket_panel.visible = false
		for frame in 2: await process_frame
	await shrinking_paper(main)
	if failures.is_empty():
		print("YARD_DECOR_CAMERA_BOUNDS checks=%d failures=0" % checks)
	else:
		for f in failures: print("FAIL ", f)
		print("YARD_DECOR_CAMERA_BOUNDS checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func bare_samples(main, vs: Vector2) -> int:
	var cam: Camera2D = main._camera
	var center: Vector2 = cam.get_screen_center_position()
	var paper: Rect2 = main._decor_panel.paper.get_global_rect()
	var bare := 0
	for gx in 33:
		for gy in 33:
			var at := Vector2(vs.x * gx / 32.0, vs.y * gy / 32.0)
			if paper.grow(9.0).has_point(at): continue
			var w := center + (at - vs * 0.5) / cam.zoom
			if w.x < -0.5 or w.y < -0.5 or w.x > 1280.5 or w.y > 720.5: bare += 1
	return bare

# Review of 616f7471: in portrait the paper hugs its rows, so opening on an empty
# place (longer hint) and then switching to a placed find used to shorten the
# paper under a frame cached for the taller one, uncovering the yard's edge.
func shrinking_paper(main) -> void:
	var store = root.get_node("SaveStore")
	var panel = main._decor_panel
	main._show_basket()
	main._basket_panel.decor_button.pressed.emit()
	for frame in 2: await process_frame
	panel.choose_spot("fence_edge")
	panel.choose_find(ExplorationRoutes.FINDS[0])
	panel.commit()
	check(await store.flush_pending(), "find placed at the fence")
	for frame in 3: await process_frame
	check(not main._world.decor_view.placed("fence_edge").is_empty(), "fence place now holds a find")
	main._hide_decor()
	main._basket_panel.visible = false
	for loc: String in ["zh-CN", "en"]:
		root.get_node("I18n").set_locale(loc)
		for vs: Vector2 in [Vector2(390, 844), Vector2(360, 640), Vector2(768, 1024), Vector2(320, 568)]:
			root.size = Vector2i(vs)
			for frame in 3: await process_frame
			main._show_basket()
			main._basket_panel.decor_button.pressed.emit()
			panel.choose_spot("house_edge")
			for frame in 2: await process_frame
			main._hide_decor()
			main._basket_panel.visible = false
			for frame in 2: await process_frame
			main._show_basket()
			main._basket_panel.decor_button.pressed.emit()
			for frame in 2: await process_frame
			var tall: float = panel.paper.size.y
			var tag := "%s %dx%d" % [loc, vs.x, vs.y]
			check(bare_samples(main, vs) == 0, "%s opened on an empty place stays on the yard" % tag)
			panel.choose_spot("fence_edge")
			for frame in 2: await process_frame
			check(panel.paper.size.y >= tall - 0.5, "%s paper does not shorten while decor is open (%.1f < %.1f)" % [tag, panel.paper.size.y, tall])
			check(bare_samples(main, vs) == 0, "%s switching to the placed find stays on the yard" % tag)
			panel.nudge(Vector2i(0, 1))
			for frame in 2: await process_frame
			check(bare_samples(main, vs) == 0, "%s nudging stays on the yard" % tag)
			root.size = Vector2i(vs.x, int(vs.y * 0.66))
			for frame in 3: await process_frame
			var short := Vector2(vs.x, int(vs.y * 0.66))
			check(panel.paper.size.y <= minf(320.0, short.y * 0.48) + 0.6, "%s held paper respects a shorter window" % tag)
			check(bare_samples(main, short) == 0, "%s shorter window stays on the yard" % tag)
			main._hide_decor()
			main._basket_panel.visible = false
			for frame in 2: await process_frame
	root.get_node("I18n").set_locale("zh-CN")
