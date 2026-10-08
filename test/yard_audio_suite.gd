extends SceneTree

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var audio := root.get_node("AudioDirector")
	var tuning := root.get_node("TuningStore")
	tuning.reset_defaults()
	audio.release_streams()
	audio._load_streams()
	audio._headless = false
	audio._unlocked = false
	audio._yard_active = false
	audio._application_active = true
	audio._music_enabled = true
	audio._ambience_enabled = true
	audio._awaiting_gesture = false
	_check(audio.get_voice_capacity().ambience == 4, "bounded day/night/rain/sleep ambience players are created once")
	_check(audio.get_voice_capacity().music == 2, "music stays on the existing pair of players")
	var players_before: int = audio.get_voice_capacity().music + audio.get_voice_capacity().ambience
	audio.set_yard_active(true)
	_check(audio.yard_active() and not _music_stream(audio) and not _ambience_stream(audio), "before the enter gesture both layers stay silent")
	audio.set_yard_active(false)
	audio.set_yard_active(true)
	_check(not _music_stream(audio), "repeated enter before unlock keeps only the final silent state")
	var heard: bool = audio.unlock_audio()
	_check(heard, "headless-native resume reports the gesture path without claiming a speaker")
	_check(_music_stream(audio) != null and _ambience_stream(audio) != null, "after unlock both yard layers are armed")
	_check(str(_music_stream(audio).resource_path).ends_with("bed_yard_music.ogg"), "music uses the music stem")
	_check(str(_ambience_stream(audio).resource_path).ends_with("bed_yard_env.ogg"), "ambience uses the environment stem")
	var index: int = audio._music_index
	var music_stream: AudioStream = _music_stream(audio)
	var ambience_stream: AudioStream = _ambience_stream(audio)
	audio.set_yard_active(true)
	_check(audio._music_index == index and _music_stream(audio) == music_stream and _ambience_stream(audio) == ambience_stream, "a repeated enter does not restart or replace the layers")
	var music_bus := AudioServer.get_bus_index("Music")
	var ambience_bus := AudioServer.get_bus_index("Ambience")
	var music_open := AudioServer.get_bus_volume_db(music_bus)
	var ambience_open := AudioServer.get_bus_volume_db(ambience_bus)
	audio.set_game_paused(true)
	_check(is_equal_approx(AudioServer.get_bus_volume_db(music_bus), music_open - 8.0), "pause ducks music by the existing 8 dB")
	_check(is_equal_approx(AudioServer.get_bus_volume_db(ambience_bus), ambience_open - 8.0), "pause ducks ambience by the same temporary 8 dB")
	_check(_music_stream(audio) == music_stream and not _transport_paused(audio), "pause is not leaving the yard and does not freeze transport")
	audio.set_application_active(false)
	_check(_transport_paused(audio) and _music_stream(audio) == music_stream and _ambience_stream(audio) == ambience_stream, "background pauses both layers and keeps their place")
	audio.set_game_paused(false)
	_check(_transport_paused(audio), "clearing the game pause does not cancel a background pause")
	audio.set_application_active(true)
	_check(not _transport_paused(audio) and _music_stream(audio) == music_stream, "foreground restores the same streams")
	audio.set_music_enabled(false)
	_check(_music_stream(audio) == null and _ambience_stream(audio) == ambience_stream, "music can turn off without silencing the yard air")
	audio.set_music_enabled(true)
	_check(_music_stream(audio) == music_stream, "music returns on its own stem")
	audio.set_ambience_enabled(false)
	_check(_ambience_stream(audio) == null and _music_stream(audio) != null, "ambience can turn off without stopping music")
	audio.set_ambience_enabled(true)
	audio.unregister_cue("yard.ambience")
	audio.set_yard_active(true)
	_check(_ambience_stream(audio) == null and _music_stream(audio) != null, "a missing ambience stem leaves music and the yard up")
	audio._load_streams()
	audio.set_yard_active(true)
	_check(_ambience_stream(audio) != null, "restoring the stem brings ambience back")
	var epoch: int = audio.lifecycle_epoch()
	audio.set_yard_active(false)
	_check(audio.lifecycle_epoch() == epoch + 1 and _music_stream(audio) == null and _ambience_stream(audio) == null, "leaving stops both layers and retires the old life")
	audio._ambience_player.finished.emit()
	audio._on_music_finished(audio._music_players[audio._music_index])
	_check(_music_stream(audio) == null and _ambience_stream(audio) == null, "a late finished callback does not revive a yard that was left")
	_check(bool(tuning.set_value("audio.master.muted", true)), "master mute still uses the session tuning value")
	_check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "master mute is audible to the mix")
	audio.set_yard_active(true)
	_check(audio.yard_active(), "mute does not block entering the yard")
	tuning.set_value("audio.master.muted", false)
	for _i: int in 4:
		audio.set_yard_active(false)
		audio.set_yard_active(true)
	_check(audio.get_voice_capacity().music + audio.get_voice_capacity().ambience == players_before, "enter and leave do not allocate more players")
	audio._forced_backend_state = "unavailable"
	audio.set_yard_active(false)
	audio._unlocked = false
	audio._awaiting_gesture = false
	audio.set_yard_active(true)
	var missing_backend: bool = bool(audio.unlock_audio())
	_check(not missing_backend and audio.awaiting_gesture() and _music_stream(audio) == null and _ambience_stream(audio) == null, "a missing backend does not start beds or claim the gesture finished")
	audio._on_browser_resume_settled(['{"state":"running","token":%d}' % (audio._resume_token - 1)])
	_check(audio.awaiting_gesture() and _music_stream(audio) == null, "a stale resume callback does not start beds")
	audio._forced_backend_state = "suspended"
	audio.note_gesture()
	_check(not audio.awaiting_gesture() and _music_stream(audio) != null and _ambience_stream(audio) != null, "a suspended context starts both layers on that same gesture")
	_check(not audio.unlock_audio(), "suspended is not reported as a running speaker")
	audio.set_yard_active(false)
	audio._on_browser_resume_settled(['{"state":"running","token":%d}' % audio._resume_token])
	_check(not audio.yard_active() and _music_stream(audio) == null and _ambience_stream(audio) == null, "a resume that settles after leaving does not restart the yard")
	audio._forced_backend_state = ""
	audio._unlocked = true
	audio._awaiting_gesture = false
	audio.set_yard_active(true)
	var stale_player: Node = audio._music_players[audio._music_index]
	var stale_epoch: int = int(audio.lifecycle_epoch())
	var stale_generation: int = int(audio._music_generation)
	for _i: int in 10:
		audio.set_music_enabled(false)
		_check(_music_stream(audio) == null and _ambience_stream(audio) != null, "music can turn off ten times without taking the yard air")
		audio.set_music_enabled(true)
		_check(_music_stream(audio) != null and audio.music_enabled(), "music can turn back on ten times without leaving the yard")
	audio._retire_faded_music(stale_player, stale_epoch, stale_generation)
	_check(audio.music_enabled() and _music_stream(audio) != null, "a fade from before the toggles does not stop music that is on")
	for _i: int in 10:
		audio.set_ambience_enabled(false)
		_check(_ambience_stream(audio) == null and _music_stream(audio) != null, "ambience can turn off ten times without stopping music")
		audio.set_ambience_enabled(true)
		_check(_ambience_stream(audio) != null and audio.ambience_enabled(), "ambience can turn back on ten times without leaving the yard")
	audio.set_music_enabled(false)
	audio.set_ambience_enabled(false)
	audio.set_ambience_enabled(true)
	audio.set_music_enabled(true)
	_check(_music_stream(audio) != null and _ambience_stream(audio) != null, "crossing the two switches ends with both layers on")
	audio.set_game_paused(true)
	audio.set_music_enabled(false)
	audio.set_music_enabled(true)
	_check(audio.music_enabled() and _music_stream(audio) != null and _ambience_stream(audio) != null, "a paused yard can still turn music off and back on")
	audio.set_game_paused(false)
	audio.set_application_active(false)
	audio.set_ambience_enabled(false)
	audio.set_ambience_enabled(true)
	_check(audio.ambience_enabled() and _ambience_stream(audio) == null, "turning ambience on in the background does not play there")
	audio.set_application_active(true)
	_check(_ambience_stream(audio) != null and _music_stream(audio) != null and not audio.awaiting_gesture(), "returning to the yard restarts the open layers without a trip home")
	var master_bus := AudioServer.get_bus_index("Master")
	var music_full := AudioServer.get_bus_volume_db(music_bus)
	var ambience_full := AudioServer.get_bus_volume_db(ambience_bus)
	var music_stream_now: AudioStream = _music_stream(audio)
	var ambience_stream_now: AudioStream = _ambience_stream(audio)
	audio.set_music_gain(0.0)
	_check(AudioServer.is_bus_mute(music_bus) and not AudioServer.is_bus_mute(ambience_bus) and not AudioServer.is_bus_mute(master_bus), "music at 0% is real silence and does not mute the yard air or the master")
	_check(_music_stream(audio) == music_stream_now and _ambience_stream(audio) == ambience_stream_now, "moving a volume slider does not restart either layer")
	audio.set_music_gain(0.5)
	_check(not AudioServer.is_bus_mute(music_bus) and is_equal_approx(AudioServer.get_bus_volume_db(music_bus), music_full + linear_to_db(0.5)), "half music is the authored level plus the linear midpoint")
	_check(is_equal_approx(AudioServer.get_bus_volume_db(ambience_bus), ambience_full), "a music change leaves the yard air level alone")
	audio.set_ambience_gain(0.0)
	_check(AudioServer.is_bus_mute(ambience_bus) and not AudioServer.is_bus_mute(music_bus), "yard air at 0% is real silence and leaves music on")
	audio.set_ambience_gain(1.0)
	audio.set_music_gain(1.0)
	_check(is_equal_approx(audio.music_gain(), 1.0) and is_equal_approx(audio.ambience_gain(), 1.0), "both sliders can return to full on their own")
	audio.set_music_gain(0.25)
	audio.set_music_enabled(false)
	audio.set_music_enabled(true)
	_check(is_equal_approx(audio.music_gain(), 0.25) and _music_stream(audio) != null, "turning music off and on restores the same non-zero level")
	audio.set_ambience_gain(0.4)
	audio.set_ambience_enabled(false)
	audio.set_ambience_enabled(true)
	_check(is_equal_approx(audio.ambience_gain(), 0.4) and _ambience_stream(audio) != null, "turning yard air off and on restores the same non-zero level")
	audio.set_game_paused(true)
	_check(is_equal_approx(AudioServer.get_bus_volume_db(music_bus), music_full + linear_to_db(0.25) - 8.0), "pause still ducks a partial music level by 8 dB")
	audio.set_music_gain(0.0)
	_check(AudioServer.is_bus_mute(music_bus), "pause does not turn a zero music slider back up")
	audio.set_game_paused(false)
	audio.set_music_gain(0.25)
	audio.set_yard_active(false)
	audio.set_yard_active(true)
	_check(is_equal_approx(audio.music_gain(), 0.25) and is_equal_approx(audio.ambience_gain(), 0.4), "leaving and returning keeps this session's two levels")
	audio.set_music_gain(1.0)
	audio.set_ambience_gain(1.0)
	await _scene_music_cases(audio)
	audio.release_streams()
	# This suite exercises the native transport even with a headless display.
	# Let stopped playback objects retire before exiting the test process.
	music_stream = null
	ambience_stream = null
	music_stream_now = null
	ambience_stream_now = null
	await create_timer(0.25).timeout
	if failures.is_empty():
		print("YARD AUDIO PASS ", checks)
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	print("YARD AUDIO FAIL ", failures.size())
	quit(1)


