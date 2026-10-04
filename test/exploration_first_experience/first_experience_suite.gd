extends SceneTree
# 首条画卷体验研究（#201）的隔离测试：只在独立最小项目里运行，核心与假宿主来自 #176 固定 SHA。
# 覆盖：横竖屏同一停留点的取景比较、停下看景不调用核心、空手中途返回的院内说明、
# 「走近—松手观察—选择／不选择—中途回院」的连续触屏操作、观察态拦下误触、键盘退出观察、
# 观察中回院与旧信号失效、空手往返的各种保存结果、玩家可见文字不出现进度 / 任务类措辞。
# 只证明隔离研究切片的交互与状态表述；不证明耐久保存、强退恢复或真实宿主接入。

const SCENE := "res://test/exploration_first_experience/first_experience.tscn"
const Experience := preload("res://test/exploration_first_experience/first_experience.gd")
const Framing := preload("res://test/exploration_first_experience/framing_model.gd")
const WalkModel := preload("res://test/exploration_scroll_prototype/scroll_walk_model.gd")
const CORE_SHA := "e2a6d70b186d40c09cfcf48c48292838993d7eb7"
const SAVED_WORDS := ["已收好", "已记下"]
const RETURN_ORDER := [
	"return_requested", "core:pending_commit", "scroll_input_off", "scroll_camera_off",
	"scroll_disconnected", "scroll_freed", "yard_camera_current", "yard_input_on", "flight_started",
]
## 横屏桌面、宽屏、竖屏手机两种、横放手机
const VIEWPORTS := [Vector2(1280, 720), Vector2(1920, 1080), Vector2(390, 844), Vector2(360, 780), Vector2(844, 390)]
const PORTRAIT := Vector2i(390, 844)
const LANDSCAPE := Vector2i(1280, 720)
## 不应出现在探索文字里的进度 / 任务类措辞
const PROGRESS_WORDS := ["进度", "任务", "打卡", "完成度", "收集", "%"]

var checks := 0
var failures: Array[String] = []
## 测试过程中出现过的玩家可见文字，最后统一检查措辞
var seen_texts: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = LANDSCAPE
	await process_frame
	_core_source()
	_framing_model()
	await _stop_to_look()
	await _empty_handed_return()
	await _touch_sequence_with_find()
	await _keyboard_leaves_observe()
	await _camera_follows_framing()
	await _return_while_observing()
	await _empty_trip_results()
	_wording()
	for failure: String in failures:
		push_error(failure)
	print("EXPLORATION FIRST EXPERIENCE %s %d" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)


## 0. 核心来源可追溯
func _core_source() -> void:
	var text := FileAccess.get_file_as_string("res://CORE_SOURCE.txt")
	_check(text.contains(CORE_SHA), "the temporary project records the pinned core SHA")
	_check(ResourceLoader.exists("res://test/fixtures/exploration_fake_host.gd"), "the fake host comes from the pinned core branch")


