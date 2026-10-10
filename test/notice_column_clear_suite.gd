extends SceneTree

## Yard notices stay clear of the top-right column on short landscapes.
## Before: the notice paper sits just above the hold hotbar and grows upward
## when it wraps. On 640x300 / 568x320 a two-line notice (for example the
## first-day hint) reached the height of the top-right column, and at its full
## 440px width it covered the day tag and the clock under 「歇一会儿」.
## Now: when the notice could grow up to that column, a long notice slides left
## until its right edge is NOTICE_COLUMN_GAP left of the column, keeping its
## width unless the room left of the column (down to NOTICE_EDGE from the screen
## edge) is narrower, e.g. 440 -> 408px at 568 wide. Short notices that already fit stay
## centred; wide and portrait screens are unchanged.

const VIEWPORTS := [
	Vector2i(568, 320), Vector2i(600, 340), Vector2i(640, 300), Vector2i(640, 360), Vector2i(667, 375),
	Vector2i(740, 360), Vector2i(844, 390), Vector2i(1024, 600), Vector2i(1280, 720),
	Vector2i(390, 844), Vector2i(360, 640), Vector2i(320, 568),
]
const LOCALES := ["zh-CN", "en"]

var checks := 0
var failures: Array[String] = []
var main
var notice_keys: Dictionary = {}
var narrowed := 0
var unchanged_wide := 0
var tall_preexisting := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


func _run() -> void:
	var i18n: Node = root.get_node("/root/I18n")
	var original_locale: String = i18n.get_locale()
	for loc: String in LOCALES:
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://localization/%s.json" % loc))
		var keys: Array[String] = []
		for k: String in d:
			if k.begins_with("notice."):
				keys.append(k)
		notice_keys[loc] = keys
	for dims: Vector2i in VIEWPORTS:
		root.size = dims
		main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		await process_frame
		await process_frame
		main.set_process(false)
		await main._start_holiday()
		main._ensure_hold_hotbar()
		for loc: String in LOCALES:
			i18n.set_locale(loc)
			main._layout()
			main._refresh_hud()
			main._sync_hold_hotbar_visibility()
			for k: String in notice_keys[loc]:
				main._notice.text = i18n.t(k, {"n": 12, "day": 12})
				main._notice_time = 3.0
				# Main re-syncs every frame in _process; do the same twice so the hotbar has settled
				for i in 2:
					main._sync_notice_visibility()
					main._fit_notice()
					await process_frame
				_check_notice("%s %s %s" % [dims, loc, k], dims)
		main.queue_free()
		await process_frame
	_check(narrowed > 0, "short landscapes slid at least one notice left (%d)" % narrowed)
	print("[notice-column-clear] tall notices that already reach the goal paper when centred: %d" % tall_preexisting)
	_check(unchanged_wide > 0, "notices far below the column keep their width (%d)" % unchanged_wide)
	i18n.set_locale(original_locale)
	_finish()


func _check_notice(tag: String, dims: Vector2i) -> void:
	var notice: Rect2 = main._notice.get_global_rect()
	if not main._notice.visible:
		_check(false, tag + " notice visible")
		return
	var screen := Rect2(Vector2.ZERO, Vector2(dims))
	var column: Rect2 = main._top_right_column_rect()
	_check(screen.encloses(notice), "%s notice on screen %s" % [tag, notice])
	_check(column.has_area(), tag + " top-right column measured")
	_check(not notice.intersects(column), "%s notice clear of pause/day/clock %s vs %s" % [tag, notice, column])
	var hint: Rect2 = main._hint_panel.get_global_rect()
	if main._hint_panel.visible and notice.intersects(hint):
		# Tall multi-line notices (3-5 lines from the copy itself) already reach the goal paper on
		# 300-320px-tall screens when centred; only an overlap caused by sliding left is a failure.
		var centred := Rect2(Vector2(dims.x * 0.5 - notice.size.x * 0.5, notice.position.y), notice.size)
		_check(centred.intersects(hint), "%s sliding left pushed the notice into the goal paper %s vs %s" % [tag, notice, hint])
		tall_preexisting += 1
	var bar: Control = main._hold_hotbar
	if bar != null and bar.visible:
		_check(not notice.intersects(bar.get_global_rect()), "%s notice clear of the hotbar" % tag)
	_check(notice.position.x >= main.NOTICE_EDGE - 0.5, "%s notice keeps the left screen margin (%.1f)" % [tag, notice.position.x])
	var centre := dims.x * 0.5
	if notice.get_center().x < centre - 0.5:
		narrowed += 1
		_check(absf(notice.end.x - (column.position.x - main.NOTICE_COLUMN_GAP)) <= 0.5, "%s slid notice stops right at the column gap" % tag)
	elif notice.position.y > column.end.y + 120.0:
		unchanged_wide += 1
		_check(absf(notice.get_center().x - centre) <= 0.5, "%s far notice stays centred" % tag)


func _finish() -> void:
	if failures.is_empty():
		print("[notice-column-clear] PASS: %d checks" % checks)
		quit(0)
	else:
		for line: String in failures.slice(0, 40):
			printerr("FAIL: " + line)
		print("[notice-column-clear] FAIL: %d of %d checks" % [failures.size(), checks])
		quit(1)
