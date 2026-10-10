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

static func tint(fraction: float, palette: Dictionary, weather: String = "sun") -> Color:
	var h := hour(fraction)
	var hours := [0.0, 3.0, 5.0, 6.0, 8.0, 11.0, 14.0, 17.0, 19.0, 20.0, 22.0, 24.0]
	var keys := ["midnight", "midnight", "night", "dawn", "morning", "noon", "noon", "afternoon", "evening", "night", "night", "midnight"]
	var strengths := [0.90, 0.90, 0.80, 0.32, 0.08, 0.0, 0.0, 0.14, 0.34, 0.80, 0.80, 0.90]
	for i in range(hours.size() - 1):
		if h < hours[i + 1]:
			var a := _key_color(keys[i], strengths[i], palette, weather)
			var b := _key_color(keys[i + 1], strengths[i + 1], palette, weather)
			var weight: float = smoothstep(hours[i], hours[i + 1], h)
			return a.lerp(b, weight)
	return Color.TRANSPARENT

static func _key_color(key: String, strength: float, palette: Dictionary, weather: String) -> Color:
	var color: Color = palette.get(key, palette["night"])
	# The painted overcast/rain backdrop should not acquire a sunny orange wash.
	if weather != "sun" and key in ["dawn", "morning", "afternoon", "evening"]:
		color = Color(0.67, 0.72, 0.80)
		strength *= 0.35
	color.a = strength
	return color
