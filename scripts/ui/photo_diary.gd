class_name PhotoDiary
extends RefCounted

# Pure presentation. A bounded variant is chosen once by PhotoMoment.capture.
# Reading, switching languages and reopening the album never draw again.
#
# REQ-20261009-077 (Owner GROK-CONTRIBUTOR): when the snapshot recorded weather,
# the diary line pads a short weather crumb (reusing hud.weather.*) between the
# day and the moment — sunny / overcast / rainy photos read apart at a glance.
# Old saves without a weather field keep the previous two-line caption.
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
	var weather := weather_crumb(snapshot, locale)
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
