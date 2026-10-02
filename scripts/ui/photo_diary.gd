class_name PhotoDiary
extends RefCounted

# Pure presentation. Snapshot IDs and days are stored by PhotoMoment; no
# extra diary state, wall clock, randomness, or generated event descriptions.
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
	var moment := str(locale.call("t", key)) if locale.call("has_key", key) else title
	return str(locale.call("t", "photo.diary.day", {"day": str(day), "moment": moment}))
