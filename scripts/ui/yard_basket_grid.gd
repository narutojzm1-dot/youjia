extends Control
## REQ-20261007-064（#565 图8，Owner GROK-CONTRIBUTOR）：大背篓的标准行列格子。
## 每样东西一格（贴图 + 名字 + 数量），整行补齐空格；点有货的一格弹出这一格的操作纸片
## （拿一条 / 拿一束 / 拿一把 / 摆到院里 / 收回背篓），手机点按同样可用。
## 本切片只做格子与点按操作，发出与 yard_basket_panel 相同的 action_requested(action, kind)，
## 不读写存档、不改库存事务。拖出（面板半透明、合法摆放区着色）在下一切片接 Leader 的摆放接口。
const BasketPanel := preload("res://scripts/ui/yard_basket_panel.gd")
const KeepsakeArtScript := preload("res://scripts/exploration/keepsake_art.gd")
signal action_requested(action: String, kind: String)
signal menu_toggled(open: bool)

const ORDER := ["small", "medium", "odd", "grass", "millet", "round_stone", "pine_cone", "feather"]
const FISH := ["small", "medium", "odd"]
const KEEPSAKES := ["round_stone", "pine_cone", "feather"]
const FIND_IDS := {"round_stone": ExplorationRoutes.FIND_STONE, "pine_cone": ExplorationRoutes.FIND_PINE_CONE, "feather": ExplorationRoutes.FIND_FEATHER}
const ICONS := {
	"small": "res://assets/holiday/objects/ground_fish.png",
	"medium": "res://assets/holiday/objects/ground_fish.png",
	"odd": "res://assets/holiday/objects/ground_fish.png",
	"grass": "res://assets/holiday/fx/grass_bundle.png",
	"millet": "res://assets/holiday/objects/millet.png",
}
## 小鱼 / 中鱼共用一张鱼的原画，用格内占比区分大小，不改色、不变形
const ICON_SCALE := {"small": 0.62, "medium": 0.82}
## 一格最窄 MIN_CELL；放得下四格就排四列，否则三列（280 宽手机的纸内约 224px 也能排三列）
const MIN_CELL := 64.0
const MAX_COLUMNS := 4
const MIN_COLUMNS := 3
const GAP := 8
const NAME_SIZE := 14
const NAME_MIN_SIZE := 12
## 格子比宽多出 CELL_EXTRA 的高度，放上方数量角标（COUNT_ROW）与下方名字（NAME_ROW）
const CELL_EXTRA := 24.0
const COUNT_ROW := 24.0
const NAME_ROW := 22.0
const COUNT_SIZE := 15
const INK := Color("5b4637")
const EMPTY_INK := Color("7a6152")
const SLOT_FILL := Color("f7ecdc")
const SLOT_EDGE := Color("e2c9a6")

var grid: GridContainer
var cells: Dictionary = {}
var icons: Dictionary = {}
var name_labels: Dictionary = {}
var count_labels: Dictionary = {}
var blanks: Array[Panel] = []
var menu: PanelContainer
var menu_title: Label
var menu_note: Label
var menu_action: Button
var menu_close: Button
var selected := ""
var counts: Dictionary = {}
var _names: Dictionary = {}
var _held := ""
var _busy := false
var _loaded := false
var _menu_action_id := ""
var _layout_queued := false
## 外层（背篓纸面）给定的排版宽度；> 0 时按它排列，不跟着滚动条出现/消失来回变宽变窄。
## 否则格子变高 → 出滚动条 → 变窄 → 格子变矮 → 滚动条消失……会无限重排。
var layout_width := -1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	grid = GridContainer.new()
	grid.add_theme_constant_override("h_separation", GAP)
	grid.add_theme_constant_override("v_separation", GAP)
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(grid)
	for kind: String in ORDER:
		var cell := _cell(kind)
		grid.add_child(cell)
		cells[kind] = cell
	menu = PanelContainer.new()
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("fffaf1")
	paper.border_color = Color("b88a61")
	paper.set_border_width_all(2)
	paper.set_corner_radius_all(14)
	paper.set_content_margin_all(10)
	paper.shadow_color = Color(0.24, 0.17, 0.12, 0.18)
	paper.shadow_size = 4
	menu.add_theme_stylebox_override("panel", paper)
	menu.visible = false
	menu.top_level = true
	menu.z_index = 10
	add_child(menu)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	menu.add_child(column)
	menu_title = _label(17, INK)
	column.add_child(menu_title)
	menu_note = _label(14, EMPTY_INK)
	menu_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(menu_note)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	column.add_child(actions)
	menu_action = _menu_button()
	menu_action.pressed.connect(_on_menu_action)
	actions.add_child(menu_action)
	menu_close = _menu_button()
	menu_close.pressed.connect(close_menu)
	actions.add_child(menu_close)
	resized.connect(_queue_layout)
	_layout()

