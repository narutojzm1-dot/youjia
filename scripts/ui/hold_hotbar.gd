extends Control
## REQ-20261008-075（Owner GROK-CONTRIBUTOR）：Minecraft 式底部横排快捷栏。
## REQ-20261009-076：选中且 place_armed 时加墨色底边角标，空手持选中一眼可分。
## 只展示真实 yard_inventory 的手持 / 可拿食物格（小鱼 / 中鱼 / 怪鱼 / 草束 / 小米），不另建库存。
## 选中态跟着 held 走；点选中格可解除「点地投放」武装；点有货的其他格发出 withdraw_requested，
## 由 Main 走既有 YardInventoryController.request("withdraw", …)。取消 / 非法落点不在此扣数。
## 本切片不改 main.gd / yard_world.gd；不改 withdraw/arm/grass-no-auto-arm 逻辑。

signal slot_selected(kind: String)
signal selection_cleared
signal withdraw_requested(kind: String)
signal place_armed_changed(armed: bool)

const Inventory := preload("res://scripts/inventory/yard_inventory.gd")
const SLOT_ORDER := ["small", "medium", "odd", "grass", "millet"]
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
## 武装态在选中描边之外加 3px 墨色底边，一眼区分「仅选中」与「点地投放已武装」。
const ARMED_ACCENT_PX := 3

var strip: HBoxContainer
var cells: Dictionary = {}
var icons: Dictionary = {}
var counts_labels: Dictionary = {}
var held := ""
var counts: Dictionary = {}
var selected := ""
var place_armed := false
var busy := false
var _names: Dictionary = {}


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
	for kind: String in SLOT_ORDER:
		var cell := _make_cell(kind)
		strip.add_child(cell)
		cells[kind] = cell
	custom_minimum_size = Vector2(SLOT_ORDER.size() * SLOT + (SLOT_ORDER.size() - 1) * GAP + PAD * 2.0, SLOT + PAD * 2.0)
	_refresh_names()


func _make_cell(kind: String) -> Button:
	var cell := Button.new()
	cell.name = "Slot_%s" % kind
	cell.toggle_mode = true
	cell.focus_mode = Control.FOCUS_ALL
	cell.custom_minimum_size = Vector2(SLOT, SLOT)
	cell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_apply_cell_style(cell, false, false)
	cell.pressed.connect(func() -> void: _on_slot_pressed(kind))
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shrink := (1.0 - float(ICON_SCALE.get(kind, 0.7))) * 4.0
	icon.offset_left = 6.0 + shrink
	icon.offset_top = 4.0 + shrink
	icon.offset_right = -6.0 - shrink
	icon.offset_bottom = -14.0
	var path: String = ICONS.get(kind, "")
	if not path.is_empty():
		var tex = load(path)
		if tex is Texture2D:
			icon.texture = tex
	cell.add_child(icon)
	icons[kind] = icon
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
	counts_labels[kind] = count
	return cell


func _apply_cell_style(cell: Button, selected_slot: bool, armed: bool) -> void:
	var show_armed := selected_slot and armed
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = SLOT_HOT if selected_slot else SLOT_FILL
		box.border_color = SELECT_EDGE if selected_slot else EDGE
		box.set_border_width_all(2 if selected_slot else 1)
		if show_armed:
			# 底边加粗：选中描边 2px + 墨色武装角标 3px，保持水彩纸语言。
			box.set_border_width(SIDE_BOTTOM, 2 + ARMED_ACCENT_PX)
			box.border_color = SELECT_EDGE
		box.set_corner_radius_all(8)
		box.set_content_margin_all(2)
		cell.add_theme_stylebox_override(state, box)
	if selected_slot:
		var focus := StyleBoxFlat.new()
		focus.draw_center = false
		focus.border_color = SELECT_EDGE
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
	}


func _slot_tooltip(kind: String, count: int) -> String:
	var base := "%s ×%d" % [_names.get(kind, kind), count]
	if kind.is_empty() or kind != selected or kind != held or selected.is_empty():
		return base
	var en := I18n.get_locale() == "en"
	if place_armed:
		return base + (" · tap ground to place" if en else " · 点地放下")
	# 选中但未武装（草默认，或用户点格解除）：提示再点一次可点地放下。
	return base + (" · Tap again, then tap the ground" if en else " · 再点一次，可点地放下")


func _refresh_tooltips() -> void:
	for kind: String in SLOT_ORDER:
		var count := int(counts.get(kind, 0))
		var cell: Button = cells[kind]
		cell.tooltip_text = _slot_tooltip(kind, count)


## 与背篓 / Main 同一份 inventory 视图同步；keepsakes 本切片不进栏（拖放小物留给后续，避开 #579/#576）。
func update_view(inventory: Dictionary, _keepsakes: Dictionary = {}, state: String = "idle", is_busy: bool = false) -> void:
	_refresh_names()
	busy = is_busy or state in ["saving", "unknown", "failed", "blocked"]
	var previous_held := held
	held = str(inventory.get("held", "")) if not inventory.is_empty() else ""
	for kind: String in SLOT_ORDER:
		var count := 0
		if kind in Inventory.FISH:
			count = int(inventory.get("fish", {}).get(kind, 0))
		else:
			count = int(inventory.get(kind, 0))
		# 手里那一件不在背篓计数里，栏上要看得见：held 时该格至少显示 1
		if kind == held and not held.is_empty():
			count = maxi(count, 1)
		counts[kind] = count
		var owned := count > 0
		var cell: Button = cells[kind]
		cell.disabled = not owned or busy
		counts_labels[kind].text = "×%d" % count if owned else ""
		counts_labels[kind].add_theme_color_override("font_color", INK if owned else EMPTY_INK)
		icons[kind].modulate = Color(1, 1, 1, 1.0 if owned else 0.28)
	# 选中态跟着真实手持走；空手则清空
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
	for id: String in SLOT_ORDER:
		var cell: Button = cells[id]
		var on := id == kind and not kind.is_empty()
		cell.set_pressed_no_signal(on)
		_apply_cell_style(cell, on, on and place_armed)
	_refresh_tooltips()


func _set_armed(armed: bool) -> void:
	var changed := place_armed != armed
	if changed:
		place_armed = armed
		place_armed_changed.emit(place_armed)
	# 武装变化或重复同步时都重绘选中格，保证角标与 place_armed 一致。
	if not selected.is_empty() and cells.has(selected):
		_apply_cell_style(cells[selected], true, place_armed)
	_refresh_tooltips()


## 触屏：点在某格中心即选中（与背篓 press_at 同思路）
func press_at(screen_point: Vector2) -> bool:
	for kind: String in SLOT_ORDER:
		var cell: Button = cells[kind]
		if cell.get_global_rect().has_point(screen_point):
			if cell.disabled:
				return true
			_on_slot_pressed(kind)
			return true
	return false


## 合入方布局：贴在底部按钮行上方，不遮挡 action / 背篓芯片
static func preferred_rect(viewport: Vector2, compact: bool) -> Rect2:
	var width := SLOT_ORDER.size() * SLOT + (SLOT_ORDER.size() - 1) * GAP + PAD * 2.0
	var height := SLOT + PAD * 2.0
	var bottom_row := viewport.y - 124.0 if compact else viewport.y - 68.0
	var left := (viewport.x - width) * 0.5
	var top := bottom_row - height - 8.0
	return Rect2(Vector2(left, top), Vector2(width, height))
