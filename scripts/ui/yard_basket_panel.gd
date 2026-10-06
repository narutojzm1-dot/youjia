extends Control
signal close_requested
signal action_requested(action: String, fish: String)
signal retry_requested

var panel: PanelContainer
var rows: VBoxContainer
var scroll: ScrollContainer
var title: Label
var status: Label
var close_button: Button
var retry_button: Button
var return_button: Button
var held_label: Label
var fish_labels: Dictionary = {}
var fish_buttons: Dictionary = {}
var keepsake_labels: Dictionary = {}
var _touch_index := -1
var _touch_start := Vector2.ZERO
var _touch_scrolled := false
const FISH := ["small", "medium", "odd", "grass"]
## 背篓里的按钮原来悬停、按下、禁用三态共用同一块 #eadcc8 底和同一条 #b88a61 边，
## 禁用只把字调浅到 #7a6152（约 4.25:1）。空背篓、手里已拿着东西或正在确认保存时，
## 一排「拿一条 / 拿一束 / 收回背篓」看上去像全被按着，又比可点的字更难读。
## 禁用态改用与 Main._soft_button 相同的淡暖纸底 + 1px 浅棕边（REQ-20261006-038），
## 字对底约 4.78:1；可点、悬停、按下、焦点样式和尺寸、文案、何时禁用都不变（REQ-20261007-049）。
const BUTTON_ACTIVE_FILL := Color("eadcc8")
const BUTTON_EDGE := Color("b88a61")
const BUTTON_DISABLED_FILL := Color("f3e9db")
const BUTTON_DISABLED_EDGE := Color("bfa588")
const BUTTON_DISABLED_TEXT := Color("7a6152")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.2, 0.15, 0.1, 0.35)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	panel = PanelContainer.new()
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("fff6e8")
	paper.border_color = Color("d6ae78")
	paper.set_border_width_all(2)
	paper.set_corner_radius_all(20)
	paper.content_margin_left = 16
	paper.content_margin_right = 16
	paper.content_margin_top = 12
	paper.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", paper)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	title = _label(24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 6)
	scroll.add_child(rows)
	for kind: String in ["round_stone", "pine_cone", "feather"]:
		var label := _label(18)
		rows.add_child(label)
		keepsake_labels[kind] = label
	for kind: String in FISH:
		var row := HBoxContainer.new()
		rows.add_child(row)
		var label := _label(18)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		fish_labels[kind] = label
		var button := _button()
		button.pressed.connect(func() -> void: action_requested.emit("withdraw", kind))
		row.add_child(button)
		fish_buttons[kind] = button
	held_label = _label(16)
	rows.add_child(held_label)
	return_button = _button()
	rows.add_child(return_button)
	status = _label(15)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	retry_button = _button()
	retry_button.pressed.connect(func() -> void: retry_requested.emit())
	column.add_child(retry_button)
	close_button = _button()
	close_button.pressed.connect(func() -> void: close_requested.emit())
	column.add_child(close_button)
	resized.connect(fit)
	fit()

func _label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_color_override("font_color", Color("5b4637"))
	label.add_theme_font_size_override("font_size", font_size)
	return label

func _button() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(104, 44)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("5b4637"))
	button.add_theme_color_override("font_hover_color", Color("3d2d23"))
	button.add_theme_color_override("font_pressed_color", Color("3d2d23"))
	button.add_theme_color_override("font_focus_color", Color("5b4637"))
	button.add_theme_color_override("font_disabled_color", BUTTON_DISABLED_TEXT)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = Color("916d49")
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(12)
	button.add_theme_stylebox_override("focus", focus)
	for mode: String in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("fffaf1") if mode == "normal" else BUTTON_ACTIVE_FILL
		style.border_color = BUTTON_EDGE
		if mode == "disabled":
			style.bg_color = BUTTON_DISABLED_FILL
			style.border_color = BUTTON_DISABLED_EDGE
		style.set_border_width_all(1)
		style.set_corner_radius_all(12)
		button.add_theme_stylebox_override(mode, style)
	return button

