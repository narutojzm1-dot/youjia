extends Control
const PaperScrollbarStyle := preload("res://scripts/ui/paper_scrollbar_style.gd")
signal close_requested
signal action_requested(action: String, fish: String)
signal retry_requested
## #594：小物拖到院里空着的亮圈上松手、或在格子纸片里点「摆在某处」，就摆在那处
## （Main 走 YardDecorController.request('place', …)）。没有单独的布置面板。
signal place_requested(find_id: String, spot: String)

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
## REQ-20261007-064（#565 图8，Owner GROK-CONTRIBUTOR）：玩家看到的是一张行列格子（yard_basket_grid.gd），
## 每样东西一格、点格子弹操作。原来逐行的「名字 × N + 拿一条」清单节点仍保留（fish_buttons /
## fish_labels / keepsake_labels 及其信号给旧接口与旧测试用），但不再显示，避免同一样东西出现两遍。
var grid: Control
var list_rows: Array[Control] = []
## 院内布置的现状（YardDecorController.view() / state / busy()），由 Main.update_decor 送来
var decor_value: Dictionary = {}
var decor_state := "idle"
var decor_busy := false
var _inventory_state := ""
const DECOR_SPOTS_SCRIPT := "res://scripts/inventory/yard_decor.gd"
## REQ-20261007-064 第三切片（#565 图8 拖出）：按住圆石 / 松果 / 落羽的格子拖出来，
## 背篓纸面变半透明、暗底撤掉，院里只有还空着的固定摆放处（屋前 / 篱边 / 塘边小路）亮起杏色圈；
## 松在亮圈里 = 发 place_requested，Main 直接摆在那一处（#594）；
## 松在别处、Esc、背篓被收起或保存忙起来 = 取消，什么都不提交。
## 院子世界（Main._world）。Main 可直接赋值；未赋值时沿父节点找一次 `_world`。
var world: Node2D
## #597：手持快捷栏；背篓开着时它贴在屏幕底边当落点，纸面让出 reserve_bottom 这一条
var hotbar: Control
var reserve_bottom := 0.0
var drag_kind := ""
var drag_spot := ""
var drag_layer: Control
var drag_ghost: TextureRect
var shade: ColorRect
var _drag_from := Vector2.ZERO
var _touch_time := 0
var _touch_kind := ""
var _mouse_kind := ""
var _mouse_start := Vector2.ZERO
var _swallow_toggle := false
## 手指 / 鼠标移动超过 DRAG_START 才算拖；列表能滚时手指竖着划仍是滚动，
## 横着拖、列表不用滚、或按住 HOLD_MS 以后再动，才把小物拖出来
const DRAG_START := 12.0
const HOLD_MS := 300
const ZONE_RADIUS := 40.0
const ZONE_SLOP := 8.0
const DRAG_ALPHA := 0.3
const GHOST_SIZE := 56.0
const ZONE_FILL := Color(0.953, 0.827, 0.682, 0.55)
const ZONE_HOT_FILL := Color(1.0, 0.906, 0.784, 0.9)
const ZONE_EDGE := Color("b88a61")
const ZONE_HOT_EDGE := Color("5b4637")
## REQ-20261008-068（Owner GROK-CONTRIBUTOR）：亮圈旁的位置名（屋前 / 篱边 / 塘边小路）原先直接用墨字
## 画在院子画面上，压在草地、篱笆和塘边深色处很难认。字下垫一块与背篓纸同色的小纸签，亮着的那处换墨边；
## 纸签整块留在屏内，圈上方放不下（镜头外贴屏顶的那处）就放到圈下方，不盖住圈。
const ZONE_LABEL_SIZE := 16
const ZONE_LABEL_PAD := Vector2(8, 3)
const ZONE_LABEL_GAP := 6.0
const ZONE_LABEL_MARGIN := 4.0
const ZONE_LABEL_FILL := Color(1.0, 0.965, 0.91, 0.92)
const ZONE_LABEL_EDGE := Color("d6ae78")
var fish_labels: Dictionary = {}
var fish_buttons: Dictionary = {}
var keepsake_labels: Dictionary = {}
var _touch_index := -1
var _touch_start := Vector2.ZERO
var _touch_scrolled := false
var column: VBoxContainer
var compact := false
var _status_is_note := true
## 拖放摆好/正在摆/没摆成的那句话；背篓刷新时保留，下次拖动或合上背篓时清掉
var place_note := ""
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
	shade = ColorRect.new()
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
		if not visible:
			cancel_drag()
			place_note = ""
			grid.close_menu())
	for kind: String in grid.KEEPSAKES + grid.HOLDABLE:
		grid.cells[kind].gui_input.connect(func(event: InputEvent) -> void: _on_cell_mouse(kind, event))
		# 鼠标拖完松在原格上：格子自己会把这一下当点按开纸片，这里随即收起，拖出不顺带弹纸片
		grid.cells[kind].toggled.connect(func(_on: bool) -> void:
			if _swallow_toggle: grid.close_menu())
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
	drag_layer = Control.new()
	drag_layer.name = "DragZones"
	drag_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drag_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_layer.visible = false
	drag_layer.draw.connect(_draw_zones)
	add_child(drag_layer)
	drag_ghost = TextureRect.new()
	drag_ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	drag_ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_ghost.size = Vector2.ONE * GHOST_SIZE
	drag_layer.add_child(drag_ghost)
	resized.connect(fit)
	# 说明句显隐或折行变化后，隐藏期间的旧最小高度会把纸面撑高；下一帧按新内容再排一次
	panel.minimum_size_changed.connect(_queue_fit)
	rows.minimum_size_changed.connect(_queue_fit)
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
	button.add_theme_stylebox_override("focus", focus_style())
	return button