## 1. 取景比较：同一停留点，收景方案在横竖屏下都能一次看全小景和角色；跟随方案在竖屏下看不全
func _framing_model() -> void:
	var model = WalkModel.new()
	for stop: Dictionary in WalkModel.STOPS:
		var stop_id := String(stop["id"])
		var scene := Framing.scene_rect(stop_id)
		_check(scene.size != Vector2.ZERO, "%s has a placeholder scene rect" % stop_id)
		_check(scene.has_point(Vector2(float(stop["x"]), WalkModel.GROUND_Y)), "%s scene contains its stop on the path" % stop_id)
		for offset: float in [-WalkModel.NEAR_DISTANCE, 0.0, WalkModel.NEAR_DISTANCE]:
			model.x = float(stop["x"]) + offset
			for size: Vector2 in VIEWPORTS:
				var follow: Dictionary = Framing.follow(model, size)
				var fit: Dictionary = Framing.fit(model, size, stop_id)
				var tag := "%s at %+d on %dx%d" % [stop_id, int(offset), int(size.x), int(size.y)]
				_check(is_equal_approx(Framing.coverage(fit, scene), 1.0), "fit shows the whole scene: %s" % tag)
				_check(Framing.walker_visible(fit, model.x), "fit keeps the walker on screen: %s" % tag)
				_check(float(fit["zoom"]) <= float(follow["zoom"]) + 0.0001, "fit never zooms closer than follow: %s" % tag)
				if size.x >= size.y:
					_check(is_equal_approx(float(fit["zoom"]), float(follow["zoom"])), "landscape fit keeps the follow zoom: %s" % tag)
	## 记录竖屏基线问题：停在停留点正中时，跟随方案只能看到小景的一部分
	model.x = 2200.0
	var portrait := Vector2(PORTRAIT)
	var scene_b := Framing.scene_rect("placeholder_b")
	var follow_cov := Framing.coverage(Framing.follow(model, portrait), scene_b)
	var fit_view := Framing.fit(model, portrait, "placeholder_b")
	_check(follow_cov < 0.7, "portrait follow framing shows only part of the scene (%.2f)" % follow_cov)
	_check(Framing.margin_ratio(fit_view) > 0.3, "portrait fit pays with visible mount margins (%.2f)" % Framing.margin_ratio(fit_view))
	_check(Framing.margin_ratio(Framing.fit(model, Vector2(LANDSCAPE), "placeholder_b")) < 0.0001, "landscape fit shows no mount margin")
	_check(Framing.frame(Framing.MODE_FIT, model, portrait, "") == Framing.follow(model, portrait), "without a stop the fit mode falls back to follow")
	_check(Framing.frame(Framing.MODE_FOLLOW, model, portrait, "placeholder_b") == Framing.follow(model, portrait), "follow mode ignores the observed stop")


## 2. 停下看景：只看不带的停留点 C，停下后角色不动、不调用核心、不出现带走按钮
func _stop_to_look() -> void:
	var a = await _spawn()
	a.set_out()
	var record: int = a.session().record_revision()
	var view_before: Dictionary = a.session().get_view()
	a.scroll.model.x = 3600.0
	await _press(KEY_E)
	_check(a.scroll.is_observing() and a.scroll.observing_stop == "placeholder_c", "E near stop C enters observing")
	_check(a.events.has("observe_only:placeholder_c"), "stop C is look-only and does not call the core")
	_check(a.session().record_revision() == record and a.session().get_view()["current_stop"] == view_before["current_stop"], "looking at stop C changes nothing in the core")
	_check(a.scroll._pick_tag.visible and a.scroll._pick_tag.text == "只是看看", "the choice bar says it is only for looking")
	_collect(a)
	await _press(KEY_T)
	_check(a.session().record_revision() == record and a.scroll._note.text.contains("只是看看"), "T at a look-only stop changes nothing")
	var x: float = a.scroll.model.x
	await _frames(5)
	_check(a.scroll.model.x == x, "the walker stays put while observing")
	await _press(KEY_E)
	_check(not a.scroll.is_observing() and a.events.has("observe_end:placeholder_c"), "E again ends observing")
	_check(not a.scroll._pick_tag.visible and not a.scroll._go_tag.visible and a.scroll._hint.visible, "the choice bar hides and the walking hint returns after observing")
	Input.parse_input_event(_key(KEY_RIGHT, true))
	await _frames(5)
	Input.parse_input_event(_key(KEY_RIGHT, false))
	await process_frame
	_check(a.scroll.model.x > x, "walking resumes after observing")
	var follow: Dictionary = Framing.follow(a.scroll.model, Vector2(root.size))
	_check(a.scroll.camera.position.is_equal_approx(follow["camera"]) and is_equal_approx(a.scroll.camera.zoom.x, float(follow["zoom"])), "outside framing switches the camera follows exactly like #199, without walking easing")
	await _despawn(a)


