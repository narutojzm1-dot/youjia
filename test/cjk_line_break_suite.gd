extends SceneTree
## 中文自动折行守行首禁则：句号、逗号、右引号等不单独落到下一行开头。
## 修前：导出包不带文字服务器的断行数据（`internationalization/locale/include_text_server_data` 默认关），
## Web 上中文退成逐字断行，近郊 280 宽「……带上的」后面的「。」独占一行。编辑器里有数据，原生看不出来，
## 所以这里既守项目开关，也用游戏字体把全部中文文案在常见宽度下排一遍，确认行首没有禁则符号。
const SETTING := "internationalization/locale/include_text_server_data"
const LINE_START_FORBIDDEN := "。，、！？；：）」』》〉】”’…"
const BREAK_FLAGS := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
const FONT_SIZES := [15, 17]

var checks := 0
var failures: Array[String] = []


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


func _init() -> void:
	check(ProjectSettings.get_setting(SETTING, false) == true, "export ships text server break data (%s)" % SETTING)
	var server := TextServerManager.get_primary_interface()
	check(server.has_feature(TextServer.FEATURE_BREAK_ITERATORS), "text server '%s' uses break iterators" % server.get_name())

	var font: Font = load("res://assets/template/fonts/ui_regular.tres")
	check(font != null, "game UI font loads")
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://localization/zh-CN.json"))
	var strings: Dictionary = catalog.get("strings", catalog)
	check(strings.size() > 100, "zh-CN catalog has its strings (%d)" % strings.size())

	# 近郊 280 宽实玩复现句：窄到放不下「的」时，「的。」一起换行
	var repro := "路边草里落着松果，左边远处是一片松林。\n篮子里的松果是在这里带上的。"
	for width: int in range(200, 260, 2):
		var lines := _lines(repro, font, 17, width)
		check(not lines.has("。"), "repro caption at %dpx keeps the full stop with its word %s" % [width, lines])

	var laid := 0
	for key: String in strings:
		var text := str(strings[key])
		if text.length() < 6: continue
		var bad := ""
		for font_size: int in FONT_SIZES:
			for width: int in range(96, 580, 6):
				for line: String in _lines(text, font, font_size, width):
					laid += 1
					if not line.is_empty() and LINE_START_FORBIDDEN.contains(line[0]):
						bad = "%dpx/%d '%s'" % [width, font_size, line]
						break
				if not bad.is_empty(): break
			if not bad.is_empty(): break
		check(bad.is_empty(), "%s never starts a line with closing punctuation %s" % [key, bad])
	check(laid > 10000, "laid out enough lines (%d)" % laid)

	if failures.is_empty():
		print("CJK_LINE_BREAK checks=%d failures=0" % checks)
	else:
		print("CJK_LINE_BREAK checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _lines(text: String, font: Font, font_size: int, width: int) -> Array[String]:
	var paragraph := TextParagraph.new()
	paragraph.add_string(text, font, font_size)
	paragraph.width = width
	paragraph.break_flags = BREAK_FLAGS
	var out: Array[String] = []
	for i: int in paragraph.get_line_count():
		var r := paragraph.get_line_range(i)
		out.append(text.substr(r.x, r.y - r.x).strip_edges(true, false))
	return out