## 键盘焦点：2px 褐墨描边、不填底。小鸡成长、种植纸面上的按钮也用这一套。
static func focus_style() -> StyleBoxFlat:
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = Color("916d49")
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(12)
	return focus

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
	var room := size.y - _reserved_bottom()
	var target := Vector2(minf(520, size.x - EDGE * 2.0), minf(620, room - EDGE * 2.0))
	_set_compact(target.y <= COMPACT_HEIGHT)
	var row_width := NARROW_ROW_BUTTON_WIDTH if target.x < NARROW_WIDTH else ROW_BUTTON_WIDTH
	for button: Button in fish_buttons.values():
		button.custom_minimum_size.x = row_width
	# 格子按「纸内宽 − 滚动条宽」排，不论滚动条此刻显不显示，格子尺寸都不变
	if grid != null:
		var bar := scroll.get_v_scroll_bar().get_combined_minimum_size().x
		grid.set_layout_width(maxf(0.0, target.x - 32.0 - bar))
	# 内容放得下时纸面贴着内容收高，不在「收回背篓」和提示之间留一大块空白；放不下才按上限滚动
	var natural := panel.get_combined_minimum_size().y - scroll.get_combined_minimum_size().y + rows.get_combined_minimum_size().y
	panel.size = Vector2(target.x, minf(target.y, ceilf(natural)))
	panel.position = (Vector2(size.x, room) - panel.size) * 0.5

func set_hotbar(bar: Control, reserve: float) -> void:
	hotbar = bar
	reserve_bottom = reserve
	grid.hotbar = bar
	fit()

func _reserved_bottom() -> float:
	return reserve_bottom if _bar_ready() else 0.0

