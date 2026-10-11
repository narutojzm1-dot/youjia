extends Control
## REQ-20261008-075（Owner GROK-CONTRIBUTOR）：Minecraft 式底部横排快捷栏。
## REQ-20261009-076：选中且 place_armed 时加墨色底边角标，空手持选中一眼可分。
## #597 2026-10-09 用户追加：五格不预设，由玩家从背篓配置（鱼 / 草束 / 小米 / 麦粒 / 玉米粒），空格点开背篓；
## 数量读真实 yard_inventory，不另建库存。
## 选中态跟着 held 走；点选中格可解除「点地投放」武装；点有货的其他格发出 withdraw_requested，
## 由 Main 走既有 YardInventoryController.request("withdraw", …)。取消 / 非法落点不在此扣数。

signal slot_selected(kind: String)
signal selection_cleared
signal withdraw_requested(kind: String)
signal place_armed_changed(armed: bool)
## #597 2026-10-09 用户追加：点空格打开背篓；格子配置变了由 Main 记下
signal basket_requested
signal slots_changed(slots: Array)

const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const CropArt := preload("res://scripts/game/crop_art.gd")
## 五格不预设内容，玩家从背篓拖进来（或用格子纸片「放进快捷栏」）。格子只记物品种类，
## 数量始终读同一份背篓库存，配置、替换、拿下都不增减任何物品。
const SLOT_COUNT := 5
const HOLDABLE := ["small", "medium", "odd", "grass", "millet", "wheat", "corn"]
const GRAINS := ["wheat", "corn"]
const ICONS := {
	"small": "res://assets/holiday/objects/ground_fish.png",
	"medium": "res://assets/holiday/objects/ground_fish.png",
	"odd": "res://assets/holiday/objects/ground_fish.png",
	"grass": "res://assets/holiday/fx/grass_bundle.png",
	"millet": "res://assets/holiday/objects/millet.png",
}
const ICON_SCALE := {"small": 0.55, "medium": 0.72, "odd": 0.62}
const SLOT := 52.0
const GAP := 6.0
const PAD := 8.0
const PAPER := Color("fff6e8")
const INK := Color("5b4637")
const EDGE := Color("b88a61")
const SELECT_EDGE := Color("5b4637")
const EMPTY_INK := Color("7a6152")
const SLOT_FILL := Color("f7ecdc")
const SLOT_HOT := Color("f3d3ae")
const EMPTY_FILL := Color(0.969, 0.925, 0.863, 0.55)
const DROP_EDGE := Color("916d49")
const BASKET_MARGIN := 8.0
const SIDE_MARGIN := 4.0
const MIN_SLOT := 40.0
## 武装态在选中描边之外加 3px 墨色底边，一眼区分「仅选中」与「点地投放已武装」。
const ARMED_ACCENT_PX := 3

var strip: HBoxContainer
## 按格序的五个按钮；cells / icons / counts_labels 只收已配置的种类，键是物品种类
var slot_cells: Array[Button] = []
var slot_icons: Array[TextureRect] = []
var slot_counts: Array[Label] = []
var slots: Array[String] = []
var cells: Dictionary = {}
var icons: Dictionary = {}
var counts_labels: Dictionary = {}
var held := ""
var counts: Dictionary = {}
var selected := ""
var place_armed := false
var busy := false
## 背篓开着时快捷栏只当落点：点格子不取物、不开背篓
var configuring := false
var drop_hint := -1
var _names: Dictionary = {}
var _cell_style_keys: Array[int] = []
## 套件用：实际新建格子样式的次数。
var restyle_builds := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var paper := PanelContainer.new()
	paper.name = "Paper"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(PAPER, 0.94)
	style.border_color = EDGE
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(PAD)
	paper.add_theme_stylebox_override("panel", style)
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(paper)
	strip = HBoxContainer.new()
	strip.add_theme_constant_override("separation", int(GAP))
	paper.add_child(strip)
	for index in SLOT_COUNT:
		slots.append("")
		strip.add_child(_make_cell(index))
	custom_minimum_size = Vector2(SLOT_COUNT * SLOT + (SLOT_COUNT - 1) * GAP + PAD * 2.0, SLOT + PAD * 2.0)
	_refresh_names()
	_apply_slots()


