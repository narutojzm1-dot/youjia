extends Control
## Bundled notes describe this PCK. A network response may only update the status.
signal closed
const NOTES := "res://config/release_notes.json"
const IDENTITY := "res://config/build_identity.json"
var back: Button
var status: Label
var content: RichTextLabel
var card: PanelContainer
var request: HTTPRequest
var _focus_input: Node

static func version() -> String:
	var notes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(NOTES))
	return str(notes.get("version", "0.2.0"))

static func identity() -> Dictionary:
	var value = JSON.parse_string(FileAccess.get_file_as_string(IDENTITY))
	return value if value is Dictionary else {}

static func build_name() -> String:
	var sha := str(identity().get("sourceCommit", ""))
	return "game-" + sha.left(7) if sha.length() == 40 else "本地开发版（未发布）"

static func latest_status(data: Variant, current: String) -> String:
	if not data is Dictionary: return "暂时无法检查更新；以下仍是本版本公告。"
	var source := str(data.get("sourceCommit", ""))
	# Match the loading shell's release identity contract before claiming latest.
	var source_pattern := RegEx.create_from_string("^[a-f0-9]{40}$")
	if data.get("schema", "") != "youjia.release/v1" or source.length() != 40 or source_pattern.search(source) == null or str(data.get("entry", "")) != "game-" + source.left(7):
		return "暂时无法检查更新；以下仍是本版本公告。"
	if current.is_empty(): return "本地开发版，未发布。"
	if source == current: return "已与线上核对：当前是最新发布版本。"
	return "线上版本为 game-%s，与当前不同。请保存进度后重新打开试玩入口。" % source.left(7)

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
	var heading := Label.new()
	heading.text = "更新公告"
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
	back.text = "返回歇一下"
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
	request.timeout = 8.0
	request.body_size_limit = 65536
	request.request_completed.connect(_checked)
	add_child(request)
	resized.connect(_fit)
	_fit()
	hide()

func _fit() -> void:
	if card == null: return
	card.size = Vector2(minf(640, size.x - 24), minf(620, size.y - 24))
	card.position = (size - card.size) * 0.5

func open() -> void:
	show()
	var notes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(NOTES))
	var lines := PackedStringArray(["当前版本 %s · %s" % [notes.version, notes.label], build_name(), ""])
	for release: Dictionary in notes.releases:
		var build := build_name() if release.build == "current" else "game-" + str(release.build)
		lines.append("%s · %s\n%s" % [release.date, release.title, build])
		for field: String in ["features", "fixes"]:
			if release.get(field, []).is_empty(): continue
			lines.append("新增功能" if field == "features" else "问题修复")
			for item: String in release[field]: lines.append("• " + item)
		if release.has("note"): lines.append(str(release.note))
		lines.append("")
	content.text = "\n".join(lines)
	content.scroll_to_line(0)
	# 第一次打开时本面板才建出来，没收到点「公告」的那次按下；按「公告」当时的焦点是否可见来判断。
	var opener := get_viewport().gui_get_focus_owner()
	_focus_input.pointer = opener == null or not opener.has_focus(true)
	_focus_input.grab(back)
	status.text = "离线公告 · 尚未检查线上版本。"
	if OS.has_feature("web"):
		var url = JavaScriptBridge.eval("new URL('game-release.json', location.href).href", true)
		if url is String:
			status.text = "正在检查线上版本…"
			if request.request(url + "?check=" + str(Time.get_unix_time_from_system()), ["Cache-Control: no-cache"]) != OK:
				status.text = latest_status(null, "")
	else:
		status.text = "本地版本；未检查线上发布。"

func close() -> void:
	request.cancel_request()
	hide()
	closed.emit()
	# 收到 closed 的一方会把焦点交回「公告」；点按关上的就不画焦点圈，键盘一导航再显出来。
	var returned := get_viewport().gui_get_focus_owner()
	if _focus_input.pointer and returned != null and returned.has_focus(true):
		returned.release_focus()
		returned.grab_focus(true)

func _checked(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if not visible: return
	var data = JSON.parse_string(body.get_string_from_utf8()) if result == HTTPRequest.RESULT_SUCCESS and code == 200 else null
	status.text = latest_status(data, str(identity().get("sourceCommit", "")))
