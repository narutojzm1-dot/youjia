extends Control
signal close_requested
signal preview_changed(spot: String, entry: Dictionary)
signal action_requested(action: String, spot: String, details: Dictionary)
signal retry_requested
const Model := preload("res://scripts/inventory/yard_decor.gd")
const PaperScrollbarStyle := preload("res://scripts/ui/paper_scrollbar_style.gd")
var paper: PanelContainer
var outer: VBoxContainer
var column: VBoxContainer
var scroll: ScrollContainer
var status: Label
var close_button: Button
var confirm_button: Button
var remove_button: Button
var retry_button: Button
var buttons: Array[Button] = []
var slot_buttons: Dictionary = {}
var find_buttons: Dictionary = {}
var nudge_buttons: Array[Button] = []
var selected := "house_edge"
var draft: Dictionary = {}
var value: Dictionary = {}
var counts: Dictionary = {}
var busy := false
var state := "idle"
var _touch := -1
var _start := Vector2.ZERO
var _dragged := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	paper = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fff6e8")
	style.set_corner_radius_all(12)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	paper.add_theme_stylebox_override("panel", style)
	add_child(paper)
	outer = VBoxContainer.new()
	paper.add_child(outer)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_color_override("font_color", Color("5b4637"))
	outer.add_child(status)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	# REQ-20261007-058：与大背篓同一套纸面滚动条
	PaperScrollbarStyle.apply(scroll.get_v_scroll_bar())
	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	var slots := HBoxContainer.new()
	column.add_child(slots)
	var names := ["屋前", "篱边", "塘边小路"]
	for i in Model.SPOTS.size():
		var spot: String = Model.SPOTS.keys()[i]
		slot_buttons[spot] = button(slots, names[i], func() -> void: choose_spot(spot))
		slot_buttons[spot].toggle_mode = true
	var finds := HBoxContainer.new()
	column.add_child(finds)
	for id: String in ExplorationRoutes.FINDS:
		find_buttons[id] = button(finds, "", func() -> void: choose_find(id))
	var nudges := HBoxContainer.new()
	column.add_child(nudges)
	for direction: Vector2i in NUDGE_DIRECTIONS:
		var label: String = ["←", "→", "↑", "↓"][nudge_buttons.size()]
		nudge_buttons.append(button(nudges, label, func() -> void: nudge(direction)))
	var actions := HBoxContainer.new()
	column.add_child(actions)
	confirm_button = button(actions, "确认摆好", commit)
	remove_button = button(actions, "收回背篓", func() -> void: action_requested.emit("remove", selected, {}))
	retry_button = button(column, "再确认保存", func() -> void: retry_requested.emit())
	close_button = button(outer, "取消预览 · 回到背篓", func() -> void: close_requested.emit())
	resized.connect(fit)
	fit()

# REQ-20261007-054: the chosen place (a pressed toggle) and an unavailable
# button used to share one fill, so "House" selected looked exactly like
# "Cone ×0" greyed out. Each state now reads on its own.
const BUTTON_STATES := {
	"normal": {"fill": Color("fffaf1"), "edge": Color("b88a61"), "width": 1, "ink": Color("5b4637")},
	"hover": {"fill": Color("ffe7c8"), "edge": Color("b88a61"), "width": 1, "ink": Color("3d2d23")},
	"pressed": {"fill": Color("f3d3ae"), "edge": Color("5b4637"), "width": 2, "ink": Color("3d2d23")},
	"hover_pressed": {"fill": Color("f3d3ae"), "edge": Color("5b4637"), "width": 2, "ink": Color("3d2d23")},
	"disabled": {"fill": Color("f3e9db"), "edge": Color("bfa588"), "width": 1, "ink": Color("7a6152")},
}
const FOCUS_EDGE := Color("916d49")
const NUDGE_DIRECTIONS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

# REQ-20261007-060: an arrow that cannot move the preview any further (the
# offset is already at the model's ±1 step) used to stay lit; tapping it did
# nothing and gave no sign the edge was reached. It now greys out there.
func can_nudge(direction: Vector2i) -> bool:
	if busy or draft.is_empty(): return false
	var dx := int(draft.get("dx", 0))
	var dy := int(draft.get("dy", 0))
	return clampi(dx + direction.x, -1, 1) != dx or clampi(dy + direction.y, -1, 1) != dy

static func state_style(mode: String) -> StyleBoxFlat:
	var spec: Dictionary = BUTTON_STATES[mode]
	var style := StyleBoxFlat.new()
	style.bg_color = spec.fill
	style.border_color = spec.edge
	style.set_border_width_all(int(spec.width))
	style.set_corner_radius_all(8)
	# Same content margins in every state, so a 2px selected edge never resizes the row.
	style.set_content_margin_all(1)
	return style