## 3. 空手中途返回：在可带东西的停留点停下看但不带，直接回院；院内说空手回来，不说已收好
func _empty_handed_return() -> void:
	var a = await _spawn()
	a.set_out()
	a.scroll.model.x = 2200.0
	await _press(KEY_E)
	_check(a.events.has("observe:pond"), "observing at B moves the core to the pond")
	_check(a.session().get_view()["offer"] == "formal.find.reed" and a.session().get_view()["carried"].is_empty(), "the offer is shown but not taken automatically")
	_check(a.scroll._pick_tag.text == "带上（T）", "the choice bar offers to take it")
	_collect(a)
	await _press(KEY_E)
	_check(not a.scroll.is_observing(), "the player walks on without taking")
	var mark: int = a.events.size()
	await _press(KEY_R)
	_check(a.events.slice(mark, mark + RETURN_ORDER.size()) == RETURN_ORDER, "an empty-handed return keeps the fixed return order")
	_check(a.mode == "yard" and a.core_state() == "pending_commit", "returning mid-trip goes straight home")
	_check(a.session().get_view()["proposal_items"] == 0, "the frozen proposal is empty")
	_check(a.status_text() == Experience.TEXT_EMPTY_SAVING, "the yard says the walk is being noted, not that items are stored")
	_no_saved_claim(a, "an empty trip in flight")
	_collect(a)
	a.host_action("ok")
	_check(a.status_text() == Experience.TEXT_EMPTY_SAVED and a.core_state() == "idle", "only a confirmed empty commit says the walk is noted")
	_check(not a.status_text().contains("已收好"), "an empty trip never claims items were stored")
	_check(a.host.grants == 0 and a.host.inventory.is_empty(), "nothing is granted for an empty trip")
	_collect(a)
	await _despawn(a)


## 4. 连续触屏（竖屏）：走近—松手观察—误触不走—带上—放回—再带上—中途回院
func _touch_sequence_with_find() -> void:
	root.size = PORTRAIT
	await process_frame
	var a = await _spawn()
	a.set_out()
	var size := Vector2(PORTRAIT)
	var mid_y := size.y * 0.5
	a.scroll.model.x = 2100.0
	Input.parse_input_event(_touch(0, size.x * 0.8, mid_y, true))
	await _frames(5)
	var walked: float = a.scroll.model.x
	_check(walked > 2100.0, "holding the right half walks toward B")
	Input.parse_input_event(_touch(0, size.x * 0.8, mid_y, false))
	await process_frame
	var stopped: float = a.scroll.model.x
	await _frames(5)
	_check(a.scroll.model.x == stopped, "releasing the finger stops the walker")
	a.scroll.model.x = 2200.0
	Input.parse_input_event(_touch(1, size.x * 0.3, 40.0, true))
	Input.parse_input_event(_touch(1, size.x * 0.3, 40.0, false))
	await process_frame
	_check(a.scroll.is_observing() and a.scroll.observing_stop == "placeholder_b", "tapping the top bar near B enters observing")
	_check(a.scroll.input.held_count() == 0, "no walking source is held after the observe tap")
	_check(not a.scroll._hint.visible, "the walking hint hides so it cannot cover the choice bar")
	var title: Rect2 = a.scroll.title_tag.get_global_rect()
	var back: Rect2 = a.scroll._return_tag.get_global_rect()
	_check(title.size.x > 0.0 and title.end.x <= back.position.x, "the title tag does not overlap the return tag in portrait (%s vs %s)" % [title, back])
	var x: float = a.scroll.model.x
	## 观察中误触半屏（同侧、对侧各一次）：不走、只记一次拦截
	Input.parse_input_event(_touch(2, size.x * 0.8, mid_y, true))
	await _frames(5)
	Input.parse_input_event(_drag(2, size.x * 0.9, mid_y + 10.0))
	await _frames(3)
	Input.parse_input_event(_touch(2, size.x * 0.9, mid_y + 10.0, false))
	Input.parse_input_event(_touch(3, size.x * 0.2, mid_y, true))
	await _frames(3)
	Input.parse_input_event(_touch(3, size.x * 0.2, mid_y, false))
	await process_frame
	_check(a.scroll.model.x == x and a.scroll.is_observing(), "stray touches on either half do not walk while observing")
	_check(a.scroll.suppressed_touches == 2, "both stray touches were suppressed (%d)" % a.scroll.suppressed_touches)
	var bar_y := size.y - 40.0
	await _tap(4, size.x * 0.25, bar_y)
	_check(a.events.has("take:formal.find.reed") and a.session().get_view()["carried"].size() == 1, "tapping the lower left takes the find through the core")
	_check(a.scroll._pick_tag.text == "放回（T）" and a.scroll.is_observing(), "the bar now offers to put it back and observing continues")
	_collect(a)
	await _tap(5, size.x * 0.25, bar_y)
	_check(a.events.has("release:formal.find.reed") and a.session().get_view()["carried"].is_empty(), "tapping again puts it back")
	_check(a.session().get_view()["offer"] == "formal.find.reed" and a.scroll._pick_tag.text == "带上（T）", "the find is offered again after putting it back")
	await _tap(6, size.x * 0.25, bar_y)
	_check(a.session().get_view()["carried"] == ["formal.find.reed"], "the player can change their mind and take it again")
	_check(a.scroll.model.x == x, "choosing never moved the walker")
	var mark: int = a.events.size()
	await _tap(7, size.x - 40.0, 40.0)
	_check(a.events.slice(mark, mark + RETURN_ORDER.size()) == RETURN_ORDER, "returning from B with one find keeps the fixed return order")
	_check(a.mode == "yard" and a.session().get_view()["proposal_items"] == 1, "the find goes home without walking back to the start")
	_check(a.status_text() == Experience.TEXT_SAVING, "the yard says the find is being stored")
	_no_saved_claim(a, "a trip with one find in flight")
	a.host_action("ok")
	_check(a.status_text() == Experience.TEXT_SAVED and a.host.grants == 1 and a.host.inventory.has("formal.find.reed"), "the confirmed find is stored once")
	_collect(a)
	await _despawn(a)
	root.size = LANDSCAPE
	await process_frame