func _make_cell(index: int) -> Button:
	var cell := Button.new()
	cell.name = "Slot_%d" % index
	cell.toggle_mode = true
	cell.focus_mode = Control.FOCUS_ALL
	cell.custom_minimum_size = Vector2(SLOT, SLOT)
	cell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cell.pressed.connect(func() -> void: _on_cell_pressed(index))
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_bottom = -14.0
	cell.add_child(icon)
	var count := Label.new()
	count.name = "Count"
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count.add_theme_color_override("font_color", INK)
	count.add_theme_font_size_override("font_size", 13)
	count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	count.offset_left = 2
	count.offset_top = 2
	count.offset_right = -3
	count.offset_bottom = -2
	cell.add_child(count)
	slot_cells.append(cell)
	slot_icons.append(icon)
	slot_counts.append(count)
	_cell_style_keys.append(-1)
	return cell


static func icon_texture(kind: String) -> Texture2D:
	if kind in GRAINS: return CropArt.texture(kind)
	var path: String = ICONS.get(kind, "")
	if path.is_empty(): return null
	var tex = load(path)
	return tex if tex is Texture2D else null


## Main 读回玩家上次的配置；不认识的种类、重复的种类都当空格
func set_slots(list: Array) -> void:
	var seen: Array[String] = []
	for index in SLOT_COUNT:
		var kind := str(list[index]) if index < list.size() else ""
		if kind not in HOLDABLE or kind in seen: kind = ""
		if not kind.is_empty(): seen.append(kind)
		slots[index] = kind
	_apply_slots()


func slot_of(kind: String) -> int:
	return slots.find(kind) if not kind.is_empty() else -1


## 把一种东西放进第 index 格：原来那格里的东西换下（仍在背篓），同一种不会占两格
func assign(kind: String, index: int) -> bool:
	if kind not in HOLDABLE or index < 0 or index >= SLOT_COUNT: return false
	if slots[index] == kind: return true
	var before := slot_of(kind)
	if before >= 0: slots[before] = ""
	slots[index] = kind
	_apply_slots()
	slots_changed.emit(slots.duplicate())
	return true


## 放进第一个空格；没有空格返回 -1
func add_to_first_empty(kind: String) -> int:
	if slot_of(kind) >= 0: return slot_of(kind)
	var index := slots.find("")
	if index < 0 or not assign(kind, index): return -1
	return index


func remove_kind(kind: String) -> bool:
	var index := slot_of(kind)
	if index < 0: return false
	slots[index] = ""
	_apply_slots()
	slots_changed.emit(slots.duplicate())
	return true


func is_full() -> bool:
	return slots.find("") < 0


func slot_index_at(screen_point: Vector2) -> int:
	if not is_visible_in_tree(): return -1
	for index in SLOT_COUNT:
		if slot_cells[index].get_global_rect().grow(GAP * 0.5).has_point(screen_point): return index
	return -1


func set_drop_hint(index: int) -> void:
	if drop_hint == index: return
	drop_hint = index
	_restyle()


func set_configuring(on: bool) -> void:
	var hint := drop_hint if on else -1
	if configuring == on and drop_hint == hint: return
	configuring = on
	drop_hint = hint
	_restyle()


func _apply_slots() -> void:
	cells.clear()
	icons.clear()
	counts_labels.clear()
	for index in SLOT_COUNT:
		var kind := slots[index]
		var icon := slot_icons[index]
		icon.texture = icon_texture(kind) if not kind.is_empty() else null
		var shrink := (1.0 - float(ICON_SCALE.get(kind, 0.7))) * 4.0
		icon.offset_left = 6.0 + shrink
		icon.offset_top = 4.0 + shrink
		icon.offset_right = -6.0 - shrink
		if not kind.is_empty():
			cells[kind] = slot_cells[index]
			icons[kind] = icon
			counts_labels[kind] = slot_counts[index]
	_refresh_counts()
	_set_selected(selected)


func _refresh_counts() -> void:
	for index in SLOT_COUNT:
		var kind := slots[index]
		var cell := slot_cells[index]
		var label := slot_counts[index]
		if kind.is_empty():
			label.text = ""
			cell.disabled = busy
			continue
		var count := int(counts.get(kind, 0))
		var owned := count > 0
		# 麦粒 / 玉米粒留最后一把播种，与背篓同一规则；手里那件始终可点（切换点地投放）
		var usable := kind == held or (count > (1 if kind in GRAINS else 0))
		cell.disabled = busy or not usable
		label.text = "×%d" % count if owned else ""
		label.add_theme_color_override("font_color", INK if owned else EMPTY_INK)
		slot_icons[index].modulate = Color(1, 1, 1, 1.0 if owned else 0.28)


