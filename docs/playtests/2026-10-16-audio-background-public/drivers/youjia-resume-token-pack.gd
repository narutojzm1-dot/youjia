extends SceneTree
func _initialize() -> void:
	var identity = JSON.parse_string(FileAccess.get_file_as_string("res://config/build_identity.json"))
	var notes = JSON.parse_string(FileAccess.get_file_as_string("res://config/release_notes.json"))
	var args := OS.get_cmdline_user_args()
	var ok: bool = args.size() == 1 and identity.sourceCommit == args[0]
	ok = ok and notes.releases[0].title == "后台迟到恢复边界修正" and notes.releases[1].build == "0a1b56e"
	print("VISIBILITY_PACK ", JSON.stringify({"identity":identity,"notes":notes.releases[0],"previous":notes.releases[1].build,"matched":ok}))
	quit(0 if ok else 1)