func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _menu_button() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(88, 44)
	button.add_theme_font_size_override("font_size", 16)
	for mode: String in BasketPanel.BUTTON_STATES:
		button.add_theme_stylebox_override(mode, BasketPanel.state_style(mode))
		button.add_theme_color_override("font_" + ("" if mode == "normal" else mode + "_") + "color", BasketPanel.BUTTON_STATES[mode].ink)
	# 打开纸片时焦点落在动作按钮上：字保持墨色，焦点只加一圈褐边（与背篓按钮相同），不变成引擎白字灰底
	button.add_theme_color_override("font_focus_color", BasketPanel.BUTTON_STATES.normal.ink)
	button.add_theme_stylebox_override("focus", _focus_box())
	return button

static func _focus_box() -> StyleBoxFlat:
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = Color("916d49")
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(12)
	return focus

func _cell(kind: String) -> Button:
	var cell := Button.new()
	cell.toggle_mode = true
	cell.focus_mode = Control.FOCUS_ALL
	cell.clip_contents = true
	for mode: String in BasketPanel.BUTTON_STATES:
		cell.add_theme_stylebox_override(mode, BasketPanel.state_style(mode))
	cell.add_theme_stylebox_override("focus", _focus_box())
	# 选中的格子在纸片打开期间保持按下杏纸 + 墨边，一眼知道纸片说的是哪一格
	cell.toggled.connect(func(on: bool) -> void:
		if on and selected != kind: open_menu(kind)
		elif not on and selected == kind: close_menu())
	var icon := TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = _icon_texture(kind)
	cell.add_child(icon)
	icons[kind] = icon
	var name_label := _label(NAME_SIZE, INK)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	cell.add_child(name_label)
	name_labels[kind] = name_label
	var count_label := _label(COUNT_SIZE, INK)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cell.add_child(count_label)
	count_labels[kind] = count_label
	return cell

static func _icon_texture(kind: String) -> Texture2D:
	if kind in KEEPSAKES:
		return KeepsakeArtScript.texture(FIND_IDS[kind])
	var path: String = ICONS.get(kind, "")
	return load(path) if not path.is_empty() and ResourceLoader.exists(path) else null

func columns_for(width: float) -> int:
	var fit := int(floor((width + GAP) / (MIN_CELL + GAP)))
	return clampi(fit, MIN_COLUMNS, MAX_COLUMNS)

func cell_side(width: float) -> float:
	var cols := columns_for(width)
	return floorf((width - GAP * (cols - 1)) / cols)

func _queue_layout() -> void:
	if _layout_queued: return
	_layout_queued = true
	call_deferred("_run_layout")

func _run_layout() -> void:
	_layout_queued = false
	_layout()

func set_layout_width(width: float) -> void:
	if is_equal_approx(width, layout_width): return
	layout_width = width
	_queue_layout()

