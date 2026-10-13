extends Control
## Bundled notes describe this PCK. A network response may only update the status.
signal closed
const NOTES := "res://config/release_notes.json"
const IDENTITY := "res://config/build_identity.json"
var back: Button
var heading: Label
var status: Label
var content: RichTextLabel
var card: PanelContainer
var request: HTTPRequest
var _focus_input: Node
var _opened_once := false
var _status_phase := ""
var _status_data: Variant = null
var _status_current := ""

static func version() -> String:
	var notes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(NOTES))
	return str(notes.get("version", "0.2.0"))

static func identity() -> Dictionary:
	var value = JSON.parse_string(FileAccess.get_file_as_string(IDENTITY))
	return value if value is Dictionary else {}

static func _t(key: String, replacements: Dictionary = {}) -> String:
	return Engine.get_main_loop().root.get_node("I18n").call("t", key, replacements)

static func build_name() -> String:
	var sha := str(identity().get("sourceCommit", ""))
	return "game-" + sha.left(7) if sha.length() == 40 else _t("notes.build.local")

## 暂停纸片右上角那枚小按钮。矮屏排成一行，高屏分两行。
static func chip_label(short: bool) -> String:
	var build := build_name()
	if build == _t("notes.build.local"):
		build = _t("notes.build.local_short")
	return "%s · %s%s%s" % [version(), _t("notes.chip"), " · " if short else "\n", build]

static func latest_status(data: Variant, current: String) -> String:
	if not data is Dictionary: return _t("notes.status.unavailable")
	var source := str(data.get("sourceCommit", ""))
	# Match the loading shell's release identity contract before claiming latest.
	var source_pattern := RegEx.create_from_string("^[a-f0-9]{40}$")
	if data.get("schema", "") != "youjia.release/v1" or source.length() != 40 or source_pattern.search(source) == null or str(data.get("entry", "")) != "game-" + source.left(7):
		return _t("notes.status.unavailable")
	if current.is_empty(): return _t("notes.status.unpublished")
	if source == current: return _t("notes.status.latest")
	return _t("notes.status.different", {"build": source.left(7)})

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_focus_input = preload("res://scripts/ui/pointer_focus.gd").new()
	add_child(_focus_input)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.2, 0.16, 0.12, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	card = PanelContainer.new()
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("fff6e8")
	paper.border_color = Color("c89564")
	paper.set_border_width_all(2)
	paper.set_corner_radius_all(16)
	paper.content_margin_left = 16
	paper.content_margin_right = 16
	paper.content_margin_top = 12
	paper.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", paper)
	add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	heading = Label.new()
	heading.text = _t("notes.heading")
	heading.add_theme_font_size_override("font_size", 24)
	heading.add_theme_color_override("font_color", Color("604936"))
	box.add_child(heading)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 14)
	status.add_theme_color_override("font_color", Color("775c47"))
	box.add_child(status)
	content = RichTextLabel.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.bbcode_enabled = false
	content.add_theme_color_override("default_color", Color("604936"))
	content.add_theme_font_size_override("normal_font_size", 16)
	content.focus_mode = Control.FOCUS_ALL
	box.add_child(content)
	back = Button.new()
	back.text = _t("notes.back")
	back.custom_minimum_size.y = 42
	back.add_theme_color_override("font_color", Color("604936"))
	back.add_theme_color_override("font_hover_color", Color("604936"))
	back.add_theme_color_override("font_pressed_color", Color("604936"))
	back.add_theme_color_override("font_focus_color", Color("604936"))
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("f1dfc7") if state != "hover" else Color("f7e8d3")
		style.border_color = Color("b9824e")
		style.set_border_width_all(2 if state == "focus" else 1)
		style.set_corner_radius_all(8)
		if state == "focus": style.draw_center = false
		back.add_theme_stylebox_override(state, style)
	back.pressed.connect(close)
	box.add_child(back)
	content.focus_next = content.get_path_to(back)
	content.focus_previous = content.get_path_to(back)
	back.focus_next = back.get_path_to(content)
	back.focus_previous = back.get_path_to(content)
	for direction in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		content.set_focus_neighbor(direction, content.get_path_to(back))
		back.set_focus_neighbor(direction, back.get_path_to(content))
	request = HTTPRequest.new()
	# Browser Fetch already decodes gzip/deflate but retains Content-Encoding.
	# Do not run Godot's decompressor on the decoded Web response a second time.
	request.accept_gzip = not OS.has_feature("web")
	request.timeout = 8.0
	request.body_size_limit = 65536
	request.request_completed.connect(_checked)
	add_child(request)
	resized.connect(_fit)
	Engine.get_main_loop().root.get_node("I18n").connect("locale_changed", _on_locale)
	_fit()
	hide()

