class_name PondStorySequence
extends RefCounted

# Transient choreography only. Resident identities belong to WorldResidents;
# this sequence never creates animals, grants inventory or advances saved time.
const COOLDOWN := 180.0
const APPROACH_TIMEOUT := 24.0
const DURATIONS := {"greet": 3.0, "ride": 7.0, "dismount": 2.0,
	"refuse": 2.5, "peck_attempt": 1.2}
var phase := "idle"
var elapsed := 0.0
var cooldown := 30.0
var encounter := 0

func active() -> bool:
	return phase != "idle"

func cancel() -> Dictionary:
	var was_active := active()
	phase = "idle"
	elapsed = 0.0
	if was_active: cooldown = COOLDOWN
	return {"phase": phase, "release": was_active, "encounter": encounter}

func tick(delta: float, context: Dictionary) -> Dictionary:
	if not is_finite(delta) or delta <= 0.0: return _view()
	# An inactive tab/pause freezes choreography and cooldown; no offline progress.
	if bool(context.get("paused", false)): return _view()
	var residents_ready := bool(context.get("turtle_present", false)) \
		and str(context.get("chicken_stage", "")) == "hen" \
		and bool(context.get("goose_present", false))
	if active() and (not residents_ready or not bool(context.get("owns_participants", false)) \
		or bool(context.get("interrupted", false))):
		return cancel()
	if not active():
		cooldown = maxf(0.0, cooldown - delta)
		if cooldown > 0.0 or not residents_ready or not bool(context.get("available", false)):
			return _view()
		phase = "approach_hen"
		elapsed = 0.0
		encounter += 1
		return _view()
	# Each reached pose remains visible for its full duration. Large frame gaps
	# cannot skip directly through the entire story or count approach as arrival.
	elapsed += minf(delta, 0.25)
	if phase in ["approach_hen", "approach_goose", "retreat"]:
		# The goose may stroll from the opposite side of the lawn at its
		# ordinary 13 px/s pace. Do not rush or teleport it to meet a timer.
		if elapsed >= (90.0 if phase == "approach_goose" else APPROACH_TIMEOUT): return cancel()
		var arrival_key := "hen_arrived" if phase == "approach_hen" else "goose_arrived" if phase == "approach_goose" else "turtle_home"
		if bool(context.get(arrival_key, false)):
			if phase == "retreat": return cancel()
			phase = "greet" if phase == "approach_hen" else "refuse"
			elapsed = 0.0
	elif elapsed >= float(DURATIONS.get(phase, INF)):
		var next := {"greet": "ride", "ride": "dismount", "dismount": "approach_goose",
			"refuse": "peck_attempt", "peck_attempt": "retreat"}
		phase = str(next[phase])
		elapsed = 0.0
	return _view()

func _view() -> Dictionary:
	return {"phase": phase, "release": false, "encounter": encounter}
