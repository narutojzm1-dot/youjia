extends Label
## A view of the regional solar clock, never another timer or save field.
const Daylight := preload("res://scripts/game/world_daylight.gd")

static func parts(fraction: float) -> Dictionary:
	var minutes := floori(Daylight.hour(fraction) * 60.0 + 0.0000001) % 1440
	var hour24 := floori(float(minutes) / 60.0)
	return {"hour": 12 if hour24 % 12 == 0 else hour24 % 12,
		"minute": minutes % 60, "period": "am" if hour24 < 12 else "pm"}

static func caption(fraction: float, translator: Node) -> String:
	var value := parts(fraction)
	return translator.t("hud.clock." + value.period, {
		"h": str(value.hour), "m": "%02d" % value.minute})

func _init() -> void:
	name = "RegionalClock"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_theme_color_override("font_color", Color("5b4637"))
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color(Color("fff6e8"), 0.90)
	paper.border_color = Color(Color("f3b27a"), 0.65)
	paper.set_border_width_all(1)
	paper.set_corner_radius_all(8)
	paper.content_margin_left = 5
	paper.content_margin_right = 5
	add_theme_stylebox_override("normal", paper)

func show_time(fraction: float, rect: Rect2, font_size: int) -> void:
	var next := caption(fraction, get_node("/root/I18n"))
	if text != next: text = next
	add_theme_font_size_override("font_size", font_size)
	position = rect.position
	size = rect.size
	visible = true
