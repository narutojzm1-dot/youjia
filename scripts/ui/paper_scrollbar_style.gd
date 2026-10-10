extends RefCounted

## REQ-20261007-058: the yard basket list (and the chick care / crop papers)
## scroll inside their warm paper, but their vertical scroll bar kept Godot's default theme —
## a dark grey slab (1a1a1a @ 0.6, which composites to a ~76756c grey strip on
## the fff6e8 paper) with a translucent white thumb. It was the only dark,
## off-palette strip left on those papers, and the thumb told nothing about
## "there is more below" in paper colours.
##
## Visual only: the bar keeps its 8px width (4px content margin each side, the
## same minimum size as the default theme), so rows, buttons, wrapping, touch
## scrolling and tap routing in those panels are untouched.

## Track: the same light warm groove as the pause-page volume slider (#459/040).
const TRACK := Color("eadcc8")
## Thumb: MUTED ink already used for unavailable text (#545); about 3.4:1 on the
## track and 4.3:1 on the fff6e8 paper.
const GRABBER := Color("8a7060")
## Hover darkens one step, dragging goes to the panel ink.
const GRABBER_HOVER := Color("7d6250")
const GRABBER_PRESSED := Color("5b4637")
const HALF_WIDTH := 4
const RADIUS := 4


static func apply(bar: ScrollBar) -> void:
	var track := _bar(TRACK)
	bar.add_theme_stylebox_override("scroll", track)
	# A focused bar used the default near-white slab; keep it the same groove.
	bar.add_theme_stylebox_override("scroll_focus", track)
	bar.add_theme_stylebox_override("grabber", _bar(GRABBER))
	bar.add_theme_stylebox_override("grabber_highlight", _bar(GRABBER_HOVER))
	bar.add_theme_stylebox_override("grabber_pressed", _bar(GRABBER_PRESSED))


static func _bar(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(RADIUS)
	style.set_content_margin_all(HALF_WIDTH)
	style.anti_aliasing = true
	return style
