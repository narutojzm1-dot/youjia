extends RefCounted
## Producer's first playable tuning, not user-specified quantities/timing.
## Both work types share one executable-material draw and one actor owner.
const IDLE_SECONDS := 12.0
const POND_RECIPE := {"ap":1,"stones":1,"experience":1,"seconds":12.0}
const MILL_RECIPE := {"ap":1,"wheat":1,"flour":1,"experience":1,"seconds":12.0}
## #700 / PR801 producer tuning; not inherited as a user-specified pond cost.
const STOVE_RECIPE := {"ap":1,"stones":1,"experience":1,"seconds":16.0}
const GARDEN_RECIPE := {"ap":1,"seeds":1,"experience":1,"seconds":12.0}
# Match the existing small flower-bed pace; no offline awards or extra AP/XP.
const GARDEN_BLOOM_DAYS := 3
const ORDER := ["rim_04","rim_05","rim_06","rim_07","rim_00","rim_01","rim_02","rim_03"]
const STATIONS := {"rim_04":Vector2(480,545),"rim_05":Vector2(560,535),"rim_06":Vector2(755,525)}

static func period(fraction: float) -> String:
	if not is_finite(fraction) or fraction < 0.0 or fraction >= 1.0: return ""
	# Holiday day starts at 06:00; AP remains usable between meal windows.
	if fraction < 0.25: return "breakfast"
	if fraction < 0.5: return "lunch"
	return "dinner"

static func station(section: String) -> Vector2:
	# Only the accessible bank gets a station; never make the actor walk on water
	# or remotely finish an inaccessible arc. Further arcs need authored routes.
	return STATIONS.get(section, Vector2(INF,INF))