func fit() -> void:
	if panel == null: return
	panel.size = Vector2(minf(520, size.x - 24), minf(620, size.y - 24))
	panel.position = (size - panel.size) * 0.5

func update_view(inventory: Dictionary, keepsakes: Dictionary, state: String, busy: bool) -> void:
	var en := I18n.get_locale() == "en"
	title.text = "The big basket" if en else "院里的大背篓"
	var names := {"grass": "Grass" if en else "草束", "round_stone": "Round stone" if en else "圆石", "pine_cone": "Pine cone" if en else "松果", "feather": "Feather" if en else "落羽", "small": "Small fish" if en else "小鱼", "medium": "Fish" if en else "中鱼", "odd": "Curious fish" if en else "奇怪的鱼"}
	var find_ids := {"round_stone": ExplorationRoutes.FIND_STONE, "pine_cone": ExplorationRoutes.FIND_PINE_CONE, "feather": ExplorationRoutes.FIND_FEATHER}
	for kind: String in keepsake_labels:
		keepsake_labels[kind].text = "%s  × %d" % [names[kind], int(keepsakes.get(find_ids[kind], 0))]
	var held := str(inventory.get("held", ""))
	for kind: String in FISH:
		var count := int(inventory.get("grass", 0)) if kind == "grass" else int(inventory.get("fish", {}).get(kind, 0))
		fish_labels[kind].text = "%s  × %d" % [names[kind], count]
		fish_buttons[kind].text = "Take one" if en else ("拿一束" if kind == "grass" else "拿一条")
		fish_buttons[kind].disabled = inventory.is_empty() or busy or not held.is_empty() or count == 0
	held_label.text = ("In hand: " if en else "手里拿着：") + str(names.get(held, "Nothing" if en else "空着"))
	return_button.text = "Put it back" if en else "收回背篓"
	return_button.disabled = busy or held.is_empty()
	for connection: Dictionary in return_button.pressed.get_connections():
		return_button.pressed.disconnect(connection.callable)
	return_button.pressed.connect(func() -> void: action_requested.emit("return", held))
	status.text = "Caught fish and finds stay here." if en else "钓到的鱼、散步带回的小物，都收在这里。"
	if state in ["saving", "unknown"]:
		status.text = "Checking the save…" if en else "正在确认保存，东西还不能取用……"
	elif state in ["failed", "blocked"] or inventory.is_empty():
		status.text = "Not saved yet. Your stored items are kept." if en else "这次还没存好，原有物品保留着。"
	retry_button.visible = state in ["failed", "unknown"]
	retry_button.text = "Check again" if en else "再确认一次"
	close_button.text = "Back to the yard" if en else "合上背篓"
	call_deferred("fit")

func handle_touch_event(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _touch_index != -1: return
			_touch_index = event.index
			_touch_start = event.position
			_touch_scrolled = false
		elif event.index == _touch_index:
			_touch_index = -1
			if not _touch_scrolled and event.position.distance_to(_touch_start) < 12.0:
				_activate_touch(event.position)
	elif event is InputEventScreenDrag and event.index == _touch_index:
		if event.position.distance_to(_touch_start) >= 12.0: _touch_scrolled = true
		if _touch_scrolled and scroll.get_global_rect().has_point(_touch_start):
			scroll.scroll_vertical -= int(event.relative.y)

func _activate_touch(position_in_view: Vector2) -> void:
	var buttons: Array = [close_button, retry_button, return_button]
	buttons.append_array(fish_buttons.values())
	for button: Button in buttons:
		if button.is_visible_in_tree() and not button.disabled and button.get_global_rect().has_point(position_in_view):
			if button in fish_buttons.values() or button == return_button:
				if not scroll.get_global_rect().has_point(position_in_view): continue
			button.pressed.emit()
			return
