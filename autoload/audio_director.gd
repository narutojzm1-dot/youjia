extends Node

const BrowserBgmPlayer = preload("res://scripts/manus/browser_bgm_player.gd")

const MAX_SFX_VOICES := 8
const MAX_UI_VOICES := 2
# PLAYTEST-20261007: a full ambience slider is 30% of its previous output.
# Keep this authored ceiling separate from the player's 0..1 slider value.
const AMBIENCE_OUTPUT_SCALE := 0.3
const DEFAULT_AMBIENCE_GAIN := 0.5
# Optional resource paths. Empty means intentionally silent; add project audio
# here or call register_cue() after importing an AudioStream resource.
const CUES := {
	"music.title": {"path": "", "kind": "music"},
	"music.gameplay": {"path": "", "kind": "music"},
	"ui.confirm": {"path": "", "bus": "UI"},
	"ui.cancel": {"path": "", "bus": "UI"},
	"ui.page": {"path": "", "bus": "UI"},
	"player.action": {"path": "", "bus": "SFX"},
	"enemy.impact": {"path": "", "bus": "SFX"},
	"score.reward": {"path": "", "bus": "SFX"},
	"game.pause": {"path": "", "bus": "UI"},
	"game.victory": {"path": "", "bus": "SFX"},
	"game.defeat": {"path": "", "bus": "SFX", "kind": "sfx"},
	"yard.ambience": {"path": "res://assets/holiday/audio/bed_yard_env.ogg", "kind": "ambience"},
	"yard.music": {"path": "res://assets/holiday/audio/bed_yard_music.ogg", "kind": "music"},
}

var _streams: Dictionary = {}
var _music_players: Array[BrowserBgmPlayer] = []
var _sfx_players: Array[AudioStreamPlayer] = []
var _ui_players: Array[AudioStreamPlayer] = []
var _music_index := 0
var _music_cue := ""
var _unlocked := false
var _headless := false
var _paused := false
var _music_tween: Tween
var _ambience_player: BrowserBgmPlayer
var _yard_active := false
var _application_active := true
var _music_enabled := true
var _ambience_enabled := true
var _ambience_volume_db := linear_to_db(DEFAULT_AMBIENCE_GAIN)
var _music_gain := 1.0
var _ambience_gain := DEFAULT_AMBIENCE_GAIN
var _epoch := 0
var _awaiting_gesture := false
var _backend_state := "uninitialized"
var _resume_token := 0
var _resume_callback: JavaScriptObject
var _resume_hook_ready := false
var _forced_backend_state := ""
var _music_generation := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_headless = DisplayServer.get_name() == "headless"
	_ensure_buses()
	for index: int in 2:
		var player := BrowserBgmPlayer.new()
		player.name = "Music%d" % index
		player.bus = "Music"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		player.force_loop = true
		add_child(player)
		player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		player.finished.connect(_on_music_finished.bind(player))
		_music_players.append(player)
	_ambience_player = BrowserBgmPlayer.new()
	_ambience_player.name = "Ambience"
	_ambience_player.bus = "Ambience"
	_ambience_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_ambience_player.force_loop = true
	add_child(_ambience_player)
	_ambience_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	_ambience_player.finished.connect(_on_ambience_finished)
	for index: int in MAX_SFX_VOICES:
		_sfx_players.append(_make_player("Sfx%d" % index, "SFX"))
	for index: int in MAX_UI_VOICES:
		_ui_players.append(_make_player("Ui%d" % index, "UI"))
	_load_streams()
	TuningStore.value_changed.connect(_on_tuning_changed)
	_apply_bus_settings()


func _exit_tree() -> void:
	release_streams()


func release_streams() -> void:
	_epoch += 1
	_resume_token += 1
	_yard_active = false
	stop_music(0.0)
	_stop_ambience_immediate()
	for player: AudioStreamPlayer in _sfx_players + _ui_players:
		player.stop()
		player.stream = null
	for stream: AudioStream in _streams.values():
		BrowserBgmPlayer.release_cached_stream(stream)
	_streams.clear()


func register_cue(cue_id: String, resource_path: String) -> bool:
	if not CUES.has(cue_id):
		return false
	# Avoid load() on empty/missing paths. Missing audio is expected.
	if resource_path.is_empty() or not ResourceLoader.exists(resource_path):
		unregister_cue(cue_id)
		return false
	var stream := ResourceLoader.load(resource_path) as AudioStream
	return register_stream(cue_id, stream)


