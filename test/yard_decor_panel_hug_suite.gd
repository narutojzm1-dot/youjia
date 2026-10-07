extends SceneTree
# REQ-20261007-055: the yard decor paper hugs its rows instead of always taking
# its whole allowance (full screen height in landscape) and leaving blank paper
# between the rows and the close button. When the rows don't fit, it stops at
# the old allowance and scrolls exactly as before.
var checks := 0
var failures: Array[String] = []
const VIEWPORTS := [Vector2(280, 653), Vector2(300, 560), Vector2(320, 568), Vector2(360, 640), Vector2(390, 844), Vector2(768, 1024), Vector2(568, 320), Vector2(640, 300), Vector2(844, 390), Vector2(1280, 720), Vector2(1920, 1080)]
const STATES := ["idle", "draft", "placed", "busy", "failed"]

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func allowance(vs: Vector2) -> float:
	return vs.y - 16.0 if vs.x > vs.y else minf(320.0, vs.y * 0.48)

func apply_state(p: Control, state: String) -> void:
	var stone: String = ExplorationRoutes.FINDS[0]
	var counts := {stone: 2, ExplorationRoutes.FINDS[1]: 0, ExplorationRoutes.FINDS[2]: 1}
	match state:
		"idle":
			p.update_view({"places": {}}, counts, "idle", false)
		"draft":
			p.update_view({"places": {}}, counts, "idle", false)
			p.choose_find(stone)
		"placed":
			p.update_view({"places": {"house_edge": {"find_id": stone, "dx": 0, "dy": 0}}}, counts, "idle", false)
			p.choose_spot("house_edge")
		"busy":
			p.update_view({"places": {}}, counts, "pending", true)
		"failed":
			p.update_view({"places": {}}, counts, "failed", false)

func run() -> void:
	var i18n := root.get_node("I18n")
	for loc: String in ["zh-CN", "en"]:
		i18n.set_locale(loc)
		for vs: Vector2 in VIEWPORTS:
			for state: String in STATES:
				var tag := "%s %dx%d %s" % [loc, vs.x, vs.y, state]
				root.size = Vector2i(vs)
				var host := Control.new()
				root.add_child(host)
				host.size = vs
				var p: Control = load("res://scripts/ui/yard_decor_panel.gd").new()
				host.add_child(p)
				await process_frame
				p.size = vs
				apply_state(p, state)
				await process_frame
				await process_frame
				await process_frame
				verify(p, vs, state, tag)
				host.queue_free()
				await process_frame
	if failures.is_empty():
		print("[yard-decor-panel-hug] PASS: %d checks" % checks)
		quit(0)
	else:
		for f: String in failures: printerr("[yard-decor-panel-hug] FAIL: " + f)
		printerr("[yard-decor-panel-hug] FAILED %d of %d checks" % [failures.size(), checks])
		quit(1)

func verify(p: Control, vs: Vector2, state: String, tag: String) -> void:
	var landscape := vs.x > vs.y
	var r: Rect2 = p.paper.get_global_rect()
	var cap := allowance(vs)
	var frame: StyleBox = p.paper.get_theme_stylebox("panel")
	var column_need: float = p.column.get_combined_minimum_size().y
	var scroll_h: float = p.scroll.size.y
	check(r.position.x >= 7.5 and r.position.y >= 7.5 and r.end.x <= vs.x - 7.5 and r.end.y <= vs.y - 7.5, tag + " paper stays on screen " + str(r))
	if landscape:
		check(absf(r.position.y - 8.0) < 0.6 and absf(vs.x - r.end.x - 8.0) < 0.6, tag + " landscape paper keeps its top-right corner " + str(r))
		check(absf(r.size.x - minf(310.0, vs.x * 0.48)) < 0.6, tag + " landscape width unchanged")
	else:
		check(absf(r.position.x - 8.0) < 0.6 and absf(vs.y - r.end.y - 8.0) < 0.6, tag + " portrait paper keeps its bottom-left corner " + str(r))
		check(absf(r.size.x - (vs.x - 16.0)) < 0.6, tag + " portrait width unchanged")
	check(r.size.y <= cap + 0.6, tag + " never taller than the old allowance (%.1f > %.1f)" % [r.size.y, cap])
	check(scroll_h <= column_need + 1.6, tag + " no blank paper under the rows (%.1f of room for %.1f)" % [scroll_h, column_need])
	if r.size.y < cap - 0.6:
		check(scroll_h >= column_need - 0.6, tag + " every row shows without scrolling (%.1f < %.1f)" % [scroll_h, column_need])
	else:
		check(absf(r.size.y - cap) < 0.6, tag + " rows that don't fit keep the old allowance and scroll")
	var close: Rect2 = p.close_button.get_global_rect()
	check(r.grow(0.5).encloses(close), tag + " close button stays on the paper")
	check(r.end.y - close.end.y <= frame.content_margin_bottom + 1.0, tag + " close button sits at the paper's foot, not below blank paper")
	var st: Rect2 = p.status.get_global_rect()
	check(r.grow(0.5).encloses(st) and st.size.y >= p.status.get_combined_minimum_size().y - 0.6, tag + " status line is whole on the paper")
	var visible_rect: Rect2 = p.scroll.get_global_rect().grow(0.6)
	for b: Button in p.buttons:
		if not b.is_visible_in_tree(): continue
		check(b.size.y >= 43.5, tag + " button keeps 44px touch height: " + b.text)
		if r.size.y < cap - 0.6 and b != p.close_button:
			check(visible_rect.encloses(b.get_global_rect()), tag + " row fully visible without scrolling: " + b.text)
	check(p.retry_button.is_visible_in_tree() == (state == "failed"), tag + " retry only shows after a failed save")
	var preview: Rect2 = p.preview_rect()
	check(preview.size.x > 100.0 and preview.size.y > 100.0, tag + " preview keeps room " + str(preview))
	if not landscape:
		check(preview.size.y >= vs.y - cap - 24.0 - 0.6, tag + " portrait preview is never smaller than before")
	if vs == Vector2(1280, 720) or vs == Vector2(1920, 1080):
		check(r.size.y <= 360.0, tag + " desktop paper is a card, not a full-height strip (%.0f)" % r.size.y)
