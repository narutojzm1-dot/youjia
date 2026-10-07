extends RefCounted
## Durable identity of acquired residents. No inventory items or offline clock.
const FIELD := "world_residents"
const Contract := preload("res://scripts/exploration/exploration_contract.gd")
const DAY_SECONDS := 600.0
const GROW_SECONDS := 3.0 * DAY_SECONDS
const MAX_REVISION := 2147483647
const STRAY_STOP := "village_stray"
const TURTLE_STOP := "village_lake"

static func empty() -> Dictionary:
	return {"schema": 3, "revision": 0, "beibei": {"stage": "unmet", "adopted_clock": null}, "turtle": {"stage": "unmet", "found_trip": ""}, "chicken": {"stage": "unmet", "settled_clock": null}}

static func read(snapshot: Dictionary) -> Dictionary:
	if not snapshot.has(FIELD): return empty()
	var raw: Variant = snapshot[FIELD]
	if not raw is Dictionary or not raw.has_all(["schema", "revision", "beibei"]): return {}
	if Contract.as_int(raw.schema, 1, 3) == null or Contract.as_int(raw.revision, 0, MAX_REVISION) == null: return {}
	if raw.size() != int(raw.schema) + 2: return {}
	if int(raw.schema) >= 2:
		var turtle: Variant = raw.get("turtle")
		if not turtle is Dictionary or turtle.size() != 2 or not turtle.has_all(["stage", "found_trip"]): return {}
		if turtle.stage not in ["unmet", "found", "pond"] or not turtle.found_trip is String: return {}
		if turtle.found_trip.length() > 96: return {}
		if (turtle.stage == "unmet") != turtle.found_trip.is_empty(): return {}
	var dog: Variant = raw.beibei
	if not dog is Dictionary or dog.size() != 2 or not dog.has_all(["stage", "adopted_clock"]): return {}
	if dog.stage not in ["unmet", "puppy", "grown"]: return {}
	if dog.stage == "unmet":
		if dog.adopted_clock != null: return {}
	elif _clock_seconds(dog.adopted_clock) < 0.0: return {}
	if int(raw.schema) >= 2 and raw.turtle.stage != "unmet" and dog.stage != "grown": return {}
	if int(raw.schema) == 3:
		var chicken: Variant = raw.get("chicken")
		if not chicken is Dictionary or chicken.size() != 2 or not chicken.has_all(["stage", "settled_clock"]): return {}
		if chicken.stage not in ["unmet", "chick", "hen"]: return {}
		if chicken.stage == "unmet":
			if chicken.settled_clock != null: return {}
		elif _clock_seconds(chicken.settled_clock) < 0.0: return {}
	var result: Dictionary = raw.duplicate(true)
	result.schema = 3
	if not result.has("chicken"): result.chicken = empty().chicken
	if not result.has("turtle"): result.turtle = empty().turtle
	result.revision = int(raw.revision)
	if result.beibei.adopted_clock != null:
		result.beibei.adopted_clock.day = int(result.beibei.adopted_clock.day)
		result.beibei.adopted_clock.elapsed = float(result.beibei.adopted_clock.elapsed)
	if result.chicken.settled_clock != null:
		result.chicken.settled_clock.day = int(result.chicken.settled_clock.day)
		result.chicken.settled_clock.elapsed = float(result.chicken.settled_clock.elapsed)
	return result

