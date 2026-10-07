extends Control
const PaperScrollbarStyle := preload("res://scripts/ui/paper_scrollbar_style.gd")
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
var scoop_button: Button
var decor_button: Button
## REQ-20261007-064（#565 图8，Owner GROK-CONTRIBUTOR）：玩家看到的是一张行列格子（yard_basket_grid.gd），
## 每样东西一格、点格子弹操作。原来逐行的「名字 × N + 拿一条」清单节点仍保留（fish_buttons /
## fish_labels / keepsake_labels 及其信号给旧接口与旧测试用），但不再显示，避免同一样东西出现两遍。
var grid: Control
var list_rows: Array[Control] = []
## 院内布置面板（Main 在同一层建的兄弟节点）。Main 可直接赋值；未赋值时在同层按脚本找一次。
var decor_panel: Control
const DECOR_PANEL_SCRIPT := "res://scripts/ui/yard_decor_panel.gd"
const DECOR_SPOTS_SCRIPT := "res://scripts/inventory/yard_decor.gd"
var fish_labels: Dictionary = {}
var fish_buttons: Dictionary = {}
var keepsake_labels: Dictionary = {}
var _touch_index := -1
var _touch_start := Vector2.ZERO
var _touch_scrolled := false
var column: VBoxContainer
var compact := false
var _status_is_note := true
var _fit_queued := false
const FISH := ["small", "medium", "odd", "grass", "millet"]
## REQ-20261007-051：纸面始终离屏幕边至少 EDGE；纸面不高于 COMPACT_HEIGHT（矮横屏）时
## 标题收小、间距收紧、只省掉那句说明，让清单多露出几行。保存/失败提示照常显示。
const EDGE := 12.0
const COMPACT_HEIGHT := 420.0
const TITLE_SIZE := 24
const COMPACT_TITLE_SIZE := 19
const COLUMN_GAP := 8
const COMPACT_COLUMN_GAP := 4
const ROW_GAP := 6
const COMPACT_ROW_GAP := 3
## 纸面窄于 NARROW_WIDTH（屏宽约 304 以下的手机）时，每行「拿一条」按钮从 104 收到 88px，
## 字仍放得下、高度仍 44px，名字多出 16px，中文不用折行
const NARROW_WIDTH := 280.0
const ROW_BUTTON_WIDTH := 104.0
const NARROW_ROW_BUTTON_WIDTH := 88.0
## REQ-20261007-056：悬停、按下和不可用原先共用同一块 eadcc8 浅褐底和同一条边，
## 「小米 × 0」旁点不了的「拿一把」和鼠标停着的按钮长得一样。与院内布置面板（#531）同一套：
## 悬停暖杏、按下（含按住时悬停，原先掉回引擎灰底）杏色加 2px 墨边、不可用浅纸淡边，字色不变。
const BUTTON_STATES := {
	"normal": {"fill": Color("fffaf1"), "edge": Color("b88a61"), "width": 1, "ink": Color("5b4637")},
	"hover": {"fill": Color("ffe7c8"), "edge": Color("b88a61"), "width": 1, "ink": Color("3d2d23")},
	"pressed": {"fill": Color("f3d3ae"), "edge": Color("5b4637"), "width": 2, "ink": Color("3d2d23")},
	"hover_pressed": {"fill": Color("f3d3ae"), "edge": Color("5b4637"), "width": 2, "ink": Color("3d2d23")},
	"disabled": {"fill": Color("f3e9db"), "edge": Color("bfa588"), "width": 1, "ink": Color("7a6152")},
}
## REQ-20261007-061：数量为 0 的行（「小米  × 0」「松果  × 0」）原先和有货的行同一深墨 5b4637，
## 一眼分不出背篓里到底有什么。0 的名字改用与旁边灰掉按钮同色的 7a6152（纸上 5.36:1，仍达 AA），
## 有货的行保持 5b4637；字号、折行、排版都不变。
const ROW_INK := Color("5b4637")
const EMPTY_ROW_INK := Color("7a6152")

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
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", COLUMN_GAP)
	panel.add_child(column)
	title = _label(TITLE_SIZE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	# REQ-20261007-058：清单滚动条换成纸面浅槽 + 褐色滑块，不再是一条默认深灰条
	PaperScrollbarStyle.apply(scroll.get_v_scroll_bar())
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", ROW_GAP)
	scroll.add_child(rows)
	# 运行时 load：格子脚本 preload 了本脚本的按钮样式，这里不能再反向 preload
	grid = load("res://scripts/ui/yard_basket_grid.gd").new()
	grid.name = "BasketGrid"
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_child(grid)
	grid.action_requested.connect(_on_grid_action)
	# 清单滚动后格子位置变了，操作纸片不再贴着那一格，先收起
	scroll.get_v_scroll_bar().value_changed.connect(func(_value: float) -> void: grid.close_menu())
	visibility_changed.connect(func() -> void:
		if not visible: grid.close_menu())
	for kind: String in ["round_stone", "pine_cone", "feather"]:
		var label := _label(18)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rows.add_child(label)
		keepsake_labels[kind] = label
		label.visible = false
		list_rows.append(label)
	for kind: String in FISH:
		var row := HBoxContainer.new()
		rows.add_child(row)
		row.visible = false
		list_rows.append(row)
		var label := _label(18)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# 名字放不下就在名字内折行，不再把整张纸撑出屏幕边
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(label)
		fish_labels[kind] = label
		var button := _button()
		button.pressed.connect(func() -> void: action_requested.emit("withdraw", kind))
		row.add_child(button)
		fish_buttons[kind] = button
	held_label = _label(16)
	held_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(held_label)
	scoop_button = _button()
	scoop_button.pressed.connect(func() -> void: action_requested.emit("scoop", "millet"))
	rows.add_child(scoop_button)
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
	# 说明句显隐或折行变化后，隐藏期间的旧最小高度会把纸面撑高；下一帧按新内容再排一次
	panel.minimum_size_changed.connect(_queue_fit)
	_set_compact(false, true)
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
	for mode: String in BUTTON_STATES:
		button.add_theme_stylebox_override(mode, state_style(mode))
		button.add_theme_color_override("font_" + ("" if mode == "normal" else mode + "_") + "color", BUTTON_STATES[mode].ink)
	button.add_theme_color_override("font_focus_color", BUTTON_STATES.normal.ink)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = Color("916d49")
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(12)
	button.add_theme_stylebox_override("focus", focus)
	return button

static func state_style(mode: String) -> StyleBoxFlat:
	var spec: Dictionary = BUTTON_STATES[mode]
	var style := StyleBoxFlat.new()
	style.bg_color = spec.fill
	style.border_color = spec.edge
	style.set_border_width_all(int(spec.width))
	style.set_corner_radius_all(12)
	# 各状态内容边距一致，按下时 2px 墨边不会让按钮或整行变大
	style.set_content_margin_all(1)
	return style

func fit() -> void:
	if panel == null: return
	var target := Vector2(minf(520, size.x - EDGE * 2.0), minf(620, size.y - EDGE * 2.0))
	_set_compact(target.y <= COMPACT_HEIGHT)
	var row_width := NARROW_ROW_BUTTON_WIDTH if target.x < NARROW_WIDTH else ROW_BUTTON_WIDTH
	for button: Button in fish_buttons.values():
		button.custom_minimum_size.x = row_width
	panel.size = target
	panel.position = (size - panel.size) * 0.5
	# 格子按「纸内宽 − 滚动条宽」排，不论滚动条此刻显不显示，格子尺寸都不变
	if grid != null:
		var bar := scroll.get_v_scroll_bar().get_combined_minimum_size().x
		grid.set_layout_width(maxf(0.0, target.x - 32.0 - bar))

func _queue_fit() -> void:
	if _fit_queued: return
	_fit_queued = true
	call_deferred("_run_queued_fit")

func _run_queued_fit() -> void:
	_fit_queued = false
	fit()

func _set_compact(on: bool, force: bool = false) -> void:
	if on != compact or force:
		compact = on
		title.add_theme_font_size_override("font_size", COMPACT_TITLE_SIZE if on else TITLE_SIZE)
		column.add_theme_constant_override("separation", COMPACT_COLUMN_GAP if on else COLUMN_GAP)
		rows.add_theme_constant_override("separation", COMPACT_ROW_GAP if on else ROW_GAP)
	var show_status := not (on and _status_is_note)
	if status.visible != show_status:
		status.visible = show_status

func update_view(inventory: Dictionary, keepsakes: Dictionary, state: String, busy: bool) -> void:
	var en := I18n.get_locale() == "en"
	title.text = "The big basket" if en else "院里的大背篓"
	var names := {"grass": "Grass" if en else "草束", "round_stone": "Round stone" if en else "圆石", "pine_cone": "Pine cone" if en else "松果", "feather": "Feather" if en else "落羽", "small": "Small fish" if en else "小鱼", "medium": "Fish" if en else "中鱼", "odd": "Curious fish" if en else "奇怪的鱼"}
	var find_ids := {"round_stone": ExplorationRoutes.FIND_STONE, "pine_cone": ExplorationRoutes.FIND_PINE_CONE, "feather": ExplorationRoutes.FIND_FEATHER}
	for kind: String in keepsake_labels:
		var owned := int(keepsakes.get(find_ids[kind], 0))
		keepsake_labels[kind].text = "%s  × %d" % [names[kind], owned]
		_ink_row(keepsake_labels[kind], owned)
	var held := str(inventory.get("held", ""))
	names["millet"] = "Millet" if en else "小米"
	scoop_button.text = "Scoop feed from the tin" if en else "从鸡食罐舀一小把米"
	scoop_button.disabled = inventory.is_empty() or busy or not held.is_empty()
	for kind: String in FISH:
		var count := int(inventory.get(kind, 0)) if kind in ["grass", "millet"] else int(inventory.get("fish", {}).get(kind, 0))
		fish_labels[kind].text = "%s  × %d" % [names[kind], count]
		_ink_row(fish_labels[kind], count)
		fish_buttons[kind].text = "Take one" if en else ("拿一把" if kind == "millet" else ("拿一束" if kind == "grass" else "拿一条"))
		fish_buttons[kind].disabled = inventory.is_empty() or busy or not held.is_empty() or count == 0
	held_label.text = ("In hand: " if en else "手里拿着：") + str(names.get(held, "Nothing" if en else "空着"))
	return_button.text = "Put it back" if en else "收回背篓"
	return_button.disabled = busy or held.is_empty()
	for connection: Dictionary in return_button.pressed.get_connections():
		return_button.pressed.disconnect(connection.callable)
	return_button.pressed.connect(func() -> void: action_requested.emit("return", held))
	status.text = "Caught fish and finds stay here." if en else "钓到的鱼、散步带回的小物，都收在这里。"
	_status_is_note = not (state in ["saving", "unknown", "failed", "blocked"] or inventory.is_empty())
	var show_status := not (compact and _status_is_note)
	if status.visible != show_status:
		status.visible = show_status
	if state in ["saving", "unknown"]:
		status.text = "Checking the save…" if en else "正在确认保存，东西还不能取用……"
	elif state in ["failed", "blocked"] or inventory.is_empty():
		status.text = "Not saved yet. Your stored items are kept." if en else "这次还没存好，原有物品保留着。"
	retry_button.visible = state in ["failed", "unknown"]
	retry_button.text = "Check again" if en else "再确认一次"
	close_button.text = "Back to the yard" if en else "合上背篓"
	grid.update_view(inventory, keepsakes, state, busy)
	call_deferred("fit")

func _on_grid_action(action: String, kind: String) -> void:
	if action == "decor": open_decor_with(kind)
	else: action_requested.emit(action, kind)

## 格子里点圆石/松果/落羽「摆到院里」：走现有「把小物摆在院里」入口（Main._show_decor 收起背篓、
## 打开布置面板），再在布置面板里预选这件；当前位置已摆了东西就换到第一个空位置。
## 只是预览：不提交、不扣数量，确认仍由布置面板走 YardDecorController.request('place', …)。
func open_decor_with(kind: String) -> void:
	if decor_button == null or decor_button.disabled: return
	decor_button.pressed.emit()
	var decor := _find_decor_panel()
	if decor == null or not decor.visible: return
	var id: String = grid.FIND_IDS.get(kind, "")
	if id.is_empty(): return
	var places: Dictionary = decor.value.get("places", {})
	if places.has(decor.selected):
		for spot: String in load(DECOR_SPOTS_SCRIPT).SPOTS:
			if not places.has(spot):
				decor.choose_spot(spot)
				break
	decor.choose_find(id)

func _find_decor_panel() -> Control:
	if decor_panel != null and is_instance_valid(decor_panel): return decor_panel
	var parent := get_parent()
	if parent == null: return null
	for child: Node in parent.get_children():
		var script: Script = child.get_script()
		if child is Control and script != null and script.resource_path == DECOR_PANEL_SCRIPT:
			decor_panel = child
			return decor_panel
	return null

func _ink_row(label: Label, count: int) -> void:
	label.add_theme_color_override("font_color", EMPTY_ROW_INK if count <= 0 else ROW_INK)

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
	# 格子与它的操作纸片先接：纸片开着时点别处只收起纸片，不顺手触发底下的按钮
	if grid != null and (grid.menu.visible or scroll.get_global_rect().has_point(position_in_view)):
		if grid.press_at(position_in_view): return
	var buttons: Array = [close_button, retry_button, return_button, scoop_button]
	if decor_button != null: buttons.append(decor_button)
	buttons.append_array(fish_buttons.values())
	for button: Button in buttons:
		if button.is_visible_in_tree() and not button.disabled and button.get_global_rect().has_point(position_in_view):
			if button in fish_buttons.values() or button in [return_button, scoop_button, decor_button]:
				if not scroll.get_global_rect().has_point(position_in_view): continue
			button.pressed.emit()
			return
