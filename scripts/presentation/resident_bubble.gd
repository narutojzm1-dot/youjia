class_name ResidentBubble
extends Control
## GROK #703: single picture-book bubble above the traveler.
## Ignores mouse so walk / drag / buttons stay free. One line at a time.

const PAPER := Color("fff6e8")
const EDGE := Color("cfab79")
const INK := Color("5b4637")
const MAX_WIDTH := 280.0
const PAD := Vector2(14, 10)
const HEAD_LIFT := 118.0

var _panel: PanelContainer
var _label: Label
var _token := 0
var _anchor_world := Vector2.ZERO
var _follow: Callable = Callable()
var _remain := 0.0
var _suppressed := false
var avoid_rect := Rect2()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 40
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(PAPER.r, PAPER.g, PAPER.b, 0.92)
	style.border_color = EDGE
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = PAD.x
	style.content_margin_right = PAD.x
	style.content_margin_top = PAD.y
	style.content_margin_bottom = PAD.y
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", INK)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_label)
	visible = false
	set_process(true)


func is_showing() -> bool:
	return visible and _remain > 0.0 and not _suppressed


func set_suppressed(value: bool) -> void:
	_suppressed = value
	if value:
		dismiss()


func dismiss() -> void:
	_token += 1
	_remain = 0.0
	_follow = Callable()
	visible = false


## Show one bark. Replaces any current line (one-at-a-time).
func show_bark(text: String, world_anchor: Vector2, duration: float = ResidentBarks.DISPLAY_SECONDS, follow: Callable = Callable()) -> void:
	if text.is_empty():
		return
	_token += 1
	_label.text = text
	_anchor_world = world_anchor
	_follow = follow
	_remain = maxf(0.8, duration)
	_suppressed = false
	visible = true
	_fit_and_place()


func _process(delta: float) -> void:
	if not visible:
		return
	if _suppressed:
		visible = false
		return
	if _follow.is_valid():
		var next: Variant = _follow.call()
		if next is Vector2:
			_anchor_world = next
	_remain = maxf(0.0, _remain - delta)
	if _remain <= 0.0:
		dismiss()
		return
	_fit_and_place()


func _fit_and_place() -> void:
	if _label == null or _panel == null:
		return
	_panel.visible = true
	# 不用 Control.get_parent_area_size：Godot 4.7 已有同名原生方法，脚本覆盖会被当成错误。
	var parent_size := _bark_host_size()
	if parent_size == Vector2.ZERO and get_viewport() != null:
		parent_size = get_viewport().get_visible_rect().size
	var max_w := minf(MAX_WIDTH, maxf(120.0, parent_size.x - 24.0))
	_label.custom_minimum_size = Vector2(max_w - PAD.x * 2.0, 0.0)
	_label.size = Vector2.ZERO
	var panel_size := _panel.get_combined_minimum_size()
	panel_size.x = minf(max_w, maxf(panel_size.x, 80.0))
	_panel.size = panel_size
	var screen := _world_to_screen(_anchor_world + Vector2(0.0, -HEAD_LIFT))
	var pos := screen - Vector2(panel_size.x * 0.5, panel_size.y + 8.0)
	pos.x = clampf(pos.x, 8.0, maxf(8.0, parent_size.x - panel_size.x - 8.0))
	pos.y = clampf(pos.y, 8.0, maxf(8.0, parent_size.y - panel_size.y - 8.0))
	# Confirmed sow can speak while its modal remains open. Keep the note and
	# buttons readable; return to the traveler as soon as the modal closes.
	if avoid_rect.has_area() and Rect2(pos, panel_size).intersects(avoid_rect.grow(8.0)):
		var above := avoid_rect.position.y - panel_size.y - 8.0
		var below := avoid_rect.end.y + 8.0
		if above >= 8.0:
			pos.y = above
		elif below + panel_size.y <= parent_size.y - 8.0:
			pos.y = below
		else:
			# A modal can briefly fill the viewport during deferred relayout.
			# Hide the card for that frame, keeping only the current line's
			# original lifetime (no queue or new duration when space returns).
			_panel.visible = false
			return
	position = pos
	size = panel_size


func _world_to_screen(world: Vector2) -> Vector2:
	var viewport := get_viewport()
	if viewport == null:
		return world
	return viewport.get_canvas_transform() * world


func _bark_host_size() -> Vector2:
	var p := get_parent()
	if p is Control:
		return (p as Control).size
	if get_viewport() != null:
		return get_viewport().get_visible_rect().size
	return Vector2.ZERO
