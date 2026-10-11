class_name MealAudio
extends Node
## GROK #745: room cooking audio + missed-meal hunger leaf.
## Owns one cook loop player. Spoon / hunger go through AudioDirector cues.
## Leader supplies real cook start/end and missed-meal trigger; this leaf does not infer mealtime.

const COOK_LOOP_PATH := "res://assets/holiday/audio/meal_grok/cook_loop.tres"
const SPOON_PATH := "res://assets/holiday/audio/meal_grok/cook_spoon.tres"
const HUNGER_PATH := "res://assets/holiday/audio/meal_grok/hunger.tres"

const CUE_SPOON := "meal.spoon"
const CUE_HUNGER := "meal.hunger"

## Soft spoon interval while cooking (seconds). Tests can call play_spoon_now().
const SPOON_INTERVAL := 3.2
const HUNGER_MIN_GAP := 0.35

var _cooking := false
var _paused := false
var _registered := false
var _cook_player: AudioStreamPlayer
var _spoon_accum := 0.0
var _last_hunger_at := -INF
## Successful hunger cue deliveries (headless play_cue truth counts).
var hunger_play_count := 0
## Successful spoon cue deliveries.
var spoon_play_count := 0


func _ready() -> void:
	_ensure_cook_player()
	ensure_registered()
	_apply()


func _process(delta: float) -> void:
	if not _cooking or _paused:
		_spoon_accum = 0.0
		return
	_spoon_accum += delta
	if _spoon_accum >= SPOON_INTERVAL:
		_spoon_accum = 0.0
		play_spoon_now()


func ensure_registered() -> void:
	if _registered:
		return
	_registered = true
	_register(CUE_SPOON, SPOON_PATH, 310.0)
	_register(CUE_HUNGER, HUNGER_PATH, 62.0)


## Start / stop cooking loop. Same value is a no-op (no second player, no restart).
func set_cooking(active: bool) -> void:
	if _cooking == active:
		return
	_cooking = active
	if not active:
		_spoon_accum = 0.0
	_apply()


## Pause stops cook loop and spoon ticks; cooking flag unchanged. Idempotent.
func set_paused(paused: bool) -> void:
	if _paused == paused:
		return
	_paused = paused
	if paused:
		_spoon_accum = 0.0
	_apply()


## Missed-meal hunger short cue. Leader calls when real hunger state fires.
func play_hunger() -> bool:
	ensure_registered()
	var now := Time.get_ticks_msec() * 0.001
	if now - _last_hunger_at < HUNGER_MIN_GAP:
		return false
	var audio: Node = _director()
	audio.call("unlock_audio")
	var ok: bool = bool(audio.call("play_cue", CUE_HUNGER))
	if ok:
		_last_hunger_at = now
		hunger_play_count += 1
	return ok


## Optional spoon tap (also used by the cooking timer). Public for suites.
func play_spoon_now() -> bool:
	if not _cooking or _paused:
		return false
	ensure_registered()
	var audio: Node = _director()
	audio.call("unlock_audio")
	var ok: bool = bool(audio.call("play_cue", CUE_SPOON))
	if ok:
		spoon_play_count += 1
	return ok


func is_cooking() -> bool:
	return _cooking


func is_paused() -> bool:
	return _paused


func is_cook_playing() -> bool:
	_ensure_cook_player()
	return _cook_player.playing and not _cook_player.stream_paused


func debug_snapshot() -> Dictionary:
	_ensure_cook_player()
	return {
		"cooking": _cooking,
		"paused": _paused,
		"cook_playing": is_cook_playing(),
		"child_players": _count_cook_players(),
		"hunger_play_count": hunger_play_count,
		"spoon_play_count": spoon_play_count,
		"registered": _registered,
	}


func _apply() -> void:
	_ensure_cook_player()
	var should := _cooking and not _paused
	if should:
		if _cook_player.stream == null:
			_cook_player.stream = _load_cook_stream()
		if not _cook_player.playing:
			_cook_player.stream_paused = false
			_cook_player.play()
		else:
			_cook_player.stream_paused = false
	else:
		# Stop is idempotent; do not free the player (repeat true must not stack nodes).
		if _cook_player.playing or _cook_player.stream_paused:
			_cook_player.stop()
		_cook_player.stream_paused = false


func _ensure_cook_player() -> void:
	if _cook_player != null and is_instance_valid(_cook_player):
		return
	# Tear accidental extras so repeated ensure never stacks players.
	for child in get_children():
		if child is AudioStreamPlayer and child.name.begins_with("MealCook"):
			child.queue_free()
	_cook_player = AudioStreamPlayer.new()
	_cook_player.name = "MealCookLoop"
	_cook_player.bus = "SFX"
	_cook_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_cook_player.stream = _load_cook_stream()
	add_child(_cook_player)


func _count_cook_players() -> int:
	var n := 0
	for child in get_children():
		if child is AudioStreamPlayer and str(child.name).begins_with("MealCook"):
			n += 1
	return n


func _load_cook_stream() -> AudioStream:
	if ResourceLoader.exists(COOK_LOOP_PATH):
		var stream := ResourceLoader.load(COOK_LOOP_PATH) as AudioStream
		if stream != null:
			return stream
	# Procedural fallback if tres missing.
	var ProceduralSfx = load("res://scripts/manus/procedural_sfx.gd")
	if ProceduralSfx == null:
		return null
	return ProceduralSfx.tone(72.0, 0.4, 0.12, 88.0)


# --script suites compile before autoloads; never write AudioDirector as a bare name.
func _director() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	return tree.root.get_node("AudioDirector")


func _register(cue_id: String, resource_path: String, fallback_hz: float) -> void:
	var audio: Node = _director()
	if bool(audio.call("register_cue", cue_id, resource_path)):
		return
	var ProceduralSfx = load("res://scripts/manus/procedural_sfx.gd")
	if ProceduralSfx == null:
		return
	var stream: AudioStream = ProceduralSfx.tone(fallback_hz, 0.16, 0.14, fallback_hz * 0.85)
	audio.call("register_stream", cue_id, stream)