## Evaluate at the SaveStore queue head, against its authoritative snapshot.
## Caller cannot provide a future growth clock or invent a rescue location.
static func transition(snapshot: Dictionary, revision: int, action: String) -> Dictionary:
	var residents := read(snapshot)
	if residents.is_empty(): return {"error": "RESIDENT_SOURCE_UNSUPPORTED"}
	if residents.revision != revision: return {"error": "RESIDENT_STALE"}
	if revision >= MAX_REVISION: return {"error": "RESIDENT_LIMIT"}
	var now := {"day": snapshot.get("holiday_day", 1), "elapsed": snapshot.get("holiday_day_elapsed", 0.0)}
	var seconds := _clock_seconds(now)
	if seconds < 0.0: return {"error": "RESIDENT_CLOCK_INVALID"}
	match action:
		"adopt_beibei":
			if residents.beibei.stage != "unmet": return {"error": "RESIDENT_ALREADY_HOME"}
			if not _at_stray(snapshot): return {"error": "RESIDENT_NOT_PRESENT"}
			residents.beibei = {"stage": "puppy", "adopted_clock": now.duplicate(true)}
		"grow_beibei":
			if residents.beibei.stage != "puppy": return {"error": "RESIDENT_NOT_PUPPY"}
			if seconds - _clock_seconds(residents.beibei.adopted_clock) < GROW_SECONDS:
				return {"error": "RESIDENT_NOT_READY"}
			residents.beibei.stage = "grown"
		"settle_chick":
			if residents.chicken.stage != "unmet": return {"error": "RESIDENT_ALREADY_HOME"}
			residents.chicken = {"stage": "chick", "settled_clock": now.duplicate(true)}
		"grow_chicken":
			if residents.chicken.stage != "chick": return {"error": "RESIDENT_NOT_CHICK"}
			if seconds - _clock_seconds(residents.chicken.settled_clock) < GROW_SECONDS: return {"error": "RESIDENT_NOT_READY"}
			residents.chicken.stage = "hen"
		"find_turtle":
			if residents.turtle.stage == "pond": return {"error": "RESIDENT_ALREADY_HOME"}
			if not turtle_encounter(snapshot, residents): return {"error": "RESIDENT_NOT_PRESENT"}
			var trip: String = snapshot.exploration.session.trip_id
			if residents.turtle.stage == "found" and residents.turtle.found_trip == trip: return {"error": "RESIDENT_ALREADY_FOUND"}
			residents.turtle = {"stage": "found", "found_trip": trip}
		"adopt_turtle":
			if residents.turtle.stage == "pond": return {"error": "RESIDENT_ALREADY_HOME"}
			if not turtle_encounter(snapshot, residents): return {"error": "RESIDENT_NOT_PRESENT"}
			if residents.turtle.stage != "found" or residents.turtle.found_trip != snapshot.exploration.session.trip_id:
				return {"error": "RESIDENT_NOT_FOUND"}
			residents.turtle.stage = "pond"
		_:
			return {"error": "RESIDENT_ACTION_INVALID"}
	residents.revision = revision + 1
	var candidate := snapshot.duplicate(true)
	candidate[FIELD] = residents
	return {"candidate": candidate}

static func _clock_seconds(value: Variant) -> float:
	if not value is Dictionary or value.size() != 2 or not value.has_all(["day", "elapsed"]): return -1.0
	if Contract.as_int(value.day, 1) == null or not Contract.is_number(value.elapsed): return -1.0
	var elapsed := float(value.elapsed)
	if not is_finite(elapsed) or elapsed < 0.0 or elapsed >= DAY_SECONDS: return -1.0
	return (int(value.day) - 1) * DAY_SECONDS + elapsed

static func _at_stray(snapshot: Dictionary) -> bool:
	return _at_stop(snapshot, STRAY_STOP)

static func turtle_encounter(snapshot: Dictionary, residents: Dictionary = {}) -> bool:
	if residents.is_empty(): residents = read(snapshot)
	if residents.is_empty() or residents.beibei.stage != "grown" or not _at_stop(snapshot, TURTLE_STOP): return false
	var partner: Variant = snapshot.exploration.session.get("companion", {})
	return partner is Dictionary and partner.get("actor_id", "") == "beibei" and partner.get("mode", "") == "nearby"

static func _at_stop(snapshot: Dictionary, stop: String) -> bool:
	var record: Variant = snapshot.get("exploration")
	if not record is Dictionary: return false
	if Contract.as_int(record.get("contract_version"), 1, Contract.CONTRACT_VERSION) == null: return false
	var session: Variant = record.get("session")
	if not session is Dictionary: return false
	if not Contract.validate_session_structure(session).is_empty() or session.get("catalog") != Contract.SOURCE_FORMAL: return false
	return session.get("state") == Contract.STATE_ACTIVE and session.get("route_id") == ExplorationRoutes.NEAR_PATH \
		and session.get("current_stop") == stop and stop in session.visited
