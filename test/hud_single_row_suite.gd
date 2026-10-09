extends SceneTree

## Short landscape yard HUD: one bottom row instead of two.
## Before: every screen narrower than 700px got the portrait layout (three
## chips on one row, the action button on its own full-width row underneath),
## so on 568x320 / 640x300 the two button rows plus the hold hotbar covered
## most of the yard. Separately, on 700-850px wide screens the four equal
## buttons were ~120-160px, narrower than long English action labels such as
## "Turn in for the night", so the action button grew over its neighbours.
## Now: landscape screens at least 540px wide keep everything on one row;
## the action button gets at least 180px and the other three share the rest
## (still at most 188px); English "Open journal" shortens to "Journal" when its
## chip is narrower than the full label. Portrait and very narrow screens keep
## the two-row layout. The hotbar and notices follow the bottom row.

const SINGLE_ROW := [
	Vector2i(540, 320), Vector2i(568, 320), Vector2i(640, 300), Vector2i(640, 360), Vector2i(667, 375),
	Vector2i(699, 400), Vector2i(700, 400), Vector2i(760, 400), Vector2i(844, 390), Vector2i(1024, 600),
	Vector2i(1280, 720),
]
const STACKED := [Vector2i(390, 844), Vector2i(360, 640), Vector2i(320, 568), Vector2i(500, 300), Vector2i(600, 700)]
const LOCALES := ["zh-CN", "en"]

var checks := 0
var failures: Array[String] = []
var main
var action_keys: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


func _rect(c: Control) -> Rect2:
	return Rect2(c.position, c.size)


func _run() -> void:
	var original_locale: String = root.get_node("/root/I18n").get_locale()
	for loc: String in LOCALES:
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://localization/%s.json" % loc))
		var keys: Array[String] = []
		for k: String in d:
			if k.begins_with("action."):
				keys.append(k)
		action_keys[loc] = keys
	for dims: Vector2i in SINGLE_ROW + STACKED:
		root.size = dims
		main = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		await process_frame
		await process_frame
		main.set_process(false)
		main._start_holiday()
		main._ensure_hold_hotbar()
		for loc: String in LOCALES:
			root.get_node("/root/I18n").set_locale(loc)
			main._layout()
			main._refresh_hud()
			_check_layout("%s %s" % [dims, loc], dims, dims in SINGLE_ROW, loc)
		main.queue_free()
		await process_frame
	root.get_node("/root/I18n").set_locale(original_locale)
	_finish()


func _check_layout(tag: String, dims: Vector2i, single: bool, loc: String) -> void:
	var screen := Rect2(Vector2.ZERO, Vector2(dims))
	var chips: Array = [main._album_chip, main._weather_chip, main._basket_chip]
	var buttons: Array = chips + [main._action_button]
	_check(main._stacked_hud() != single, "%s layout is %s" % [tag, "one row" if single else "two rows"])
	for b: Button in buttons:
		_check(screen.encloses(_rect(b)), "%s %s on screen %s" % [tag, b.text, _rect(b)])
		_check(b.get_combined_minimum_size().x <= b.size.x + 0.5, "%s '%s' fits its button (%.0f > %.0f)" % [tag, b.text, b.get_combined_minimum_size().x, b.size.x])
	for i in buttons.size():
		for j in range(i + 1, buttons.size()):
			var a: Rect2 = _rect(buttons[i])
			var c: Rect2 = _rect(buttons[j])
			_check(not a.grow(-0.5).intersects(c.grow(-0.5)), "%s '%s' and '%s' do not overlap" % [tag, buttons[i].text, buttons[j].text])
	if single:
		for b: Button in buttons:
			_check(is_equal_approx(b.position.y, dims.y - 68.0), "%s %s sits on the single bottom row (y=%.0f)" % [tag, b.text, b.position.y])
		_check(main._action_button.size.x >= main.ACTION_MIN_WIDTH - 0.5, "%s action button at least %.0f wide" % [tag, main.ACTION_MIN_WIDTH])
		for b: Button in chips:
			_check(b.size.x <= 188.5, "%s %s at most 188 wide" % [tag, b.text])
	else:
		_check(main._action_button.position.y > main._album_chip.position.y + 40.0, "%s action button keeps its own row" % tag)
	# Every action label the button can show still fits without widening it.
	var keep: String = main._action_button.text
	for k: String in action_keys[loc]:
		main._action_button.text = root.get_node("/root/I18n").t(k)
		_check(main._action_button.get_combined_minimum_size().x <= main._action_button.size.x + 0.5, "%s action '%s' fits (%.0f > %.0f)" % [tag, main._action_button.text, main._action_button.get_combined_minimum_size().x, main._action_button.size.x])
	main._action_button.text = keep
	var bar: Control = main._hold_hotbar
	if bar != null:
		var top := minf(main._album_chip.position.y, main._action_button.position.y)
		_check(_rect(bar).end.y <= top - 4.0, "%s hotbar sits above the bottom buttons (%.0f vs %.0f)" % [tag, _rect(bar).end.y, top])
		if single and dims.y <= 400:
			_check(bar.position.y >= dims.y * 0.45, "%s bottom HUD leaves the upper part of the yard open (hotbar top %.0f of %d)" % [tag, bar.position.y, dims.y])


func _finish() -> void:
	if failures.is_empty():
		print("[hud-single-row] PASS: %d checks" % checks)
		quit(0)
	else:
		for line: String in failures.slice(0, 40):
			printerr("FAIL: " + line)
		print("[hud-single-row] FAIL: %d of %d checks" % [failures.size(), checks])
		quit(1)
