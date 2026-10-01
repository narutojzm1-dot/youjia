extends Node

var _failures := PackedStringArray()
var _checks := 0
var _i18n: Node
var _tuning: Node
var _save_store: Node
var _audio: Node
var _saved_user_files: Dictionary = {}


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	for path: String in [SaveStore.SAVE_PATH]:
		_saved_user_files[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	_i18n = get_tree().root.get_node_or_null("I18n")
	_tuning = get_tree().root.get_node_or_null("TuningStore")
	_save_store = get_tree().root.get_node_or_null("SaveStore")
	_audio = get_tree().root.get_node_or_null("AudioDirector")
	_save_store.set("_data", _save_store.call("_default_data"))
	for item: Array in [
		[_i18n, "I18n"], [_tuning, "TuningStore"],
		[_save_store, "SaveStore"], [_audio, "AudioDirector"],
	]:
		_check(item[0] != null, "%s autoload must exist" % item[1])
	_i18n.call("set_locale", "zh-CN")
	_test_locale_detection()
	_test_expression_catalog()
	_test_localization_catalogs()
	_test_tuning_schema_and_integrity()
	_test_album_save()
	_test_audio_architecture()
	_test_assets()
	_test_font_glyph_coverage()
	await _test_runtime_scene()
	_audio.call("release_streams")
	await get_tree().process_frame
	_restore_user_files()
	if _failures.is_empty():
		print("[game-generic-tests] PASS: %d checks" % _checks)
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error("[game-generic-tests] " + failure)
	print("[game-generic-tests] FAIL: %d failures across %d checks" % [_failures.size(), _checks])
	get_tree().quit(1)


func _restore_user_files() -> void:
	for path: String in _saved_user_files:
		var original: Variant = _saved_user_files[path]
		if original == null:
			if FileAccess.file_exists(path):
				_check(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK, "test fixture must be removed: " + path)
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			_check(file != null, "original user file must be writable: " + path)
			if file != null:
				file.store_buffer(original)
				file.close()
				_check(FileAccess.get_file_as_bytes(path) == original, "original user file must be restored byte-for-byte: " + path)


func _test_locale_detection() -> void:
	var i18n_script: Script = load("res://autoload/i18n.gd")
	for case: Array in [
		["zh_CN", "zh-CN"], ["zh-CN", "zh-CN"], ["en_US", "zh-CN"], ["fr_FR", "zh-CN"], ["", "zh-CN"],
	]:
		_check(i18n_script.call("detect_locale", case[0]) == case[1], "OS locale %s must pin to %s" % case)
	_check(i18n_script.call("resolve_locale", "", "en_US") == "zh-CN", "first launch stays Chinese")
	_check(i18n_script.call("resolve_locale", "en", "en_US") == "zh-CN", "saved English cannot switch the pinned locale")


func _test_expression_catalog() -> void:
	var ids := ExpressionCatalog.all_ids()
	# 相册拍立得总数随新互动增加而更新（当前 11 张：4 草泥马 + 2 鸭/牛 + 3 抚摸 + 植物 + 钓鱼）
	_check(ids.size() == 11, "album must contain eleven polaroid expressions")
	var mainline := ExpressionCatalog.llama_mainline_ids()
	_check(mainline.size() == 4, "llama mainline must have four expressions")
	_check(str(ExpressionCatalog.find_rule("llama_overcast_goose_annoyed").get("expression", "")) == "annoyed", "overcast goose rule must annoy the llama")
	_check(bool(ExpressionCatalog.find_rule("llama_overcast_goose_annoyed").get("spit", false)), "annoyed llama must spit felt")
	_check(str(ExpressionCatalog.find_rule("llama_sun_sheep_happy").get("expression", "")) == "happy", "sun sheep rule must smile")
	_check(str(ExpressionCatalog.find_rule("llama_sheep_cow_smirk").get("expression", "")) == "smirk", "sheep-cow grazing must smirk")


func _test_localization_catalogs() -> void:
	var english: Array = _i18n.call("catalog_keys", "en")
	var chinese: Array = _i18n.call("catalog_keys", "zh-CN")
	english.sort()
	chinese.sort()
	_check(english == chinese, "EN and zh-CN catalogs must have identical keys")
	_check(english.size() >= 100, "catalogs must cover holiday UI")
	_i18n.call("set_locale", "zh-CN")
	_check(str(_i18n.call("t", "app.title")) == "悠长的假期", "t() must resolve the Chinese title")
	_check(str(_i18n.call("t", "menu.play")) == "走进院子", "play label must stay holiday-specific")
	_check("调校" in str(_i18n.call("t", "tuning.quick_tooltip")), "Chinese tuning guidance must resolve")
	_check(str(_i18n.call("t", "hud.album", {"count": "1", "total": "6"})) == "相册 1/6", "album HUD must interpolate")


func _test_tuning_schema_and_integrity() -> void:
	_check(int(_tuning.get("schema_version")) == 3, "tuning schema version must be 3")
	var settings: Array = _tuning.call("get_settings")
	_check(settings.size() == 20, "the runtime surface must expose 20 game controls")
	var categories: Array = _tuning.call("get_categories")
	for category: String in ["UI", "Gameplay", "Audio", "Player", "Enemies", "Environment"]:
		_check(category in categories, "missing tuning category: " + category)
	var ids := {}
	for setting: Dictionary in settings:
		var id := str(setting.get("id", ""))
		_check(not id.is_empty() and not ids.has(id), "tuning IDs must be unique and non-empty")
		ids[id] = true
		for field: String in ["category", "type", "default", "unit_key", "apply_mode", "integrity", "label_key", "description_key", "tags"]:
			_check(setting.has(field), "%s must declare %s" % [id, field])
		_check(str(setting.apply_mode) in ["LIVE", "NEXT_ACTION", "NEXT_STAGE", "NEXT_RUN"], id + " has invalid apply mode")
		_check(str(setting.integrity) in ["COSMETIC", "GAMEPLAY"], id + " has invalid integrity class")
	_tuning.call("end_run")
	_tuning.call("reset_defaults")
	_check(not bool(_tuning.call("set_value", "player.move.max_speed", 9999.0)), "out-of-range tuning must be rejected")
	_check(is_equal_approx(float(_tuning.call("get_value", "player.move.max_speed")), 96.0), "a rejected value must not mutate active state")
	_check(bool(_tuning.call("set_value", "player.lead.speed_multiplier", 0.5)), "a valid deferred value must be accepted")
	_check(is_equal_approx(float(_tuning.call("get_requested_value", "player.lead.speed_multiplier")), 0.5), "requested state must update")
	_check(is_equal_approx(float(_tuning.call("get_active_value", "player.lead.speed_multiplier")), 0.72), "NEXT_RUN state must remain deferred")
	_check(int(_tuning.call("pending_count")) == 1, "pending value count must be observable")
	_tuning.call("begin_run", false)
	_check(is_equal_approx(float(_tuning.call("get_active_value", "player.lead.speed_multiplier")), 0.5), "NEXT_RUN state must apply at run boundary")
	_check(not bool(_tuning.call("is_ranked_eligible")), "non-default gameplay tuning must mark the run unranked")
	_tuning.call("reset_setting", "player.lead.speed_multiplier")
	_check(not bool(_tuning.call("is_ranked_eligible")), "ranked ineligibility must remain sticky after reset")
	_tuning.call("end_run")
	_tuning.call("reset_defaults")
	_tuning.call("begin_run", false)
	_check(bool(_tuning.call("is_ranked_eligible")), "a fresh default run must be ranked")
	_tuning.call("set_value", "environment.filter.intensity", 0.5)
	_check(bool(_tuning.call("is_ranked_eligible")), "cosmetic tuning must preserve ranked eligibility")
	_tuning.call("set_value", "player.move.max_speed", 110.0)
	_check(not bool(_tuning.call("is_ranked_eligible")), "live gameplay tuning must revoke ranked eligibility")
	var before: Dictionary = _tuning.call("get_requested_values")
	_check(not bool(_tuning.call("set_values", {"audio.music.volume_db": -12.0, "player.lead.speed_multiplier": 9.0})), "transactional updates must reject an invalid bundle")
	_check((_tuning.call("get_requested_values") as Dictionary) == before, "invalid transactional updates must be atomic")
	_tuning.call("end_run")
	_tuning.call("reset_defaults")
	_check(str(_tuning.call("configuration_marker")).begins_with("cfg-"), "configuration marker must be stable and explicit")


func _test_album_save() -> void:
	_check(bool(_save_store.call("set_album", PackedStringArray(["llama_fed_gentle"]))), "album persistence must succeed")
	var album: Array = _save_store.call("get_album")
	_check(album.size() == 1 and str(album[0]) == "llama_fed_gentle", "album must retain collected ids")
	_save_store.call("_load")
	_check(_save_store.call("get_album") == album, "album must survive disk reload")


func _test_audio_architecture() -> void:
	var cue_ids: Array = _audio.call("get_cue_ids")
	for cue: String in ["music.title", "music.gameplay", "ui.confirm", "ui.cancel", "player.action", "enemy.impact", "score.reward", "game.pause", "game.victory", "game.defeat"]:
		_check(cue in cue_ids, "missing semantic audio cue: " + cue)
	var capacity: Dictionary = _audio.call("get_voice_capacity")
	_check(int(capacity.music) == 2, "music crossfade requires two voices")
	_check(int(capacity.sfx) == 8, "SFX polyphony must be bounded at eight voices")
	_check(int(capacity.ui) == 2, "UI polyphony must be bounded at two voices")
	for bus_name: String in ["Master", "Music", "SFX", "UI"]:
		_check(AudioServer.get_bus_index(bus_name) >= 0, "missing audio bus: " + bus_name)
	for cue: String in cue_ids:
		_check(not bool(_audio.call("play_music" if cue.begins_with("music.") else "play_cue", cue)), "unassigned cue must be silent: " + cue)
	_check(not bool(_audio.call("register_cue", "ui.confirm", "")), "empty audio path must be safe")
	_check(not bool(_audio.call("register_cue", "ui.confirm", "res://assets/template/audio/missing.ogg")), "missing SFX file must be safe")
	_check(not bool(_audio.call("register_cue", "music.title", "res://assets/template/audio/missing.ogg")), "missing BGM file must be safe")
	_check(not bool(_audio.call("register_cue", "ui.confirm", "res://assets/holiday/characters/llama.png")), "non-audio resources must be rejected")
	var fixture := AudioStreamWAV.new()
	fixture.format = AudioStreamWAV.FORMAT_8_BITS
	fixture.mix_rate = 8000
	fixture.data = PackedByteArray([128, 128, 128, 128])
	_check(bool(_audio.call("register_stream", "ui.confirm", fixture)), "optional stream must register")
	_audio.call("unlock_audio")
	_check(bool(_audio.call("play_cue", "ui.confirm")), "registered cue must play")
	_check(bool(_audio.call("register_stream", "music.title", fixture)), "optional BGM must register")
	_check(bool(_audio.call("play_music", "music.title")), "registered BGM must play")
	_check(not bool(_audio.call("play_music", "music.gameplay")), "missing music route must stop previous music")
	_check(str(_audio.get("_music_cue")).is_empty(), "silent music route must clear the active route")
	for player in _audio.get("_music_players"):
		_check(player.stream == null and not player.playing, "missing BGM must release old streams")
		_check(player.playback_type == AudioServer.PLAYBACK_TYPE_STREAM, "BGM must use streaming playback")
	_check(not bool(_audio.call("register_stream", "ui.confirm", null)), "null replacement must clear cue")
	_check(not bool(_audio.call("play_cue", "ui.confirm")), "removed SFX must return silence")
	for index: int in 30:
		_audio.call("play_music", "missing.music")
		_audio.call("play_cue", "missing.cue")
		_audio.call("set_game_paused", index % 2 == 0)
	_audio.call("set_game_paused", false)
	_check(_audio.call("get_voice_capacity") == capacity, "silent retries must not create voices")
	_audio.call("release_streams")
	_check(not bool(_audio.call("play_cue", "missing.cue")), "unknown cue must fail safely")


func _test_assets() -> void:
	for path: String in [
		"res://assets/holiday/environment/yard_sunny.png",
		"res://assets/holiday/environment/yard_overcast.png",
		"res://assets/holiday/characters/llama.png",
		"res://assets/holiday/characters/llama_annoyed.png",
		"res://assets/holiday/characters/llama_happy.png",
		"res://assets/holiday/characters/llama_smirk.png",
		"res://assets/holiday/characters/goose.png",
		"res://assets/holiday/characters/sheep_clingy.png",
		"res://assets/holiday/characters/sheep_dull.png",
		"res://assets/holiday/characters/cow.png",
		"res://assets/holiday/characters/duck.png",
		"res://assets/holiday/characters/player.png",
		"res://assets/holiday/fx/grass_bundle.png",
		"res://assets/holiday/fx/felt_spit.png",
		"res://assets/holiday/ui/polaroid_frame.png",
		"res://assets/holiday/ui/scrapbook_paper.png",
		"res://assets/share/favicon.png",
		"res://assets/share/og.png",
		"res://assets/template/fonts/NotoSansSC-VF.subset.woff2",
		"res://assets/template/fonts/Figtree-VF.subset.woff2",
	]:
		_check(ResourceLoader.exists(path), "required visual asset is missing: " + path)
	var llama := (load("res://assets/holiday/characters/llama.png") as Texture2D).get_image()
	_check(llama.detect_alpha() != Image.ALPHA_NONE, "felt llama must keep an alpha cutout")
	_check(not DirAccess.dir_exists_absolute("res://assets/template/audio/placeholders"), "default audio assets must not ship")


func _test_font_glyph_coverage() -> void:
	var probe := Label.new()
	get_tree().root.add_child(probe)
	var font: Font = probe.get_theme_font("font")
	probe.free()
	_check(font != null, "project font must load")
	if font == null:
		return
	_check(font == load("res://assets/template/fonts/ui_regular.tres"), "ui_regular must be the primary project font")
	_check(font is FontVariation and font.base_font.resource_path.ends_with("Figtree-VF.subset.woff2"), "primary font must use the Figtree body face")
	_check(font is FontVariation and not font.fallbacks.is_empty() and (font.fallbacks[0] as FontVariation).base_font.resource_path.ends_with("NotoSansSC-VF.subset.woff2"), "Chinese must fall back to Noto Sans SC")
	var missing := PackedInt32Array()
	var seen := {}
	_i18n.call("set_locale", "zh-CN")
	for key: String in _i18n.call("catalog_keys", "zh-CN"):
		var localized := str(_i18n.call("t", key))
		for index: int in localized.length():
			var codepoint := localized.unicode_at(index)
			if codepoint >= 32 and not font.has_char(codepoint) and not seen.has(codepoint):
				seen[codepoint] = true
				missing.append(codepoint)
	for symbol: String in ["·", "…"]:
		var codepoint := symbol.unicode_at(0)
		if not font.has_char(codepoint) and not seen.has(codepoint):
			seen[codepoint] = true
			missing.append(codepoint)
	_check(missing.is_empty(), "bundled font is missing localized/runtime code points: %s" % [missing])


func _test_runtime_scene() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	_check(packed != null, "main scene must load")
	if packed == null:
		return
	var instance := packed.instantiate()
	get_tree().root.add_child(instance)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(instance.get("_title_screen") != null and bool((instance.get("_title_screen") as Control).visible), "title screen must be visible on boot")
	_check(not instance.has_method("_open_tuning"), "Addon owns tuning UI; no duplicate game panel")
	_check(not FileAccess.file_exists("res://scripts/ui/tuning_panel.gd"), "native tuning panel is absent")
	_check((instance.get("_title_label") as Label).text == "悠长的假期", "title must use the holiday identity")
	_check((instance.get("_play_button") as Button).text == "走进院子", "play button must enter the yard")
	instance.call("_start_holiday")
	await get_tree().process_frame
	var world: YardWorld = instance.get("_world")
	_check(world != null, "starting a holiday must create the yard")
	if world != null:
		_check(world.get_world_size() == Vector2(1280, 720), "yard panorama must stay 1280x720")
		_check(world.actor_named("llama") != null, "yard must include the llama")
		var llama: FeltActor = world.actor_named("llama")
		_check(YardGround.allows(llama.position, YardGround.lawn(), true), "llama starts on the lawn")
		llama.nudge_toward(llama.position + Vector2(40, -10))
		var before: Vector2 = llama.position
		for _step: int in 12:
			world.tick(0.1, Vector2.ZERO)
		_check(llama.position.distance_to(before) > 8.0, "llama walks across the grass")
		_check(YardGround.allows(llama.position, YardGround.lawn(), true), "llama stays on the lawn")
		_check(world.actor_named("goose") != null, "yard must include the goose")
		# 相册总数随新互动增加而更新（当前 11 张）
		_check(world.collectible_total() == 11, "album total must be eleven polaroids")
		world.set_weather("overcast")
		world.debug_place_actor("llama", Vector2(640, 400))
		world.debug_place_actor("goose", Vector2(700, 400))
		_check(bool(world.debug_force_rule("llama_overcast_goose_annoyed")), "annoyed llama polaroid must collect")
		_check(world.actor_named("llama").current_expression == "annoyed", "llama sprite must swap to annoyed")
		world.set_weather("sun")
		world.debug_place_actor("sheep_a", Vector2(620, 400))
		# 牛和马也先移走，以免在喂草测试时误触发抚摸优先分支
		world.debug_place_actor("cow", Vector2(300, 560))
		world.debug_place_actor("horse", Vector2(200, 560))
		_check(bool(world.debug_force_rule("llama_sun_sheep_happy")), "sun-sheep polaroid must collect")
		_check(bool(world.debug_force_rule("llama_sheep_cow_smirk")), "sheep-cow smirk must collect")
		# 喂草测试前把所有可抚摸动物移走，确保 try_interact() 走到喂草泥马分支
		world.debug_place_actor("sheep_a", Vector2(200, 460))
		world.debug_place_actor("sheep_b", Vector2(200, 490))
		world.debug_place_player(Vector2(340, 600))
		world.try_interact()
		_check(bool(world.get_player().carrying_grass), "yard grass pile must be pickable")
		# 玩家走到草泥马旁边喂草（草泥马在 640,400；玩家在 600,400；可抚摸动物已远离）
		world.debug_place_player(world.actor_named("llama").position + Vector2(-40, 0))
		world.try_interact()
		_check(not bool(world.get_player().carrying_grass), "feeding must consume the grass")
		_check("llama_fed_gentle" in world.collected, "feeding should be photographable")
		_check(world.collected_count() >= 3, "forced mainline photos must land in the album")
	instance.call("_toggle_pause")
	_check(bool((instance.get("_pause_screen") as Control).visible), "pause command must show the pause menu")
	instance.call("_request_destructive_action", "restart")
	_check(bool((instance.get("_confirm_screen") as Control).visible), "restart must require confirmation")
	instance.call("_cancel_destructive_action")
	_check(bool((instance.get("_pause_screen") as Control).visible), "canceling confirmation must preserve the paused holiday")
	instance.call("_toggle_pause")
	instance.call("_show_album")
	_check(bool((instance.get("_album_screen") as Control).visible), "album must open from the holiday")
	instance.call("_hide_album")
	instance.call("_show_title")
	_check(bool((instance.get("_title_screen") as Control).visible), "returning to the door must restore the title")
	instance.queue_free()
	await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
