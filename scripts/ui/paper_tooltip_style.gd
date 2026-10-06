extends RefCounted

## REQ-20261006-041: hovering the album chip with a mouse showed Godot's default
## tooltip — a half-transparent black box (alpha 0.5) with light-grey text. Over
## the cream HUD that box reads as a grey smudge and the text sits about 3.2:1;
## it is the only un-themed popup left on the paper UI.
##
## Installed on the shared runtime Theme by `autoload/manus_font_theme.gd`
## (the Theme already reaches every root Control and the tooltip label), so
## `scripts/main.gd` is not edited. Visual only: tooltip text, delay, placement
## and which controls have tooltips are untouched.

## Near-opaque warm paper (same PAPER as Main) so the yard never shows through.
const PANEL_FILL := Color(1.0, 0.964706, 0.909804, 0.97) # fff6e8 @ 0.97
## Soft-brown 1px edge, the same tone as the slider track edge (≥3:1 on PAPER).
const PANEL_EDGE := Color("9c7f68")
## Faint ink shadow so the slip lifts off a cream button below it.
const PANEL_SHADOW := Color(0.356863, 0.27451, 0.215686, 0.18) # 5b4637 @ 0.18
const PANEL_RADIUS := 8
const PANEL_MARGIN_X := 10
const PANEL_MARGIN_Y := 5
## Main.INK on PAPER is ~8:1.
const TEXT := Color("5b4637")


static func apply(theme: Theme) -> void:
	theme.set_stylebox("panel", "TooltipPanel", panel())
	theme.set_color("font_color", "TooltipLabel", TEXT)
	theme.set_color("font_shadow_color", "TooltipLabel", Color(0, 0, 0, 0))
	theme.set_color("font_outline_color", "TooltipLabel", Color(0, 0, 0, 0))
	theme.set_constant("outline_size", "TooltipLabel", 0)
	theme.set_constant("shadow_offset_x", "TooltipLabel", 0)
	theme.set_constant("shadow_offset_y", "TooltipLabel", 0)


static func panel() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_FILL
	style.border_color = PANEL_EDGE
	style.set_border_width_all(1)
	style.set_corner_radius_all(PANEL_RADIUS)
	style.shadow_color = PANEL_SHADOW
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	style.content_margin_left = PANEL_MARGIN_X
	style.content_margin_right = PANEL_MARGIN_X
	style.content_margin_top = PANEL_MARGIN_Y
	style.content_margin_bottom = PANEL_MARGIN_Y
	style.anti_aliasing = true
	return style