static func focus_style() -> StyleBoxFlat:
	var ring := StyleBoxFlat.new()
	ring.draw_center = false
	ring.border_color = FOCUS_EDGE
	ring.set_border_width_all(2)
	ring.set_corner_radius_all(10)
	ring.set_expand_margin_all(2.0)
	return ring

func button(parent: Node, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(44, 44)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 16)
	for mode: String in BUTTON_STATES:
		b.add_theme_stylebox_override(mode, state_style(mode))
		b.add_theme_color_override("font_" + ("" if mode == "normal" else mode + "_") + "color", BUTTON_STATES[mode].ink)
	b.add_theme_stylebox_override("focus", focus_style())
	b.add_theme_color_override("font_focus_color", BUTTON_STATES.normal.ink)
	b.pressed.connect(action)
	parent.add_child(b)
	buttons.append(b)
	return b

# REQ-20261007-055: the paper used to always take its whole allowance (the full
# screen height in landscape), so on a 1280x720 window the five rows sat at the
# top and the close button at the bottom with ~420px of blank paper between.
# It now hugs its rows; only when they don't fit does it stop at the old
# allowance and scroll exactly as before.
func fit() -> void:
	if paper == null: return
	var landscape := size.x > size.y
	var width := minf(310, size.x * 0.48) if landscape else size.x - 16
	var allowance := size.y - 16 if landscape else minf(320, size.y * 0.48)
	var height := minf(allowance, content_height(width))
	paper.size = Vector2(width, height)
	paper.position = Vector2(size.x - paper.size.x - 8, 8) if landscape else Vector2(8, size.y - paper.size.y - 8)

func content_height(width: float) -> float:
	var frame := paper.get_theme_stylebox("panel").get_minimum_size()
	# Wrap the status line at the width it will really get before measuring it.
	status.size = Vector2(maxf(1.0, width - frame.x), status.size.y)
	var gap := float(outer.get_theme_constant("separation"))
	var rows := status.get_combined_minimum_size().y + column.get_combined_minimum_size().y + close_button.get_combined_minimum_size().y
	return ceilf(frame.y + rows + gap * 2.0)

func preview_rect() -> Rect2:
	return Rect2(8, 8, paper.position.x - 16, size.y - 16) if size.x > size.y else Rect2(8, 8, size.x - 16, paper.position.y - 16)

func update_view(next: Dictionary, available: Dictionary, next_state: String, waiting: bool) -> void:
	value = next
	counts = available
	state = next_state
	busy = waiting
	if busy: draft.clear()
	elif value.get("places", {}).has(selected): draft = value.places[selected].duplicate(true)
	refresh()

func choose_spot(spot: String) -> void:
	if busy: return
	selected = spot
	draft = value.get("places", {}).get(spot, {}).duplicate(true)
	refresh()

func choose_find(id: String) -> void:
	if busy or value.get("places", {}).has(selected) or int(counts.get(id, 0)) == 0: return
	draft = {"find_id": id, "dx": 0, "dy": 0}
	refresh()

func nudge(direction: Vector2i) -> void:
	if not can_nudge(direction): return
	draft.dx = clampi(int(draft.dx) + direction.x, -1, 1)
	draft.dy = clampi(int(draft.dy) + direction.y, -1, 1)
	refresh()

func commit() -> void:
	if busy or draft.is_empty(): return
	if value.get("places", {}).has(selected): action_requested.emit("move", selected, {"dx": draft.dx, "dy": draft.dy})
	else: action_requested.emit("place", selected, draft.duplicate(true))

