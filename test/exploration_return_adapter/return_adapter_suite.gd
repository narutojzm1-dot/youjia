extends SceneTree
# 回院适配隔离原型（#200）的隔离测试：只在独立最小项目里运行，核心与假宿主来自 #176 固定 SHA。
# 覆盖：回院事件顺序、重复回院只导航一次、退出边界后旧输入 / 旧信号 / 旧相机无效、
# 结果未知 / 迟到确认 / 明确失败时院内可走且不显示虚假已收好、持有 flight 时不能新出门、
# 反复往返连接与节点不累积、暂停与触摸取消路径。
# 只证明视图适配与导航；不证明耐久保存或强退恢复。

const SCENE := "res://test/exploration_return_adapter/return_adapter.tscn"
const Adapter := preload("res://test/exploration_return_adapter/return_adapter.gd")
const CORE_SHA := "e2a6d70b186d40c09cfcf48c48292838993d7eb7"
## 「已收好」字样：只允许在核心确认提交后出现
const SAVED_WORD := "已收好"
const RETURN_ORDER := [
	"return_requested", "core:pending_commit", "scroll_input_off", "scroll_camera_off",
	"scroll_disconnected", "scroll_freed", "yard_camera_current", "yard_input_on", "flight_started",
]

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	## 无头模式默认视口只有 64×64，触摸半屏与顶部操作条需要真实尺寸
	root.size = Vector2i(1280, 720)
	await process_frame
	_core_source()
	await _return_order()
	await _repeat_return()
	await _stale_after_exit()
	await _held_unknown()
	await _held_lost_callback()
	await _held_failure()
	await _held_unknown_not_landed()
	await _content_rejected()
	await _stale_generation_alive()
	await _return_refused()
	await _round_trips()
	await _pause_and_cancel()
	await _touch_bar()
	for failure: String in failures:
		push_error(failure)
	print("EXPLORATION RETURN ADAPTER %s %d" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)


## 0. 核心来源可追溯：临时工程里记录了固定 SHA，核心类来自该来源
func _core_source() -> void:
	var text := FileAccess.get_file_as_string("res://CORE_SOURCE.txt")
	_check(text.contains(CORE_SHA), "the temporary project records the pinned core SHA")
	_check(text.contains("scripts/exploration/exploration_session.gd"), "the core session file is listed as extracted")
	_check(ResourceLoader.exists("res://test/fixtures/exploration_fake_host.gd"), "the fake host comes from the pinned core branch")


