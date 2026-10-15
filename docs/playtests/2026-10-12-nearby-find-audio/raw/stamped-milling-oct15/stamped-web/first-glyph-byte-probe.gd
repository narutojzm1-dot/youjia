extends SceneTree
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)
func run() -> void:
	var identity: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/build_identity.json"))
	check(identity.get("sourceCommit") == "b784c2cb9020c11cf17821db4f534c3bcceeb328", "actual packed identity matches the validated source")
	var notes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/release_notes.json"))
	var feature := "近郊拾起小物时，会响一声轻柔的提示音。"
	var fix := "静音、歇一下或返院会停止拾物声音，恢复或重新进入不补播。"
	check(feature in notes.releases[0].features and fix in notes.releases[0].fixes, "actual pack contains the pickup announcement")
	var font := load("res://assets/template/fonts/ui_regular.tres") as Font
	for point in (feature + fix + str(notes.releases[0].title)).to_utf32_buffer():
		if point >= 32: check(font != null and font.has_char(point), "actual packed announcement glyph " + str(point))
	check(ResourceLoader.exists("res://assets/holiday/audio/exploration_find_get.wav"), "approved pickup resource is retained")
	root.get_node("AudioDirector").release_streams()
	await create_timer(0.15).timeout
	print("FIND16_STAMPED_PACK checks=%d failures=%d identity=%s" % [checks,failures.size(),identity.get("sourceCommit", "")])
	quit(0 if failures.is_empty() else 1)
