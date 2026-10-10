extends SceneTree
## Short landscapes: the pause / confirm paper covers part of the yard HUD (goal paper, 「歇一会儿」,
## day label, bottom chips) and left half-cut text peeking past its edge. Any HUD piece the open
## paper overlaps is now faded out with its group (goal paper / top-right column / bottom row, so the
## row never shows a gap; self_modulate only) and comes back when the paper closes. The basket,
## chick care and crop papers follow the same rule.
const VIEWPORTS := [Vector2i(280, 653), Vector2i(320, 568), Vector2i(390, 844), Vector2i(568, 320), Vector2i(640, 300), Vector2i(640, 360), Vector2i(844, 390), Vector2i(1024, 600), Vector2i(1280, 720), Vector2i(1920, 1080)]
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func settle() -> void:
	for i in 5: await process_frame

func groups(main: Node) -> Array:
	return main._hud_menu_groups()

func names(main: Node) -> Array:
	return ["goal paper", "top-right column", "bottom row"]

func flags(main: Node) -> Array:
	var out: Array = []
	for group: Array in groups(main):
		for node: Control in group:
			out.append([node.visible, node.mouse_filter, (node as Button).disabled if node is Button else false])
	return out

func check_against(main: Node, covers: Array, tag: String) -> Dictionary:
	var hidden := {}
	var list := groups(main)
	for i in list.size():
		var group: Array = list[i]
		var covered := false
		for node: Control in group:
			for cover: Rect2 in covers:
				if node.get_global_rect().intersects(cover): covered = true
		for node: Control in group:
			check(is_equal_approx(node.self_modulate.a, 0.0 if covered else 1.0), "%s %s is %s" % [tag, names(main)[i], "faded under the paper" if covered else "shown (not under the paper)"])
		if covered: hidden[names(main)[i]] = true
	return hidden

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		print("[hud_under_menu] refused: not an isolated data dir")
		quit(2)
		return
	var store = root.get_node("SaveStore")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	check(await store.flush_pending(), "isolated save ready")
	await settle()
	var hidden_at := {}
	for locale: String in ["zh-CN", "en"]:
		root.get_node("I18n").set_locale(locale)
		for viewport: Vector2i in VIEWPORTS:
			var tag := "%s %s" % [locale, viewport]
			root.size = viewport
			await settle()
			for group: Array in groups(main):
				for node: Control in group:
					check(is_equal_approx(node.self_modulate.a, 1.0), tag + " HUD fully shown before pausing")
			var before := flags(main)
			main._toggle_pause()
			await settle()
			check(main._pause_screen.visible, tag + " pause paper open")
			var pause_rect: Rect2 = main._pause_panel.get_global_rect()
			check(main._centered_panel_rect(main._pause_panel).is_equal_approx(pause_rect), tag + " predicted pause paper rect matches its laid-out rect")
			var hidden := check_against(main, [pause_rect], tag + " pause:")
			hidden_at["%s %s" % [locale, viewport]] = hidden
			check(flags(main) == before, tag + " pausing changes no HUD visibility, input filter or disabled state")
			main._request_destructive_action("restart")
			await settle()
			var confirm_rect: Rect2 = main._confirm_panel.get_global_rect()
			check(main._centered_panel_rect(main._confirm_panel).is_equal_approx(confirm_rect), tag + " predicted confirm paper rect matches")
			check_against(main, [pause_rect, confirm_rect], tag + " confirm:")
			main._cancel_destructive_action()
			await settle()
			check_against(main, [pause_rect], tag + " back on pause:")
			root.size = Vector2i(viewport.y, viewport.x)
			await settle()
			check_against(main, [main._pause_panel.get_global_rect()], tag + " rotated while paused:")
			root.size = viewport
			await settle()
			main._toggle_pause()
			await settle()
			check(not main._pause_screen.visible, tag + " pause paper closed")
			for group: Array in groups(main):
				for node: Control in group:
					check(is_equal_approx(node.self_modulate.a, 1.0), tag + " every HUD piece comes back after resuming")
			check(flags(main) == before, tag + " resuming leaves HUD state as before")
	var papers := {
		"basket": [func() -> void: main._show_basket(), func() -> void: main._hide_basket(), func() -> Control: return main._basket_panel.panel],
		"chick": [func() -> void: main._show_chick_care(), func() -> void: main._hide_chick_care(), func() -> Control: return main._chick_panel.paper],
		"crop": [func() -> void: main._show_crops(), func() -> void: main._hide_crops(), func() -> Control: return main._crop_panel.paper],
	}
	for locale: String in ["zh-CN", "en"]:
		root.get_node("I18n").set_locale(locale)
		for viewport: Vector2i in VIEWPORTS:
			root.size = viewport
			await settle()
			for kind: String in papers:
				var tag := "%s %s %s" % [kind, locale, viewport]
				var before := flags(main)
				(papers[kind][0] as Callable).call()
				await settle()
				var paper: Control = (papers[kind][2] as Callable).call()
				check(paper.is_visible_in_tree(), tag + " paper open")
				var hidden := check_against(main, [paper.get_global_rect()], tag + ":")
				hidden_at["%s %s %s" % [kind, locale, viewport]] = hidden
				check(flags(main) == before, tag + " opening changes no HUD visibility, input filter or disabled state")
				(papers[kind][1] as Callable).call()
				await settle()
				for group: Array in groups(main):
					for node: Control in group:
						check(is_equal_approx(node.self_modulate.a, 1.0), tag + " every HUD piece comes back after closing")
				check(flags(main) == before, tag + " closing leaves HUD state as before")
	for locale: String in ["zh-CN", "en"]:
		check((hidden_at["basket %s (568, 320)" % locale] as Dictionary).size() == 3, locale + " 568x320: basket paper fades all three groups it covers")
		check((hidden_at["basket %s (390, 844)" % locale] as Dictionary).is_empty(), locale + " 390x844: basket paper covers no HUD, all stay")
		check((hidden_at["crop %s (1920, 1080)" % locale] as Dictionary).is_empty(), locale + " 1920x1080: crop paper covers no HUD")
	if OS.get_environment("HUD_UNDER_MENU_REPORT") == "1":
		for key: String in hidden_at: print("hidden ", key, " ", (hidden_at[key] as Dictionary).keys())
	for locale: String in ["zh-CN", "en"]:
		var short: Dictionary = hidden_at["%s (568, 320)" % locale]
		check(short.size() == 3, locale + " 568x320: goal paper, top-right column and bottom row all sit under the pause paper and fade")
		var phone: Dictionary = hidden_at["%s (390, 844)" % locale]
		check(phone.is_empty(), locale + " 390x844: portrait HUD stays shown")
		var landscape: Dictionary = hidden_at["%s (844, 390)" % locale]
		check(landscape.has("top-right column") and landscape.has("bottom row") and not landscape.has("goal paper"), locale + " 844x390: the half-covered day label column and bottom row fade, the clear goal paper stays")
		var wide: Dictionary = hidden_at["%s (1920, 1080)" % locale]
		check(wide.is_empty(), locale + " 1920x1080: nothing is under the pause paper")
	if failures.is_empty():
		print("[hud_under_menu] PASS: %d checks" % checks)
		quit(0)
	else:
		for f: String in failures.slice(0, 30): printerr("FAIL: " + f)
		print("[hud_under_menu] FAIL: %d of %d" % [failures.size(), checks])
		quit(1)
