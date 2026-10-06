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
## REQ-20261006-039: the shutter line ("旅人随手拍下了这一刻。") floated straight
## on the live yard. On portrait phones it sat over the dark roof timbers, and on
## short landscape screens it ran across the target hint's text. A small warm
## paper slip now sits behind the line, fitted to the text, and fades with it.
const SHUTTER_INK := Color("5b4637")
const SHUTTER_PAPER := Color(1.0, 0.965, 0.91, 0.94) # PAPER fff6e8, nearly opaque
const SHUTTER_EDGE := Color(0.953, 0.698, 0.478, 0.6) # APRICOT f3b27a
const SHUTTER_PAD_X := 14.0
const SHUTTER_PAD_Y := 3.0
## REQ-20261006-046: the print's caption ("Holiday day N" + the moment line) is a
## 192×56 box on the paper strip under the photo. 51 of 81 English captions
## (27 lines × day 1/12/365) and 6 Chinese ones wrap to three lines: at 13px that
## is 66px, so the text spilt 5px past both box edges, sat low against the bottom
## of the print and often left one word ("pond.") alone on the last line.
## When the caption does not fit, tighten its line spacing and, if still needed,
## drop to 12px; when it wraps, narrow and centre the box to the narrowest width
## that keeps the same line count so the lines balance. Captions that already
## fit unwrapped keep the original box, size and spacing.
const CAPTION_RECT := Rect2(24, 227, 192, 56)
const CAPTION_FONT_SIZE := 13
const CAPTION_SMALL_FONT_SIZE := 12
const CAPTION_TIGHT_LINE_SPACING := 0
const CAPTION_BALANCE_MIN_WIDTH := 96.0
const CAPTION_BALANCE_SLACK := 2.0

var _card: Control
var _mat: ColorRect
var _frame: TextureRect
var _picture: PhotoMoment
var _caption: Label
var _shutter: Label
var _shutter_paper: Panel
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
	_caption.position = CAPTION_RECT.position
	_caption.size = CAPTION_RECT.size
	_caption.add_theme_color_override("font_color", Color("5b4637"))
	_caption.add_theme_font_size_override("font_size", CAPTION_FONT_SIZE)
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(_caption)
	_shutter = Label.new()
	_shutter.name = "ShutterCaption"
	_shutter.add_theme_color_override("font_color", SHUTTER_INK)
	_shutter.add_theme_color_override("font_outline_color", Color(1.0, 0.98, 0.91, 0.95))
	_shutter.add_theme_constant_override("outline_size", 3)
	_shutter.add_theme_font_size_override("font_size", 16)
	_shutter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shutter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_shutter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shutter)
	# Child of the line so it shares its position and fade; drawn behind the text.
	_shutter_paper = Panel.new()
	_shutter_paper.name = "ShutterPaper"
	_shutter_paper.show_behind_parent = true
	_shutter_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shutter_paper.add_theme_stylebox_override("panel", shutter_paper_style())
	_shutter.add_child(_shutter_paper)
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
	_fit_shutter_paper()


static func shutter_paper_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = SHUTTER_PAPER
	style.border_color = SHUTTER_EDGE
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.anti_aliasing = true
	return style


## Paper slip rect inside the shutter label: as wide as the text plus padding
## (never wider than the label), as tall as one line plus padding, centred.
static func shutter_paper_rect(label_size: Vector2, text_size: Vector2) -> Rect2:
	var width := minf(label_size.x, ceilf(text_size.x) + SHUTTER_PAD_X * 2.0)
	var height := minf(label_size.y, ceilf(text_size.y) + SHUTTER_PAD_Y * 2.0)
	return Rect2((label_size - Vector2(width, height)) * 0.5, Vector2(width, height))