func register_stream(cue_id: String, stream: AudioStream) -> bool:
	if not CUES.has(cue_id):
		return false
	unregister_cue(cue_id)
	if stream == null:
		return false
	_streams[cue_id] = stream
	return true


func unregister_cue(cue_id: String) -> void:
	if cue_id == _music_cue:
		stop_music(0.0)
	var old_stream: AudioStream = _streams.get(cue_id)
	if old_stream != null:
		for players in [_music_players, _sfx_players, _ui_players]:
			for player in players:
				if player.stream == old_stream:
					player.stop()
					player.stream = null
		if _ambience_player != null and _ambience_player.stream == old_stream:
			_stop_ambience_immediate()
		BrowserBgmPlayer.release_cached_stream(old_stream)
	_streams.erase(cue_id)


func unlock_audio() -> bool:
	# Real button/input gesture only. The flag is not proof the browser is audible.
	_unlocked = true
	_awaiting_gesture = false
	_backend_state = _query_backend()
	if not _backend_starts_now(_backend_state):
		_awaiting_gesture = true
	_reconcile()
	return _headless or _backend_state == "native" or _backend_state == "running"


func note_gesture() -> void:
	if not _awaiting_gesture:
		return
	_backend_state = _query_backend()
	if _backend_starts_now(_backend_state):
		_awaiting_gesture = false
		_unlocked = true
		_reconcile()


func set_yard_active(active: bool) -> void:
	if _yard_active == active:
		_reconcile()
		return
	_yard_active = active
	if not active:
		_epoch += 1
		_resume_token += 1
		_awaiting_gesture = false
		stop_music(0.0)
		_stop_ambience_immediate()
		_release_idle_yard_caches()
		return
	_reconcile()


func set_application_active(active: bool) -> void:
	if _application_active == active:
		_reconcile()
		return
	_application_active = active
	if not active:
		_awaiting_gesture = false
	elif _yard_active and _unlocked and not _headless:
		_backend_state = _query_backend()
		# Coming back is not a fresh click. A still-suspended context waits for
		# the resume promise or the next real gesture, and must not look unlocked.
		_awaiting_gesture = _backend_state != "native" and _backend_state != "running"
	_reconcile()


func set_music_enabled(enabled: bool) -> void:
	_music_enabled = enabled
	_reconcile()


func set_ambience_enabled(enabled: bool) -> void:
	_ambience_enabled = enabled
	_reconcile()


func music_enabled() -> bool:
	return _music_enabled


func ambience_enabled() -> bool:
	return _ambience_enabled


func set_music_gain(linear: float) -> void:
	_music_gain = clampf(linear, 0.0, 1.0)
	_apply_bus_settings()


func set_ambience_gain(linear: float) -> void:
	_ambience_gain = clampf(linear, 0.0, 1.0)
	_ambience_volume_db = -80.0 if _ambience_gain <= 0.0 else linear_to_db(_ambience_gain)
	_apply_bus_settings()


func music_gain() -> float:
	return _music_gain


func ambience_gain() -> float:
	return _ambience_gain


func set_ambience_volume_db(volume_db: float) -> void:
	var db := clampf(volume_db, -40.0, 0.0)
	set_ambience_gain(0.0 if db <= -40.0 else db_to_linear(db))


func yard_active() -> bool:
	return _yard_active


func awaiting_gesture() -> bool:
	return _awaiting_gesture


func lifecycle_epoch() -> int:
	return _epoch


func backend_state() -> String:
	return _backend_state


func play_music(cue_id: String, crossfade_seconds: float = 0.35) -> bool:
	var stream: AudioStream = _streams.get(cue_id)
	if stream == null or CUES.get(cue_id, {}).get("kind", "") != "music":
		stop_music(0.0)
		return false
	if not _unlocked and not _headless:
		return false
	var current: BrowserBgmPlayer = _music_players[_music_index]
	if current.stream == stream and (current.playing or _headless):
		_music_cue = cue_id
		return true
	_kill_music_tween()
	var old_player := current
	_music_index = 1 - _music_index
	var next_player: BrowserBgmPlayer = _music_players[_music_index]
	next_player.stop()
	next_player.stream = stream
	next_player.volume_db = -40.0 if old_player.playing else 0.0
	_music_cue = cue_id
	if _headless:
		old_player.stop()
		old_player.stream = null
		return true
	var epoch := _epoch
	var generation := _music_generation
	next_player.play()
	_music_tween = create_tween().set_parallel(true)
	_music_tween.tween_property(next_player, "volume_db", 0.0, maxf(0.0, crossfade_seconds))
	if old_player.playing:
		_music_tween.tween_property(old_player, "volume_db", -40.0, maxf(0.0, crossfade_seconds))
		_music_tween.chain().tween_callback(func() -> void:
			_retire_faded_music(old_player, epoch, generation)
		)
	return true


