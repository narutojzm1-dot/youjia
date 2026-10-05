extends SceneTree

## REQ-20261005-032: native Open Source Licenses AcceptDialog used a fixed
## 560×320 TextEdit (~576×378 window). On portrait phones and short landscape
## it ran off the screen. The text area now fits the viewport minus margins
## and title/OK chrome; the window is clamped and recentred. Desktop sizes keep
## 560×320 when they fit. Web still opens the HTML page and is not covered here.

const OpenSourceLicenses = preload("res://scripts/manus/open_source_licenses.gd")

const VIEWPORTS := [
	Vector2i(320, 568), Vector2i(360, 640), Vector2i(390, 844), Vector2i(412, 915),
	Vector2i(568, 320), Vector2i(640, 300), Vector2i(844, 390), Vector2i(700, 400),
	Vector2i(1280, 720),
]
const MARGIN := 12.0
const EPS := 1.5

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for dims in VIEWPORTS:
		root.size = dims
		await _settle()
		await _check_fit(dims, "open")
	await _check_resize_path()
	_finish()


func _settle() -> void:
	for i in 6:
		await process_frame


func _purge_dialogs() -> void:
	for child in root.get_children():
		if child is AcceptDialog:
			(child as AcceptDialog).hide()
			child.queue_free()
	# Allow exclusive-window teardown
	for i in 8:
		await process_frame


func _open_dialog() -> AcceptDialog:
	await _purge_dialogs()
	OpenSourceLicenses.open(root)
	await _settle()
	var found: AcceptDialog = root.get_node_or_null("OpenSourceLicensesDialog") as AcceptDialog
	if found == null:
		for child in root.get_children():
			if child is AcceptDialog:
				found = child as AcceptDialog
				break
	return found


func _close_dialog(dialog: AcceptDialog) -> void:
	if dialog != null and is_instance_valid(dialog):
		dialog.hide()
		dialog.queue_free()
	await _purge_dialogs()


func _check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append(msg)


func _check_fit(dims: Vector2i, tag: String) -> void:
	var dialog := await _open_dialog()
	_check(dialog != null, "%s %s: dialog opened" % [dims, tag])
	if dialog == null:
		return
	var text: TextEdit = null
	for child in dialog.get_children():
		if child is TextEdit:
			text = child as TextEdit
			break
	_check(text != null, "%s %s: TextEdit present" % [dims, tag])
	if text == null:
		await _close_dialog(dialog)
		return
	var decoration := OpenSourceLicenses._decoration(dialog)
	var available := Vector2(dims) - Vector2(decoration.x + decoration.z, decoration.y + decoration.w)
	var expected: Vector2 = OpenSourceLicenses._fit_text_size(available)
	_check(absf(text.custom_minimum_size.x - expected.x) <= EPS and absf(text.custom_minimum_size.y - expected.y) <= EPS,
		"%s %s: text min %s == %s" % [dims, tag, text.custom_minimum_size, expected])
	var rect := _outer_rect(dialog)
	_check(rect.size.x <= float(dims.x) - MARGIN * 2.0 + EPS and rect.size.y <= float(dims.y) - MARGIN * 2.0 + EPS,
		"%s %s: dialog size %s within viewport-minus-margin %s" % [dims, tag, dialog.size, dims])
	_check(rect.position.x >= MARGIN - EPS and rect.position.y >= MARGIN - EPS
		and rect.end.x <= float(dims.x) - MARGIN + EPS and rect.end.y <= float(dims.y) - MARGIN + EPS,
		"%s %s: dialog rect %s stays inside %dpx margin" % [dims, tag, rect, int(MARGIN)])
	_check(absf(rect.get_center().x - float(dims.x) * 0.5) <= 2.0
		and absf(rect.get_center().y - float(dims.y) * 0.5) <= 2.0,
		"%s %s: dialog centred" % [dims, tag])
	_check(dialog.title == "Open Source Licenses", "%s %s: title unchanged" % [dims, tag])
	_check(not text.editable and text.wrap_mode == TextEdit.LINE_WRAPPING_BOUNDARY,
		"%s %s: TextEdit still read-only wrapped" % [dims, tag])
	_check(text.text.contains("Godot Engine"), "%s %s: license body present" % [dims, tag])
	if available.x >= 560 + MARGIN * 2.0 + 16.0 and available.y >= 320 + MARGIN * 2.0 + 58.0:
		_check(absf(text.custom_minimum_size.x - 560.0) <= EPS and absf(text.custom_minimum_size.y - 320.0) <= EPS,
			"%s %s: desktop keeps design 560×320" % [dims, tag])
	await _close_dialog(dialog)


