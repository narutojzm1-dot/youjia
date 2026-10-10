class_name PhotoDiary
extends RefCounted

# Pure presentation. A bounded variant is chosen once by PhotoMoment.capture.
# Reading, switching languages and reopening the album never draw again.
#
# REQ-20261009-077：只有记下 caption_variant 的新快照，才在瞬间文案前垫天气纸签。
# 纸签复用 hud.weather.*（大太阳 / 阴天 / 细雨）。
# 缺 caption_variant 的旧照片即使仍带合法 weather，也保持原先说明，不回溯改字。
# 无 weather、未知值、或旧存档没有 day：行为与改前一致。
static func caption(snapshot: Dictionary, rule_id: String = "") -> String:
	var id := rule_id if not rule_id.is_empty() else str(snapshot.get("rule_id", ""))
	var rule := ExpressionCatalog.find_rule(id)
	if rule.is_empty():
		return ""
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return ""
	var locale := tree.root.get_node_or_null("I18n")
	if locale == null:
		return ""
	var title := str(locale.call("t", str(rule.get("title_key", ""))))
	if not snapshot.has("day"):
		return title # Old saves did not record the day: do not invent day one.
	var day := int(snapshot.day)
	if day < 1 or day > 10000:
		return title
	var key := "photo.diary." + id
	var variant := int(snapshot.get("caption_variant", 0))
	if variant > 0 and variant < clampi(int(rule.get("caption_variants", 1)), 1, 3):
		var alternative := key + ".v%d" % variant
		if locale.call("has_key", alternative): key = alternative
	var moment := str(locale.call("t", key)) if locale.call("has_key", key) else title
	# 天气纸签只加给带 caption_variant 的快照；缺该字段的旧照片保持原文。
	var weather := weather_crumb(snapshot, locale) if snapshot.has("caption_variant") else ""
	if not weather.is_empty():
		moment = "%s · %s" % [weather, moment]
	return str(locale.call("t", "photo.diary.day", {"day": str(day), "moment": moment}))


## Returns the existing hud.weather.* label for a recorded snapshot weather, or "".
## Unknown / missing weather leaves the caption unchanged (legacy album IDs).
static func weather_crumb(snapshot: Dictionary, locale: Node = null) -> String:
	if not snapshot is Dictionary or not snapshot.has("weather"):
		return ""
	var weather := str(snapshot.get("weather", ""))
	if weather not in ["sun", "overcast", "rain"]:
		return ""
	var key := "hud.weather." + weather
	if locale == null:
		var tree := Engine.get_main_loop() as SceneTree
		if tree == null:
			return ""
		locale = tree.root.get_node_or_null("I18n")
	if locale == null:
		return ""
	if not locale.call("has_key", key):
		return ""
	return str(locale.call("t", key))
