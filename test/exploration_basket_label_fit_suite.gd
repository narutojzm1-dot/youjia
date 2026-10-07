extends SceneTree
# REQ-20261007-050：近郊提篮名称（中英、所有可带组合、宽窄视口）整行读得全、留在底板和屏内；
# 放得下的 15px 一行完全不变。只读 NearPathScroll 的排版结果，不改会话、存档或输入。

const MemoryStore := preload("res://test/fixtures/exploration_memory_store.gd")
const CLOCK := {"day": 3, "elapsed": 12.5}
const VIEWS := [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(640, 300), Vector2i(568, 320), Vector2i(390, 844), Vector2i(360, 640), Vector2i(320, 568), Vector2i(300, 560), Vector2i(280, 653)]

var failures: Array[String] = []
var checks := 0
var stores: Array[Node] = []
var i18n: Node
var Scroll: GDScript
var Director: GDScript


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


## 篮子里可能出现的全部文字：空篮 + 1–3 件（按拾取顺序，重复的合成 ×N）
func basket_texts() -> PackedStringArray:
	var out := PackedStringArray([i18n.t("exploration.basket.empty")])
	var finds: Array = ExplorationRoutes.FINDS
	var seqs: Array = [[]]
	for depth in 3:
		var next: Array = []
		for seq: Array in seqs:
			for find_id: String in finds:
				next.append(seq + [find_id])
		seqs = next
		for seq: Array in seqs:
			var text: String = Director.items_text(PackedStringArray(seq))
			if not out.has(text):
				out.append(text)
	return out


func run() -> void:
	i18n = root.get_node("I18n")
	Scroll = load("res://scripts/exploration/near_path_scroll.gd")
	Director = load("res://scripts/exploration/exploration_director.gd")
	var before_locale: String = i18n.get_locale()
	for locale: String in ["zh-CN", "en"]:
		i18n.set_locale(locale)
		for view_size: Vector2i in VIEWS:
			await _view(locale, view_size)
	i18n.set_locale(before_locale)
	_helpers()
	for store in stores:
		store.free()
	print("[exploration-basket-label-fit] ", "PASS: %d checks" % checks if failures.is_empty() else "FAIL: %d/%d %s" % [failures.size(), checks, failures])
	quit(0 if failures.is_empty() else 1)


func _view(locale: String, view_size: Vector2i) -> void:
	root.size = view_size
	var store := MemoryStore.new()
	stores.append(store)
	var host := ExplorationHost.new(store)
	host.restore()
	host.begin(CLOCK, 1)
	var scroll: Node2D = Scroll.new()
	root.add_child(scroll)
	scroll.setup(host, "sunny")
	await process_frame
	await process_frame
	var font: Font = scroll._basket.get_theme_default_font()
	var screen := Rect2(Vector2.ZERO, Vector2(view_size))
	var width: float = scroll._basket_label_width
	for text: String in basket_texts():
		var tag := "[%s %dx%d] %s: " % [locale, view_size.x, view_size.y, text]
		var fit: Dictionary = Scroll.basket_label_fit(font, text, width)
		var size: int = fit.font_size
		var full_15 := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		check(size >= Scroll.BASKET_LABEL_MIN_FONT_SIZE and size <= 15, tag + "font size stays 13–15px")
		check(int(fit.lines) >= 1 and int(fit.lines) <= Scroll.BASKET_LABEL_MAX_LINES, tag + "at most two lines")
		if full_15 <= width:
			check(size == 15 and int(fit.lines) == 1 and fit.baseline == Scroll.BASKET_LABEL_AT, tag + "a name that fits keeps 15px on the original line")
		# 整段文字都画得出来：一行时不截字；折行时每个词都排进两行内
		var drawn_w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x if int(fit.lines) == 1 else font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, size).x
		var all_lines_h := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width if int(fit.lines) > 1 else -1.0, size).y
		check(drawn_w <= width + 0.5, tag + "the whole name fits the label width (no trailing letters cut off)")
		check(all_lines_h <= font.get_height(size) * int(fit.lines) + 0.5, tag + "no words fall past the drawn lines")
		var backing: Rect2 = Scroll.basket_label_rect(font, text, width)
		var ink := Rect2(Vector2(fit.baseline) + Vector2(0, -font.get_ascent(size)), Vector2(drawn_w, all_lines_h))
		check(backing.encloses(ink), tag + "the backing paper covers every line")
		var global_backing := Rect2(scroll._basket.global_position + backing.position, backing.size)
		check(screen.encloses(global_backing), tag + "the backing paper stays on screen")
		check(global_backing.end.x <= view_size.x - 13.5, tag + "the backing leaves the side margin")
		check(backing.end.y <= scroll._basket.size.y + 6.0, tag + "the label still sits on the basket row (grows upward, not down onto buttons)")
	# 当前篮子名称（空篮）按真实绘制路径也走同一排法
	var live: Dictionary = Scroll.basket_label_fit(font, scroll.basket_text(), width)
	check(int(live.font_size) == 15, "[%s %dx%d] the empty basket keeps 15px" % [locale, view_size.x, view_size.y])
	scroll.free()


func _helpers() -> void:
	check(is_equal_approx(Scroll.basket_label_width_for(1280, 20, 20), Scroll.BASKET_LABEL_WIDTH), "wide screens keep the 200px label width")
	check(is_equal_approx(Scroll.basket_label_width_for(280, 14, 14), 280 - 14 - 14 - 90), "280px portrait narrows the label to stay inside the right margin")
	check(is_equal_approx(Scroll.basket_label_width_for(100, 14, 14), Scroll.BASKET_LABEL_MIN_WIDTH), "label width never collapses below the floor")