func _layout() -> void:
	if grid == null: return
	var width := layout_width if layout_width > 0.0 else size.x
	var cols := columns_for(width)
	var side := cell_side(width)
	grid.columns = cols
	# 整行补齐：最后一行空着的位置画成浅色空格，看得出是一张格子而不是一串按钮
	var need := (cols - ORDER.size() % cols) % cols
	while blanks.size() < need:
		var blank := Panel.new()
		var slot := StyleBoxFlat.new()
		slot.bg_color = SLOT_FILL
		slot.border_color = SLOT_EDGE
		slot.set_border_width_all(1)
		slot.set_corner_radius_all(12)
		blank.add_theme_stylebox_override("panel", slot)
		blank.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.add_child(blank)
		blanks.append(blank)
	while blanks.size() > need:
		blanks.pop_back().free()
	var cell_size := Vector2(side, side + CELL_EXTRA)
	for kind: String in ORDER:
		var cell: Button = cells[kind]
		cell.custom_minimum_size = cell_size
		# 上：数量角标；中：贴图；下：名字。三层互不重叠
		var icon_box := Rect2(Vector2(8, COUNT_ROW), Vector2(side - 16, cell_size.y - COUNT_ROW - NAME_ROW))
		var s: float = ICON_SCALE.get(kind, 1.0)
		var shrunk := icon_box.size * s
		icons[kind].position = icon_box.position + (icon_box.size - shrunk) * 0.5
		icons[kind].size = shrunk
		name_labels[kind].position = Vector2(4, cell_size.y - NAME_ROW)
		name_labels[kind].size = Vector2(side - 8, NAME_ROW)
		count_labels[kind].position = Vector2(side * 0.4, 0)
		count_labels[kind].size = Vector2(side * 0.6 - 6, COUNT_ROW)
	for blank: Panel in blanks:
		blank.custom_minimum_size = cell_size
	grid.size = Vector2(side * cols + GAP * (cols - 1), 0)
	grid.position = Vector2(maxf(0.0, (size.x - grid.size.x) * 0.5), 0)
	custom_minimum_size.y = rows_for(cols) * cell_size.y + (rows_for(cols) - 1) * GAP
	_fit_names()
	if menu.visible: _place_menu()

func rows_for(cols: int) -> int:
	return int(ceil(float(ORDER.size()) / cols))

func update_view(inventory: Dictionary, keepsakes: Dictionary, state: String, busy: bool) -> void:
	var en := I18n.get_locale() == "en"
	_names = {"small": "Small fish" if en else "小鱼", "medium": "Fish" if en else "中鱼", "odd": "Curious fish" if en else "奇怪的鱼", "grass": "Grass" if en else "草束", "millet": "Millet" if en else "小米", "round_stone": "Round stone" if en else "圆石", "pine_cone": "Pine cone" if en else "松果", "feather": "Feather" if en else "落羽"}
	# 格内只放得下短名；完整名字在弹出的纸片标题和悬停提示里
	var short := _names.duplicate()
	if en: short.merge({"small": "Small", "odd": "Odd fish", "round_stone": "Stone", "pine_cone": "Cone"}, true)
	_held = str(inventory.get("held", ""))
	_busy = busy or state in ["saving", "unknown", "failed", "blocked"]
	_loaded = not inventory.is_empty()
	for kind: String in ORDER:
		var count := 0
		if kind in FISH: count = int(inventory.get("fish", {}).get(kind, 0))
		elif kind in KEEPSAKES: count = int(keepsakes.get(FIND_IDS[kind], 0))
		else: count = int(inventory.get(kind, 0))
		counts[kind] = count
		var owned := count > 0 or kind == _held
		name_labels[kind].text = short[kind]
		count_labels[kind].text = "×%d" % count
		var ink := INK if owned else EMPTY_INK
		name_labels[kind].add_theme_color_override("font_color", ink)
		count_labels[kind].add_theme_color_override("font_color", ink)
		icons[kind].modulate = Color(1, 1, 1, 1.0 if owned else 0.32)
		var cell: Button = cells[kind]
		cell.disabled = not owned
		cell.tooltip_text = "%s ×%d" % [_names[kind], count]
	_fit_names()
	if not selected.is_empty():
		if cells[selected].disabled: close_menu()
		else: _fill_menu(selected)

## 名字放不下时字号最多收到 NAME_MIN_SIZE，不折行、不撑大格子
func _fit_names() -> void:
	for kind: String in ORDER:
		var label: Label = name_labels[kind]
		var font := label.get_theme_font("font")
		var font_size := NAME_SIZE
		while font_size > NAME_MIN_SIZE and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > label.size.x:
			font_size -= 1
		# 字号没变就不重设：每次重设都会触发一轮最小尺寸重算
		if not label.has_theme_font_size_override("font_size") or label.get_theme_font_size("font_size") != font_size:
			label.add_theme_font_size_override("font_size", font_size)

