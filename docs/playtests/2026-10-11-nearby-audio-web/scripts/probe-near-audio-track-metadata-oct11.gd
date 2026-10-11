extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		push_error("Audio metadata probe requires isolated user data")
		quit(2)
		return
	var audio := root.get_node("AudioDirector")
	var rows: Array[Dictionary] = []
	for cue: String in audio._streams:
		var stream: AudioStream = audio._streams[cue]
		rows.append({"cue": cue, "path": audio.CUES[cue].path, "length_seconds": stream.get_length(), "loop": stream.loop, "resource_type": stream.get_class()})
	var output := FileAccess.open("D:/games/youjia-test/assistant-recovery/nearby-audio-web-proof-oct11/track-metadata.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"method": "readonly actual imported AudioDirector streams in isolated native profile; not playback or listening", "tracks": rows}, "\t") + "\n")
	output.close()
	print("NEAR_AUDIO_METADATA tracks=", rows.size())
	quit(0)