func _bar_ready() -> bool:
	return hotbar != null and is_instance_valid(hotbar)

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
	names["wheat"] = "Wheat grains" if en else "麦粒"
	names["corn"] = "Corn kernels" if en else "玉米粒"
	scoop_button.visible = false
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
	if not place_note.is_empty() and not state in ["saving", "unknown", "failed", "blocked"]:
		status.text = place_note
		_status_is_note = false
		status.visible = true
	_inventory_state = state
	_sync_retry()
	retry_button.text = "Check again" if en else "再确认一次"
	close_button.text = "Back to the yard" if en else "合上背篓"
	grid.update_view(inventory, keepsakes, state, busy)
	# 拖着的时候保存忙起来、或那件小物没了：直接取消，不留半截拖动
	if not drag_kind.is_empty() and not can_drag(drag_kind): cancel_drag()
	call_deferred("fit")

func _on_grid_action(action: String, kind: String) -> void:
	if action == "hotbar_add" and _bar_ready():
		var index: int = hotbar.add_to_first_empty(kind)
		if index >= 0: _hotbar_note(kind, index)
		return
	if action == "hotbar_remove" and _bar_ready():
		if hotbar.remove_kind(kind): _hotbar_note(kind, -1)
		return
	if action.begins_with("place:"):
		var id: String = grid.FIND_IDS.get(kind, "")
		var spot := action.trim_prefix("place:")
		if not id.is_empty() and spot in legal_spots() and can_drag(kind):
			place_note = ""
			place_requested.emit(id, spot)
	else: action_requested.emit(action, kind)

## 背篓存储或布置任一边没存好（失败 / 结果未知）时给「再确认一次」；Main 先重试布置那一边
func _sync_retry() -> void:
	retry_button.visible = _inventory_state in ["failed", "unknown"] or (decor_busy and decor_state in ["failed", "unknown"])

func update_decor(value: Dictionary, state: String, busy: bool) -> void:
	decor_value = value
	decor_state = state
	decor_busy = busy
	_sync_retry()
	grid.set_free_spots(legal_spots(), busy or value.is_empty())
	if not drag_kind.is_empty() and not can_drag(drag_kind): cancel_drag()
	call_deferred("fit")

func _find_world() -> Node2D:
	if world != null and is_instance_valid(world): return world
	var node := get_parent()
	while node != null:
		var found: Variant = node.get("_world")
		if found is Node2D:
			world = found
			return world
		node = node.get_parent()
	return null

## 现在能不能把这一格拖出来：可手持的东西拖到底下快捷格（只记种类，不受保存忙碌影响）；小物要背篓里有、背篓与布置都没在确认保存、布置已载入且还有空位
func can_drag(kind: String) -> bool:
	if kind in grid.HOLDABLE:
		return _bar_ready() and hotbar.is_visible_in_tree() and (int(grid.counts.get(kind, 0)) > 0 or kind == grid._held)
	if kind not in grid.KEEPSAKES or int(grid.counts.get(kind, 0)) <= 0 or grid._busy or not grid._loaded: return false
	if decor_value.is_empty() or decor_busy or _find_world() == null: return false
	return not legal_spots().is_empty()

## 还空着、可以摆的固定位置（已摆了东西的那处不亮、也不接）
func legal_spots() -> Array[String]:
	var result: Array[String] = []
	if decor_value.is_empty(): return result
	var places: Dictionary = decor_value.get("places", {})
	for spot: String in load(DECOR_SPOTS_SCRIPT).SPOTS:
		if not places.has(spot): result.append(spot)
	return result

## 院里固定位置在屏幕上的点：世界坐标经院子（相机）的画布变换换到屏幕，再夹进屏内，
## 镜头外的那处贴在屏边，仍可松手
func spot_screen_position(spot: String) -> Vector2:
	var w := _find_world()
	if w == null: return Vector2(-INF, -INF)
	var holder: Node2D = w.get("decor_view") if w.get("decor_view") is Node2D else w
	var at: Vector2 = holder.get_global_transform_with_canvas() * Vector2(load(DECOR_SPOTS_SCRIPT).SPOTS[spot])
	var margin := ZONE_RADIUS + 4.0
	return Vector2(clampf(at.x, margin, maxf(margin, size.x - margin)), clampf(at.y, margin + 20.0, maxf(margin + 20.0, size.y - margin)))

