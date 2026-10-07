extends SceneTree

## REQ-20261007-053: when a find is taken on the near path, its name used to sit
## on a square, 85%-opaque pale-yellow block (draw_rect), so the path texture
## showed through and it did not match the rounded warm-paper slips used by the
## look caption and the mouse tooltip. The name now sits on the same warm paper
## as PaperTooltipStyle: near-opaque PAPER, 1px soft-brown edge, 8px corners,
## faint ink shadow; the text is centred on the font's ascent/descent.
## Unchanged: font, 17px size, ink colour, when the name shows (halo > 0.5),
## its fade, and the reveal's path, timing and basket result.
##
## Checks (zh-CN + en, all finds, 7 viewports, normal + reduced motion, every
## drawn frame): the slip encloses the text line with its padding, is centred
## on the find, clears the reveal disc, stays inside the room near_path_scroll
## reserves above the find (so the look caption stays uncovered) and on screen,
## and fades with the halo. On unmodified main the slip API does not exist, so
## every slip check fails.

const MemoryStore := preload("res://test/fixtures/exploration_memory_store.gd")
const PaperTooltipStyle := preload("res://scripts/ui/paper_tooltip_style.gd")
const CLOCK := {"day": 3, "elapsed": 12.5}
const VIEWS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(568, 320), Vector2i(390, 844), Vector2i(360, 640), Vector2i(320, 568), Vector2i(280, 653)]

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


func seed_all_four() -> int:
	for value in 4000:
		var session := ExplorationSession.new(ExplorationRoutes.catalog(), 0)
		session.begin(ExplorationRoutes.NEAR_PATH, CLOCK, value)
		var full := str(session.get_view().get("offer", "")) != ""
		for stop_id: String in ["brook", "shade", "slope"]:
			session.visit(stop_id)
			full = full and str(session.get_view().get("offer", "")) != ""
		if full:
			return value
	return -1


static func luminance(c: Color) -> float:
	var channel := func(v: float) -> float: return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * channel.call(c.r) + 0.7152 * channel.call(c.g) + 0.0722 * channel.call(c.b)


static func contrast(a: Color, b: Color) -> float:
	var la := luminance(a)
	var lb := luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func run() -> void:
	var probe := FindReveal.new()
	var has_api := probe.has_method("name_slip_rect") and probe.has_method("name_slip_style") and probe.has_method("name_font")
	check(has_api, "the reveal exposes its name slip geometry and paper style")
	if not has_api:
		probe.free()
		finish()
		return
	_style(probe)
	probe.free()
	_geometry()
	await _in_scroll()
	finish()


func _style(probe: FindReveal) -> void:
	var style: StyleBoxFlat = probe.name_slip_style(1.0)
	var paper: StyleBoxFlat = PaperTooltipStyle.panel()
	check(style.bg_color.is_equal_approx(paper.bg_color) and style.bg_color.a >= 0.95, "the name slip is the near-opaque tooltip paper, not an 85% pale block")
	check(style.border_color.is_equal_approx(paper.border_color) and style.border_width_top == 1 and style.border_width_left == 1 and style.border_width_right == 1 and style.border_width_bottom == 1, "it has the 1px soft-brown paper edge")
	check(style.corner_radius_top_left == 8 and style.corner_radius_bottom_right == 8 and style.anti_aliasing, "it has rounded 8px corners")
	check(style.shadow_color.is_equal_approx(paper.shadow_color) and style.shadow_size == FindReveal.NAME_SHADOW_SIZE and style.shadow_offset == FindReveal.NAME_SHADOW, "it lifts off the path with the faint ink shadow")
	check(contrast(FindReveal.INK, Color(paper.bg_color, 1.0)) >= 7.0, "the ink name reads on the paper (>= 7:1)")
	check(contrast(Color(paper.border_color, 1.0), Color(paper.bg_color, 1.0)) >= 3.0, "the edge stays visible on the paper (>= 3:1)")
	for halo: float in [0.5, 0.75, 1.0]:
		var faded: StyleBoxFlat = probe.name_slip_style(halo)
		check(is_equal_approx(faded.bg_color.a, paper.bg_color.a * halo) and is_equal_approx(faded.border_color.a, paper.border_color.a * halo) and is_equal_approx(faded.shadow_color.a, paper.shadow_color.a * halo), "the slip fades with the halo (%.2f)" % halo)
	probe.name_slip_style(1.0)


