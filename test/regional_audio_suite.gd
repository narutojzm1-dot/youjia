extends SceneTree
const Mix := preload("res://scripts/audio/regional_soundscape.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\","/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\","/").to_lower().begins_with(isolated):
		quit(2)
		return
	var audio = root.get_node("AudioDirector")
	audio.set_process(false)
	audio.release_streams()
	audio._load_streams()
	audio._headless = true
	audio.set_yard_active(true)
	var layer = audio._soundscape
	var capacity: Dictionary = audio.get_voice_capacity()
	check(capacity.ambience == 4 and capacity.music == 2,"fixed six music/environment voices")
	for cue: String in ["night.music","night.ambience","rain.ambience","sleep.ambience"]:
		check(audio._streams.get(cue) != null,"actual imported candidate " + cue)
	for n: bool in [false,true]:
		for r: bool in [false,true]:
			for s: bool in [false,true]:
				var mix: Dictionary = Mix.weights(n,r,s)
				var sum := 0.0
				for v: float in mix.values(): sum += v
				check(is_equal_approx(sum,1.0),"every environment combination has one gain budget")
	audio.set_world_sound(true,false,false)
	audio._process(8.0)
	check(audio._music_cue == "night.music","night selects original nocturne")
	check(layer.players["night.ambience"].stream != null,"night bed prepared")
	check(audio._ambience_player.volume_linear < 0.0001,"daytime air fades out at night")
	check(layer.players["sleep.ambience"].stream == null,"ordinary night never snores")
	var index: int = audio._music_index
	audio.set_music_scene("near_path")
	check(audio._music_index == index,"same region night retains track through gate")
	audio.set_world_sound(true,true,false)
	for i in 80:
		audio._process(0.05)
		var sum := 0.0
		for v: float in layer.gains.values(): sum += v
		check(sum <= 1.00001,"crossfade never amplifies layered environment")
	check(layer.players["rain.ambience"].stream != null,"rain layer starts")
	audio.set_world_sound(true,true,true)
	audio._process(2.0)
	check(layer.players["sleep.ambience"].stream != null,"confirmed sleep starts breath")
	audio.set_game_paused(true)
	check(layer.players["sleep.ambience"].stream_paused,"pause freezes breath with sleeper")
	audio.set_application_active(false)
	for cue: String in Mix.CUES: check(layer.players[cue].stream_paused,"background freezes " + cue)
	var old_gains: Dictionary = layer.gains.duplicate()
	audio.set_world_sound(false,false,false)
	audio._process(100.0)
	check(layer.gains == old_gains,"background does not consume fades or replay elapsed time")
	audio.set_application_active(true)
	audio.set_game_paused(false)
	audio._process(8.0)
	check(audio._music_cue == "near_path.music","morning chooses current location's daytime theme")
	check(layer.players["sleep.ambience"].stream == null,"wake discards snore even after hidden time")
	audio.set_ambience_enabled(false)
	for cue: String in Mix.CUES: check(layer.players[cue].stream == null,"environment toggle stops " + cue)
	audio.set_world_sound(true,true,true)
	audio._process(8.0)
	check(layer.players["sleep.ambience"].stream == null,"sleep cannot bypass environment off")
	audio.set_ambience_enabled(true)
	audio.set_ambience_gain(0.0)
	audio._process(8.0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Ambience")),"new layers obey zero slider")
	audio.set_ambience_gain(1.0)
	check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Ambience"))),0.3),"all layers use existing 30 percent ceiling")
	audio.unregister_cue("rain.ambience")
	audio._process(1.0)
	check(layer.players["rain.ambience"].stream == null and layer.players["night.ambience"].stream != null,"missing rain silences only rain")
	audio.unregister_cue("yard.ambience")
	audio._process(1.0)
	check(layer.players["night.ambience"].stream != null,"missing daytime bed cannot stop independent night bed")
	audio.set_yard_active(false)
	audio._process(20.0)
	for cue: String in Mix.CUES: check(layer.players[cue].stream == null,"title cannot revive " + cue)
	audio.release_streams()
	audio._process(20.0)
	check(not layer.running,"release revokes transport before cache disposal")
	audio._load_streams()
	# Exercise the real Main adapter, not a duplicate hour calculation.
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	await main._start_holiday()
	main.set_process(false)
	var world = main._world
	world._day_elapsed = 400.0
	world.weather = "rain"
	world.house.stage = "saving"
	main._sync_world_sound()
	check(audio._night and audio._rain and not audio._sleeping,"saving/failed receipt does not produce snore")
	world.house.stage = "sleep"
	main._sync_world_sound()
	check(audio._sleeping,"confirmed house stage supplies sleep fact")
	world.house.stage = "wake"
	world._day_elapsed = 0.0
	main._sync_world_sound()
	check(not audio._night and not audio._sleeping,"actual morning removes both night/sleep facts")
	main._screen = "exploring"
	world._day_elapsed = 400.0
	world.house.stage = "sleep"
	main._sync_world_sound()
	check(audio._night and not audio._sleeping,"nearby uses same night but cannot inherit yard snore")
	world.house.stage = ""
	main._screen = "game"
	check(await root.get_node("SaveStore").flush_pending(),"test save drained")
	main.queue_free()
	await process_frame
	audio.release_streams()
	check(audio.get_voice_capacity() == capacity,"no new players after lifecycle/scene combinations")
	for failure: String in failures: push_error(failure)
	print("REGIONAL_AUDIO checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