func zone_at(at: Vector2) -> String:
	var best := ""
	var best_distance := ZONE_RADIUS + ZONE_SLOP
	for spot: String in legal_spots():
		var d := at.distance_to(spot_screen_position(spot))
		if d <= best_distance:
			best = spot
			best_distance = d
	return best

func begin_drag(kind: String, at: Vector2) -> bool:
	if not drag_kind.is_empty() or not can_drag(kind): return false
	place_note = ""
	grid.close_menu()
	drag_kind = kind
	_drag_from = at
	panel.modulate.a = DRAG_ALPHA
	shade.visible = false
	drag_ghost.texture = grid._icon_texture(kind)
	drag_layer.visible = true
	move_child(drag_layer, get_child_count() - 1)
	drag_to(at)
	return true

func drag_to(at: Vector2) -> void:
	if drag_kind.is_empty(): return
	drag_ghost.position = at - drag_ghost.size * 0.5
	if _dragging_to_bar():
		hotbar.set_drop_hint(hotbar.slot_index_at(at))
		return
	drag_spot = zone_at(at)
	drag_layer.queue_redraw()

## 松手：落在亮圈里返回那一处并请求摆在那里；否则什么都不做，返回 ""
func end_drag(at: Vector2) -> String:
	if drag_kind.is_empty(): return ""
	var kind := drag_kind
	if _dragging_to_bar():
		var index: int = hotbar.slot_index_at(at)
		_finish_drag()
		if index < 0 or not hotbar.assign(kind, index):
			var en_bar := I18n.get_locale() == "en"
			place_note = "Drop it on a hotbar slot below. Nothing changed." if en_bar else "要松在下面的快捷格上；快捷栏没有变。"
			status.text = place_note
			_status_is_note = false
			status.visible = true
			return ""
		_hotbar_note(kind, index)
		return "hotbar"
	var spot := zone_at(at)
	_finish_drag()
	if spot.is_empty():
		var en := I18n.get_locale() == "en"
		status.text = "Drop it on a lit spot in the yard. It is still in the basket." if en else "要松在院里亮着的圈上；东西还在背篓里。"
		_status_is_note = false
		status.visible = true
		return ""
	var id: String = grid.FIND_IDS.get(kind, "")
	if not id.is_empty(): place_requested.emit(id, spot)
	return spot

## 拖放摆放的进展写在背篓状态行：stage 为 saving / placed / failed（可再确认）/ blocked（没摆成）；
## 背篓合着时不留话
func show_place_note(find_id: String, spot: String, stage: String) -> void:
	if not visible:
		place_note = ""
		return
	var en := I18n.get_locale() == "en"
	var kind := ""
	for k: String in grid.FIND_IDS:
		if grid.FIND_IDS[k] == find_id: kind = k
	var names := {"round_stone": "The round stone" if en else "圆石", "pine_cone": "The pine cone" if en else "松果", "feather": "The feather" if en else "落羽"}
	var places := {"house_edge": "by the house" if en else "屋前", "fence_edge": "by the fence" if en else "篱边", "pond_path": "on the pond path" if en else "塘边小路"}
	var thing: String = names.get(kind, "It" if en else "小物")
	var where: String = places.get(spot, spot)
	if stage == "saving":
		place_note = ("Setting %s down %s…" % [thing.to_lower(), where]) if en else "正在把%s摆到%s……" % [thing, where]
	elif stage == "failed":
		place_note = ("%s is not set down yet and is still in the basket.\nTap \"Check again\" to save it once more." % thing) if en else "%s还没摆好，还在背篓里；\n点「再确认一次」再存一次。" % thing
	elif stage == "blocked":
		place_note = ("%s could not be set down there and is still in the basket." % thing) if en else "%s没能摆在那里，还在背篓里。" % thing
	else:
		place_note = ("%s is %s now.\nTap it outside the basket, or close the basket and tap it." % [thing, where]) if en else "%s摆在%s了。\n背篓外点它，或合上背篓再点，就能收回。" % [thing, where]
	status.text = place_note
	_status_is_note = false
	status.visible = true

