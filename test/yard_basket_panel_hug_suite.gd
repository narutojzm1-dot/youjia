extends SceneTree

## UI basket polish: the yard basket paper hugs its content.
## Before: the paper was always min(620, screen height - 24) tall. Once #648
## removed the decor button, the list scrolled area kept the spare height, so
## on tall screens a blank band sat between 「收回背篓」 and the note below it.
## Now: when everything fits, the paper is exactly as tall as its content and
## stays centred; when the content is taller than the cap, the paper keeps the
## cap height and the list scrolls as before. Changing the content (another
## locale, a status line, the retry button) re-fits on the next frames.
## Fixture only: the panel is built on its own; no save is read or written.

const VIEWPORTS := [
	Vector2i(1280, 720), Vector2i(1024, 600), Vector2i(412, 915), Vector2i(390, 844), Vector2i(375, 667),
	Vector2i(360, 640), Vector2i(320, 568), Vector2i(844, 390), Vector2i(568, 320), Vector2i(640, 300),
]
const LOCALES := ["zh-CN", "en"]
const STATES := ["ready", "saving", "failed"]
const EDGE := 12.0
const EPS := 1.5
const PAPER_BOTTOM_MARGIN := 12.0

var checks := 0
var failures: Array[String] = []
var panel: Control
var hugged := 0
var capped := 0


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


func _settle() -> void:
	for i in 5:
		await process_frame


func _inventory() -> Dictionary:
	return {"fish": {"small": 12, "medium": 3, "odd": 10}, "grass": 4, "millet": 25, "held": ""}


func _keepsakes() -> Dictionary:
	return {ExplorationRoutes.FIND_STONE: 2, ExplorationRoutes.FIND_PINE_CONE: 11, ExplorationRoutes.FIND_FEATHER: 1}


func _last_visible_bottom() -> float:
	var bottom := 0.0
	for child: Node in panel.column.get_children():
		if child is Control and child.visible:
			bottom = maxf(bottom, (child as Control).get_global_rect().end.y)
	return bottom


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
		for viewport: Vector2i in VIEWPORTS:
			root.size = viewport
			for state: String in STATES:
				panel.update_view(_inventory(), _keepsakes(), state, false)
				await _settle()
				var tag := "%s %dx%d %s" % [language, viewport.x, viewport.y, state]
				var paper: Rect2 = panel.panel.get_global_rect()
				var cap := minf(620.0, viewport.y - EDGE * 2.0)
				var bar: VScrollBar = panel.scroll.get_v_scroll_bar()
				check(paper.size.y <= cap + EPS, tag + " paper not taller than the cap (%s > %.1f)" % [paper, cap])
				check(paper.position.y >= EDGE - EPS and paper.end.y <= viewport.y - EDGE + EPS, tag + " paper keeps the screen margin (%s)" % paper)
				check(absf(paper.get_center().y - viewport.y * 0.5) <= EPS, tag + " paper stays centred (%s)" % paper)
				var gap := paper.end.y - _last_visible_bottom()
				check(gap <= PAPER_BOTTOM_MARGIN + EPS + 1.0, tag + " no blank band under the last line (gap %.1f)" % gap)
				var list_room: float = panel.scroll.size.y
				var list_need: float = panel.rows.get_combined_minimum_size().y
				if paper.size.y < cap - EPS:
					hugged += 1
					check(list_room <= list_need + EPS, tag + " hugging paper leaves no spare list height (%.1f vs %.1f)" % [list_room, list_need])
					check(not bar.visible or bar.max_value - bar.page <= EPS, tag + " hugging paper does not scroll")
				else:
					capped += 1
					check(list_need >= list_room - EPS, tag + " capped paper only when the list needs the room")
	# Content shrink re-fits: dropping the retry button and status shortens the paper again.
	locale.call("set_locale", "zh-CN")
	root.size = Vector2i(1280, 720)
	# Ten kinds now fill three grid rows and legitimately hit the height cap.
	# The real ten-kind layouts above cover that case. Isolate the existing
	# row-sizing mechanism here with a short content fixture below the cap.
	panel.grid.hide()
	panel.update_view(_inventory(), _keepsakes(), "failed", false)
	await _settle()
	var with_retry: float = panel.panel.size.y
	panel.update_view(_inventory(), _keepsakes(), "ready", false)
	await _settle()
	var without_retry: float = panel.panel.size.y
	check(without_retry < with_retry - 20.0, "paper shortens once the retry button goes away (%.1f -> %.1f)" % [with_retry, without_retry])
	# A row-only change (nothing else resizes) still re-hugs: grow the list by 30px, then shrink it back.
	var before: float = panel.panel.size.y
	var extra := Control.new()
	extra.custom_minimum_size = Vector2(10, 30)
	panel.rows.add_child(extra)
	await _settle()
	var grown: float = panel.panel.size.y
	check(absf(grown - before - 30.0 - float(panel.rows.get_theme_constant("separation"))) <= EPS, "paper grows with a row-only change (%.1f -> %.1f)" % [before, grown])
	extra.queue_free()
	await _settle()
	check(absf(panel.panel.size.y - before) <= EPS, "paper shrinks back after the row goes (%.1f)" % panel.panel.size.y)
	check(not panel._fit_queued, "panel settles after content changes")
	check(hugged >= 10, "tall screens hug the content (%d cases)" % hugged)
	check(capped >= 4, "short screens keep the capped scrolling paper (%d cases)" % capped)
	_finish()


func _finish() -> void:
	if failures.is_empty():
		print("[yard-basket-panel-hug] PASS: %d checks" % checks)
		quit(0)
	else:
		for line: String in failures.slice(0, 40):
			printerr("FAIL: " + line)
		print("[yard-basket-panel-hug] FAIL: %d of %d checks" % [failures.size(), checks])
		quit(1)
