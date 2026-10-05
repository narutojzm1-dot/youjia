class_name PhotoArrival
extends Control

signal tucked_away

const POLAROID := preload("res://assets/holiday/ui/polaroid_frame.png")
const CARD_SIZE := Vector2(240, 300)

var _card: Control
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


func play(snapshot: Dictionary, reduced_motion: bool) -> bool:
	var valid := PhotoMoment.sanitize(snapshot)
	if valid.is_empty():
		return false
	dismiss()
	_snapshot = valid
	_picture.setup(valid)
	refresh_locale()
	var viewport := get_viewport_rect().size
	var center := viewport * 0.5
	_card.position = center - CARD_SIZE * 0.5
	_card.scale = Vector2.ONE
	_card.modulate.a = 1.0
	_shutter.position = Vector2(maxf(12.0, (viewport.x - 360.0) * 0.5), _card.position.y - 46.0)
	_shutter.size = Vector2(minf(360.0, viewport.x - 24.0), 34)
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