func _apply_cell_style(cell: Button, selected_slot: bool, armed: bool, empty: bool = false, hot: bool = false) -> void:
	var show_armed := selected_slot and armed
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = SLOT_HOT if selected_slot or hot else (EMPTY_FILL if empty else SLOT_FILL)
		box.border_color = SELECT_EDGE if selected_slot else (DROP_EDGE if hot else EDGE)
		box.set_border_width_all(2 if selected_slot or hot else 1)
		if show_armed:
			# 底边加粗：选中描边 2px + 墨色武装角标 3px，保持水彩纸语言。
			box.set_border_width(SIDE_BOTTOM, 2 + ARMED_ACCENT_PX)
			box.border_color = SELECT_EDGE
		box.set_corner_radius_all(8)
		box.set_content_margin_all(2)
		cell.add_theme_stylebox_override(state, box)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = SELECT_EDGE if selected_slot else DROP_EDGE
	focus.set_border_width_all(2)
	if show_armed:
		focus.set_border_width(SIDE_BOTTOM, 2 + ARMED_ACCENT_PX)
	focus.set_corner_radius_all(8)
	cell.add_theme_stylebox_override("focus", focus)


## 套件用：选中且武装的格底边宽于顶边（有墨色武装角标）。
func slot_has_armed_accent(kind: String) -> bool:
	if not cells.has(kind):
		return false
	var cell: Button = cells[kind]
	var box := cell.get_theme_stylebox("normal") as StyleBoxFlat
	if box == null:
		return false
	return box.get_border_width(SIDE_BOTTOM) > box.get_border_width(SIDE_TOP)


func _refresh_names() -> void:
	var en := I18n.get_locale() == "en"
	_names = {
		"small": "Small fish" if en else "小鱼",
		"medium": "Fish" if en else "中鱼",
		"odd": "Curious fish" if en else "奇怪的鱼",
		"grass": "Grass" if en else "草束",
		"millet": "Millet" if en else "小米",
		"wheat": "Wheat" if en else "麦粒",
		"corn": "Corn" if en else "玉米粒",
	}


func _slot_tooltip(kind: String, count: int) -> String:
	var en := I18n.get_locale() == "en"
	if kind.is_empty():
		if configuring: return "Drag something from the basket here" if en else "从背篓拖一样东西放到这格"
		return "Empty · tap to open the basket" if en else "空格 · 点一下打开背篓"
	var base := "%s ×%d" % [_names.get(kind, kind), count]
	if kind != selected or kind != held or selected.is_empty():
		return base
	if place_armed:
		return base + (" · tap ground to place" if en else " · 点地放下")
	# 选中但未武装（草默认，或用户点格解除）：提示再点一次可点地放下。
	return base + (" · Tap again, then tap the ground" if en else " · 再点一次，可点地放下")


func _refresh_tooltips() -> void:
	for index in SLOT_COUNT:
		var kind := slots[index]
		slot_cells[index].tooltip_text = _slot_tooltip(kind, int(counts.get(kind, 0)))


## 与背篓 / Main 同一份 inventory 视图同步；格子只显示，不另记数量。
func update_view(inventory: Dictionary, _keepsakes: Dictionary = {}, state: String = "idle", is_busy: bool = false) -> void:
	_refresh_names()
	busy = is_busy or state in ["saving", "unknown", "failed", "blocked"]
	var previous_held := held
	held = str(inventory.get("held", "")) if not inventory.is_empty() else ""
	for kind: String in HOLDABLE:
		var count := 0
		if kind in Inventory.FISH:
			count = int(inventory.get("fish", {}).get(kind, 0))
		else:
			count = int(inventory.get(kind, 0))
		# 手里那一件不在背篓计数里，栏上要看得见：held 时该格至少显示 1
		if kind == held and not held.is_empty():
			count = maxi(count, 1)
		counts[kind] = count
	_refresh_counts()
	# 选中态跟着真实手持走；空手则清空。手里的东西没放进格子也照样能点地投放。
	if held.is_empty():
		_set_selected("")
		_set_armed(false)
	else:
		_set_selected(held)
		# 鱼/小米：手持变化时默认武装点地投放（玩家可再点同一格解除）。
		# 草束不自动武装：院里拔草后仍走 YardInteraction 走动/牵绳/取消语义，
		# 投放继续由动作键负责；需要点地投放时再点草格武装。
		if held != previous_held:
			_set_armed(held != "grass")
	_refresh_tooltips()


