class_name BoundaryFeedback
extends RefCounted

## REQ-20261003-024: unreachable-tap mark alpha/radius.
## Under reduced motion keep a fixed readable alpha until the cue ends.
static func pose(remaining: float, reduced_motion: bool) -> Dictionary:
	remaining = maxf(0.0, remaining)
	if remaining <= 0.0:
		return {"alpha": 0.0, "radius": 12.0}
	if reduced_motion:
		return {"alpha": 0.80, "radius": 12.0}
	return {
		"alpha": minf(1.0, remaining / 0.35) * 0.80,
		"radius": 12.0,
	}