## 5. 键盘：观察中按方向键视为有意继续走；回到原处还能再停下看
func _keyboard_leaves_observe() -> void:
	var a = await _spawn()
	a.set_out()
	a.scroll.model.x = 900.0
	await _press(KEY_SPACE)
	_check(a.scroll.is_observing() and a.events.has("observe:gate"), "Space near A observes the gate")
	var x: float = a.scroll.model.x
	Input.parse_input_event(_key(KEY_LEFT, true))
	await _frames(5)
	Input.parse_input_event(_key(KEY_LEFT, false))
	await process_frame
	_check(not a.scroll.is_observing() and a.scroll.model.x < x, "an arrow key ends observing and walks")
	_check(a.scroll.model.facing == -1, "the walker faces the chosen direction")
	await _press(KEY_E)
	_check(a.scroll.is_observing(), "the walker can stop and look again")
	await _press(KEY_E)
	## 一根手指还按在右半屏时按 E 停下看：观察态清掉这根手指，角色不再走，抬手后也不会续走
	var size := Vector2(root.size)
	Input.parse_input_event(_touch(0, size.x * 0.8, size.y * 0.5, true))
	await _frames(3)
	await _press(KEY_E)
	var held_x: float = a.scroll.model.x
	await _frames(5)
	_check(a.scroll.is_observing() and a.scroll.model.x == held_x, "observing while a finger is held stops the walker")
	_check(a.scroll.input.held_count() == 0, "observing drops the held finger")
	Input.parse_input_event(_drag(0, size.x * 0.9, size.y * 0.5))
	Input.parse_input_event(_touch(0, size.x * 0.9, size.y * 0.5, false))
	await _frames(3)
	_check(a.scroll.model.x == held_x, "lifting the old finger does not resume walking")
	await _despawn(a)