## 1. 回院顺序：核心先进入待提交，再关画卷输入 / 相机 / 连接，最后开放小院
func _return_order() -> void:
	var a = await _spawn()
	_check(a.mode == "yard" and a.status_text() == Adapter.TEXT_IDLE, "the adapter starts in the yard")
	_check(a.set_out().ok and a.mode == "scroll", "setting out opens the scroll")
	_check(not a.yard.active and not a.yard.camera.enabled, "the yard is inert while on the scroll")
	_check(root.get_viewport().get_camera_2d() == a.scroll.camera, "the scroll camera drives the view outside")
	a.scroll.model.x = 2200.0
	Input.parse_input_event(_key(KEY_E, true))
	Input.parse_input_event(_key(KEY_E, false))
	await process_frame
	_check(a.events.has("take:formal.find.reed"), "observing at placeholder B takes the offered find through the core")
	_check(a.core_state() == "active" and a.session().get_view()["carried"].size() == 1, "the core carries one find before returning")
	var old = a.scroll
	var mark: int = a.events.size()
	## 小院接管那一刻的真实状态，不依赖适配器自己写的事件记录
	var seen: Array[Dictionary] = []
	var probe := func() -> void:
		seen.append({
			"scroll_dropped": a.scroll == null,
			"old_out": is_instance_valid(old) and not old.is_inside_tree(),
			"old_inert": is_instance_valid(old) and not old.active and not old.camera.enabled,
			"old_unlinked": is_instance_valid(old) and old.return_requested.get_connections().is_empty() and old.observe_requested.get_connections().is_empty(),
			"core": a.core_state(),
		})
	a.yard.activated.connect(probe)
	Input.parse_input_event(_key(KEY_R, true))
	Input.parse_input_event(_key(KEY_R, false))
	await process_frame
	var tail: Array = a.events.slice(mark, mark + RETURN_ORDER.size())
	_check(tail == RETURN_ORDER, "return runs in the fixed order: %s" % [tail])
	a.yard.activated.disconnect(probe)
	_check(seen.size() == 1, "the yard opened exactly once")
	if seen.size() == 1:
		var at: Dictionary = seen[0]
		_check(at["core"] == "pending_commit", "the core was already pending when the yard opened")
		_check(at["scroll_dropped"] and at["old_out"], "the scroll had left the tree when the yard opened")
		_check(at["old_inert"], "scroll input and camera were off when the yard opened")
		_check(at["old_unlinked"], "scroll signals were disconnected when the yard opened")
	_check(a.mode == "yard" and a.scroll == null, "the yard is open and the adapter dropped the scroll")
	_check(not is_instance_valid(old) or (not old.active and not old.camera.enabled and not old.is_inside_tree()), "the old scroll is inert and out of the tree until it is freed")
	_check(root.get_viewport().get_camera_2d() == a.yard.camera, "the yard camera now drives the view")
	_check(a.core_state() == "pending_commit", "the core stays pending_commit after navigating home")
	_check(not a.host.in_flight.is_empty() and a.host.return_calls == 1, "one write is in flight for the returned trip")
	_check(a.status_text() == Adapter.TEXT_SAVING, "the yard says saving, not saved")
	_check(not a.status_text().contains(SAVED_WORD), "no saved claim while the write is in flight")
	a.host_action("ok")
	_check(a.status_text() == Adapter.TEXT_SAVED and a.core_state() == "idle", "only a confirmed commit shows saved")
	_check(a.host.grants == 1 and a.host.inventory.has("formal.find.reed"), "the confirmed find is granted once")
	await process_frame
	_check(not is_instance_valid(old), "the old scroll node is freed")
	await _despawn(a)


## 2. 重复回院：同一画卷连发、平台返回键再发都只导航一次，不重冻提案、不重复入队
func _repeat_return() -> void:
	var a = await _spawn()
	a.set_out()
	a.scroll.model.x = 2200.0
	a.scroll.observe_requested.emit("placeholder_b")
	var old = a.scroll
	var generation: int = a.scroll_generation
	old.return_requested.emit()
	var revision: int = a.session().get_proposal()["revision"]
	var record: int = a.session().record_revision()
	var flight: Dictionary = a.host.in_flight.duplicate(true)
	old.return_requested.emit()
	old.return_requested.emit()
	a._on_return_requested(generation)
	a.host.go_home("player")
	a.host.go_home("host_interrupt")
	_check(old.return_requested.get_connections().is_empty() and old.observe_requested.get_connections().is_empty(), "the old scroll signals are disconnected")
	_check(not old.active and not old.camera.enabled and not old.is_inside_tree(), "the old scroll is inert and out of the tree before it is freed")
	Input.parse_input_event(_key(KEY_R, true))
	Input.parse_input_event(_key(KEY_R, false))
	await process_frame
	_check(a.events.count("return_requested") == 1, "the return navigation ran once")
	_check(a.events.count("stale_return_ignored") == 1, "a direct stale return call is ignored")
	_check(a.host.return_calls == 1, "the core was asked to return once")
	_check(a.session().get_proposal()["revision"] == revision, "the proposal is not refrozen")
	_check(a.session().record_revision() == record, "repeated returns do not touch the core record")
	_check(a.host.queue.is_empty() and a.host.in_flight["trip_id"] == flight["trip_id"] and a.host.in_flight["revision"] == flight["revision"], "the trip is not queued twice")
	_check(not is_instance_valid(old), "the old scroll is freed by the next frame")
	await _despawn(a)


