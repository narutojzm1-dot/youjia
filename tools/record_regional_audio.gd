extends SceneTree
## Controlled production-AudioDirector PCM capture. NOT a human listening review
## and NOT an ordinary gameplay proof. Captures our Master bus, never a microphone.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var folder := OS.get_environment("YOUJIA_AUDIO_CAPTURE_DIR")
	if folder.is_empty(): quit(2); return
	DirAccess.make_dir_recursive_absolute(folder)
	var director = root.get_node("AudioDirector")
	var effect := AudioEffectCapture.new()
	effect.buffer_length = 2.0
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.add_bus_effect(bus,effect)
	director.unlock_audio()
	director.set_music_enabled(false)
	director.set_ambience_gain(1.0)
	director.set_yard_active(true)
	var rows: Array = []
	for item: Array in [["day",false,false,false,false], ["night",true,false,false,false],
		["rain-night",true,true,false,false],["sleep",true,false,true,false],
		["environment-off",true,true,true,true],["wake",false,false,false,false]]:
		director.set_world_sound(item[1],item[2],item[3])
		director.set_ambience_enabled(not item[4])
		await create_timer(3.0).timeout
		effect.clear_buffer()
		var bytes := PackedByteArray()
		var peak := 0.0
		var energy := 0.0
		var frames := 0
		var discarded_before := effect.get_discarded_frames()
		var end := Time.get_ticks_msec() + 4000
		while Time.get_ticks_msec() < end:
			await process_frame
			var pcm := effect.get_buffer(effect.get_frames_available())
			for frame: Vector2 in pcm:
				for value: float in [frame.x,frame.y]:
					peak = maxf(peak,absf(value))
					energy += value * value
					var n := bytes.size()
					bytes.resize(n+2)
					bytes.encode_s16(n,int(clampf(value,-1.0,1.0)*32767.0))
			frames += pcm.size()
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = int(AudioServer.get_mix_rate())
		wav.stereo = true
		wav.data = bytes
		var error := wav.save_to_wav(folder.path_join(str(item[0])+".wav"))
		var ok := error == OK and frames > 0 and effect.get_discarded_frames() == discarded_before
		ok = ok and (peak == 0.0 if item[4] else peak > 0.0001)
		var row := {"case":item[0],"peak":peak,"rms":sqrt(energy/maxi(1,frames*2)),
			"frames":frames,"mix_rate":wav.mix_rate,"no_dropped_frames":effect.get_discarded_frames() == discarded_before,
			"passed":ok,"audio_driver":AudioServer.get_driver_name(),"listening":"not reviewed"}
		rows.append(row)
		print("REGIONAL_PCM ",JSON.stringify(row))
	director.set_yard_active(false)
	# Real native playback crosses each imported loop boundary, with no
	# manual finished callback/restart that could conceal a missing loop flag.
	for cue: String in ["night.ambience","rain.ambience","sleep.ambience","night.music"]:
		var probe := AudioStreamPlayer.new()
		probe.stream = director._streams[cue]
		probe.volume_db = -80.0
		root.add_child(probe)
		probe.play(probe.stream.get_length()-0.2)
		await create_timer(0.8).timeout
		var loop_ok: bool = probe.playing and probe.get_playback_position() < 2.0
		rows.append({"case":"loop-boundary-"+cue,"passed":loop_ok,"position":probe.get_playback_position(),"listening":"not reviewed"})
		print("REGIONAL_LOOP ",cue," passed=",loop_ok)
		probe.queue_free()
	var output := FileAccess.open(folder.path_join("capture.json"),FileAccess.WRITE)
	output.store_string(JSON.stringify(rows,"\t")+"\n")
	output.close()
	var passed := true
	for row: Dictionary in rows: passed = passed and row.passed
	print("REGIONAL_PCM_COMPLETE passed=",passed)
	quit(0 if passed else 1)
