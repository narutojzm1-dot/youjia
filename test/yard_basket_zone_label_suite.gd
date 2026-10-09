extends SceneTree
## REQ-20261008-068 (Owner GROK-CONTRIBUTOR): while a round stone / pine cone / feather is
## dragged out of the big basket, each lit yard spot's name (屋前 / 篱边 / 塘边小路) sits on a
## small warm paper slip instead of bare ink over the grass, fence or pond edge. The lit spot
## under the finger gets the ink edge. The slip stays fully on screen and never covers its own
## circle: when there is no room above (a spot pinned to the top edge) it goes below.
## Runs the real Main against an isolated native save; nothing is committed.
var checks := 0
var failures: Array[String] = []
var main
var store
const VIEWPORTS := [Vector2i(280, 653), Vector2i(390, 844), Vector2i(568, 320), Vector2i(844, 390), Vector2i(1280, 720)]

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func settle() -> void:
	check(await store.flush_pending(), "native write and acknowledgement complete")
	for frame in 3: await process_frame

func frames(n: int = 4) -> void:
	for frame in n: await process_frame

func circle_gap(rect: Rect2, at: Vector2) -> float:
	var nearest := Vector2(clampf(at.x, rect.position.x, rect.end.x), clampf(at.y, rect.position.y, rect.end.y))
	return nearest.distance_to(at)

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		push_error("Basket zone labels require an isolated player profile")
		quit(2)
		return
	store = root.get_node("SaveStore")
	root.size = Vector2i(390, 844)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(3)
	await main._start_holiday()
	var cone: String = ExplorationRoutes.FIND_PINE_CONE
	var feather: String = ExplorationRoutes.FIND_FEATHER
	store.request_exploration_trip(null, 1, PackedStringArray([cone, feather]), {})
	await settle()
	main._on_inventory_changed()
	main._on_decor_changed()
	var i18n := root.get_node("I18n")
	var spots: Dictionary = load("res://scripts/inventory/yard_decor.gd").SPOTS
	var expected := {"zh-CN": {"house_edge": "屋前", "fence_edge": "篱边", "pond_path": "塘边小路"}, "en": {"house_edge": "House", "fence_edge": "Fence", "pond_path": "Path"}}
	var places_before: int = store.get_yard_decor().places.size()
	var cone_before := int(store.get_available_keepsakes().get(cone, 0))
	for loc: String in ["zh-CN", "en"]:
		i18n.set_locale(loc)
		for viewport: Vector2i in VIEWPORTS:
			var tag := "%s %dx%d" % [loc, viewport.x, viewport.y]
			root.size = viewport
			await frames()
			main._show_basket()
			await frames()
			var panel = main._basket_panel
			var view_rect := Rect2(Vector2.ZERO, panel.size)
			var font: Font = panel.get_theme_default_font()
			check(panel.begin_drag("pine_cone", panel.size * 0.5), tag + " cone drag starts")
			await frames(2)
			check(panel.drag_layer.visible and panel.legal_spots().size() == 3, tag + " three lit spots while dragging")
			for spot: String in spots:
				var at: Vector2 = panel.spot_screen_position(spot)
				var slip: Rect2 = panel.zone_label_rect(spot)
				var text: String = panel.zone_label_text(spot)
				var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, panel.ZONE_LABEL_SIZE).x
				check(text == expected[loc][spot], tag + " %s slip names the spot" % spot)
				check(view_rect.encloses(slip), tag + " %s slip is fully on screen %s in %s" % [spot, slip, view_rect])
				check(slip.size.x >= text_width + panel.ZONE_LABEL_PAD.x * 2.0 - 0.5, tag + " %s name fits inside its slip" % spot)
				check(slip.size.y >= font.get_height(panel.ZONE_LABEL_SIZE), tag + " %s slip is as tall as the text" % spot)
				check(circle_gap(slip, at) >= panel.ZONE_RADIUS, tag + " %s slip does not cover its circle" % spot)
				if slip.position.y > at.y:
					check(at.y - panel.ZONE_RADIUS - panel.ZONE_LABEL_GAP - slip.size.y < panel.ZONE_LABEL_MARGIN, tag + " %s slip only goes below when there is no room above" % spot)
				else:
					check(is_equal_approx(slip.end.y, at.y - panel.ZONE_RADIUS - panel.ZONE_LABEL_GAP), tag + " %s slip sits just above its circle" % spot)
				if at.x - slip.size.x * 0.5 >= panel.ZONE_LABEL_MARGIN and at.x + slip.size.x * 0.5 <= view_rect.size.x - panel.ZONE_LABEL_MARGIN:
					check(absf(slip.get_center().x - at.x) < 0.5, tag + " %s slip is centred over its circle" % spot)
			# Hot spot: drag over the fence spot, its slip gets the ink edge.
			panel.drag_to(panel.spot_screen_position("fence_edge"))
			check(panel.drag_spot == "fence_edge", tag + " fence spot lights up under the finger")
			panel.cancel_drag()
			await frames()
			check(not panel.drag_layer.visible, tag + " cancel hides the zones and slips")
			main._hide_basket()
			await frames()
	# A spot pushed above the camera is pinned to the top edge: no room above, so its slip
	# goes below the circle, still fully on screen and still off the circle.
	i18n.set_locale("zh-CN")
	root.size = Vector2i(390, 844)
	await frames()
	main._show_basket()
	await frames()
	var p = main._basket_panel
	var holder: Node2D = main._world.decor_view
	var holder_at := holder.position
	holder.position += Vector2(0, -4000)
	check(p.begin_drag("pine_cone", p.size * 0.5), "pinned: cone drag starts")
	await frames(2)
	for spot: String in spots:
		var at: Vector2 = p.spot_screen_position(spot)
		var slip: Rect2 = p.zone_label_rect(spot)
		check(at.y <= p.ZONE_RADIUS + 24.5, "pinned: %s circle is pinned to the top edge" % spot)
		check(slip.position.y >= at.y + p.ZONE_RADIUS + p.ZONE_LABEL_GAP - 0.5, "pinned: %s slip goes below its circle" % spot)
		check(Rect2(Vector2.ZERO, p.size).encloses(slip) and circle_gap(slip, at) >= p.ZONE_RADIUS, "pinned: %s slip on screen and off the circle" % spot)
	p.cancel_drag()
	holder.position = holder_at
	main._hide_basket()
	await frames()
	var cold: StyleBoxFlat = load("res://scripts/ui/yard_basket_panel.gd").zone_label_style(false)
	var hot: StyleBoxFlat = load("res://scripts/ui/yard_basket_panel.gd").zone_label_style(true)
	check(cold.bg_color.is_equal_approx(Color(1.0, 0.965, 0.91, 0.92)) and cold.draw_center, "slip is warm basket paper")
	check(cold.border_color == Color("d6ae78") and cold.border_width_left == 1, "unlit slip has the paper edge")
	check(hot.border_color == Color("5b4637") and hot.border_width_left == 2, "lit slip has the 2px ink edge like its circle")
	check(hot.bg_color == cold.bg_color and hot.corner_radius_top_left == 8, "lit and unlit slips share fill and corners")
	check(store.get_yard_decor().places.size() == places_before and int(store.get_available_keepsakes().get(cone, 0)) == cone_before, "dragging and cancelling commits nothing")
	root.get_node("AudioDirector").release_streams()
	print("[yard-basket-zone-label] %s: %d checks" % ["PASS" if failures.is_empty() else "FAIL: %d of" % failures.size(), checks])
	for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