func _on_locale(_locale: String) -> void:
	if heading != null: heading.text = _t("notes.heading")
	if back != null: back.text = _t("notes.back")
	if visible:
		_fill()
		_apply_status()

func _fit() -> void:
	if card == null: return
	card.size = Vector2(minf(640, size.x - 24), minf(620, size.y - 24))
	card.position = (size - card.size) * 0.5

func _fill() -> void:
	heading.text = _t("notes.heading")
	back.text = _t("notes.back")
	var notes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(NOTES))
	var lines := PackedStringArray([_t("notes.current", {"version": notes.version, "label": notes.label}), build_name(), ""])
	for release: Dictionary in notes.releases:
		var build := build_name() if release.build == "current" else "game-" + str(release.build)
		lines.append("%s · %s\n%s" % [release.date, release.title, build])
		for field: String in ["features", "fixes"]:
			if release.get(field, []).is_empty(): continue
			lines.append(_t("notes.features" if field == "features" else "notes.fixes"))
			for item: String in release[field]: lines.append("• " + item)
		if release.has("note"): lines.append(str(release.note))
		lines.append("")
	content.text = "\n".join(lines)

func open() -> void:
	show()
	_fill()
	content.scroll_to_line(0)
	# 第一次打开时本面板才建出来，没收到点「公告」的那次按下；按「公告」当时的焦点是否可见来判断。
	if not _opened_once:
		var opener := get_viewport().gui_get_focus_owner()
		_focus_input.pointer = opener == null or not opener.has_focus(true)
		_opened_once = true
	_focus_input.grab(back)
	_apply_status("offline")
	if OS.has_feature("web"):
		var url = JavaScriptBridge.eval("new URL('game-release.json', location.href).href", true)
		if url is String:
			_apply_status("checking")
			if request.request(url + "?check=" + str(Time.get_unix_time_from_system()), ["Cache-Control: no-cache"]) != OK:
				_apply_status("result", null, "")
	else:
		_apply_status("local_only")

func close() -> void:
	request.cancel_request()
	hide()
	closed.emit()
	# 收到 closed 的一方会把焦点交回「公告」；点按关上的就不画焦点圈，键盘一导航再显出来。
	var returned := get_viewport().gui_get_focus_owner()
	if _focus_input.pointer and returned != null and returned.has_focus(true):
		returned.release_focus()
		returned.grab_focus(true)

func _apply_status(phase: String = "", data: Variant = null, current: String = "") -> void:
	if phase != "":
		_status_phase = phase
		_status_data = data
		_status_current = current
	if status == null or _status_phase == "": return
	match _status_phase:
		"offline": status.text = _t("notes.status.offline")
		"checking": status.text = _t("notes.status.checking")
		"local_only": status.text = _t("notes.status.local_only")
		"result": status.text = latest_status(_status_data, _status_current)

func _checked(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if not visible: return
	var data = JSON.parse_string(body.get_string_from_utf8()) if result == HTTPRequest.RESULT_SUCCESS and code == 200 else null
	_apply_status("result", data, str(identity().get("sourceCommit", "")))
