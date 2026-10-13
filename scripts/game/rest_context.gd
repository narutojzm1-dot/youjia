extends RefCounted
## Provenance of the current game morning, committed with the world clock.
## Legacy saves have no evidence of a missed night; never infer offline fatigue.
const FIELD := "resident_rest"
const Contract := preload("res://scripts/exploration/exploration_contract.gd")
const MAX_DAY := 2147483647

static func read(snapshot: Dictionary) -> Dictionary:
	var day: Variant = Contract.as_int(snapshot.get("holiday_day", 1), 1, MAX_DAY)
	if day == null: return {}
	if not snapshot.has(FIELD): return {"schema": 1, "day": int(day), "cause": "legacy"}
	var raw: Variant = snapshot[FIELD]
	if not raw is Dictionary or raw.size() != 3 or not raw.has_all(["schema", "day", "cause"]): return {}
	if Contract.as_int(raw.schema, 1, 1) == null or Contract.as_int(raw.day, 1, MAX_DAY) != day: return {}
	if raw.cause not in ["legacy", "sleep", "awake"]: return {}
	return {"schema": 1, "day": int(day), "cause": raw.cause}

static func advance(snapshot: Dictionary, next_day: int, slept: bool) -> Dictionary:
	var state := read(snapshot)
	if state.is_empty() or next_day < int(state.day) or next_day > MAX_DAY: return {}
	if next_day == int(state.day): return state
	return {"schema": 1, "day": next_day, "cause": "sleep" if slept else "awake"}

static func fatigued(state: Dictionary) -> bool:
	return state.get("cause", "") == "awake"

## Legacy native setters explicitly assign a clock (including test/tool rewind).
## Keep their old bounds contract without leaving a mismatched rest day or
## clearing fatigue on rewind. The production queued clock stays monotonic.
static func assign_clock(snapshot: Dictionary, next_day: int) -> Dictionary:
	var state := read(snapshot)
	if state.is_empty() or next_day < 1 or next_day > MAX_DAY: return {}
	if next_day > int(state.day): return advance(snapshot, next_day, false)
	state.day = next_day
	return state

## For future autonomous work only; do not change player movement or ambience.
static func work_speed(state: Dictionary) -> float:
	if state.is_empty(): return 0.0
	return 0.5 if fatigued(state) else 1.0
