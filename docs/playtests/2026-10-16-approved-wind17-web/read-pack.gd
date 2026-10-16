extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var identity = JSON.parse_string(FileAccess.get_file_as_string("res://config/build_identity.json"))
	var notes = JSON.parse_string(FileAccess.get_file_as_string("res://config/release_notes.json"))
	var audio = root.get_node("AudioDirector")
	var cue: Dictionary = audio.CUES["yard.ambience"]
	var paths: Array = []
	for key in audio.CUES:
		if str(audio.CUES[key].get("path","")).ends_with("bed_yard_env.ogg"):paths.append(key)
	var out := {"identity":identity,"top_note":notes.releases[0],"previous_build":notes.releases[1].build,"runtime_daytime_cue":cue,"old04_registered_cues":paths,"save_commands_run":false}
	out["pass"] = identity.sourceCommit=="7a4bc8a8d47e13e9fbb571e860f0050b9d0bdf76" and cue.path=="res://assets/holiday/audio/bed_yard_gust.ogg" and paths.is_empty() and notes.releases[1].build=="70de87a"
	var f := FileAccess.open(OS.get_environment("WIND17_PACK_OUT"),FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	print("WIND17_PACK ",JSON.stringify(out))
	quit(0 if out.pass else 1)
