extends SceneTree

## REQ-20261007-051: the yard basket paper keeps its 12px screen margin and
## shows more rows on short landscape screens.
## Before: on a 280px-wide portrait screen the English fish row
## ("Curious fish  x 1" + the 104px button) forced the paper to 276px, so it
## sat 2px from each screen edge instead of 12px. On 568x320 / 640x300 the
## list window was only 146 / 126px tall (about three rows) because the 24px
## title, 8px gaps and the one-line note took the room.
## Now: row names wrap inside their own label instead of widening the paper,
## and on papers narrower than 280px the row buttons go from 104 to 88px
## (text still fits, still 44px tall) so Chinese names stay on one line;
## when the paper is at most 420px tall the title drops to 19px, gaps tighten
## and only the informational note is left out. Saving / failed / unknown
## messages and the retry button still show. Taller screens are unchanged.
## Fixture only: the panel is built on its own; no save is read or written.

const VIEWPORTS := [
	Vector2i(1280, 720), Vector2i(1024, 600), Vector2i(412, 915), Vector2i(390, 844), Vector2i(375, 667),
	Vector2i(360, 640), Vector2i(320, 568), Vector2i(320, 480), Vector2i(300, 560), Vector2i(280, 653),
	Vector2i(844, 390), Vector2i(740, 360), Vector2i(568, 320), Vector2i(640, 300),
]
const LOCALES := ["zh-CN", "en"]
const STATES := ["ready", "saving", "failed", "unknown"]
const EDGE := 12.0
const EPS := 0.75

var checks := 0
var failures: Array[String] = []
var panel: Control
var wrapped_en := 0
var compact_cases := 0


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


func _settle() -> void:
	for i in 4:
		await process_frame


func _inventory(held: String) -> Dictionary:
	return {"fish": {"small": 12, "medium": 3, "odd": 10}, "grass": 4, "millet": 25, "held": held}


func _keepsakes() -> Dictionary:
	return {ExplorationRoutes.FIND_STONE: 2, ExplorationRoutes.FIND_PINE_CONE: 11, ExplorationRoutes.FIND_FEATHER: 1}


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var tuning := root.get_node_or_null("TuningStore")
	if tuning != null and tuning.has_method("end_run"):
		tuning.call("end_run")
	var locale: Node = root.get_node("I18n")
	panel = load("res://scripts/ui/yard_basket_panel.gd").new()
	panel.name = "YardBasket"
	root.add_child(panel)
	await _settle()
	for language: String in LOCALES:
		locale.call("set_locale", language)
		for dims: Vector2i in VIEWPORTS:
			for state: String in STATES:
				for held: String in ["", "odd"]:
					root.size = dims
					panel.update_view(_inventory(held), _keepsakes(), state, state == "saving")
					await _settle()
					_check_layout(dims, "%s %s %s held=%s" % [language, dims, state, held], language, state)
	# The legacy rows are hidden behind the grid (REQ-20261007-064), so no row name wraps any more.
	check(wrapped_en == 0, "hidden legacy rows are no longer laid out as wrapped names (%d)" % wrapped_en)
	check(compact_cases > 0, "short landscape uses the compact layout (%d)" % compact_cases)
	await _specific_cases(locale)
	_finish()