## 3. 退出边界之后：旧点击、旧移动、排队中的旧信号都不改核心，旧相机不控制院内
func _stale_after_exit() -> void:
	var a = await _spawn()
	a.set_out()
	a.scroll.model.x = 2200.0
	var old = a.scroll
	var generation: int = a.scroll_generation
	old.input.press("key_%d" % KEY_RIGHT, 1)
	old.observe_requested.emit.call_deferred("placeholder_b")
	old.return_requested.emit.call_deferred()
	old.return_requested.emit()
	var record: int = a.session().record_revision()
	var old_x: float = old.model.x
	var mark: int = a.events.size()
	old._unhandled_input(_key(KEY_E, true))
	old._unhandled_input(_key(KEY_R, true))
	old._unhandled_input(_touch(0, 900.0, 300.0, true))
	old._process(1.0)
	_check(old.model.x == old_x and old.input.held_count() == 0, "the old scroll no longer moves or holds input")
	_check(not old.camera.enabled and root.get_viewport().get_camera_2d() == a.yard.camera, "the old camera cannot take the view back")
	a._on_observe_requested("placeholder_b", generation)
	Input.parse_input_event(_key(KEY_E, true))
	Input.parse_input_event(_key(KEY_E, false))
	await process_frame
	await process_frame
	_check(a.session().record_revision() == record, "late clicks and queued signals leave the core untouched")
	_check(a.session().get_proposal()["items"].is_empty(), "nothing was taken after leaving the scroll")
	var after: Array = a.events.slice(mark)
	_check(after == ["stale_observe_ignored"], "only the direct stale call reached the adapter: %s" % [after])
	_check(not is_instance_valid(old), "the old scroll was freed")
	_check(root.get_viewport().get_camera_2d() == a.yard.camera, "the yard camera still drives the view")
	await _despawn(a)


## 4. 结果未知：院内可走、不显示已收好、不能新出门；静止核验确认后才显示已收好
func _held_unknown() -> void:
	var a = await _returned_with_find()
	a.host_action("unknown")
	_check(a.status_text() == Adapter.TEXT_UNKNOWN, "an unknown result says still confirming")
	_check(not a.status_text().contains(SAVED_WORD) and a.host.grants == 0, "an unknown result is not shown as saved")
	await _yard_walks(a, "unknown")
	await _set_out_blocked(a, "unknown")
	_check(a.host.unknown and not a.host.in_flight.is_empty(), "the unknown flight is still held")
	a.host_action("resolve")
	_check(a.status_text() == Adapter.TEXT_SAVED and a.host.grants == 1, "resolving the landed write shows saved once")
	_check(a.set_out().ok, "a new trip may start after the held flight resolves")
	await _despawn(a)


## 5. 迟到确认：已落盘但回调丢失时仍显示保存中；队首重放靠水位确认，不重复授予
func _held_lost_callback() -> void:
	var a = await _returned_with_find()
	a.host_action("lost")
	_check(a.core_state() == "pending_commit", "a lost callback leaves the core pending")
	_check(a.status_text() == Adapter.TEXT_SAVING, "a lost callback still says saving")
	_check(not a.status_text().contains(SAVED_WORD), "a lost callback is not shown as saved")
	await _yard_walks(a, "late confirmation")
	await _set_out_blocked(a, "late confirmation")
	a.host_action("next")
	_check(a.status_text() == Adapter.TEXT_SAVED, "the late confirmation shows saved")
	_check(a.host.grants == 1 and a.host.inventory.count("formal.find.reed") == 1, "the late confirmation does not grant twice")
	await _despawn(a)


## 6. 明确失败：说明没收好、院内可走、不能新出门；重试成功后才显示已收好
func _held_failure() -> void:
	var a = await _returned_with_find()
	a.host_action("fail")
	_check(a.core_state() == "recoverable_failure", "a failed write moves the core to recoverable failure")
	_check(a.status_text() == Adapter.TEXT_FAILED, "a failed write says it was not saved")
	_check(not a.status_text().contains(SAVED_WORD) and a.host.grants == 0, "a failed write is not shown as saved")
	await _yard_walks(a, "failure")
	await _set_out_blocked(a, "failure")
	a.host_action("retry")
	_check(a.status_text() == Adapter.TEXT_SAVING and not a.host.in_flight.is_empty(), "retrying starts a new write and says saving")
	a.host_action("ok")
	_check(a.status_text() == Adapter.TEXT_SAVED and a.host.grants == 1, "a successful retry shows saved once")
	await _despawn(a)


