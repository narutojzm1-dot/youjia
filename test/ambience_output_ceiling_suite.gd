extends SceneTree

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func run() -> void:
	var audio := root.get_node("AudioDirector")
	var tuning := root.get_node("TuningStore")
	tuning.reset_defaults()
	audio.set_game_paused(false)
	var bus := AudioServer.get_bus_index("Ambience")
	var music := AudioServer.get_bus_index("Music")
	check(is_equal_approx(audio.ambience_gain(), 0.5), "new-session default slider is 50 percent")
	check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(bus)), 0.15), "default output is 15 percent of the former maximum")
	var player: Node = audio._ambience_player
	# The previous full-volume route was the same player and master chain with
	# the ambience bus at 0 dB. Compare against that route, not the new constant.
	AudioServer.set_bus_volume_db(bus, 0.0)
	var former_max: float = player._effective_gain()
	var music_db := AudioServer.get_bus_volume_db(music)
	for slider: float in [0.0, 0.25, 0.5, 1.0, 2.0]:
		audio.set_ambience_gain(slider)
		var selected := clampf(slider, 0.0, 1.0)
		check(is_equal_approx(audio.ambience_gain(), selected), "slider value remains independent of output ceiling")
		check(is_equal_approx(player._effective_gain(), former_max * selected * 0.3), "browser playback route scales actual gain by 30 percent")
		check(AudioServer.is_bus_mute(bus) == (selected == 0.0), "zero remains genuinely muted")
		if selected > 0:
			check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(bus)), selected * 0.3), "native bus shares the same ceiling")
		check(is_equal_approx(AudioServer.get_bus_volume_db(music), music_db), "music level is unaffected")
	audio.set_ambience_volume_db(0.0)
	check(is_equal_approx(player._effective_gain(), former_max * 0.3), "legacy dB setter cannot bypass ceiling")
	audio.set_game_paused(true)
	check(is_equal_approx(player._effective_gain(), former_max * 0.3 * db_to_linear(-8.0)), "pause duck applies below ceiling")
	audio.set_game_paused(false)
	audio.set_ambience_enabled(false)
	audio.set_ambience_enabled(true)
	check(is_equal_approx(audio.ambience_gain(), 1.0), "toggle preserves chosen full slider")
	check(is_equal_approx(player._effective_gain(), former_max * 0.3), "toggle cannot reset actual output to former maximum")
	audio.release_streams()
	if failures.is_empty():
		print("AMBIENCE_CEILING checks=%d failures=0" % checks)
		quit(0)
	else:
		for failure: String in failures: push_error(failure)
		quit(1)
