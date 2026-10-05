extends SceneTree
# Run from an imported project, passing absolute --reader and --samples paths.
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var script: Script = load(args[args.find("--reader") + 1])
	var reader: RefCounted = script.new()
	var samples := args[args.find("--samples") + 1]
	for kind: String in ["natural_full", "dense_full"]:
		var path := samples.path_join(kind + ".primary.json")
		var result: Dictionary = reader.call("read_source", path, "candidate-v1")
		assert(result.status == "present")
		assert(Marshalls.base64_to_raw(result.base64) == FileAccess.get_file_as_bytes(path))
		assert(reader.call("read_source", path).status == "read_error")
	assert(reader.call("read_source", samples.path_join("natural_full.primary.json"), "invalid").status == "read_error")
	print("[budget-source] PASS 7 assertions")
	quit()
