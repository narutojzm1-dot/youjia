extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	_check(ProjectSettings.get_setting("application/config/name") == "悠长的假期", "exported identity")
	for path: String in [
		"environment/yard_sunny.png", "environment/yard_overcast.png",
		"characters/llama.png", "characters/llama_annoyed.png", "characters/llama_happy.png",
		"characters/llama_smirk.png", "characters/goose.png", "characters/cow.png",
		"characters/duck.png", "characters/player.png", "fx/felt_spit.png", "ui/polaroid_frame.png",
	]:
		_check(ResourceLoader.exists("res://assets/holiday/" + path), "pack resource: " + path)
	_check(FileAccess.file_exists("res://assets/holiday/characters/cast_v2/manifest.json"),"cast metadata included in exported pack")
	for stem: String in ["llama_idle","llama_happy","llama_annoyed","llama_smirk","cow","horse","goose","duck","sheep_clingy","sheep_dull"]:
		_check(ResourceLoader.exists("res://assets/holiday/characters/cast_v2/"+stem+".png"),"approved cast export: "+stem)
	_check(ResourceLoader.exists("res://assets/holiday/characters/resident_walk_authored_v1/idle.png"),"accepted hero idle exported")
	_check(ResourceLoader.exists("res://assets/share/favicon.png"), "pack favicon")
	_check(ResourceLoader.exists("res://assets/share/og.png"), "pack og cover")
	_check(not ResourceLoader.exists("res://test/test_suite.tscn"), "test scene excluded")
	_check(not ResourceLoader.exists("res://tools/capture_native.gd"), "native capture tool excluded")
	_check(not root.has_node("GlobalLeaderboard"), "no dormant network autoload")
	_check(not DirAccess.dir_exists_absolute("res://assets/template/audio"), "no default audio assets")
	var font := load("res://assets/template/fonts/ui_regular.tres") as Font
	_check(font != null, "exported font")
	for locale: String in ["en", "zh-CN"]:
		var path := "res://localization/%s.json" % locale
		_check(FileAccess.file_exists(path), "exported locale: " + locale)
		var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		for value: String in catalog.values():
			for index: int in value.length():
				var codepoint := value.unicode_at(index)
				if codepoint >= 32:
					_check(font != null and font.has_char(codepoint), "exported glyph: %d" % codepoint)
	var packed := load("res://scenes/main.tscn") as PackedScene
	_check(packed != null, "exported main scene")
	if packed != null:
		var main := packed.instantiate()
		root.add_child(main)
		await process_frame
		await process_frame
		_check(bool((main.get("_title_screen") as Control).visible), "pack boots to title")
		_check((main.get("_title_label") as Label).text == "悠长的假期", "pack title copy")
		_check(not main.has_method("_maybe_capture"), "capture routing removed from runtime")
		_check(not main.has_method("_open_tuning"), "release tuning entry point excluded")
		_check(not ResourceLoader.exists("res://scripts/ui/tuning_panel.gd"), "release tuning panel excluded")
		main.call("_start_holiday")
		await process_frame
		_check(main.get("_world") != null, "pack starts gameplay")
		var world=main.get("_world")
		_check(world.actor_named("horse")!=null and world.actor_named("horse")._ground_anchor.x>=0,"exported horse loads calibrated art metadata")
		_check(world.get_player().sequence_walker_enabled,"export keeps accepted sequence hero default")
		var audio := root.get_node("AudioDirector")
		_check(not bool(audio.call("play_cue", "ui.confirm")), "pack missing SFX is silent")
		_check(not bool(audio.call("play_music", "music.gameplay")), "pack missing BGM is silent")
		audio.call("release_streams")
		main.queue_free()
		await process_frame
	if _failures.is_empty():
		print("[exported-pack] PASS: identity, resources, fonts, exclusions, boot, gameplay, silent audio")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[exported-pack] " + failure)
		quit(1)


func _check(condition: bool, context: String) -> void:
	if not condition and context not in _failures:
		_failures.append(context)