## 7. 反复往返：视口连接、子节点、信号连接、节点总数与孤儿节点都不增长
func _round_trips() -> void:
	var a = await _spawn()
	await process_frame
	var baseline: Dictionary = a.connection_report()
	var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	var peak_viewport := 0
	for trip in 6:
		_check(a.set_out().ok, "round trip %d sets out" % trip)
		peak_viewport = maxi(peak_viewport, a.connection_report()["viewport_size_changed"])
		a.scroll.model.x = 2200.0
		a.scroll.observe_requested.emit("placeholder_b")
		a.scroll.return_requested.emit()
		a.host_action("ok")
		await process_frame
		await process_frame
		_check(a.connection_report() == baseline, "round trip %d leaves connections and children as before: %s" % [trip, a.connection_report()])
	_check(peak_viewport > baseline["viewport_size_changed"], "the live scroll does hold viewport connections, so the reset above is meaningful")
	_check(Performance.get_monitor(Performance.OBJECT_NODE_COUNT) == nodes, "node count does not grow over round trips")
	_check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) == orphans, "no orphan nodes are left behind")
	_check(a.host.grants == 6 and a.trips_started == 6, "each round trip committed exactly once")
	_check(a.session().trip_id() == "" or a.core_state() == "idle", "the last trip is closed")
	await _despawn(a)


## 8. 暂停与触摸取消：画卷与小院里都能复现；画卷里按住的手指不会带进小院
func _pause_and_cancel() -> void:
	var a = await _spawn()
	a.set_out()
	var s = a.scroll
	Input.parse_input_event(_touch(0, 1000.0, 400.0, true))
	await _frames(5)
	var moved: float = s.model.x
	_check(moved > 400.0, "holding the right half walks on the scroll")
	s.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	await _frames(5)
	_check(s.input.held_count() == 0 and s.model.x == moved, "pausing on the scroll drops every held source")
	Input.parse_input_event(_touch(0, 1000.0, 400.0, false))
	Input.parse_input_event(_touch(1, 1000.0, 400.0, true))
	await _frames(3)
	var cancel := _touch(1, 1000.0, 400.0, false)
	cancel.canceled = true
	Input.parse_input_event(cancel)
	await process_frame
	var stopped: float = s.model.x
	await _frames(5)
	_check(s.model.x == stopped and s.input.held_count() == 0, "a canceled touch stops the scroll walker")
	Input.parse_input_event(_touch(2, 1000.0, 400.0, true))
	await _frames(2)
	Input.parse_input_event(_key(KEY_R, true))
	Input.parse_input_event(_key(KEY_R, false))
	await process_frame
	var yard_x: float = a.yard.x
	Input.parse_input_event(_drag(2, 1100.0, 400.0))
	await _frames(5)
	_check(a.yard.x == yard_x and a.yard.input.held_count() == 0, "a finger held on the scroll does not walk the yard")
	Input.parse_input_event(_touch(2, 1100.0, 400.0, false))
	Input.parse_input_event(_touch(3, 1000.0, 400.0, true))
	await _frames(5)
	_check(a.yard.x > yard_x, "a fresh touch walks in the yard while the write is pending")
	var state: String = a.core_state()
	a.yard.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var paused_x: float = a.yard.x
	await _frames(5)
	_check(a.yard.input.held_count() == 0 and a.yard.x == paused_x, "pausing in the yard drops held input")
	_check(a.core_state() == state, "pausing does not change the core")
	Input.parse_input_event(_touch(3, 1000.0, 400.0, false))
	Input.parse_input_event(_touch(4, 200.0, 400.0, true))
	await _frames(2)
	var yard_cancel := _touch(4, 200.0, 400.0, false)
	yard_cancel.canceled = true
	Input.parse_input_event(yard_cancel)
	await process_frame
	var yard_stopped: float = a.yard.x
	await _frames(5)
	_check(a.yard.x == yard_stopped and a.yard.input.held_count() == 0, "a canceled touch stops the yard walker")
	await _despawn(a)


