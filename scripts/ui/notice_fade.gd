extends RefCounted

## REQ-20261008-075: the bottom paper notice used to pop in and vanish in one
## frame. Fade in over FADE_IN seconds and fade out over the last FADE_OUT of
## remaining time. Reduced motion stays fully opaque while the notice is up.
## Timing ownership stays in Main (_notice_time / _notice_age); this only maps
## those to an alpha. Paper colour, ink, size, keys and when notices fire are
## unchanged.

const FADE_IN := 0.20
const FADE_OUT := 0.35


static func alpha(remaining: float, age: float, reduced_motion: bool) -> float:
	remaining = maxf(0.0, remaining)
	if remaining <= 0.0:
		return 0.0
	if reduced_motion:
		return 1.0
	var fade_in := clampf(maxf(0.0, age) / FADE_IN, 0.0, 1.0)
	var fade_out := clampf(remaining / FADE_OUT, 0.0, 1.0)
	return minf(fade_in, fade_out)
