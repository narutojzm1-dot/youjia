extends SceneTree
## 近郊画卷的地名与操作提示：傍晚、夜里压在暗山和暗草上也读得出，窄屏不出屏、不压按钮。
## 修前：地名是不带底的深墨字，入夜后几乎看不见；280 宽时地名被「歇一会儿」压住；
## 底部操作提示是浅褐色一行字，280 宽越出屏幕右边（「R 回院」被截掉）。
## 现在：地名与提示垫和时钟同款的小纸片；地名在按钮左边放不下时移到按钮下面一行，
## 「停下看看」和字幕让出地名与时钟；提示窄屏折行（最多三行）。真实 Main 进入近郊，中英文、十种视口。
const VIEWPORTS := [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(640, 300), Vector2i(568, 320),
	Vector2i(390, 844), Vector2i(360, 640), Vector2i(320, 568), Vector2i(280, 653),
	Vector2i(700, 300), Vector2i(480, 320)]
const PAPER := Color("fff6e8")

var checks := 0
var failures: Array[String] = []
var main

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func _luminance(c: Color) -> float:
	var out := 0.0
	var weights := [0.2126, 0.7152, 0.0722]
	var channels := [c.r, c.g, c.b]
	for i in 3:
		var v: float = channels[i]
		v = v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
		out += weights[i] * v
	return out

func _contrast(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		push_error("Exploration HUD readable requires an isolated player profile")
		quit(2)
		return
	var i18n = root.get_node("I18n")
	root.size = Vector2i(1280, 720)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	main._world.set_process(false)
	main._on_exploration_requested()
	for i in 20: await process_frame
	check(main._screen == "exploring", "entered the near path")
	if main._screen != "exploring":
		_finish()
		return
	var scroll = main._exploration.scroll
	scroll.set_process(false)

	for label: Label in [scroll._place_label, scroll._hint]:
		var paper := label.get_theme_stylebox("normal") as StyleBoxFlat
		check(paper != null and paper.bg_color.a >= 0.85, "%s sits on a mostly opaque paper" % label.name)
		if paper != null:
			var ink: Color = label.get_theme_color("font_color")
			check(_contrast(ink, Color(paper.bg_color, 1.0)) >= 4.5, "%s ink reaches 4.5:1 on its paper" % label.name)
			check(paper.bg_color.is_equal_approx(main._regional_clock.get_theme_stylebox("normal").bg_color), "%s paper matches the clock pill" % label.name)

	for locale: String in ["zh-CN", "en"]:
		i18n.set_locale(locale)
		for dims: Vector2i in VIEWPORTS:
			var tag := "%s %s" % [dims, locale]
			root.size = dims
			main.size = Vector2(dims)
			await process_frame
			scroll._walked = false
			scroll.end_observe()
			scroll._refresh()
			main._sync_regional_clock()
			_check_top(tag + " walking", scroll)
			_check_hint(tag, scroll, Vector2(dims))
			# 走到一处可看的地方：「停下看看」出现，不压地名和时钟
			scroll.place_at("brook")
			scroll._refresh()
			main._sync_regional_clock()
			check(scroll._look_button.visible, tag + " look button shows near the brook")
			_check_top(tag + " near brook", scroll)
			# 每一处看景字幕：不压地名、时钟，也不压左下篮子（英文矮横屏折行最多）
			for stop_id: String in ["gate", "brook", "shade", "slope", "leaf_pile"]:
				scroll.place_at(stop_id)
				check(scroll.observe(stop_id), tag + " can look at " + stop_id)
				scroll._refresh()
				main._sync_regional_clock()
				_check_top(tag + " looking at " + stop_id, scroll)
				scroll.end_observe()
	i18n.set_locale("zh-CN")
	_finish()


func _check_top(tag: String, scroll) -> void:
	var screen := Rect2(Vector2.ZERO, main.size)
	var place: Label = scroll._place_label
	var clock: Label = main._regional_clock
	var pr := place.get_global_rect()
	check(screen.encloses(pr), tag + " place name on screen %s" % pr)
	check(place.get_minimum_size().x <= place.size.x + 0.5, tag + " place name '%s' fits its paper" % place.text)
	check(clock.visible and screen.encloses(clock.get_global_rect()), tag + " clock visible on screen")
	check(clock.get_minimum_size().x <= clock.size.x + 0.5, tag + " clock text fits")
	check(not pr.intersects(clock.get_global_rect()), tag + " clock sits apart from the place name")
	var buttons := [scroll._pause_button, scroll._return_button, scroll._look_button]
	for button: Button in buttons:
		if not button.visible: continue
		check(not pr.intersects(button.get_global_rect()), tag + " place name clear of '%s'" % button.text)
		check(not clock.get_global_rect().intersects(button.get_global_rect()), tag + " clock clear of '%s'" % button.text)
	if scroll._caption.visible:
		var cr: Rect2 = scroll._caption.get_global_rect()
		check(not cr.intersects(pr) and not cr.intersects(clock.get_global_rect()), tag + " look paper clear of place name and clock")
		check(screen.encloses(cr), tag + " look paper on screen %s" % cr)
		check(not cr.intersects(_basket_rect(scroll)), tag + " look paper clear of the basket and its name")
		for button: Button in [scroll._pause_button, scroll._return_button, scroll._pick_button, scroll._go_button]:
			if button.visible:
				check(not cr.intersects(button.get_global_rect()), tag + " look paper clear of '%s'" % button.text)


func _check_hint(tag: String, scroll, view: Vector2) -> void:
	var hint: Label = scroll._hint
	check(hint.visible, tag + " walk hint shows before the first step")
	var hr := hint.get_global_rect()
	check(Rect2(Vector2.ZERO, view).encloses(hr), tag + " walk hint on screen %s" % hr)
	check(hint.get_line_count() <= scroll.HINT_MAX_LINES, tag + " walk hint wraps to at most %d lines (%d)" % [scroll.HINT_MAX_LINES, hint.get_line_count()])
	var paper := hint.get_theme_stylebox("normal")
	var lines := hint.get_line_count()
	var text_h := lines * hint.get_line_height() + (lines - 1) * hint.get_theme_constant("line_spacing") + paper.get_margin(SIDE_TOP) + paper.get_margin(SIDE_BOTTOM)
	check(hint.size.y + 0.5 >= text_h, tag + " walk hint paper is tall enough for its lines")
	var font := hint.get_theme_font("font")
	var one_line: float = font.get_string_size(hint.text, HORIZONTAL_ALIGNMENT_LEFT, -1, hint.get_theme_font_size("font_size")).x
	check(lines > 1 or one_line + paper.get_margin(SIDE_LEFT) + paper.get_margin(SIDE_RIGHT) <= hint.size.x + 1.5, tag + " single-line hint is not cut off")
	check(not hr.intersects(_basket_rect(scroll)), tag + " walk hint clear of the basket and its name")


func _finish() -> void:
	if root.has_node("AudioDirector"):
		root.get_node("AudioDirector").release_streams()
	if failures.is_empty() and checks >= 100:
		print("[exploration-hud-readable] PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures: push_error(failure)
		print("[exploration-hud-readable] FAIL: %d of %d" % [failures.size(), checks])
		quit(1)


func _basket_rect(scroll) -> Rect2:
	var basket: Control = scroll._basket
	var backing: Rect2 = scroll.basket_label_rect(basket.get_theme_default_font(), scroll.basket_text(), scroll._basket_label_width)
	return Rect2(basket.global_position + Vector2(6, 22), Vector2(70, 36)).merge(Rect2(basket.global_position + backing.position, backing.size))
