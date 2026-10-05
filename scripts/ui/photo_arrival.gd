class_name PhotoArrival
extends Control

signal tucked_away

const POLAROID := preload("res://assets/holiday/ui/polaroid_frame.png")
const CARD_SIZE := Vector2(240, 300)
## The "shutter" caption sits this far above the card's top edge (34px label + 12px gap).
const SHUTTER_GAP := 46.0
const SHUTTER_HEIGHT := 34.0
## Minimum clearance from every screen edge when the print has to be scaled down.
const VIEW_MARGIN := 8.0
const MIN_FIT_SCALE := 0.5
## REQ-20261006-037: the polaroid texture has a transparent window (texture px
## 24..338 × 24..341 of 360×448) that is larger than the 184×184 picture. Over
## the live yard the gap showed the scene (house, notices) as a ring around the
## photo. A paper mat fills the window under the frame; it is inflated a few
## texture px so its edges tuck under the opaque border.
const FRAME_WINDOW_TEXELS := Rect2(20, 20, 322, 325)
const MAT_COLOR := Color("f3e3cb")

var _card: Control
var _mat: ColorRect
var _frame: TextureRect
var _picture: PhotoMoment
var _caption: Label
var _shutter: Label
var _tween: Tween
var _snapshot: Dictionary = {}
var _presentation_duration := 0.0
var _motion_static := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card = Control.new()
	_card.name = "PhotoCard"
	_card.size = CARD_SIZE
	_card.pivot_offset = CARD_SIZE * 0.5
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card)
	_mat = ColorRect.new()
	_mat.name = "PhotoMat"
	_mat.color = MAT_COLOR
	var mat_rect := mat_rect_in_card(CARD_SIZE)
	_mat.position = mat_rect.position
	_mat.size = mat_rect.size
	_mat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(_mat)
	_frame = TextureRect.new()
	_frame.name = "Frame"
	_frame.texture = POLAROID
	_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_frame.size = CARD_SIZE
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(_frame)
	_picture = PhotoMoment.new()
	_picture.name = "Picture"
	_picture.position = Vector2(28, 28)
	_picture.size = Vector2(184, 184)
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(_picture)
	_caption = Label.new()
	_caption.name = "Caption"
	_caption.position = Vector2(24, 227)
	_caption.size = Vector2(192, 56)
	_caption.add_theme_color_override("font_color", Color("5b4637"))
	_caption.add_theme_font_size_override("font_size", 13)
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(_caption)
	_shutter = Label.new()
	_shutter.name = "ShutterCaption"
	_shutter.add_theme_color_override("font_color", Color("5b4637"))
	_shutter.add_theme_color_override("font_outline_color", Color(1.0, 0.98, 0.91, 0.95))
	_shutter.add_theme_constant_override("outline_size", 3)
	_shutter.add_theme_font_size_override("font_size", 16)
	_shutter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shutter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shutter)
	visible = false
	get_node("/root/TuningStore").value_changed.connect(_on_motion_changed)
	get_viewport().size_changed.connect(_on_viewport_resized)


