class_name ResidentBarks
extends RefCounted
## GROK #703: catalog + cooldown/dedupe for picture-book resident barks.
## Presentation-only; no SaveStore fields. Fatigue trigger waits for Leader.

const BARK_CHICK_EGGS := "chick_eggs_hope"
const BARK_PLANT_SOWN := "plant_sown"
const BARK_FATIGUE := "fatigue_sleepy"

const I18N_KEYS := {
	BARK_CHICK_EGGS: "bark.chick_eggs_hope",
	BARK_PLANT_SOWN: "bark.plant_sown",
	BARK_FATIGUE: "bark.fatigue_sleepy",
}

## Global floor between any two barks (seconds).
const GLOBAL_COOLDOWN := 8.0
## Per-id floor so the same line does not spam (seconds).
const PER_ID_COOLDOWN := {
	BARK_CHICK_EGGS: 45.0,
	BARK_PLANT_SOWN: 12.0,
	BARK_FATIGUE: 60.0,
}
## Chance when near a chick and otherwise eligible (0..1).
const CHICK_CHANCE := 0.22
## Minimum seconds between chick proximity *dice rolls* (not every render frame).
const CHICK_PROBE_INTERVAL := 2.5
## How long a shown bark stays up (seconds).
const DISPLAY_SECONDS := 3.6

var _last_global_at := -INF
var _last_id_at: Dictionary = {}
var _last_chick_probe_at := -INF
var _rng := RandomNumberGenerator.new()


func _init(seed_value: int = 0) -> void:
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()


func reset() -> void:
	_last_global_at = -INF
	_last_id_at.clear()
	_last_chick_probe_at = -INF


func i18n_key(bark_id: String) -> String:
	return str(I18N_KEYS.get(bark_id, ""))


func can_offer(bark_id: String, now: float, busy: bool) -> bool:
	if busy:
		return false
	if not I18N_KEYS.has(bark_id):
		return false
	if now - _last_global_at < GLOBAL_COOLDOWN:
		return false
	var per := float(PER_ID_COOLDOWN.get(bark_id, GLOBAL_COOLDOWN))
	if now - float(_last_id_at.get(bark_id, -INF)) < per:
		return false
	return true


## Occasional chick bark. Rolls at most once per CHICK_PROBE_INTERVAL while near chick.
func try_chick_proximity(now: float, busy: bool, force: bool = false) -> String:
	if not force:
		if now - _last_chick_probe_at < CHICK_PROBE_INTERVAL:
			return ""
		_last_chick_probe_at = now
	if not can_offer(BARK_CHICK_EGGS, now, busy):
		return ""
	if not force and _rng.randf() > CHICK_CHANCE:
		return ""
	return _accept(BARK_CHICK_EGGS, now)


func try_plant_sown(now: float, busy: bool) -> String:
	if not can_offer(BARK_PLANT_SOWN, now, busy):
		return ""
	return _accept(BARK_PLANT_SOWN, now)


## Leader fatigue interface: call only with a real fatigue flag from growth state.
## Does not infer overnight / missed sleep.
func try_fatigue(now: float, busy: bool, fatigue_active: bool) -> String:
	if not fatigue_active:
		return ""
	if not can_offer(BARK_FATIGUE, now, busy):
		return ""
	return _accept(BARK_FATIGUE, now)


func _accept(bark_id: String, now: float) -> String:
	_last_global_at = now
	_last_id_at[bark_id] = now
	return bark_id