func stop_music(fade_seconds: float = 0.25) -> void:
	_music_cue = ""
	_music_generation += 1
	_kill_music_tween()
	if fade_seconds <= 0.0 or _headless:
		for player: BrowserBgmPlayer in _music_players:
			player.stop()
			player.stream = null
		return
	var epoch := _epoch
	var generation := _music_generation
	_music_tween = create_tween().set_parallel(true)
	for player: BrowserBgmPlayer in _music_players:
		_music_tween.tween_property(player, "volume_db", -40.0, fade_seconds)
	_music_tween.chain().tween_callback(func() -> void:
		if epoch != _epoch or generation != _music_generation:
			return
		for fading: BrowserBgmPlayer in _music_players:
			fading.stop()
			fading.stream = null
	)


func _kill_music_tween() -> void:
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = null


func play_cue(cue_id: String, pitch_scale: float = 1.0) -> bool:
	var kind := str(CUES.get(cue_id, {}).get("kind", ""))
	var stream: AudioStream = _streams.get(cue_id)
	if stream == null or kind == "music" or kind == "ambience":
		return false
	if not _unlocked and not _headless:
		return false
	if _headless:
		return true
	var cue: Dictionary = CUES[cue_id]
	var players := _ui_players if str(cue.get("bus", "SFX")) == "UI" else _sfx_players
	var player := _claim_voice(players)
	player.stream = stream
	player.pitch_scale = clampf(pitch_scale, 0.75, 1.35)
	player.play()
	return true


func register_button(button: Button, cancel_cue: bool = false) -> void:
	if button == null or button.has_meta("audio_registered"):
		return
	button.set_meta("audio_registered", true)
	button.pressed.connect(func() -> void:
		unlock_audio()
		play_cue("ui.cancel" if cancel_cue else "ui.confirm")
	)


func set_game_paused(paused: bool) -> void:
	if _paused == paused:
		return
	_paused = paused
	_apply_bus_settings()
	if paused:
		play_cue("game.pause")


func get_cue_ids() -> Array:
	return CUES.keys()


func get_voice_capacity() -> Dictionary:
	return {
		"music": _music_players.size(),
		"ambience": 1 if _ambience_player != null else 0,
		"sfx": _sfx_players.size(),
		"ui": _ui_players.size(),
	}


func _make_player(player_name: String, bus_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = bus_name
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	return player


func _claim_voice(players: Array) -> AudioStreamPlayer:
	for value: Variant in players:
		var player: AudioStreamPlayer = value
		if not player.playing:
			return player
	var recycled: AudioStreamPlayer = players[0]
	recycled.stop()
	return recycled


func _load_streams() -> void:
	for cue_id: String in CUES:
		register_cue(cue_id, str(CUES[cue_id].path))


func _ensure_buses() -> void:
	for bus_name: String in ["Music", "SFX", "UI", "Ambience"]:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		var index := AudioServer.bus_count
		AudioServer.add_bus()
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, "Master")


func _apply_bus_settings() -> void:
	var master_db := float(TuningStore.get_value("audio.master.volume_db", 0.0))
	var music_db := float(TuningStore.get_value("audio.music.volume_db", -8.0))
	var sfx_db := float(TuningStore.get_value("audio.sfx.volume_db", 0.0))
	var ui_db := float(TuningStore.get_value("audio.ui.volume_db", 0.0))
	_set_plain_bus("Master", master_db)
	_set_plain_bus("SFX", sfx_db)
	_set_plain_bus("UI", ui_db)
	_set_layer_bus("Music", music_db, _music_gain, _paused)
	_set_layer_bus("Ambience", linear_to_db(AMBIENCE_OUTPUT_SCALE), _ambience_gain, _paused)
	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		AudioServer.set_bus_mute(master, bool(TuningStore.get_value("audio.master.muted", false)))


func _set_plain_bus(bus_name: String, volume_db: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, volume_db)