## 9. 顶部操作条：触屏可回院、可出门；持有 flight 时出门被拒
func _touch_bar() -> void:
	var a = await _spawn()
	var width: float = root.get_viewport().get_visible_rect().size.x
	Input.parse_input_event(_touch(0, width - 40.0, 30.0, true))
	Input.parse_input_event(_touch(0, width - 40.0, 30.0, false))
	await process_frame
	_check(a.mode == "scroll", "tapping set out in the yard bar opens the scroll")
	a.scroll.model.x = 2200.0
	Input.parse_input_event(_touch(1, 300.0, 30.0, true))
	Input.parse_input_event(_touch(1, 300.0, 30.0, false))
	await process_frame
	_check(a.events.has("take:formal.find.reed"), "tapping the top hint observes the nearby stop")
	var x_before: float = a.scroll.model.x
	Input.parse_input_event(_touch(2, width - 40.0, 30.0, true))
	Input.parse_input_event(_touch(2, width - 40.0, 30.0, false))
	await process_frame
	_check(a.mode == "yard" and a.core_state() == "pending_commit", "tapping return in the scroll bar goes home")
	_check(x_before == 2200.0, "the top bar taps did not walk the scroll")
	Input.parse_input_event(_touch(3, width - 40.0, 30.0, true))
	Input.parse_input_event(_touch(3, width - 40.0, 30.0, false))
	await process_frame
	_check(a.mode == "yard" and a.events.has("set_out_rejected:pending_exists"), "tapping set out while a flight is held is refused")
	_check(a.status_text().begins_with(Adapter.TEXT_BLOCKED), "the yard explains why it cannot set out")
	await _despawn(a)


## 6b. 结果未知且未落盘：静止核验仍未定；旧写入确定终止后才判为失败，重试成功才显示已收好
func _held_unknown_not_landed() -> void:
	var a = await _returned_with_find()
	a.host_action("unknown_lost")
	_check(a.status_text() == Adapter.TEXT_UNKNOWN and a.host.grants == 0, "an unlanded unknown result says still confirming")
	var still: Dictionary = a.host_action("resolve")
	_check(still.get("error", "") == "still_unknown" and a.status_text() == Adapter.TEXT_UNKNOWN, "without proof the old write ended, it stays unknown")
	await _yard_walks(a, "unlanded unknown")
	await _set_out_blocked(a, "unlanded unknown")
	a.host_action("terminate")
	a.host_action("resolve")
	_check(a.core_state() == "recoverable_failure" and a.status_text() == Adapter.TEXT_FAILED, "once the old write ended at the parent it counts as a failure")
	_check(not a.status_text().contains(SAVED_WORD), "the parent-on-disk outcome is not shown as saved")
	a.host_action("retry")
	a.host_action("ok")
	_check(a.status_text() == Adapter.TEXT_SAVED and a.host.grants == 1, "a retry after the unlanded unknown saves once")
	await _despawn(a)


## 6c. 内容被拒：按物品拒绝时提案去掉该物后重排；整体不可重试时可以空手收尾，不会卡死
func _content_rejected() -> void:
	var a = await _spawn()
	a.set_out()
	a.scroll.model.x = 2200.0
	a.scroll.observe_requested.emit("placeholder_b")
	a.host.reject_ids = PackedStringArray(["formal.find.reed"])
	a.scroll.return_requested.emit()
	await process_frame
	_check(a.core_state() == "pending_commit" and a.session().get_proposal()["items"].is_empty(), "a rejected find is dropped from the proposal")
	_check(a.status_text() == Adapter.TEXT_SAVING, "the trimmed proposal is still saving, not saved")
	a.host_action("next")
	a.host_action("ok")
	_check(a.status_text() == Adapter.TEXT_SAVED and a.host.grants == 0, "the trimmed trip closes without granting the rejected find")
	await _despawn(a)
	var b = await _spawn()
	b.set_out()
	var generation: int = b.scroll_generation
	b.session().request_return("player")
	b.session().commit_failed(b.session().trip_id(), false)
	b._on_return_requested(generation)
	await process_frame
	_check(b.mode == "yard" and b.core_state() == "recoverable_failure", "a non-retryable failure still navigates home")
	_check(b.status_text() == Adapter.TEXT_REJECTED and not b.status_text().contains(SAVED_WORD), "a non-retryable failure is explained without a saved claim")
	await _set_out_blocked(b, "content rejection")
	b.host_action("settle")
	_check(b.core_state() == "pending_commit" and not b.host.in_flight.is_empty(), "settling empty starts an empty write")
	b.host_action("ok")
	_check(b.status_text() == Adapter.TEXT_SAVED and b.set_out().ok, "after settling empty the player can set out again")
	await _despawn(b)
	## 关闭旅程失败：核心已 committed 但 close() 被拒时记 close_failed，不显示已收好
	var c = await _returned_with_find()
	c.host.finish(true, true)
	c.session()._quarantined = true
	c._settle_committed()
	c.refresh()
	_check(c.events.has("close_failed:quarantine_frozen"), "a refused close is logged as close_failed")
	_check(not c.status_text().contains(SAVED_WORD), "a refused close is not shown as saved")
	await _despawn(c)


