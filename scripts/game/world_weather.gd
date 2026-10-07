extends RefCounted
## One persisted regional weather episode. Time is active game seconds, not wall time.
const DAY_SECONDS := 600.0
const MIN_EPISODE := DAY_SECONDS * 0.5
const MAX_EPISODE := DAY_SECONDS * 3.0
var state: Dictionary = {}

static func sanitize(raw: Variant) -> Dictionary:
	if not raw is Dictionary: return {}
	if typeof(raw.get("remaining")) not in [TYPE_INT, TYPE_FLOAT]: return {}
	for key: String in ["seed", "episode"]:
		if typeof(raw.get(key)) not in [TYPE_INT, TYPE_FLOAT]: return {}
		var number := float(raw[key])
		if not is_finite(number) or number != floor(number) or number < 0 or number > 2147483646: return {}
	var remaining := float(raw.get("remaining", -1.0))
	var seed_value := int(raw.get("seed", 0))
	var episode := int(raw.get("episode", -1))
	if not raw.get("weather") is String or raw.weather not in ["sun", "overcast"]: return {}
	if not is_finite(remaining) or remaining <= 0.0 or remaining > MAX_EPISODE: return {}
	if seed_value <= 0 or seed_value > 2147483646 or episode < 0: return {}
	return {"weather":str(raw.weather), "remaining":remaining, "seed":seed_value, "episode":episode}

func restore(raw: Variant) -> void:
	state = sanitize(raw)
	if not state.is_empty(): return
	state = {"weather":"sun", "remaining":MIN_EPISODE, "seed":randi_range(1,2147483646), "episode":0}
	_roll(false)

func _roll(choose_weather: bool = true) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(state.seed) ^ int(state.episode)
	if choose_weather: state.weather = "sun" if rng.randf() < 0.5 else "overcast"
	state.remaining = rng.randf_range(MIN_EPISODE, MAX_EPISODE)

func advance(seconds: float) -> bool:
	if not is_finite(seconds) or seconds <= 0.0: return false
	var before := str(state.weather)
	while seconds >= float(state.remaining):
		seconds -= float(state.remaining)
		state.episode = int(state.episode) + 1
		_roll()
	state.remaining = float(state.remaining) - seconds
	return str(state.weather) != before

func select(weather: String) -> void:
	if weather not in ["sun", "overcast"]: return
	state.episode = int(state.episode) + 1
	_roll(false)
	state.weather = weather

func snapshot() -> Dictionary:
	return state.duplicate(true)