func _geometry() -> void:
	var font := load("res://assets/template/fonts/ui_regular.tres") as Font
	check(font != null, "the bundled UI font loads")
	for locale: String in ["zh-CN", "en"]:
		root.get_node("I18n").set_locale(locale)
		for find_id: String in ExplorationRoutes.FINDS:
			var text: String = root.get_node("I18n").t(ExplorationRoutes.find_name_key(find_id))
			var at := Vector2(200, 300)
			var slip: Rect2 = FindReveal.name_slip_rect(at, font, text)
			var ink_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FindReveal.NAME_SIZE).x
			var line := Rect2(Vector2(slip.position.x + FindReveal.NAME_PAD.x, slip.position.y + FindReveal.NAME_PAD.y), Vector2(ink_w, font.get_ascent(FindReveal.NAME_SIZE) + font.get_descent(FindReveal.NAME_SIZE)))
			var tag := "[%s %s] " % [locale, text]
			check(slip.grow_individual(-FindReveal.NAME_PAD.x + 0.01, -FindReveal.NAME_PAD.y + 0.01, -FindReveal.NAME_PAD.x + 0.01, -FindReveal.NAME_PAD.y + 0.01).encloses(line) and slip.encloses(line), tag + "the slip holds the whole text line with its padding")
			check(absf(line.position.y - slip.position.y - (slip.end.y - line.end.y)) < 0.01, tag + "the text sits vertically centred on the slip")
			check(absf(slip.get_center().x - at.x) < 0.01, tag + "the slip is centred over the find")
			check(slip.end.y <= at.y - FindReveal.HALO - 1.0, tag + "the slip clears the reveal disc and its shadow")
			var top_with_shadow := slip.position.y + FindReveal.NAME_SHADOW.y - FindReveal.NAME_SHADOW_SIZE
			check(top_with_shadow >= at.y - FindReveal.HALO - 8.0 - FindReveal.LABEL_ROOM + 2.0, tag + "the slip and its shadow stay inside the room reserved above the find")


func _in_scroll() -> void:
	var seed := seed_all_four()
	check(seed >= 0, "a seed offers a find at all four stops")
	for locale: String in ["zh-CN", "en"]:
		root.get_node("I18n").set_locale(locale)
		for view: Vector2i in VIEWS:
			root.size = view
			for reduced: bool in [false, true]:
				var store := MemoryStore.new()
				var host := ExplorationHost.new(store)
				host.restore()
				host.begin(CLOCK, seed)
				var scroll: Node2D = load("res://scripts/exploration/near_path_scroll.gd").new()
				root.add_child(scroll)
				scroll.setup(host, "sunny")
				await process_frame
				var tag := "[%s %dx%d%s] " % [locale, view.x, view.y, " reduced" if reduced else ""]
				var shown := Rect2(Vector2.ZERO, Vector2(view))
				var drawn := 0
				var off_screen := 0
				var over_caption := 0
				var over_buttons := 0
				var reveals := 0
				for stop: String in ["gate", "brook", "shade", "slope"]:
					if stop != "gate":
						scroll.end_observe()
						scroll.place_at(stop)
						scroll.observe()
					else:
						scroll.observe("gate")
					await process_frame
					if not scroll.pick():
						continue
					var reveal: FindReveal = scroll.reveal
					reveals += 1
					reveal.calm = reduced
					reveal.elapsed = 0.0
					var caption: Rect2 = Rect2(scroll._caption.position, scroll._caption.size) if scroll._caption.visible else Rect2()
					var cramped: bool = scroll._caption.visible and caption.end.y + FindReveal.HALO + FindReveal.LABEL_ROOM > scroll._pick_button.position.y - FindReveal.HALO - 30.0
					var buttons: Array[Rect2] = []
					for button: Control in [scroll._pick_button, scroll._go_button]:
						if button.visible:
							buttons.append(Rect2(button.position, button.size))
					var queued := false
					while reveal.is_active():
						var pose: Dictionary = reveal.pose()
						if float(pose.halo) > 0.5 and not reveal.title.is_empty():
							drawn += 1
							var slip: Rect2 = FindReveal.name_slip_rect(pose.at, reveal.name_font(), reveal.title)
							var lifted := slip.grow_individual(0, FindReveal.NAME_SHADOW_SIZE - FindReveal.NAME_SHADOW.y, 0, FindReveal.NAME_SHADOW_SIZE + FindReveal.NAME_SHADOW.y)
							if not shown.encloses(lifted):
								off_screen += 1
							if caption.size != Vector2.ZERO and not cramped and lifted.intersects(caption):
								over_caption += 1
							for box: Rect2 in buttons:
								if lifted.intersects(box):
									over_buttons += 1
							if not queued:
								# exercise the real _draw path once per reveal
								reveal.queue_redraw()
								await process_frame
								queued = true
								if not reveal.is_active():
									break
						reveal._process(1.0 / 60.0)
				check(reveals >= 3, tag + "takes and swaps start reveals at the stops")
				check(drawn > 0, tag + "the name slip is shown during the reveal")
				check(off_screen == 0, tag + "the name slip stays on screen in every frame (%d off)" % off_screen)
				check(over_caption == 0, tag + "the name slip never covers the look caption when there is room (%d)" % over_caption)
				check(over_buttons == 0, tag + "the name slip never covers the bottom buttons (%d)" % over_buttons)
				check(scroll.carried().size() >= 1, tag + "the basket still fills from the core, not the reveal")
				scroll.release()
				scroll.free()
				store.free()


func finish() -> void:
	root.get_node("AudioDirector").release_streams()
	if failures.is_empty():
		print("PASS find_reveal_name_slip_suite: %d checks" % checks)
		quit(0)
	else:
		print("FAIL find_reveal_name_slip_suite: %d/%d failed" % [failures.size(), checks])
		for failure in failures.slice(0, 20):
			print("  - " + failure)
		quit(1)
