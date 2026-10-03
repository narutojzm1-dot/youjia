class_name BoundaryFeedback
extends RefCounted

# REQ-024: low motion keeps the unreachable-tap mark readable without a late fade.
static func pose(remaining: float, reduced_motion: bool) -> Dictionary:
	remaining = maxf(0.0, remaining)
	if reduced_motion:
		return {"alpha": 0.80, "radius": 12.0}
	return {
		"alpha": minf(1.0, remaining / 0.35) * 0.80,
		"radius": 12.0,
	}