## 6. 相机按取景方案切换：竖屏停下收景、继续走回到跟随；观察中旋转屏幕重新收景；F 切到跟随对照
func _camera_follows_framing() -> void:
	root.size = PORTRAIT
	await process_frame
	var a = await _spawn()
	a.set_out()
	var scroll = a.scroll
	scroll.model.x = 2200.0
	await process_frame
	var follow_zoom: float = scroll.camera.zoom.x
	await _press(KEY_E)
	await process_frame
	var target: Dictionary = scroll.target_frame()
	_check(float(target["zoom"]) < follow_zoom, "the fit target is wider than the follow view in portrait")
	_check(scroll.camera.zoom.x < follow_zoom and scroll.camera.zoom.x >= float(target["zoom"]) - 0.0001, "the camera eases toward the fit framing")
	## 过渡按固定时长结束，停着不动时到时就完全对齐
	await create_timer(scroll.EASE_TIME + 0.1).timeout
	await process_frame
	_check(not scroll.is_easing() and is_equal_approx(scroll.camera.zoom.x, float(target["zoom"])) and scroll.camera.position.is_equal_approx(target["camera"]), "the framing switch settles exactly within its fixed duration")
	## 观察态按方向键：退出观察并立刻走，相机这一路都直接跟随，不拖着缓动
	Input.parse_input_event(_key(KEY_RIGHT, true))
	await _frames(2)
	var walking_ok := true
	for i in 10:
		await process_frame
		var follow_now: Dictionary = Framing.follow(scroll.model, Vector2(PORTRAIT))
		walking_ok = walking_ok and not scroll.is_easing() and scroll.camera.position.is_equal_approx(follow_now["camera"]) and is_equal_approx(scroll.camera.zoom.x, float(follow_now["zoom"]))
	Input.parse_input_event(_key(KEY_RIGHT, false))
	await process_frame
	_check(not scroll.is_observing() and walking_ok, "walking on right after observing follows exactly, without a lingering ease (portrait)")
	scroll.model.x = 2200.0
	await _press(KEY_E)
	scroll.low_motion = true
	await process_frame
	target = scroll.target_frame()
	_check(is_equal_approx(scroll.camera.zoom.x, float(target["zoom"])), "low motion snaps to the fit framing")
	var shown := {"zoom": scroll.camera.zoom.x, "camera": scroll.camera.position, "visible": Vector2(PORTRAIT) / scroll.camera.zoom.x}
	_check(is_equal_approx(Framing.coverage(shown, Framing.scene_rect("placeholder_b")), 1.0), "the actual camera shows the whole scene")
	await _press(KEY_F)
	await process_frame
	_check(scroll.framing_mode == Framing.MODE_FOLLOW and is_equal_approx(scroll.camera.zoom.x, follow_zoom), "F switches to the follow framing for comparison")
	await _press(KEY_F)
	await process_frame
	root.size = LANDSCAPE
	await process_frame
	await process_frame
	var turned: Dictionary = scroll.target_frame()
	var shown_turned := {"zoom": scroll.camera.zoom.x, "camera": scroll.camera.position, "visible": Vector2(LANDSCAPE) / scroll.camera.zoom.x}
	_check(is_equal_approx(scroll.camera.zoom.x, float(turned["zoom"])) and is_equal_approx(Framing.coverage(shown_turned, Framing.scene_rect("placeholder_b")), 1.0), "rotating while observing refits the scene")
	await _press(KEY_E)
	await process_frame
	_check(is_equal_approx(scroll.camera.zoom.x, float(Framing.follow(scroll.model, Vector2(LANDSCAPE))["zoom"])), "walking on returns to the follow framing")
	await _despawn(a)


## 7. 观察中回院：观察态随画卷一起失效；旧画卷迟到的带上 / 结束观察信号被忽略
func _return_while_observing() -> void:
	var a = await _spawn()
	a.set_out()
	a.scroll.model.x = 2200.0
	await _press(KEY_E)
	var old = a.scroll
	var generation: int = a.scroll_generation
	## 小院接管那一刻核对研究画卷新增的信号也已断开，不依赖画卷自己列出的信号表
	var seen: Array[bool] = []
	var probe := func() -> void:
		seen.append(is_instance_valid(old) and not old.is_observing() and old.pick_toggled.get_connections().is_empty() and old.observe_ended.get_connections().is_empty())
	a.yard.activated.connect(probe)
	await _press(KEY_R)
	a.yard.activated.disconnect(probe)
	_check(seen == [true], "observing ended and pick / observe-end signals were disconnected when the yard opened")
	_check(a.mode == "yard" and a.scroll == null, "returning while observing leaves cleanly")
	_check(a.session().get_view()["proposal_items"] == 0, "returning while observing without taking stays empty-handed")
	var record: int = a.session().record_revision()
	a._on_pick_toggled("placeholder_b", generation)
	a._on_observe_ended("placeholder_b", generation)
	_check(a.events.has("stale_pick_ignored") and a.session().record_revision() == record, "a late pick from the old scroll is ignored")
	_check(not a.events.has("observe_end:placeholder_b"), "a late observe end from the old scroll is not logged")
	a.host_action("ok")
	_check(a.set_out().ok and a.scroll != old and not a.scroll.is_observing(), "the next trip starts outside the observing state")
	a._on_pick_toggled("placeholder_b", generation)
	_check(a.session().get_view()["carried"].is_empty(), "an old-generation pick cannot take on the new trip")
	await _despawn(a)