func _check_layout(dims: Vector2i, tag: String, language: String, state: String) -> void:
	var view := Rect2(Vector2.ZERO, Vector2(dims))
	var paper: Rect2 = panel.panel.get_global_rect()
	check(paper.position.x >= EDGE - EPS and paper.end.x <= view.end.x - EDGE + EPS, tag + ": paper keeps 12px side margins (%s)" % paper)
	check(paper.position.y >= EDGE - EPS and paper.end.y <= view.end.y - EDGE + EPS, tag + ": paper keeps 12px top/bottom margins (%s)" % paper)
	var short: bool = paper.size.y <= 420.0 + EPS
	check(panel.compact == short, tag + ": compact only when the paper is at most 420px tall")
	if short:
		compact_cases += 1
	var title_size: int = panel.title.get_theme_font_size("font_size")
	check(title_size == (19 if short else 24), tag + ": title %d px" % title_size)
	var warning := state != "ready"
	check(panel.status.visible == (warning or not short), tag + ": note hidden only on short screens, warnings always shown")
	check(panel.retry_button.visible == (state in ["failed", "unknown"]), tag + ": retry visibility unchanged")
	var scroll_rect: Rect2 = panel.scroll.get_global_rect()
	check(paper.encloses(scroll_rect), tag + ": list window inside the paper")
	check(scroll_rect.size.y >= 60.0, tag + ": list window keeps room for at least one row (%.0f)" % scroll_rect.size.y)
	for control: Control in [panel.title, panel.status, panel.retry_button, panel.close_button]:
		if control.is_visible_in_tree():
			check(paper.encloses(control.get_global_rect().grow(-0.5)), tag + ": %s inside the paper" % control.name)
	for button: Button in [panel.close_button, panel.retry_button]:
		if button.is_visible_in_tree():
			_check_button(button, tag)
			check(button.size.y >= 44.0 - EPS, tag + ": %s keeps a 44px touch target" % button.text)
	# REQ-20261007-064: the player-facing list is now the rows x columns grid; the old
	# per-row name + "Take one" nodes stay for the legacy interface but are hidden.
	check(panel.grid.is_visible_in_tree(), tag + ": basket grid is what the player sees")
	for kind: String in panel.grid.cells:
		var cell: Rect2 = panel.grid.cells[kind].get_global_rect()
		check(cell.position.x >= scroll_rect.position.x - EPS and cell.end.x <= scroll_rect.end.x + EPS, tag + ": %s cell inside the list width" % kind)
	for row: Control in panel.list_rows:
		check(not row.is_visible_in_tree(), tag + ": legacy list row hidden behind the grid")
	# Rows: horizontally inside the list window, names never wider than their label.
	for label: Label in [panel.held_label]:
		_check_label(label, scroll_rect, tag)
	for kind: String in ([] if not panel.fish_labels.values()[0].is_visible_in_tree() else panel.fish_labels.keys()):
		var label: Label = panel.fish_labels[kind]
		var button: Button = panel.fish_buttons[kind]
		_check_label(label, scroll_rect, tag)
		_check_button(button, tag)
		check(button.size.y >= 44.0 - EPS, tag + ": %s button keeps 44px" % kind)
		var want := 88.0 if paper.size.x < 280.0 else 104.0
		check(is_equal_approx(button.custom_minimum_size.x, want), tag + ": %s button %.0f px wide on this paper" % [kind, want])
		var lr := label.get_global_rect()
		var br := button.get_global_rect()
		check(lr.end.x <= br.position.x + EPS, tag + ": %s name stays left of its button" % kind)
		check(br.end.x <= scroll_rect.end.x + EPS, tag + ": %s button inside the list window" % kind)
		if language == "zh-CN":
			check(label.get_line_count() == 1, tag + ": Chinese %s name stays on one line" % kind)
		elif label.get_line_count() > 1:
			wrapped_en += 1
			check(dims.x <= 300, tag + ": English %s name only wraps on the narrowest phones" % kind)
	check(not panel.scoop_button.is_visible_in_tree(), tag + ": retired infinite grain tin stays hidden")
	for button: Button in [panel.return_button]:
		_check_button(button, tag)
		check(button.get_global_rect().end.x <= scroll_rect.end.x + EPS, tag + ": %s inside the list window" % button.text)