func _dragging_to_bar() -> bool:
	return drag_kind in grid.HOLDABLE and _bar_ready()

## 快捷栏配好后的一句话；index < 0 表示刚从快捷栏拿下
func _hotbar_note(kind: String, index: int) -> void:
	var en := I18n.get_locale() == "en"
	var thing: String = grid._names.get(kind, kind)
	if index < 0:
		place_note = ("%s is off the hotbar. It is still in the basket." % thing) if en else "%s从快捷栏拿下了，东西还在背篓里。" % thing
	else:
		place_note = ("%s is on hotbar slot %d." % [thing, index + 1]) if en else "%s放进快捷栏第%d格了。" % [thing, index + 1]
	status.text = place_note
	_status_is_note = false
	status.visible = true

func cancel_drag() -> void:
	if drag_kind.is_empty(): return
	_finish_drag()

func _finish_drag() -> void:
	drag_kind = ""
	drag_spot = ""
	_touch_kind = ""
	_mouse_kind = ""
	panel.modulate.a = 1.0
	shade.visible = true
	drag_layer.visible = false
	if _bar_ready(): hotbar.set_drop_hint(-1)

func _draw_zones() -> void:
	if drag_kind.is_empty() or _dragging_to_bar(): return
	var font := get_theme_default_font()
	for spot: String in legal_spots():
		var at := spot_screen_position(spot)
		var hot := spot == drag_spot
		drag_layer.draw_circle(at, ZONE_RADIUS, ZONE_HOT_FILL if hot else ZONE_FILL)
		drag_layer.draw_arc(at, ZONE_RADIUS, 0.0, TAU, 48, ZONE_HOT_EDGE if hot else ZONE_EDGE, 3.0 if hot else 2.0, true)
		var slip := zone_label_rect(spot)
		drag_layer.draw_style_box(zone_label_style(hot), slip)
		var baseline := slip.position + Vector2(ZONE_LABEL_PAD.x, ZONE_LABEL_PAD.y + font.get_ascent(ZONE_LABEL_SIZE))
		drag_layer.draw_string(font, baseline, zone_label_text(spot), HORIZONTAL_ALIGNMENT_LEFT, -1, ZONE_LABEL_SIZE, ROW_INK)

func zone_label_text(spot: String) -> String:
	var en := I18n.get_locale() == "en"
	var names := {"house_edge": "House" if en else "屋前", "fence_edge": "Fence" if en else "篱边", "pond_path": "Path" if en else "塘边小路"}
	return names.get(spot, spot)

## 位置名纸签在屏幕上的框：默认居中在圈上方 ZONE_LABEL_GAP 处；上方放不下就放圈下方；最后整块夹进屏内
func zone_label_rect(spot: String) -> Rect2:
	var font := get_theme_default_font()
	var text_width := font.get_string_size(zone_label_text(spot), HORIZONTAL_ALIGNMENT_LEFT, -1, ZONE_LABEL_SIZE).x
	var box := Vector2(ceilf(text_width), ceilf(font.get_height(ZONE_LABEL_SIZE))) + ZONE_LABEL_PAD * 2.0
	var at := spot_screen_position(spot)
	var top := at.y - ZONE_RADIUS - ZONE_LABEL_GAP - box.y
	if top < ZONE_LABEL_MARGIN: top = at.y + ZONE_RADIUS + ZONE_LABEL_GAP
	var left := clampf(at.x - box.x * 0.5, ZONE_LABEL_MARGIN, maxf(ZONE_LABEL_MARGIN, size.x - box.x - ZONE_LABEL_MARGIN))
	top = clampf(top, ZONE_LABEL_MARGIN, maxf(ZONE_LABEL_MARGIN, size.y - box.y - ZONE_LABEL_MARGIN))
	return Rect2(Vector2(left, top), box)