func _fit_shutter_paper() -> void:
	if _shutter_paper == null:
		return
	var font := _shutter.get_theme_font("font")
	var font_size := _shutter.get_theme_font_size("font_size")
	var text_size := Vector2.ZERO
	if font != null and not _shutter.text.is_empty():
		text_size = font.get_string_size(_shutter.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	_shutter_paper.visible = text_size.x > 0.0
	var rect := shutter_paper_rect(_shutter.size, text_size)
	_shutter_paper.position = rect.position
	_shutter_paper.size = rect.size


func _on_viewport_resized() -> void:
	if visible and not _snapshot.is_empty():
		_layout(get_viewport_rect().size)


func refresh_locale() -> void:
	if _snapshot.is_empty():
		return
	_caption.text = PhotoDiary.caption(_snapshot)
	_fit_caption()
	_shutter.text = I18n.t("photo.arrival.shutter")
	_fit_shutter_paper()


## REQ-20261006-046: keep the caption inside its 192×56 slot and avoid a lone
## last word. See CAPTION_RECT. Line counts come from the TextServer (same
## breaking rule as AUTOWRAP_WORD_SMART), not from the Label's cached size.
func _fit_caption() -> void:
	_caption.add_theme_font_size_override("font_size", CAPTION_FONT_SIZE)
	_caption.remove_theme_constant_override("line_spacing")
	var font := _caption.get_theme_font("font")
	var spacing := _caption.get_theme_constant("line_spacing")
	var fit := caption_fit(_caption.text, font, spacing)
	if int(fit.font_size) != CAPTION_FONT_SIZE:
		_caption.add_theme_font_size_override("font_size", int(fit.font_size))
	if int(fit.line_spacing) != spacing:
		_caption.add_theme_constant_override("line_spacing", int(fit.line_spacing))
	var width := float(fit.width)
	_caption.position = Vector2(CAPTION_RECT.position.x + (CAPTION_RECT.size.x - width) * 0.5, CAPTION_RECT.position.y)
	# The autowrap minimum height depends on the width, and the cached minimum is
	# from the previous text/width; apply the width, refresh, then the height.
	_caption.size = Vector2(width, CAPTION_RECT.size.y)
	_caption.update_minimum_size()
	_caption.size = Vector2(width, CAPTION_RECT.size.y)


## {font_size, line_spacing, width} for a caption in the CAPTION_RECT slot.
static func caption_fit(text: String, font: Font, default_spacing: int) -> Dictionary:
	var result := {"font_size": CAPTION_FONT_SIZE, "line_spacing": default_spacing, "width": CAPTION_RECT.size.x}
	if text.is_empty() or font == null:
		return result
	var slot := CAPTION_RECT.size
	var paragraphs := text.split("\n").size()
	var lines := caption_line_count(text, font, CAPTION_FONT_SIZE, slot.x)
	if caption_height(font, CAPTION_FONT_SIZE, default_spacing, lines) <= slot.y:
		if lines <= paragraphs:
			return result # Fits unwrapped: original box, size and spacing.
	else:
		result.line_spacing = CAPTION_TIGHT_LINE_SPACING
		if caption_height(font, CAPTION_FONT_SIZE, CAPTION_TIGHT_LINE_SPACING, lines) > slot.y:
			result.font_size = CAPTION_SMALL_FONT_SIZE
			lines = caption_line_count(text, font, CAPTION_SMALL_FONT_SIZE, slot.x)
			if caption_height(font, CAPTION_SMALL_FONT_SIZE, default_spacing, lines) <= slot.y:
				result.line_spacing = default_spacing
	var font_size := int(result.font_size)
	if lines <= paragraphs:
		return result
	# Balance: the narrowest width that keeps the same number of lines.
	var lo := CAPTION_BALANCE_MIN_WIDTH
	var hi := slot.x
	if caption_line_count(text, font, font_size, lo) <= lines:
		hi = lo
	while hi - lo > 1.0:
		var mid := (lo + hi) * 0.5
		if caption_line_count(text, font, font_size, mid) <= lines:
			hi = mid
		else:
			lo = mid
	result.width = minf(slot.x, ceilf(hi) + CAPTION_BALANCE_SLACK)
	return result


static func caption_height(font: Font, font_size: int, spacing: int, lines: int) -> float:
	if lines <= 0:
		return 0.0
	return (font.get_height(font_size) + spacing) * lines - spacing


## Line count under the AUTOWRAP_WORD_SMART rule, counting manual \n breaks.
static func caption_line_count(text: String, font: Font, font_size: int, width: float) -> int:
	if text.is_empty() or font == null:
		return 0
	var ts := TextServerManager.get_primary_interface()
	var total := 0
	for para: String in text.split("\n"):
		var shaped := ts.create_shaped_text()
		ts.shaped_text_add_string(shaped, para, font.get_rids(), font_size)
		var breaks := ts.shaped_text_get_line_breaks(shaped, width, 0, TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE)
		ts.free_rid(shaped)
		total += maxi(1, breaks.size() / 2)
	return total


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
