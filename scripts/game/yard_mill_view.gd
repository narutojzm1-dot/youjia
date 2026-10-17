extends Node2D
## Presentation only. The director owns work, materials and confirmed results.
## No private clock: pause, fatigue and cancellation follow the supplied progress.
## Sprite/Line2D children use the existing frozen-photo contract without a new schema.
const ART := preload("res://assets/holiday/props/millstone_v1/millstone-watercolor-v1.png")
const WIDTH := 90.0
const SOURCE_PIVOT := Vector2(667.5, 1145.0)
const SOURCE_VISIBLE := Rect2(98, 37, 1140, 1108)
# The starting cow occupies the previous preview's (480,495) point. Keep the
# real body between cow and horse, with the player approaching from the front.
const ANCHOR := Vector2(525, 469)
const APPROACH := Vector2(572, 486)
const WORK_POINT := ANCHOR + (Vector2(650,350)-SOURCE_PIVOT)*WIDTH/1335.0
const HANDLE_POINT := ANCHOR + (Vector2(1015,320)-SOURCE_PIVOT)*WIDTH/1335.0
const BODY_RADIUS := Vector2(28, 9)
const OVERCAST_TINT := Color(0.83, 0.87, 0.92)
const SPOUT := Vector2(33.5, -18.4)

var art: Sprite2D
var flour: Line2D
var working := false
var progress := 0.0
var reduced_motion := false

func _init() -> void:
	name = "YardMill"
	position = ANCHOR
	z_as_relative = false
	z_index = roundi(position.y)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	# Contact ink uses ordinary lines so a photograph keeps the same grounding.
	_add_line("ContactSoft", PackedVector2Array([Vector2(-22,-1),Vector2(22,-1)]), 7.0, Color(0.17,0.14,0.10,0.10))
	_add_line("ContactCore", PackedVector2Array([Vector2(-15,-1),Vector2(17,-1)]), 3.4, Color(0.17,0.14,0.10,0.15))
	art = Sprite2D.new()
	art.name = "MillstoneArt"
	art.texture = ART
	art.centered = false
	art.offset = -SOURCE_PIVOT
	art.scale = Vector2.ONE * WIDTH / ART.get_width()
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(art)
	# A few falling flecks indicate the real work phase, never a credited pile.
	flour = _add_line("WorkingFlour", PackedVector2Array([Vector2.ZERO,Vector2(0.2,1.2),Vector2(0.8,2.8)]), 1.0, Color(0.93,0.88,0.73,0.55))
	flour.hide()
	set_process(false)

func _add_line(label: String, points: PackedVector2Array, width: float, color: Color) -> Line2D:
	var line := Line2D.new()
	line.name = label
	line.points = points
	line.width = width
	line.default_color = color
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.antialiased = true
	add_child(line)
	return line

func sync_environment(weather_mix: float, sun_tint: Color = Color.WHITE, rain_tint: Color = Color.WHITE) -> void:
	if not is_finite(weather_mix): return
	var blend := clampf(weather_mix,0.0,1.0)
	modulate = sun_tint.lerp(rain_tint,blend)
	# Day/night remains the parent world's CanvasModulate; do not darken twice.
	art.modulate = Color.WHITE.lerp(OVERCAST_TINT,blend)

func sync_work(active: bool, amount: float, reduced: bool = false) -> void:
	working = active and is_finite(amount)
	progress = clampf(amount,0.0,1.0) if is_finite(amount) else 0.0
	reduced_motion = reduced
	flour.visible = working
	if not working: return
	# Progress already includes the director's production-speed/fatigue multiplier.
	# Low-motion fixes the same small flour cue; the stone itself never rocks/slides.
	var fall := 0.4 if reduced else fposmod(progress * 8.0,1.0)
	flour.position = SPOUT + Vector2(1.5 * fall, 9.0 * fall)
	flour.modulate.a = 0.65 if reduced else lerpf(1.0,0.25,fall)

func local_bounds() -> Rect2:
	var factor := WIDTH / ART.get_width()
	return Rect2((SOURCE_VISIBLE.position-SOURCE_PIVOT)*factor,SOURCE_VISIBLE.size*factor).merge(Rect2(-27,-5,54,9))
