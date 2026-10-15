class_name UiInteractionAudio
extends RefCounted
## GROK #704: light UI interaction cues for basket / album / pause.
## Registers into AudioDirector; does not add a parallel player or browser bypass.
## game.pause stays empty so set_game_paused does not double-fire with these hooks.
## Missing/failed cue load: quiet degrade only — never ProceduralSfx.tone fallback
## (unapproved tones are outside locked 08/09/10 hearing hashes).

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
# 成功送出的关闭音次数。面板已隐藏时的清理不得增加。
var close_cue_count := 0


func ensure_registered() -> void:
	if _registered:
		return
	_registered = true
	_register(CUE_OPEN, OPEN_PATH)
	_register(CUE_CLOSE, CLOSE_PATH)
	_register(CUE_PAGE, PAGE_PATH)


func play_open() -> bool:
	return _play(CUE_OPEN)


func play_close() -> bool:
	var played := _play(CUE_CLOSE)
	if played:
		close_cue_count += 1
	return played


func play_page() -> bool:
	return _play(CUE_PAGE)


## Test-only: attempt register of an explicit path (missing-asset negative checks).
func try_register_path(cue_id: String, resource_path: String) -> void:
	_register(cue_id, resource_path)


# --script 套件在自动加载注册前编译本文件，不能直接写 AudioDirector 全局名。
func _director() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	return tree.root.get_node("AudioDirector")


func _register(cue_id: String, resource_path: String) -> void:
	var audio: Node = _director()
	if bool(audio.call("register_cue", cue_id, resource_path)):
		return
	# Quiet degrade: resource missing/failed load — do NOT install ProceduralSfx.tone.
	# Unapproved substitute tones are outside user-approved 08/09/10 locked hashes.
	return


func _play(cue_id: String) -> bool:
	ensure_registered()
	var now := Time.get_ticks_msec() * 0.001
	if now - _last_play_at < MIN_GAP:
		return false
	# Unlock attempt does not block UI when gesture is still pending.
	var audio: Node = _director()
	audio.call("unlock_audio")
	var ok: bool = bool(audio.call("play_cue", cue_id))
	if ok:
		_last_play_at = now
	return ok