func refresh() -> void:
	if status == null: return
	var en := I18n.get_locale() == "en"
	status.text = "Choose a place and a find. The faded item is a preview." if en else "选一处，再选小物；半透明的是预览。"
	if busy: status.text = "Checking the save. Your arrangement is kept." if en else "正在确认保存，原有摆设保留着。"
	if state in ["failed", "unknown", "blocked"]: status.text = "Not confirmed yet. Your items are kept." if en else "这次还未确认保存，原有物品保留着。"
	var occupied: bool = value.get("places", {}).has(selected)
	var unchanged: bool = occupied and draft == value.places[selected]
	if unchanged and not busy: status.text = "Use the arrows to adjust, or put it back." if en else "用箭头稍微挪动，也可收回背篓。"
	var empty_hint := empty_basket_hint(en)
	if empty_hint != "" and not occupied and draft.is_empty() and not busy and not (state in ["failed", "unknown", "blocked"]): status.text = empty_hint
	var places := {"house_edge": "House" if en else "屋前", "fence_edge": "Fence" if en else "篱边", "pond_path": "Path" if en else "塘边小路"}
	for spot: String in slot_buttons:
		slot_buttons[spot].text = places[spot]
		slot_buttons[spot].disabled = busy or value.is_empty()
		slot_buttons[spot].button_pressed = spot == selected
	var names := ["Stone", "Cone", "Feather"] if en else ["圆石", "松果", "落羽"]
	for i in ExplorationRoutes.FINDS.size():
		var id: String = ExplorationRoutes.FINDS[i]
		find_buttons[id].text = "%s ×%d" % [names[i], int(counts.get(id, 0))]
		find_buttons[id].disabled = busy or occupied or int(counts.get(id, 0)) <= 0
	for i in nudge_buttons.size(): nudge_buttons[i].disabled = not can_nudge(NUDGE_DIRECTIONS[i])
	confirm_button.disabled = busy or draft.is_empty() or unchanged
	confirm_button.text = "Place" if en else "确认摆好"
	remove_button.text = "Put back" if en else "收回背篓"
	remove_button.disabled = busy or not occupied
	retry_button.visible = state in ["failed", "unknown"]
	retry_button.text = "Check save again" if en else "再确认保存"
	close_button.text = "Back to basket" if en else "回到背篓"
	if not draft.is_empty() and not unchanged: close_button.text = "Cancel preview · Back" if en else "取消预览 · 回到背篓"
	preview_changed.emit(selected, draft)
	call_deferred("fit")

# REQ-20261007-062: with nothing left to place, an empty spot used to say
# "pick a place, then a find" while every find button read ×0 and was grey, so
# the panel asked for something the player could not do. It now says why and
# what to do instead: go out for finds, or adjust the ones already placed.
func empty_basket_hint(en: bool) -> String:
	if value.is_empty(): return ""
	for id: String in ExplorationRoutes.FINDS:
		if int(counts.get(id, 0)) > 0: return ""
	if not value.get("places", {}).is_empty():
		return "All your finds are placed. Tap one on the ground to pick it up, or choose a filled place to nudge it." if en else "小物都摆出去了。点地上的小物就能捡回背篓，也可以选已摆好的地方挪动。"
	return "No finds yet. Choose \"Take a walk outside\" on the path by the gate, then come back." if en else "背篓里还没有小物；去门前小路「出门走走」，捡到圆石、松果或落羽再来摆。"

func handle_touch_event(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch == -1:
			_touch = event.index
			_start = event.position
			_dragged = false
		elif not event.pressed and event.index == _touch:
			_touch = -1
			if not _dragged and event.position.distance_to(_start) < 12:
				for b: Button in buttons:
					if b.is_visible_in_tree() and not b.disabled and b.get_global_rect().has_point(event.position):
						if b != close_button and not scroll.get_global_rect().has_point(event.position): continue
						b.pressed.emit()
						break
	elif event is InputEventScreenDrag and event.index == _touch:
		if event.position.distance_to(_start) >= 12: _dragged = true
		if _dragged and scroll.get_global_rect().has_point(_start): scroll.scroll_vertical -= int(event.relative.y)

## 布置镜头中心：所选位置尽量落在预览区中央，视野尽量不越出院子画面。
## 冲突时依次保证：所选位置在预览区内 > 预览区全是院子 > 整个画面都是院子。
static func camera_center(spot: Vector2, viewport_size: Vector2, preview: Rect2, zoom: float, world_size: Vector2, margin: float = 48.0) -> Vector2:
	var center := spot + (viewport_size * 0.5 - preview.get_center()) / zoom
	var half := viewport_size * 0.5 / zoom
	for axis in 2:
		var mid := viewport_size[axis] * 0.5
		if half[axis] * 2.0 >= world_size[axis]:
			center[axis] = world_size[axis] * 0.5
		else:
			center[axis] = clampf(center[axis], half[axis], world_size[axis] - half[axis])
		var preview_lo := (mid - preview.position[axis]) / zoom
		var preview_hi := world_size[axis] - (preview.end[axis] - mid) / zoom
		if preview_lo <= preview_hi:
			center[axis] = clampf(center[axis], preview_lo, preview_hi)
		var inset := minf(margin, preview.size[axis] * 0.5)
		var lo := spot[axis] - (preview.end[axis] - inset - mid) / zoom
		var hi := spot[axis] - (preview.position[axis] + inset - mid) / zoom
		center[axis] = clampf(center[axis], lo, hi)
	return center
