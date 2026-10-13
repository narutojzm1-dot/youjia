class_name ResidentBarks
extends RefCounted
## GROK #703: catalog + cooldown/dedupe for picture-book resident barks.
## Presentation-only; no SaveStore fields. Fatigue trigger waits for Leader.

const BARK_CHICK_EGGS := "chick_eggs_hope"
const BARK_PLANT_SOWN := "plant_sown"
const BARK_FATIGUE := "fatigue_sleepy"
const BARK_GROWTH := "growth_completed"

const I18N_KEYS := {
	BARK_CHICK_EGGS: "bark.chick_eggs_hope",
	BARK_PLANT_SOWN: "bark.plant_sown",
	BARK_FATIGUE: "bark.fatigue_sleepy",
	BARK_GROWTH: "bark.growth_completed",
}

## Global floor between any two barks (seconds). Plant success bypasses this
## so a chick idle line cannot swallow a confirmed sow (ART #718 / Leader).
const GLOBAL_COOLDOWN := 8.0
## Per-id floor so the same line does not spam (seconds).
const PER_ID_COOLDOWN := {
	BARK_CHICK_EGGS: 45.0,
	BARK_PLANT_SOWN: 12.0,
	BARK_FATIGUE: 60.0,
	BARK_GROWTH: 12.0,
}
## Chance when near a chick and otherwise eligible (0..1).
const CHICK_CHANCE := 0.22
## Settle / detection throttle after entering proximity before the single roll.
const CHICK_PROBE_INTERVAL := 2.5
## How long a shown bark stays up (seconds).
const DISPLAY_SECONDS := 3.6

var _last_global_at := -INF
var _last_id_at: Dictionary = {}
var _last_chick_probe_at := -INF
## Continuous-near encounter: at most one roll until leave (Main applies leave margin).
var _chick_near := false
var _chick_encounter_spent := false
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
	_chick_near = false
	_chick_encounter_spent = false


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


## Confirmed plant success: ignore global cooldown left by idle chick chat.
## Still respects hard busy and plant per-id dedupe.
func can_offer_plant(now: float, hard_blocked: bool) -> bool:
	if hard_blocked:
		return false
	if not I18N_KEYS.has(BARK_PLANT_SOWN):
		return false
	var per := float(PER_ID_COOLDOWN.get(BARK_PLANT_SOWN, GLOBAL_COOLDOWN))
	if now - float(_last_id_at.get(BARK_PLANT_SOWN, -INF)) < per:
		return false
	return true


## Occasional chick bark. One roll per continuous near stretch (`near` must go
## false—after Main leave margin—before another chance). Miss or accept both spend.
func try_chick_proximity(now: float, busy: bool, near: bool = true, force: bool = false) -> String:
	if force:
		if not can_offer(BARK_CHICK_EGGS, now, busy):
			return ""
		return _accept(BARK_CHICK_EGGS, now)

	if not near:
		_chick_near = false
		_chick_encounter_spent = false
		return ""

	# Soft/hard busy while near: do not start settle or spend; leave clears via near=false.
	if busy:
		return ""

	if not _chick_near:
		_chick_near = true
		_chick_encounter_spent = false
		_last_chick_probe_at = now

	if _chick_encounter_spent:
		return ""
	if now - _last_chick_probe_at < CHICK_PROBE_INTERVAL:
		return ""

	_chick_encounter_spent = true
	_last_chick_probe_at = now
	if not can_offer(BARK_CHICK_EGGS, now, false):
		return ""
	if _rng.randf() > CHICK_CHANCE:
		return ""
	return _accept(BARK_CHICK_EGGS, now)


func try_plant_sown(now: float, hard_blocked: bool) -> String:
	if not can_offer_plant(now, hard_blocked):
		return ""
	return _accept(BARK_PLANT_SOWN, now)


## Only offered by a newly confirmed production transaction, never by loading.
func try_growth_completed(now: float, blocked: bool) -> String:
	if not can_offer(BARK_GROWTH, now, blocked): return ""
	return _accept(BARK_GROWTH, now)


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