func _check_resize_path() -> void:
	await _purge_dialogs()
	var original_connections := root.size_changed.get_connections().size()
	root.size = Vector2i(1280, 720)
	await _settle()
	var dialog := await _open_dialog()
	_check(dialog != null, "resize: dialog on desktop")
	var identity := dialog.get_instance_id()
	var text := dialog.get_child(0) as TextEdit
	var original_body := text.text
	for dims in [Vector2i(390, 844), Vector2i(568, 320), Vector2i(320, 568), Vector2i(640, 300), Vector2i(1280, 720)]:
		root.size = dims
		await _settle()
		_check(dialog.get_instance_id() == identity and dialog.visible, "resize: same live dialog")
		var rect := _outer_rect(dialog)
		_check(rect.position.x >= MARGIN - EPS and rect.position.y >= MARGIN - EPS
			and rect.end.x <= dims.x - MARGIN + EPS and rect.end.y <= dims.y - MARGIN + EPS,
			"live %s: fitted %s" % [dims, rect])
		_check(text.custom_minimum_size == OpenSourceLicenses._fit_text_size(Vector2(dims) - (_outer_rect(dialog).size - Vector2(dialog.size))), "live: text refits")
		_check(text.text == original_body, "live: license body preserved")
		var ok := dialog.get_ok_button().get_global_rect()
		_check(Rect2(Vector2.ZERO, Vector2(dialog.size)).encloses(ok), "live: OK within dialog")
		if dims == Vector2i(1280, 720):
			_check(text.custom_minimum_size == Vector2(560, 320), "live: desktop text restored")
			_check(dialog.size.x >= 560 and dialog.size.y >= 320, "live: desktop window restored")
	dialog.confirmed.emit()
	await _settle()
	_check(not is_instance_valid(dialog), "confirmed: frees dialog")
	_check(root.size_changed.get_connections().size() == original_connections, "confirmed: disconnects resize")
	# Reopen/cancel and resize after both exit paths must not retain dead targets.
	dialog = await _open_dialog()
	root.size = Vector2i(640, 300)
	dialog.canceled.emit()
	await _settle()
	_check(not is_instance_valid(dialog), "canceled: frees dialog")
	_check(root.size_changed.get_connections().size() == original_connections, "canceled: disconnects resize")
	root.size = Vector2i(390, 844)
	await _settle()
	await _check_fit(Vector2i(390, 844), "reopen-after-close")
	_check(root.size_changed.get_connections().size() == original_connections, "reopen: no connection accumulation")


func _outer_rect(dialog: Window) -> Rect2:
	var edges := OpenSourceLicenses._decoration(dialog)
	return Rect2(Vector2(dialog.position) - Vector2(edges.x, edges.y),
		Vector2(dialog.size) + Vector2(edges.x + edges.z, edges.y + edges.w))


func _finish() -> void:
	print("licenses_dialog_fit_suite checks=%d failures=%d" % [checks, failures.size()])
	for f in failures:
		print("FAIL: ", f)
	if failures.is_empty():
		print("PASS licenses_dialog_fit_suite")
		quit(0)
	else:
		quit(1)
