class_name PaperSliderStyle
extends RefCounted

## REQ-20261006-040: the pause page's two volume sliders used Godot's default
## theme — a flat grey bar with a tiny near-white dot for the handle — the only
## un-themed control on the warm paper panel. On PAPER the grey bar reads like
## a disabled control and the white dot nearly vanishes.
##
## Applied to every HSlider as it enters the tree by `autoload/paper_slider_boot.gd`
## (the same node_added pattern as ManusFontTheme), so `scripts/main.gd` is not
## edited. Visual only: value range, step, size, focus mode, mouse filter,
## signals, Main._input touch/drag routing (#382) and the focus ring (#459) are
## untouched; the slider rect used for hit testing stays the same.

## Unfilled track: light warm paper with a soft-brown 1px edge (≥3:1 on PAPER).
const TRACK_FILL := Color("eadcc8")
const TRACK_EDGE := Color("9c7f68")
## Filled part up to the handle, same deep apricot as the title accent (4.6:1 on PAPER).
const FILL := Color("a85d28")
const FILL_HOVER := Color("94501f")
## Handle: cream disc with an accent ring; hover/drag darkens the ring to ink.
const GRABBER_FILL := Color("fffaf1")
const GRABBER_HOVER_FILL := Color("ffe7c8")
const GRABBER_RING := Color("a85d28")
const GRABBER_HOVER_RING := Color("5b4637")
const GRABBER_DISABLED_FILL := Color("f3e9db")
const GRABBER_DISABLED_RING := Color("bfa588")
const TRACK_HALF_HEIGHT := 4
const GRABBER_SIZE := 24
const GRABBER_RING_WIDTH := 2.5


static func apply(slider: Slider) -> void:
	slider.add_theme_stylebox_override("slider", _bar(TRACK_FILL, TRACK_EDGE, 1))
	slider.add_theme_stylebox_override("grabber_area", _bar(FILL, FILL, 0))
	slider.add_theme_stylebox_override("grabber_area_highlight", _bar(FILL_HOVER, FILL_HOVER, 0))
	slider.add_theme_icon_override("grabber", grabber(GRABBER_FILL, GRABBER_RING))
	slider.add_theme_icon_override("grabber_highlight", grabber(GRABBER_HOVER_FILL, GRABBER_HOVER_RING))
	slider.add_theme_icon_override("grabber_disabled", grabber(GRABBER_DISABLED_FILL, GRABBER_DISABLED_RING))


static func _bar(fill: Color, edge: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(width)
	style.set_corner_radius_all(TRACK_HALF_HEIGHT)
	style.content_margin_top = TRACK_HALF_HEIGHT
	style.content_margin_bottom = TRACK_HALF_HEIGHT
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.anti_aliasing = true
	return style


## Vector disc so it stays crisp when Web HiDPI raises content_scale_factor (REQ-20261005-026).
static func grabber(fill: Color, ring: Color) -> Texture2D:
	var s := float(GRABBER_SIZE)
	var r := s * 0.5 - GRABBER_RING_WIDTH * 0.5
	var svg := "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"%d\" height=\"%d\" viewBox=\"0 0 %d %d\"><circle cx=\"%s\" cy=\"%s\" r=\"%s\" fill=\"#%s\" stroke=\"#%s\" stroke-width=\"%s\"/></svg>" % [
		GRABBER_SIZE, GRABBER_SIZE, GRABBER_SIZE, GRABBER_SIZE,
		str(s * 0.5), str(s * 0.5), str(r),
		fill.to_html(false), ring.to_html(false), str(GRABBER_RING_WIDTH)]
	return DPITexture.create_from_string(svg)
