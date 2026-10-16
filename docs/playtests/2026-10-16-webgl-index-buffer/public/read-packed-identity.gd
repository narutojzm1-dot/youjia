extends SceneTree

func _init() -> void:
    var args := OS.get_cmdline_user_args()
    var identity = JSON.parse_string(FileAccess.get_file_as_string("res://config/build_identity.json"))
    var notes = JSON.parse_string(FileAccess.get_file_as_string("res://config/release_notes.json"))
    var result := {"expected": args[0], "identity": identity, "first_note": notes.releases[0], "previous_note_build": notes.releases[1].build}
    var passed: bool = identity.sourceCommit == args[0] and notes.releases[0].build == "current" and notes.releases[1].build == "4923085"
    result["passed"] = passed
    var file := FileAccess.open(args[1], FileAccess.WRITE)
    file.store_string(JSON.stringify(result))
    file.close()
    print("PACK_IDENTITY_AND_NOTES ", JSON.stringify(result))
    quit(0 if passed else 1)
