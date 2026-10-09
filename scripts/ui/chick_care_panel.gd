extends Control
signal close_requested
var paper: PanelContainer
var scroll: ScrollContainer
var column: VBoxContainer
var title: Label
var portrait: TextureRect
var progress: ProgressBar
var note: Label
var close_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.1, 0.08, 0.06, 0.35)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	paper = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fff7e8")
	style.border_color = Color("cfab79")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(20)
	paper.add_theme_stylebox_override("panel", style)
	add_child(paper)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	paper.add_child(scroll)
	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	scroll.add_child(column)
	title = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color("5b4637"))
	column.add_child(title)
	portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(0, 120)
	column.add_child(portrait)
	progress = ProgressBar.new()
	progress.custom_minimum_size.y = 24
	var background := StyleBoxFlat.new()
	background.bg_color = Color("e8dac6")
	background.set_corner_radius_all(8)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("a9bb86")
	fill.set_corner_radius_all(8)
	progress.add_theme_stylebox_override("background", background)
	progress.add_theme_stylebox_override("fill", fill)
	progress.add_theme_color_override("font_color", Color("5b4637"))
	progress.add_theme_font_size_override("font_size", 16)
	column.add_child(progress)
	note = Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", Color("5b4637"))
	column.add_child(note)
	close_button = Button.new()
	close_button.custom_minimum_size.y = 46
	close_button.add_theme_font_size_override("font_size", 17)
	for mode: String in preload("res://scripts/ui/yard_basket_panel.gd").BUTTON_STATES:
		close_button.add_theme_stylebox_override(mode, preload("res://scripts/ui/yard_basket_panel.gd").state_style(mode))
		close_button.add_theme_color_override("font_" + ("" if mode == "normal" else mode + "_") + "color", Color("5b4637"))
	column.add_child(close_button)
	close_button.pressed.connect(func() -> void: close_requested.emit())
	resized.connect(_fit)
	SaveStore.commit_confirmed.connect(func(_id: String, _kind: String) -> void:
		if visible: refresh())

func open() -> void:
	visible = true
	scroll.scroll_vertical = 0
	refresh()

func refresh() -> void:
	var value: Dictionary = SaveStore.get_chick_growth()
	var en := I18n.get_locale() == "en"
	var grown: bool = value.get("stage", "") == "hen"
	title.text = ("A grown hen" if grown else "The little chick") if en else ("已经长大的鸡" if grown else "慢慢长大的小鸡")
	portrait.texture = load("res://assets/holiday/characters/chicken/%s.png" % ("hen" if grown else "chick"))
	progress.value = 100.0 if grown else maxf(0.0, float(value.get("age_seconds", 0.0))) / 18.0
	var remaining := maxf(0.0, (1800.0 - float(value.get("age_seconds", 0.0))) / 600.0)
	var bonus := float(value.get("bonus_seconds", 0)) / 600.0
	if en:
		note.text = ("All grown up. It still enjoys finding grain around the yard." if grown else "Chick stage · About %.1f game days to grow.\nFeeding has helped by %.1f game days." % [remaining, bonus]) + "\n\nGrowing normally takes 3 game days. No feeding is required; it will not starve.\nDrop millet, wheat or corn nearby from the basket. A portion it actually eats helps by half a day, up to 2 days in total."
		close_button.text = "Back to the yard"
	else:
		note.text = ("已经长大，还是喜欢在院里寻找谷粒。" if grown else "小鸡阶段 · 再过约 %.1f 个游戏天长大\n投喂已帮助它提前 %.1f 个游戏天" % [remaining, bonus]) + "\n\n不投喂也会长大，不会饿死。\n正常成长需要3个游戏天。\n\n背篓里的谷粒可以丢在它附近。\n吃到一份提前半天，累计最多提前2天。"
		close_button.text = "回到院子"
	_fit.call_deferred()

func _fit() -> void:
	if paper == null: return
	var width := minf(420.0, maxf(240.0, size.x - 32.0))
	note.custom_minimum_size.x = width - 64.0
	scroll.custom_minimum_size = Vector2(width - 40.0, minf(maxf(160.0, size.y - 72.0), column.get_combined_minimum_size().y))
	paper.size = Vector2(width, scroll.custom_minimum_size.y + 40.0)
	paper.position = (size - paper.size) * 0.5
