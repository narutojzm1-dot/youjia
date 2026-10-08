extends SceneTree
# The yard decor editor zooms toward the chosen place. Its view must stay on the
# painted yard (no blank paper band past the edge) while the chosen place stays
# inside the preview area beside or above the decor paper.
var DecorPanel: GDScript
const Model := preload("res://scripts/inventory/yard_decor.gd")
const VIEWPORTS := [Vector2(1280, 720), Vector2(1920, 1080), Vector2(1024, 768), Vector2(844, 390), Vector2(640, 300), Vector2(568, 320), Vector2(390, 844), Vector2(360, 640), Vector2(320, 568), Vector2(768, 1024)]
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func helper_checks() -> void:
	var world := Vector2(1280, 720)
	var vs := Vector2(1280, 720)
	var preview := Rect2(8, 8, 760, 704)
	var spot := Vector2(290, 575)
	var unclamped := spot + (vs * 0.5 - preview.get_center()) / 1.6
	check(unclamped.y + vs.y * 0.5 / 1.6 > world.y, "old centring ran past the yard bottom at 1280x720")
	var c: Vector2 = DecorPanel.camera_center(spot, vs, preview, 1.6, world)
	check(c.y + vs.y * 0.5 / 1.6 <= world.y + 0.01 and c.x - vs.x * 0.5 / 1.6 >= -0.01, "clamped view stays on the yard")
	var narrow := Rect2(8, 8, 374, 300)
	var tall := Vector2(390, 844)
	var c2: Vector2 = DecorPanel.camera_center(spot, tall, narrow, 1.44, world)
	var screen_y := tall.y * 0.5 + (spot.y - c2.y) * 1.44
	check(screen_y <= narrow.end.y - 47.9, "spot stays above the paper when the yard edge would push it under")
	var c3: Vector2 = DecorPanel.camera_center(Vector2(640, 360), vs, Rect2(Vector2.ZERO, vs), 0.5, world)
	check(c3.is_equal_approx(world * 0.5), "view wider than the yard is centred")

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
	var world := Vector2(1280, 720)
	for vs: Vector2 in VIEWPORTS:
		root.size = Vector2i(vs)
		for frame in 3: await process_frame
		main._show_basket()
		main._basket_panel.decor_button.pressed.emit()
		for spot: String in Model.SPOTS:
			main._decor_panel.choose_spot(spot)
			for frame in 2: await process_frame
			var tag := "%dx%d %s" % [vs.x, vs.y, spot]
			var cam: Camera2D = main._camera
			var center: Vector2 = cam.get_screen_center_position()
			var view := Rect2(center - vs * 0.5 / cam.zoom, vs / cam.zoom)
			var preview: Rect2 = main._decor_panel.preview_rect()
			var on_screen: Vector2 = vs * 0.5 + (Vector2(Model.SPOTS[spot]) - center) * cam.zoom
			check(preview.grow(-40.0).has_point(on_screen), "%s place visible in preview %s" % [tag, on_screen])
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
	if failures.is_empty():
		print("YARD_DECOR_CAMERA_BOUNDS checks=%d failures=0" % checks)
	else:
		for f in failures: print("FAIL ", f)
		print("YARD_DECOR_CAMERA_BOUNDS checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