static func zone_label_style(hot: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = ZONE_LABEL_FILL
	style.border_color = ZONE_HOT_EDGE if hot else ZONE_LABEL_EDGE
	style.set_border_width_all(2 if hot else 1)
	style.set_corner_radius_all(8)
	return style

## 鼠标：按在小物格上、移动超过 DRAG_START 开始拖，松开时落点决定预览或取消。
## 松手若仍在原格上，这一下不再当作点格子开纸片。
func _on_cell_mouse(kind: String, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_mouse_kind = kind
			_mouse_start = event.global_position
		elif not drag_kind.is_empty():
			_swallow_toggle = true
			set_deferred("_swallow_toggle", false)
			end_drag(event.global_position)
		else:
			_mouse_kind = ""
	elif event is InputEventMouseMotion and _mouse_kind == kind:
		if drag_kind.is_empty():
			if event.global_position.distance_to(_mouse_start) >= DRAG_START:
				begin_drag(kind, event.global_position)
		else:
			drag_to(event.global_position)

func _unhandled_key_input(event: InputEvent) -> void:
	if not drag_kind.is_empty() and event.is_action_pressed("ui_cancel"):
		cancel_drag()
		get_viewport().set_input_as_handled()

func _ink_row(label: Label, count: int) -> void:
	label.add_theme_color_override("font_color", EMPTY_ROW_INK if count <= 0 else ROW_INK)

func handle_touch_event(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _touch_index != -1: return
			_touch_index = event.index
			_touch_start = event.position
			_touch_scrolled = false
			_touch_time = Time.get_ticks_msec()
			_touch_kind = _keepsake_cell_at(event.position)
		elif event.index == _touch_index:
			_touch_index = -1
			if not drag_kind.is_empty():
				end_drag(event.position)
				return
			if not _touch_scrolled and event.position.distance_to(_touch_start) < 12.0:
				_activate_touch(event.position)
	elif event is InputEventScreenDrag and event.index == _touch_index:
		if not drag_kind.is_empty():
			drag_to(event.position)
			return
		if not _touch_scrolled and not _touch_kind.is_empty() and event.position.distance_to(_touch_start) >= DRAG_START:
			var moved: Vector2 = event.position - _touch_start
			var scrolls := scroll.get_v_scroll_bar().visible
			if not scrolls or absf(moved.x) > absf(moved.y) or Time.get_ticks_msec() - _touch_time >= HOLD_MS:
				if begin_drag(_touch_kind, event.position): return
		if event.position.distance_to(_touch_start) >= 12.0: _touch_scrolled = true
		if _touch_scrolled and scroll.get_global_rect().has_point(_touch_start):
			scroll.scroll_vertical -= int(event.relative.y)

## 手指按下处是不是一格能拖的（小物拖到院里，可手持的东西拖到快捷格；且在清单窗内可见）
func _keepsake_cell_at(at: Vector2) -> String:
	if grid == null or not scroll.get_global_rect().has_point(at): return ""
	for kind: String in grid.KEEPSAKES + grid.HOLDABLE:
		if grid.cells[kind].get_global_rect().has_point(at): return kind
	return ""

func _activate_touch(position_in_view: Vector2) -> void:
	# 格子与它的操作纸片先接：纸片开着时点别处只收起纸片，不顺手触发底下的按钮
	if grid != null and (grid.menu.visible or scroll.get_global_rect().has_point(position_in_view)):
		if grid.press_at(position_in_view): return
	var buttons: Array = [close_button, retry_button, return_button, scoop_button]
	buttons.append_array(fish_buttons.values())
	for button: Button in buttons:
		if button.is_visible_in_tree() and not button.disabled and button.get_global_rect().has_point(position_in_view):
			if button in fish_buttons.values() or button in [return_button, scoop_button]:
				if not scroll.get_global_rect().has_point(position_in_view): continue
			button.pressed.emit()
			return
