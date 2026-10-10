class_name UiInteractionAudio
extends RefCounted
## GROK #704: light UI interaction cues for basket / album / pause.
## Registers into AudioDirector; does not add a parallel player or browser bypass.
## game.pause stays empty so set_game_paused does not double-fire with these hooks.

const OPEN_PATH := "res://assets/holiday/audio/ui_grok/ui_open.tres"
const CLOSE_PATH := "res://assets/holiday/audio/ui_grok/ui_close.tres"
const PAGE_PATH := "res://assets/holiday/audio/ui_grok/ui_page.tres"

const CUE_OPEN := "ui.confirm"
const CUE_CLOSE := "ui.cancel"
const CUE_PAGE := "ui.page"

## Minimum gap between plays (seconds) to avoid rapid-click stacking.
const MIN_GAP := 0.07

var _last_play_at := -INF
var _registered := false


func ensure_registered() -> void:
	if _registered:
		return
	_registered = true
	_register(CUE_OPEN, OPEN_PATH, 523.25)
	_register(CUE_CLOSE, CLOSE_PATH, 392.0)
	_register(CUE_PAGE, PAGE_PATH, 659.25)


func play_open() -> bool:
	return _play(CUE_OPEN)


func play_close() -> bool:
	return _play(CUE_CLOSE)


func play_page() -> bool:
	return _play(CUE_PAGE)


func _register(cue_id: String, resource_path: String, fallback_hz: float) -> void:
	if AudioDirector.register_cue(cue_id, resource_path):
		return
	# Procedural fallback when the .tres is missing (should not happen in-tree).
	var ProceduralSfx = load("res://scripts/manus/procedural_sfx.gd")
	if ProceduralSfx == null:
		return
	var stream: AudioStream = ProceduralSfx.tone(fallback_hz, 0.09, 0.16, fallback_hz * 0.92)
	AudioDirector.register_stream(cue_id, stream)


func _play(cue_id: String) -> bool:
	ensure_registered()
	var now := Time.get_ticks_msec() * 0.001
	if now - _last_play_at < MIN_GAP:
		return false
	# Unlock attempt does not block UI when gesture is still pending.
	AudioDirector.unlock_audio()
	var ok := AudioDirector.play_cue(cue_id)
	if ok:
		_last_play_at = now
	return ok