func _scene_music_cases(audio: Node) -> void:
	var yard: AudioStream = _music_stream(audio)
	var air: AudioStream = _ambience_stream(audio)
	_check(audio.set_music_scene("near_path"), "near-path scene is accepted")
	var path: AudioStream = _music_stream(audio)
	_check(path != null and path != yard and path.resource_path.ends_with("bed_near_path_music.ogg"), "going out selects a different authored music stream")
	_check(audio._music_continues(), "near-path finished callbacks may continue the current music")
	var index: int = audio._music_index
	audio.set_music_scene("near_path")
	_check(audio._music_index == index and _ambience_stream(audio) == air, "repeated scene facts do not restart music or ambience")
	_check(not audio.set_music_scene("unknown") and _music_stream(audio) == path, "an unknown scene does not replace the current track")
	audio.set_music_enabled(false)
	audio.set_music_scene("yard")
	_check(_music_stream(audio) == null, "scene changes do not enable disabled music")
	audio.set_music_scene("near_path")
	audio.set_music_enabled(true)
	_check(_music_stream(audio) == path, "enabling music starts the latest scene instead of the yard default")
	audio.set_application_active(false)
	audio.set_music_scene("yard")
	_check(_transport_paused(audio) and _music_stream(audio) == path, "a background scene change keeps transport paused")
	audio.set_application_active(true)
	_check(_music_stream(audio) == yard and not _transport_paused(audio), "foreground reconciles the latest scene")
	audio.set_game_paused(true)
	audio.set_music_gain(0.0)
	audio.set_music_scene("near_path")
	_check(_music_stream(audio) == path and AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "scene crossfade cannot override a zero music slider or pause")
	audio.set_game_paused(false)
	audio.set_music_gain(1.0)
	for i: int in 8:
		audio.set_music_scene("yard" if i % 2 == 0 else "near_path")
	await create_timer(2.7).timeout
	var active := 0
	for player: Node in audio._music_players:
		if player.playing: active += 1
	_check(_music_stream(audio) == path and active == 1, "rapid scene changes retire the old voice and leave exactly one latest track")
	_check(audio.get_voice_capacity().music == 2 and _ambience_stream(audio) == air, "scene changes reuse the same pair and leave ambience intact")
	audio.unregister_cue("near_path.music")
	audio.set_music_scene("near_path")
	_check(_music_stream(audio) == null and _ambience_stream(audio) == air, "missing scene music safely silences only that layer")
	audio.register_stream("near_path.music", path)
	audio.set_music_scene("near_path")
	_check(_music_stream(audio) == path, "restoring a scene resource can resume its own track")
	audio.set_yard_active(false)
	_check(_music_stream(audio) == null and _ambience_stream(audio) == null, "title stops near-path music too")
	audio._on_music_finished(audio._music_players[audio._music_index])
	_check(_music_stream(audio) == null, "late near-path completion cannot revive title audio")
	audio.set_music_scene("yard")
	audio.set_yard_active(true)
	_check(_music_stream(audio) == yard, "a fresh yard entry restores the yard track")


func _music_stream(audio: Node) -> AudioStream:
	return audio._music_players[audio._music_index].stream


func _ambience_stream(audio: Node) -> AudioStream:
	return audio._ambience_player.stream


func _transport_paused(audio: Node) -> bool:
	return bool(audio._ambience_player.stream_paused) and bool(audio._music_players[0].stream_paused)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