func _set_layer_bus(bus_name: String, authored_db: float, gain: float, ducked: bool) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	if gain <= 0.0:
		AudioServer.set_bus_mute(index, true)
		AudioServer.set_bus_volume_db(index, authored_db)
		return
	AudioServer.set_bus_mute(index, false)
	var duck := 8.0 if ducked else 0.0
	AudioServer.set_bus_volume_db(index, authored_db + linear_to_db(gain) - duck)


func _on_tuning_changed(id: String, _requested: Variant, _active: Variant) -> void:
	if id.begins_with("audio."):
		_apply_bus_settings()


func _on_music_finished(player: BrowserBgmPlayer) -> void:
	if player != _music_players[_music_index] or not _music_continues():
		return
	if player.stream != null and not _headless:
		player.play(player.get_playback_position())


func _on_ambience_finished() -> void:
	if not _ambience_continues() or _ambience_player.stream == null or _headless:
		return
	_ambience_player.play(0.0)


func _retire_faded_music(player: BrowserBgmPlayer, epoch: int, generation: int) -> void:
	if epoch != _epoch or generation != _music_generation:
		return
	if player == _music_players[_music_index] and _music_enabled and not _music_cue.is_empty():
		return
	player.stop()
	player.stream = null


func _release_idle_yard_caches() -> void:
	for cue_id: String in ["yard.music", "yard.ambience"]:
		var stream: AudioStream = _streams.get(cue_id)
		if stream != null:
			BrowserBgmPlayer.release_cached_stream(stream)


func _query_backend() -> String:
	if not _forced_backend_state.is_empty():
		return _forced_backend_state
	_install_resume_hook()
	_resume_token += 1
	return str(BrowserBgmPlayer.resume_shared_backend(_resume_token))


func _install_resume_hook() -> void:
	if _resume_hook_ready or not OS.has_feature("web"):
		return
	if not BrowserBgmPlayer.ensure_shared_backend():
		return
	var engine := JavaScriptBridge.get_interface("__manusBgm")
	if engine == null:
		return
	_resume_callback = JavaScriptBridge.create_callback(_on_browser_resume_settled)
	engine.setResumeHook(_resume_callback)
	_resume_hook_ready = true


func _on_browser_resume_settled(args: Array) -> void:
	if args.is_empty() or not args[0] is String:
		return
	var payload: Variant = JSON.parse_string(args[0])
	if not payload is Dictionary:
		return
	var token := int(payload.get("token", -1))
	if token != _resume_token:
		return
	_backend_state = str(payload.get("state", "unknown"))
	if not _yard_active or not _unlocked:
		return
	if _backend_state == "running":
		_awaiting_gesture = false
		_reconcile()
	elif _backend_state == "interrupted" or _backend_state == "closed":
		_awaiting_gesture = true


func _backend_starts_now(state: String) -> bool:
	return _headless or state == "native" or state == "running" or state == "suspended"


func _music_continues() -> bool:
	return _yard_active and _application_active and _music_enabled and _music_cue == "yard.music" and (_unlocked or _headless) and not _awaiting_gesture


func _ambience_continues() -> bool:
	return _yard_active and _application_active and _ambience_enabled and (_unlocked or _headless) and not _awaiting_gesture


func _reconcile() -> void:
	if not _yard_active:
		return
	if not _music_enabled:
		stop_music(0.0)
	if not _ambience_enabled:
		_stop_ambience_immediate()
	_apply_transport_pause(not _application_active)
	if not _application_active:
		return
	if not _unlocked and not _headless:
		return
	if _awaiting_gesture and not _headless:
		return
	if _ambience_enabled:
		_start_ambience()
	if _music_enabled:
		play_music("yard.music")


func _apply_transport_pause(paused: bool) -> void:
	if _ambience_player != null:
		_ambience_player.stream_paused = paused
	for player: BrowserBgmPlayer in _music_players:
		player.stream_paused = paused


func _start_ambience() -> void:
	var stream: AudioStream = _streams.get("yard.ambience")
	if stream == null or _ambience_player == null:
		_stop_ambience_immediate()
		return
	if _ambience_player.stream == stream and (_ambience_player.playing or _headless):
		return
	var resume_from := 0.0
	if _ambience_player.stream == stream:
		resume_from = _ambience_player.get_playback_position()
	_ambience_player.stream = stream
	_ambience_player.volume_db = 0.0
	if _headless:
		return
	_ambience_player.play(resume_from)


func _stop_ambience_immediate() -> void:
	if _ambience_player == null:
		return
	_ambience_player.stream_paused = false
	_ambience_player.stop()
	_ambience_player.stream = null