## 这一格现在能做什么：[动作 id, 按钮文字, 不能做时的原因]
func action_for(kind: String) -> Array:
	var en := I18n.get_locale() == "en"
	if kind == _held and not _held.is_empty():
		return ["return", "Put it back" if en else "收回背篓", "" if not _busy else _busy_note(en)]
	var label := ""
	var action := "withdraw"
	if kind in KEEPSAKES:
		action = "decor"
		label = "Place in yard" if en else "摆到院里"
	elif kind == "millet": label = "Take a scoop" if en else "拿一把"
	elif kind == "grass": label = "Take a bundle" if en else "拿一束"
	else: label = "Take one" if en else "拿一条"
	var reason := ""
	if not _loaded or _busy: reason = _busy_note(en)
	elif counts.get(kind, 0) <= 0: reason = "None in the basket." if en else "背篓里还没有。"
	elif action == "withdraw" and not _held.is_empty():
		reason = ("Put back the %s first." % _names.get(_held, _held).to_lower()) if en else ("先把手里的%s收回背篓。" % _names.get(_held, _held))
	return [action, label, reason]

func _busy_note(en: bool) -> String:
	return "Checking the save…" if en else "正在确认保存，先等一下。"

func open_menu(kind: String) -> void:
	if not cells.has(kind) or cells[kind].disabled: return
	if not selected.is_empty() and selected != kind:
		cells[selected].set_pressed_no_signal(false)
	selected = kind
	cells[kind].set_pressed_no_signal(true)
	_fill_menu(kind)
	menu.visible = true
	_place_menu()
	menu_toggled.emit(true)
	if menu_action.disabled: menu_close.grab_focus()
	else: menu_action.grab_focus()

func close_menu() -> void:
	var was_open := menu.visible
	if not selected.is_empty() and cells.has(selected):
		cells[selected].set_pressed_no_signal(false)
	selected = ""
	menu.visible = false
	if was_open: menu_toggled.emit(false)

func _fill_menu(kind: String) -> void:
	var en := I18n.get_locale() == "en"
	var spec := action_for(kind)
	_menu_action_id = spec[0]
	menu_title.text = "%s  ×%d" % [_names.get(kind, kind), counts.get(kind, 0)]
	menu_action.text = spec[1]
	menu_action.disabled = not str(spec[2]).is_empty()
	menu_note.text = spec[2]
	menu_note.visible = not str(spec[2]).is_empty()
	menu_close.text = "Never mind" if en else "算了"
	menu.reset_size()

func _place_menu() -> void:
	if selected.is_empty(): return
	menu.reset_size()
	var view := get_viewport_rect()
	var cell_rect: Rect2 = cells[selected].get_global_rect()
	var width := minf(maxf(menu.get_combined_minimum_size().x, 200.0), view.size.x - 16.0)
	menu.size = Vector2(width, 0)
	menu.reset_size()
	menu.size.x = width
	var h := menu.size.y
	var y := cell_rect.end.y + 6.0
	if y + h > view.size.y - 8.0: y = cell_rect.position.y - h - 6.0
	y = clampf(y, 8.0, maxf(8.0, view.size.y - h - 8.0))
	var x := clampf(cell_rect.get_center().x - width * 0.5, 8.0, maxf(8.0, view.size.x - width - 8.0))
	menu.global_position = Vector2(x, y)

func _on_menu_action() -> void:
	if selected.is_empty() or menu_action.disabled: return
	var kind := selected
	var action := _menu_action_id
	close_menu()
	action_requested.emit(action, kind)

## 触屏 / 外层统一点按入口：返回 true 表示这一下被格子或纸片接住了
func press_at(at: Vector2) -> bool:
	if menu.visible:
		for button: Button in [menu_action, menu_close]:
			if button.is_visible_in_tree() and button.get_global_rect().has_point(at):
				if not button.disabled: button.pressed.emit()
				return true
		if menu.get_global_rect().has_point(at): return true
	for kind: String in ORDER:
		var cell: Button = cells[kind]
		if cell.get_global_rect().has_point(at):
			if cell.disabled:
				close_menu()
				return true
			if selected == kind: close_menu()
			else: open_menu(kind)
			return true
	if menu.visible:
		close_menu()
		return true
	return false

func _unhandled_key_input(event: InputEvent) -> void:
	if menu.visible and event.is_action_pressed("ui_cancel"):
		close_menu()
		get_viewport().set_input_as_handled()
