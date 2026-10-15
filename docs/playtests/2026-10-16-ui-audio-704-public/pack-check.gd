extends SceneTree

func _initialize() -> void:
	var identity = JSON.parse_string(FileAccess.get_file_as_string("res://config/build_identity.json"))
	var notes = JSON.parse_string(FileAccess.get_file_as_string("res://config/release_notes.json"))
	var assets: Dictionary = {}
	for name in ["ui_open", "ui_close", "ui_page"]:
		var path = "res://assets/holiday/audio/ui_grok/%s.tres" % name
		var stream = load(path)
		assets[name] = {"loaded": stream is AudioStreamWAV, "length": stream.get_length() if stream is AudioStreamWAV else 0}
	var args := OS.get_cmdline_user_args()
	var matched: bool = args.size() == 1 and identity is Dictionary and identity.get("sourceCommit") == args[0]
	matched = matched and notes is Dictionary and notes.releases[0].title == "背篓与相册轻交互音" and notes.releases[1].build == "bb04fde"
	print("UI704_PUBLIC_PACK ", JSON.stringify({"identity": identity, "identity_and_notes_match": matched, "first_release": notes.releases[0], "previous_release": notes.releases[1], "approved_streams": assets}))
	quit(0 if matched and assets.ui_open.loaded and assets.ui_close.loaded and assets.ui_page.loaded else 1)