## 8. 空手往返的保存结果：未知、失败、重试时都不说已记下 / 已收好；确认后才说已记下
func _empty_trip_results() -> void:
	var a = await _spawn()
	a.set_out()
	await _press(KEY_R)
	_check(a.mode == "yard" and a.session().get_view()["proposal_items"] == 0, "returning right away is an empty trip")
	a.host_action("unknown")
	_check(a.status_text() == Experience.TEXT_EMPTY_UNKNOWN, "an unknown empty result says it is still being checked")
	_no_saved_claim(a, "an unknown empty result")
	_collect(a)
	a.host_action("resolve")
	_check(a.status_text() == Experience.TEXT_EMPTY_SAVED, "a resolved landed empty trip says the walk is noted")
	_collect(a)
	a.set_out()
	await _press(KEY_R)
	a.host_action("fail")
	_check(a.status_text() == Experience.TEXT_EMPTY_FAILED, "a failed empty trip offers to try again")
	_no_saved_claim(a, "a failed empty trip")
	_collect(a)
	var blocked: Dictionary = a.set_out()
	_check(not blocked.ok and a.status_text().begins_with(Experience.TEXT_BLOCKED) and a.status_text().ends_with(Experience.TEXT_EMPTY_FAILED), "setting out with a failed empty trip is explained")
	_collect(a)
	a.host_action("retry")
	_check(a.status_text() == Experience.TEXT_EMPTY_SAVING, "retrying an empty trip shows it is being noted")
	a.host_action("ok")
	_check(a.status_text() == Experience.TEXT_EMPTY_SAVED, "the retried empty trip is noted after confirmation")
	await _despawn(a)


## 9. 措辞：测试中出现过的院内文字、提示与按钮都不含进度 / 任务类词
func _wording() -> void:
	_check(seen_texts.size() >= 10, "enough player-facing texts were collected (%d)" % seen_texts.size())
	var offending: Array[String] = []
	for text: String in seen_texts:
		for word: String in PROGRESS_WORDS:
			if text.contains(word):
				offending.append(text)
	_check(offending.is_empty(), "no progress wording in player-facing texts: %s" % [offending])


func _no_saved_claim(a, label: String) -> void:
	for word: String in SAVED_WORDS:
		_check(not a.status_text().contains(word), "no saved claim (%s) during %s" % [word, label])


func _collect(a) -> void:
	seen_texts.append(a.status_text())
	if a.scroll != null:
		for label: Label in [a.scroll._note, a.scroll._near, a.scroll._hint, a.scroll._pick_tag, a.scroll._go_tag]:
			if not label.text.is_empty():
				seen_texts.append(label.text)


func _spawn():
	var a = (load(SCENE) as PackedScene).instantiate()
	root.add_child(a)
	await process_frame
	return a


func _despawn(a: Node) -> void:
	var unverified: Array = a.events.filter(func(event: String) -> bool: return event.ends_with(":unverified") or event == "yard_open_refused")
	_check(unverified.is_empty(), "every logged step matched the real state: %s" % [unverified])
	a.queue_free()
	await process_frame
	await process_frame


func _press(code: Key) -> void:
	Input.parse_input_event(_key(code, true))
	Input.parse_input_event(_key(code, false))
	await process_frame


func _tap(index: int, x: float, y: float) -> void:
	Input.parse_input_event(_touch(index, x, y, true))
	Input.parse_input_event(_touch(index, x, y, false))
	await process_frame


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _key(code: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	return event


func _touch(index: int, x: float, y: float, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = Vector2(x, y)
	event.pressed = pressed
	return event


func _drag(index: int, x: float, y: float) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = Vector2(x, y)
	return event


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
