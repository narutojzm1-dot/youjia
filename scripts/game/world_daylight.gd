extends RefCounted
## Shared local solar time. A saved day begins at 06:00; no second clock.
static func hour(fraction: float) -> float:
	return fposmod(6.0 + fraction * 24.0, 24.0) if is_finite(fraction) else 6.0

static func phase(fraction: float) -> String:
	var h := hour(fraction)
	if h < 5.0 or h >= 20.0: return "night"
	if h < 7.0: return "dawn"
	if h < 11.0: return "morning"
	if h < 14.0: return "noon"
	if h < 18.0: return "afternoon"
	return "evening"

static func daylight(fraction: float) -> float:
	# Sunrise 06:00, overhead noon, sunset 18:00. This is an art direction
	# curve, not a geographical/seasonal astronomical simulation.
	return maxf(0.0, sin((hour(fraction) - 6.0) * PI / 12.0))

static func tint(fraction: float, palette: Dictionary) -> Color:
	var h := hour(fraction)
	var hours := [0.0, 5.0, 6.0, 8.0, 11.0, 14.0, 17.0, 19.0, 20.0, 24.0]
	var keys := ["night", "night", "dawn", "morning", "noon", "noon", "afternoon", "evening", "night", "night"]
	var strengths := [0.32, 0.32, 0.14, 0.08, 0.0, 0.0, 0.14, 0.24, 0.32, 0.32]
	for i in range(hours.size() - 1):
		if h < hours[i + 1]:
			var a: Color = palette[keys[i]]
			var b: Color = palette[keys[i + 1]]
			a.a = strengths[i]
			b.a = strengths[i + 1]
			var weight: float = smoothstep(hours[i], hours[i + 1], h)
			return a.lerp(b, weight)
	return Color.TRANSPARENT
