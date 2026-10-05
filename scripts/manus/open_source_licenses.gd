extends RefCounted

# The title menu owns the entry; the shared Web exporter owns the versioned page.
# Native AcceptDialog used to hard-code a 560×320 text area (~576×378 window),
# which ran off portrait phones and short landscape (REQ-20261005-032).

const DESIGN_TEXT_SIZE := Vector2(560, 320)
const VIEW_MARGIN := 12.0
## Title bar + OK button row + AcceptDialog padding around the TextEdit.
const CHROME := Vector2(16, 58)


static func open(parent: Node) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.open(new URL('open-source-licenses.html', window.location.href).href, '_blank', 'noopener');", true)
		parent.get_viewport().set_input_as_handled()
		return
	var viewport := parent.get_viewport()
	var viewport_size: Vector2 = viewport.get_visible_rect().size
	var dialog := AcceptDialog.new()
	dialog.name = "OpenSourceLicensesDialog"
	dialog.title = "Open Source Licenses"
	var text := TextEdit.new()
	text.editable = false
	text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	text.custom_minimum_size = _fit_text_size(viewport_size)
	text.text = "Godot Engine " + Engine.get_version_info().string + "\n\n" + Engine.get_license_text()
	text.text += "\n\n" + JSON.stringify(Engine.get_copyright_info(), "\t")
	for license_name: String in Engine.get_license_info():
		text.text += "\n\n" + license_name + "\n" + str(Engine.get_license_info()[license_name])
	dialog.add_child(text)
	parent.add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	# Observe the parent viewport, not the dialog's own size_changed signal.
	# Reset the content minimum before fitting, so shrink and desktop restore work.
	var refit := _fit_open_dialog.bind(dialog, text, viewport)
	viewport.size_changed.connect(refit, CONNECT_DEFERRED)
	dialog.tree_exiting.connect(func() -> void:
		if is_instance_valid(viewport) and viewport.size_changed.is_connected(refit):
			viewport.size_changed.disconnect(refit)
	, CONNECT_ONE_SHOT)
	dialog.popup_centered()
	refit.call()
	parent.get_viewport().set_input_as_handled()


static func _fit_open_dialog(dialog: AcceptDialog, text: TextEdit, viewport: Viewport) -> void:
	if not is_instance_valid(dialog) or dialog.is_queued_for_deletion():
		return
	var viewport_size := viewport.get_visible_rect().size
	var decoration := _decoration(dialog)
	var content_view := viewport_size - Vector2(decoration.x + decoration.z, decoration.y + decoration.w)
	text.custom_minimum_size = _fit_text_size(content_view)
	# AcceptDialog recomputes its minimum from content plus actual theme chrome.
	dialog.size = Vector2i.ZERO
	_clamp_dialog(dialog, content_view)
	dialog.position += Vector2i(int(decoration.x), int(decoration.y))


static func _decoration(dialog: Window) -> Vector4:
	if not dialog.is_embedded():
		return Vector4.ZERO
	var border := dialog.get_theme_stylebox("embedded_border")
	return Vector4(border.get_content_margin(SIDE_LEFT),
		maxf(border.get_content_margin(SIDE_TOP), dialog.get_theme_constant("title_height")),
		border.get_content_margin(SIDE_RIGHT), border.get_content_margin(SIDE_BOTTOM))


static func _fit_text_size(viewport_size: Vector2) -> Vector2:
	var max_dialog := Vector2(
		maxf(180.0, viewport_size.x - VIEW_MARGIN * 2.0),
		maxf(160.0, viewport_size.y - VIEW_MARGIN * 2.0)
	)
	var max_text := Vector2(
		maxf(160.0, max_dialog.x - CHROME.x),
		maxf(120.0, max_dialog.y - CHROME.y)
	)
	return Vector2(minf(DESIGN_TEXT_SIZE.x, max_text.x), minf(DESIGN_TEXT_SIZE.y, max_text.y))


static func _clamp_dialog(dialog: Window, viewport_size: Vector2) -> void:
	var max_w := maxf(180.0, viewport_size.x - VIEW_MARGIN * 2.0)
	var max_h := maxf(160.0, viewport_size.y - VIEW_MARGIN * 2.0)
	var w := minf(float(dialog.size.x), max_w)
	var h := minf(float(dialog.size.y), max_h)
	dialog.size = Vector2i(int(round(w)), int(round(h)))
	dialog.position = Vector2i(
		int(round((viewport_size.x - w) * 0.5)),
		int(round((viewport_size.y - h) * 0.5))
	)
