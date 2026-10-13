extends SceneTree
const Notices := preload("res://scripts/ui/release_notes.gd")
var checks := 0
var failures := 0
var main

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func settle() -> void:
	for i in 8: await process_frame

func key(code: Key) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		root.push_input(event)
		await process_frame

func _run() -> void:
	var sha := "c874273bc16f6b99e43da49de8907008f52d44d9"
	var release := {"schema":"youjia.release/v1", "sourceCommit":sha, "entry":"game-c874273"}
	check(Notices.latest_status(release, sha).contains("最新"), "same build")
	check(Notices.latest_status(release, "older").contains("不同"), "old build")
	for invalid in [null, [], {}, {"schema":"youjia.release/v1", "sourceCommit":sha, "entry":"wrong"}]:
		check(Notices.latest_status(invalid, sha).contains("无法"), "never claim latest on failed check")
	var missing_schema := release.duplicate()
	missing_schema.erase("schema")
	check(Notices.latest_status(missing_schema, sha).contains("无法"), "missing schema cannot claim latest")
	var wrong_schema := release.duplicate()
	wrong_schema.schema = "youjia.release/v2"
	check(Notices.latest_status(wrong_schema, sha).contains("无法"), "wrong schema cannot claim latest")
	for invalid_source: String in ["g".repeat(40), sha.to_upper(), sha.left(39), sha + "0"]:
		var invalid_release := {"schema":"youjia.release/v1", "sourceCommit":invalid_source, "entry":"game-" + invalid_source.left(7)}
		check(Notices.latest_status(invalid_release, invalid_source).contains("无法"), "invalid source cannot claim latest: " + invalid_source)
	for dims in [Vector2i(1280,720),Vector2i(390,844),Vector2i(280,640),Vector2i(640,300),Vector2i(844,390)]:
		root.size = dims
		main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		await settle()
		main.set_process(false)
		await main._start_holiday()
		await settle()
		main._toggle_pause()
		await settle()
		check(main._release_button.is_visible_in_tree(), "pause entry visible")
		check(Rect2(Vector2.ZERO,Vector2(dims)).encloses(main._release_button.get_global_rect()), "entry on screen")
		if OS.get_environment("YOUJIA_CAPTURE_NOTICES") == "1":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/playtests/2026-10-12-release-notices/pause-%sx%s.png" % [dims.x,dims.y])
		main._release_button.pressed.emit()
		await settle()
		var panel = main._release_panel
		check(paused and panel.visible and main._pause_screen.visible, "notes keep world paused")
		check(Rect2(Vector2.ZERO,Vector2(dims)).encloses(panel.card.get_global_rect()), "notes fit %s" % dims)
		check(panel.content.size.y > 32, "scrolling body has space")
		check(panel.content.text.contains("新增功能") and panel.content.text.contains("问题修复"), "notes categories")
		check(panel.content.text.contains("c874273"), "retained history")
		await key(KEY_TAB)
		check(panel.is_ancestor_of(root.gui_get_focus_owner()), "tab stays inside notes")
		for direction in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
			await key(direction)
			check(panel.is_ancestor_of(root.gui_get_focus_owner()), "arrows stay inside notes")
		await key(KEY_ESCAPE)
		check(not panel.visible and paused and main._pause_screen.visible, "escape returns to paused menu")
		check(root.gui_get_focus_owner() == main._release_button, "return focus")
		if OS.get_environment("YOUJIA_CAPTURE_NOTICES") == "1":
			main._show_release_notes()
			await settle()
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/playtests/2026-10-12-release-notices/notes-%sx%s.png" % [dims.x,dims.y])
			panel.close()
		await key(KEY_ESCAPE)
		check(not paused and not main._pause_screen.visible, "second escape resumes world")
		main.queue_free()
		await settle()
	print("RELEASE_NOTES checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