func play(snapshot: Dictionary, reduced_motion: bool) -> bool:
	var valid := PhotoMoment.sanitize(snapshot)
	if valid.is_empty():
		return false
	dismiss()
	_snapshot = valid
	_picture.setup(valid)
	refresh_locale()
	_layout(get_viewport_rect().size)
	_card.modulate.a = 1.0
	_shutter.modulate.a = 1.0
	visible = true
	_motion_static = reduced_motion
	_presentation_duration = 1.6 if reduced_motion else 1.58
	if reduced_motion:
		_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_tween.tween_interval(1.6)
		_tween.tween_callback(_finish)
		return true
	_card.modulate.a = 0.0
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(_card, "modulate:a", 1.0, 0.20)
	_tween.tween_interval(1.10)
	_tween.tween_property(_card, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(_shutter, "modulate:a", 0.0, 0.24)
	_tween.tween_callback(_finish)
	return true


func _on_motion_changed(id: String, _requested: Variant, active: Variant) -> void:
	if id != "ui.reduced_motion" or active != true or _motion_static or not visible or _tween == null:
		return
	var remaining := maxf(0.0, _presentation_duration - _tween.get_total_elapsed_time())
	_tween.kill()
	_tween = null
	_motion_static = true
	_card.modulate.a = 1.0
	_shutter.modulate.a = 1.0
	if remaining <= 0.0:
		_finish()
		return
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_interval(remaining)
	_tween.tween_callback(_finish)


## REQ-20261005-033: on short landscape screens (e.g. 568×320, 640×300) the
## centred 240×300 print touched the edges and its shutter caption sat above
## the top of the screen. When the full-size stack (caption + card) fits with
## VIEW_MARGIN, keep the original centred full-size layout; otherwise scale the
## card around its centre and centre the caption+card stack on screen.
static func fit_layout(viewport: Vector2) -> Dictionary:
	var center := viewport * 0.5
	var shutter_width := minf(360.0, viewport.x - 24.0)
	var shutter_x := maxf(12.0, (viewport.x - 360.0) * 0.5)
	var full_top := center.y - CARD_SIZE.y * 0.5
	if full_top - SHUTTER_GAP >= VIEW_MARGIN and CARD_SIZE.x + VIEW_MARGIN * 2.0 <= viewport.x:
		return {
			"scale": 1.0,
			"card_position": center - CARD_SIZE * 0.5,
			"shutter_position": Vector2(shutter_x, full_top - SHUTTER_GAP),
			"shutter_size": Vector2(shutter_width, SHUTTER_HEIGHT),
		}
	var fit := minf((viewport.y - VIEW_MARGIN * 2.0 - SHUTTER_GAP) / CARD_SIZE.y, (viewport.x - VIEW_MARGIN * 2.0) / CARD_SIZE.x)
	fit = clampf(fit, MIN_FIT_SCALE, 1.0)
	var visual := CARD_SIZE * fit
	var stack_top := maxf(VIEW_MARGIN, (viewport.y - SHUTTER_GAP - visual.y) * 0.5)
	var visual_top := stack_top + SHUTTER_GAP
	# The card scales around pivot_offset (its centre): visual top-left = position + pivot * (1 - scale).
	var pivot := CARD_SIZE * 0.5
	return {
		"scale": fit,
		"card_position": Vector2(center.x - visual.x * 0.5, visual_top) - pivot * (1.0 - fit),
		"shutter_position": Vector2(shutter_x, stack_top),
		"shutter_size": Vector2(shutter_width, SHUTTER_HEIGHT),
	}


## Where FRAME_WINDOW_TEXELS lands inside a card of `card_size` when the frame
## texture is drawn with STRETCH_KEEP_ASPECT_CENTERED (same rule as _frame).
static func mat_rect_in_card(card_size: Vector2) -> Rect2:
	var texture_size := Vector2(POLAROID.get_width(), POLAROID.get_height())
	var factor := minf(card_size.x / texture_size.x, card_size.y / texture_size.y)
	var offset := (card_size - texture_size * factor) * 0.5
	return Rect2(offset + FRAME_WINDOW_TEXELS.position * factor, FRAME_WINDOW_TEXELS.size * factor)


func _layout(viewport: Vector2) -> void:
	var fit := fit_layout(viewport)
	var factor := float(fit.scale)
	_card.pivot_offset = CARD_SIZE * 0.5
	_card.scale = Vector2(factor, factor)
	_card.position = fit.card_position
	_shutter.position = fit.shutter_position
	_shutter.size = fit.shutter_size


func _on_viewport_resized() -> void:
	if visible and not _snapshot.is_empty():
		_layout(get_viewport_rect().size)


func refresh_locale() -> void:
	if _snapshot.is_empty():
		return
	_caption.text = PhotoDiary.caption(_snapshot)
	_shutter.text = I18n.t("photo.arrival.shutter")


func dismiss() -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
	_tween = null
	visible = false
	_snapshot.clear()


func _finish() -> void:
	visible = false
	_snapshot.clear()
	_tween = null
	tucked_away.emit()