func _check_label(label: Label, window: Rect2, tag: String) -> void:
	var rect := label.get_global_rect()
	check(rect.position.x >= window.position.x - EPS and rect.end.x <= window.end.x + EPS, tag + ": '%s' inside the list width" % label.text)
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var lines := label.get_line_count()
	var line_h := font.get_height(font_size)
	check(lines * line_h <= rect.size.y + EPS + lines, tag + ": '%s' all %d lines get their height (%.0f)" % [label.text, lines, rect.size.y])
	var widest := 0.0
	for word: String in label.text.split(" ", false):
		widest = maxf(widest, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	check(widest <= rect.size.x + EPS, tag + ": '%s' longest word fits" % label.text)
	if lines == 1:
		var full := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		check(full <= rect.size.x + EPS, tag + ": '%s' one line fits (%.0f/%.0f)" % [label.text, full, rect.size.x])


func _check_button(button: Button, tag: String) -> void:
	var font := button.get_theme_font("font")
	var need := font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
	check(need + 8.0 <= button.size.x + EPS, tag + ": '%s' text fits its button (%.0f/%.0f)" % [button.text, need, button.size.x])


func _specific_cases(locale: Node) -> void:
	# The old failure: 280 portrait, English.
	locale.call("set_locale", "en")
	root.size = Vector2i(280, 653)
	panel.update_view(_inventory(""), _keepsakes(), "ready", false)
	await _settle()
	var paper: Rect2 = panel.panel.get_global_rect()
	check(is_equal_approx(paper.position.x, 12.0) and is_equal_approx(paper.size.x, 256.0), "en 280x653 paper is 256px wide at x=12 (got %s)" % paper)
	check(panel.grid.grid.columns == 3, "en 280x653 basket grid uses three columns")
	check(panel.grid.name_labels["odd"].get_line_count() == 1, "en 280x653 'Odd fish' cell name stays on one line")
	# Short landscape: the list window really is taller than before (146 / 126px).
	for dims: Vector2i in [Vector2i(568, 320), Vector2i(640, 300)]:
		root.size = dims
		panel.update_view(_inventory(""), _keepsakes(), "ready", false)
		await _settle()
		var before := 146.0 if dims.y == 320 else 126.0
		var now: float = panel.scroll.size.y
		check(now >= before + 36.0, "en %s list window grows from %.0f to %.0f px" % [dims, before, now])
		check(panel.rows.get_combined_minimum_size().y > now, "en %s list still scrolls for the lower rows" % dims)
	# Rotating while open: compact turns on and back off; the note returns.
	root.size = Vector2i(390, 844)
	await _settle()
	check(not panel.compact and panel.status.visible and panel.title.get_theme_font_size("font_size") == 24, "rotating back to portrait restores the full layout and the note")
	check(panel.column.get_theme_constant("separation") == 8 and panel.rows.get_theme_constant("separation") == 6, "portrait gaps stay 8/6")
	root.size = Vector2i(844, 390)
	await _settle()
	check(panel.compact and not panel.status.visible, "rotating to 844x390 while open goes compact")
	panel.update_view(_inventory(""), _keepsakes(), "failed", false)
	await _settle()
	check(panel.status.visible and panel.retry_button.visible, "a failed save still explains itself and offers retry on short landscape")
	panel.update_view({}, _keepsakes(), "ready", false)
	await _settle()
	check(panel.status.visible, "an unreadable inventory still shows its notice on short landscape")
	# Leaving short landscape straight into the narrowest portrait: the note was
	# hidden at width 1 and must not carry its stale 500px+ height into the paper.
	panel.update_view(_inventory(""), {}, "ready", false)
	root.size = Vector2i(844, 390)
	await _settle()
	for language: String in LOCALES:
		locale.call("set_locale", language)
		for dims: Vector2i in [Vector2i(844, 390), Vector2i(280, 653), Vector2i(640, 300), Vector2i(320, 568), Vector2i(568, 320), Vector2i(360, 640)]:
			root.size = dims
			panel.update_view(_inventory(""), {}, "ready", false)
			await _settle()
			paper = panel.panel.get_global_rect()
			var view := Rect2(Vector2.ZERO, Vector2(dims)).grow(-EDGE + EPS)
			check(view.encloses(paper), "%s rotate into %s: paper stays inside the 12px margin (%s)" % [language, dims, paper])
	# Same, but the paper is first built and filled while already on short
	# landscape, so the note has never been laid out (width 1, 500px+ tall).
	for language: String in LOCALES:
		locale.call("set_locale", language)
		root.size = Vector2i(844, 390)
		await _settle()
		var fresh: Control = load("res://scripts/ui/yard_basket_panel.gd").new()
		root.add_child(fresh)
		fresh.update_view(_inventory(""), {}, "ready", false)
		await _settle()
		check(fresh.compact and not fresh.status.visible, "%s fresh paper on 844x390 opens compact" % language)
		for dims: Vector2i in [Vector2i(280, 653), Vector2i(320, 568), Vector2i(390, 844)]:
			root.size = dims
			fresh.update_view(_inventory(""), {}, "ready", false)
			await _settle()
			var fresh_paper: Rect2 = fresh.panel.get_global_rect()
			check(Rect2(Vector2.ZERO, Vector2(dims)).grow(-EDGE + EPS).encloses(fresh_paper), "%s fresh paper rotated to %s stays inside the 12px margin (%s)" % [language, dims, fresh_paper])
			check(fresh_paper.size.y <= 620.0 + EPS, "%s fresh paper rotated to %s keeps the 620px cap" % [language, dims])
		fresh.queue_free()
		await _settle()
	var queued_frames := 0
	for i in 6:
		await process_frame
		if panel._fit_queued:
			queued_frames += 1
	check(queued_frames == 0, "the panel settles instead of re-fitting every frame")
	# Tall screens: same 520px width, centred; the height now hugs the content (capped at 620).
	locale.call("set_locale", "zh-CN")
	root.size = Vector2i(1280, 720)
	panel.update_view(_inventory(""), _keepsakes(), "ready", false)
	await _settle()
	paper = panel.panel.get_global_rect()
	check(is_equal_approx(paper.position.x, 380.0) and is_equal_approx(paper.size.x, 520.0) and paper.size.y <= 620.0 and absf(paper.get_center().y - 360.0) <= EPS, "1280x720 paper 520 wide at x=380, centred, at most 620 tall (got %s)" % paper)
	check(panel.status.visible and panel.status.text == "钓到的鱼、散步带回的小物，都收在这里。", "tall screens keep the note")


func _finish() -> void:
	if failures.is_empty():
		print("[yard-basket-panel-fit] PASS: %d checks" % checks)
		quit(0)
	else:
		for line: String in failures.slice(0, 40):
			printerr("FAIL: " + line)
		print("[yard-basket-panel-fit] FAIL: %d of %d checks" % [failures.size(), checks])
		quit(1)