## 6d. 代号守卫：上一代画卷的迟到请求在新画卷存活时到达，也不能回院或改核心
func _stale_generation_alive() -> void:
	var a = await _returned_with_find()
	var old_generation: int = a.scroll_generation
	a.host_action("ok")
	_check(a.set_out().ok and a.mode == "scroll", "a second trip opens a new scroll")
	a.scroll.model.x = 2200.0
	var live = a.scroll
	var record: int = a.session().record_revision()
	a._on_return_requested(old_generation)
	a._on_observe_requested("placeholder_b", old_generation)
	await process_frame
	_check(a.events.count("stale_return_ignored") == 1 and a.events.count("stale_observe_ignored") == 1, "requests from the previous scroll are ignored")
	_check(a.mode == "scroll" and a.scroll == live and a.core_state() == "active", "the live scroll stays and the core stays active")
	_check(a.session().record_revision() == record and a.host.return_calls == 1, "the previous scroll did not touch the new trip")
	await _despawn(a)


## 6e. 回院被拒：不在可回院的停留点时留在画卷并给出提示；走回可回院处后正常回院
func _return_refused() -> void:
	var a = (load(SCENE) as PackedScene).instantiate()
	a.route_id = "fixture.gate_only"
	a.catalog_kind = "fixture"
	a.stop_map = {"placeholder_a": "gate", "placeholder_b": "field"}
	root.add_child(a)
	await process_frame
	_check(a.set_out().ok, "the gate-only fixture route sets out")
	a.scroll.observe_requested.emit("placeholder_b")
	var record: int = a.session().record_revision()
	a.scroll.return_requested.emit()
	await process_frame
	_check(a.events.has("return_rejected:not_return_stop"), "returning away from a return stop is refused by the core")
	_check(a.mode == "scroll" and a.scroll != null and a.scroll.active and a.core_state() == "active", "a refused return stays on the scroll")
	_check(a.scroll._note.text.contains("还不能回院"), "the refusal is shown to the player")
	_check(a.session().record_revision() == record, "a refused return does not change the core record")
	a.scroll.observe_requested.emit("placeholder_a")
	a.scroll.return_requested.emit()
	await process_frame
	_check(a.mode == "yard" and a.core_state() != "active", "returning from the gate goes home")
	await _despawn(a)


func _returned_with_find():
	var a = await _spawn()
	a.set_out()
	a.scroll.model.x = 2200.0
	a.scroll.observe_requested.emit("placeholder_b")
	a.scroll.return_requested.emit()
	await process_frame
	return a


func _yard_walks(a, label: String) -> void:
	var x: float = a.yard.x
	Input.parse_input_event(_key(KEY_RIGHT, true))
	await _frames(5)
	Input.parse_input_event(_key(KEY_RIGHT, false))
	await process_frame
	_check(a.yard.x > x, "the yard stays walkable during %s" % label)


func _set_out_blocked(a, label: String) -> void:
	var flight: Dictionary = a.host.in_flight.duplicate(true)
	var record: int = a.session().record_revision()
	var result: Dictionary = a.set_out()
	await process_frame
	_check(not result.ok and result.get("error", "") == "pending_exists", "setting out during %s is refused as pending_exists" % label)
	_check(a.mode == "yard" and a.scroll == null, "no scroll is built during %s" % label)
	_check(a.host.in_flight == flight and a.session().record_revision() == record, "the held flight is untouched during %s" % label)
	_check(a.status_text().begins_with(Adapter.TEXT_BLOCKED) and not a.status_text().contains(SAVED_WORD), "the refusal is explained without a saved claim during %s" % label)


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