func selected_kind() -> String:
	return selected


func is_place_armed() -> bool:
	return place_armed and not selected.is_empty() and selected == held


func clear_selection() -> void:
	_set_armed(false)
	# 仍显示 held 的选中描边（真实手持未变），只解除点地武装
	selection_cleared.emit()


func arm_placement(armed: bool) -> void:
	if held.is_empty():
		_set_armed(false)
		return
	_set_selected(held)
	_set_armed(armed)


func _on_cell_pressed(index: int) -> void:
	slot_cells[index].set_pressed_no_signal(slots[index] == selected and not selected.is_empty())
	if configuring or busy:
		return
	if slots[index].is_empty():
		basket_requested.emit()
		return
	_on_slot_pressed(slots[index])


func _on_slot_pressed(kind: String) -> void:
	if busy or not cells.has(kind) or cells[kind].disabled:
		return
	if kind == held and not held.is_empty():
		# 点当前手持格：切换点地投放武装
		_set_armed(not place_armed)
		slot_selected.emit(kind)
		return
	if counts.get(kind, 0) <= 0:
		return
	if not held.is_empty():
		# 手里已有东西：不能直接换，需先收回（与背篓格子同一规则）
		return
	withdraw_requested.emit(kind)
	slot_selected.emit(kind)


func _set_selected(kind: String) -> void:
	selected = kind
	_restyle()


func _restyle() -> void:
	for index in SLOT_COUNT:
		var cell := slot_cells[index]
		var kind := slots[index]
		var on := not kind.is_empty() and kind == selected
		cell.set_pressed_no_signal(on)
		var armed := on and place_armed
		var hot := index == drop_hint
		var key := int(on) | int(armed) << 1 | int(kind.is_empty()) << 2 | int(hot) << 3
		if _cell_style_keys[index] != key:
			_cell_style_keys[index] = key
			restyle_builds += 1
			_apply_cell_style(cell, on, armed, kind.is_empty(), hot)
	_refresh_tooltips()


func _set_armed(armed: bool) -> void:
	var changed := place_armed != armed
	if changed:
		place_armed = armed
		place_armed_changed.emit(place_armed)
	# 武装变化或重复同步时都重绘，保证角标与 place_armed 一致。
	_restyle()


## 触屏：点在某格中心即按下（与背篓 press_at 同思路）
func press_at(screen_point: Vector2) -> bool:
	for index in SLOT_COUNT:
		var cell := slot_cells[index]
		if cell.get_global_rect().has_point(screen_point):
			if not cell.disabled:
				_on_cell_pressed(index)
			return true
	return false


## 合入方布局：贴在底部按钮行上方，不遮挡 action / 背篓芯片
static func preferred_rect(viewport: Vector2, compact: bool) -> Rect2:
	var side := slot_side(viewport.x)
	var width := SLOT_COUNT * side + (SLOT_COUNT - 1) * GAP + PAD * 2.0
	var height := side + PAD * 2.0
	var bottom_row := viewport.y - 124.0 if compact else viewport.y - 68.0
	var left := (viewport.x - width) * 0.5
	var top := bottom_row - height - 8.0
	return Rect2(Vector2(left, top), Vector2(width, height))


## 背篓开着时快捷栏贴屏幕底边，背篓纸面让出这一条
static func basket_rect(viewport: Vector2) -> Rect2:
	var side := slot_side(viewport.x)
	var width := SLOT_COUNT * side + (SLOT_COUNT - 1) * GAP + PAD * 2.0
	var height := side + PAD * 2.0
	return Rect2(Vector2((viewport.x - width) * 0.5, viewport.y - height - BASKET_MARGIN), Vector2(width, height))


## 五格放不下时（280 宽手机）格子边长跟着收，整条留 SIDE_MARGIN 边距不出屏
static func slot_side(viewport_width: float) -> float:
	var room := viewport_width - SIDE_MARGIN * 2.0 - (SLOT_COUNT - 1) * GAP - PAD * 2.0
	return clampf(floorf(room / SLOT_COUNT), MIN_SLOT, SLOT)


func set_slot_side(side: float) -> void:
	for cell: Button in slot_cells:
		cell.custom_minimum_size = Vector2(side, side)
	custom_minimum_size = Vector2(SLOT_COUNT * side + (SLOT_COUNT - 1) * GAP + PAD * 2.0, side + PAD * 2.0)
