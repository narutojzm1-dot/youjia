extends RefCounted
## Atomic queue-head transition. An old night can never grant another morning.
const Weather := preload("res://scripts/game/world_weather.gd")
const Daylight := preload("res://scripts/game/world_daylight.gd")
const Rest := preload("res://scripts/game/rest_context.gd")
const DAY := 600.0

static func finish(current: Dictionary, night: Dictionary) -> Variant:
	var day := int(night.get("holiday_day", 0))
	var elapsed := float(night.get("holiday_day_elapsed", -1.0))
	if day < 1 or not is_finite(elapsed) or elapsed < 0.0 or elapsed >= DAY: return false
	if Daylight.phase(elapsed / DAY) != "night": return false
	var confirmed_day := int(current.get("holiday_day", 1))
	if confirmed_day > day: return current.duplicate(true)
	if confirmed_day == day and float(current.get("holiday_day_elapsed", 0.0)) > elapsed: return false
	var climate := Weather.sanitize(night.get("world_weather", {}))
	if climate.is_empty(): return false
	var rest := Rest.advance(current, day + 1, true)
	if rest.is_empty(): return false
	var next := current.duplicate(true)
	next[Rest.FIELD] = rest
	for key: String in ["plant_state", "plant_day_planted", "plant_watered_day"]:
		next[key] = night.get(key, current.get(key, 0))
	next.holiday_day = day + 1
	next.holiday_day_elapsed = 0.0
	var scheduler := Weather.new()
	scheduler.restore(climate)
	scheduler.advance(DAY - elapsed)
	next.world_weather = scheduler.snapshot()
	if int(next.plant_state) == 1 and day + 1 >= int(next.plant_day_planted) + 1:
		next.plant_state = 2
	elif int(next.plant_state) == 2 and day + 1 >= int(next.plant_day_planted) + 3 and int(next.plant_watered_day) >= int(next.plant_day_planted):
		next.plant_state = 3
	return next
