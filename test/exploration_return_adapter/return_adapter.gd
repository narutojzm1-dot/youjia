extends Node
# 回院适配器（#200）：把画卷视图、模拟小院和 #176 探索核心 + 假宿主接在一起，只验证视图适配与导航。
# 回院顺序：核心确认进入待提交 → 画卷输入 / 处理关闭 → 画卷相机关闭 → 断开画卷信号与视口连接
#           → 移出并释放画卷 → 小院相机接管 → 小院输入开放。保存结果只由假宿主决定。
# 核心与假宿主来自 #176 固定 SHA，由运行脚本装入临时工程；这里按路径运行时加载，
# 主项目扫描到本目录时不会因为缺少未合入的核心文件而解析失败。
# 不证明耐久保存或强退恢复；真实宿主、H2/H3/H4 由 CODEX-LEAD 负责。

const AdaptedScroll := preload("res://test/exploration_return_adapter/adapted_scroll.gd")
const SimYard := preload("res://test/exploration_return_adapter/sim_yard.gd")
const CONTRACT_PATH := "res://scripts/exploration/exploration_contract.gd"
const FAKE_HOST_PATH := "res://test/fixtures/exploration_fake_host.gd"
const FIXTURES_PATH := "res://test/fixtures/exploration_fixture_routes.gd"


## 院内保存状态文字；只有核心进入 committed 后才会出现「已收好」
const TEXT_IDLE := "小院 · 可以出门"
const TEXT_SAVING := "正在收好带回的东西…可以先在院子里走走"
const TEXT_UNKNOWN := "还在确认带回的东西有没有收好，可以先在院子里走走"
## 占位文案不承诺自动重试：原型里重试 / 空手收尾都要由假宿主控制键触发
const TEXT_FAILED := "这次没能收好，带回的东西还记着，可以再试一次"
const TEXT_REJECTED := "有带回的东西收不下，可以空手收尾"
const TEXT_SAVED := "带回的东西已收好"
const TEXT_BLOCKED := "上一趟带回的东西还没收好，先不出门"

## 核心契约与假宿主按路径加载，因此保持无类型
var C
var host
## 以下三项可在加入场景树前改写；默认借用 #176 夹具里的测试路线：
## gate ↔ pond，pond 必出 formal.find.reed，任意停留点可回院
var route_id := "formal.test_walk"
## "formal" 用夹具里的模拟正式目录（可提交）；"fixture" 用夹具目录（只用于测试回院限制等，不提交）
var catalog_kind := "formal"
## 画卷占位停留点 → 核心路线停留点；未映射的停留点只能看，不调用核心
var stop_map := {"placeholder_a": "gate", "placeholder_b": "pond"}
## 每次出门实例化的画卷脚本；研究切片可换成 AdaptedScroll 的子类
var scroll_script: GDScript = AdaptedScroll
var yard: SimYard
var scroll: AdaptedScroll
## "yard" 或 "scroll"；只在完整切换后改变
var mode := "yard"
## 事件顺序记录，测试与演示都读它
var events: Array[String] = []
## 每次出门换一代画卷；旧画卷的迟到信号带着旧代号，一律忽略
var scroll_generation := 0
var trips_started := 0
var _saved_trip := ""
var _blocked := false


func _ready() -> void:
	C = load(CONTRACT_PATH)
	var fixtures = load(FIXTURES_PATH)
	host = load(FAKE_HOST_PATH).new(fixtures.formal_catalog() if catalog_kind == "formal" else fixtures.catalog())
	yard = SimYard.new()
	yard.name = "Yard"
	add_child(yard)
	yard.set_out_requested.connect(set_out)
	yard.host_action_requested.connect(host_action)
	yard.activate()
	_log("yard_on")
	refresh()


func session():
	return host.session


func core_state() -> String:
	return host.session.get_state()


## 小院里请求出门：核心拒绝（例如还有持有中的 flight）时留在院里，不建画卷
func set_out() -> Dictionary:
	if mode != "yard":
		_log("set_out_ignored")
		return {"ok": false, "error": "not_in_yard"}
	_settle_committed()
	var result: Dictionary = host.set_out(route_id, {"day": 1, "elapsed": 0.0}, trips_started + 1)
	if not result.ok:
		_blocked = result.get("error", "") == "pending_exists"
		_log("set_out_rejected:%s" % result.get("error", ""))
		refresh()
		return result
	if result.get("persist", false):
		host.persist()
	trips_started += 1
	_blocked = false
	_saved_trip = ""
	_log("set_out:%s" % host.session.trip_id())
	yard.deactivate()
	_log("yard_off")
	scroll_generation += 1
	scroll = scroll_script.new()
	scroll.name = "Scroll"
	add_child(scroll)
	_connect_scroll(scroll, scroll_generation)
	mode = "scroll"
	_log("scroll_on")
	return result


## 新画卷的请求信号都绑定本次代号；子类追加信号时先调用父类
func _connect_scroll(target: AdaptedScroll, generation: int) -> void:
	target.return_requested.connect(_on_return_requested.bind(generation))
	target.observe_requested.connect(_on_observe_requested.bind(generation))


## 回院：核心没进入待提交就留在画卷；进入后按固定顺序拆掉画卷再开放小院
func _on_return_requested(generation: int) -> void:
	if generation != scroll_generation or mode != "scroll":
		_log("stale_return_ignored")
		return
	_log("return_requested")
	host.go_home("player")
	if core_state() == C.STATE_ACTIVE:
		var reason := "not_return_stop" if not host.session.get_view().get("can_return", true) else "rejected"
		scroll.show_note("这里还不能回院，先走回能回院的地方" if reason == "not_return_stop" else "现在还不能回院")
		_log("return_rejected:%s" % reason)
		return
	_log("core:%s" % core_state())
	_leave_scroll()
	_enter_yard()
	if host.in_flight.is_empty() and not host.queue.is_empty():
		host.start_next()
		_log("flight_started")
	_settle_committed()
	refresh()


func _on_observe_requested(stop_id: String, generation: int) -> void:
	if generation != scroll_generation or mode != "scroll":
		_log("stale_observe_ignored")
		return
	if not stop_map.has(stop_id):
		scroll.show_note("这里只是看看（未接入路线的占位停留点）")
		_log("observe_only:%s" % stop_id)
		return
	var target: String = stop_map[stop_id]
	var view: Dictionary = host.session.get_view()
	if view.get("current_stop", "") != target:
		var moved: Dictionary = host.session.visit(target)
		if not moved.ok:
			scroll.show_note("从这里还走不到那儿（%s）" % moved.get("error", ""))
			_log("visit_rejected:%s" % moved.get("error", ""))
			return
		host.persist()
		view = host.session.get_view()
	var offer: String = view.get("offer", "")
	if offer.is_empty():
		scroll.show_note("停下看了看，没有要带走的东西")
		_log("observe:%s" % target)
		return
	var taken: Dictionary = host.session.take(offer)
	if taken.ok:
		host.persist()
		scroll.show_note("带上了一样东西（占位：%s）" % offer)
		_log("take:%s" % offer)
	else:
		scroll.show_note("带不下了（%s）" % taken.get("error", ""))
		_log("take_rejected:%s" % taken.get("error", ""))


func _leave_scroll() -> void:
	## 每条事件都在核对真实状态后才记录；核对不过记为 :unverified，测试据此失败
	var old := scroll
	old.deactivate()
	_log_checked("scroll_input_off", not old.active and not old.is_processing() and not old.is_processing_unhandled_input() and old.input.held_count() == 0)
	_log_checked("scroll_camera_off", not old.camera.enabled and not get_viewport().size_changed.is_connected(old.layout))
	## 连接时绑定了代号，is_connected 认不出原方法，所以按连接表逐个断开
	var signals := old.request_signals()
	for sig: Signal in signals:
		for link: Dictionary in sig.get_connections():
			if (link["callable"] as Callable).get_object() == self:
				sig.disconnect(link["callable"])
	_log_checked("scroll_disconnected", signals.all(func(sig: Signal) -> bool: return sig.get_connections().is_empty()))
	remove_child(old)
	old.queue_free()
	scroll = null
	_log_checked("scroll_freed", not old.is_inside_tree() and old.is_queued_for_deletion())


## 画卷没拆干净就不开放小院
func _enter_yard() -> void:
	if scroll != null:
		_log("yard_open_refused")
		return
	mode = "yard"
	yard.activate()
	_log_checked("yard_camera_current", get_viewport().get_camera_2d() == yard.camera)
	_log_checked("yard_input_on", yard.active and yard.is_processing_unhandled_input())


## 假宿主控制：模拟平台给出的各种保存结果；真实平台没有这些入口
func host_action(action: String) -> Dictionary:
	var result: Dictionary = {}
	match action:
		"ok":
			result = host.finish(true, true)
		"fail":
			result = host.finish(false, true)
		"lost":
			result = host.finish(true, false)
		"unknown":
			host.finish_unknown(true)
			result = {"ok": true}
		"unknown_lost":
			host.finish_unknown(false)
			result = {"ok": true}
		"terminate":
			## 模拟 H2 举证旧写入已确定终止；之后静止核验才能把「停在 parent」判为失败
			host.old_write_terminated = true
			result = {"ok": true}
		"resolve":
			result = host.resolve_unknown()
		"next":
			result = host.start_next()
		"retry":
			result = host.session.retry_commit()
			if result.ok:
				host.enqueue_submit()
				if host.in_flight.is_empty():
					host.start_next()
		"settle":
			result = host.session.settle_empty()
			if result.ok:
				host.enqueue_submit()
				if host.in_flight.is_empty():
					host.start_next()
		_:
			result = {"ok": false, "error": "unknown_action"}
	_log("host:%s" % action)
	## 「先不出门」只解释刚才那次被拒；保存结果一变就回到普通状态文字
	_blocked = false
	_settle_committed()
	refresh()
	return result


## 只按核心与假宿主当前状态刷新院内文字，不改任何状态
func refresh() -> void:
	yard.set_status(status_text())


func status_text() -> String:
	var state := core_state()
	var text := TEXT_IDLE
	if state == C.STATE_PENDING:
		text = TEXT_UNKNOWN if host.unknown else TEXT_SAVING
	elif state == C.STATE_FAILURE:
		var failure: Dictionary = host.session.get_view().get("failure", {})
		text = TEXT_FAILED if failure.get("retryable", false) else TEXT_REJECTED
	elif state == C.STATE_IDLE and not _saved_trip.is_empty():
		text = TEXT_SAVED
	if _blocked and state != C.STATE_IDLE:
		text = TEXT_BLOCKED + " · " + text
	return text


## 收到提交结果后调用：核心已 committed 才关闭旅程并记住「已收好」；关闭失败不显示已收好
func _settle_committed() -> void:
	if core_state() != C.STATE_COMMITTED:
		return
	var trip: String = host.session.trip_id()
	var closed: Dictionary = host.session.close()
	if closed.ok:
		_saved_trip = trip
		_log("closed:%s" % trip)
	else:
		_log("close_failed:%s" % closed.get("error", ""))


## 连接与节点计数：反复往返时不应增长
func connection_report() -> Dictionary:
	return {
		"viewport_size_changed": get_viewport().size_changed.get_connections().size(),
		"children": get_child_count(),
		"yard_set_out": yard.set_out_requested.get_connections().size(),
		"yard_host_action": yard.host_action_requested.get_connections().size(),
		"scroll_alive": scroll != null,
	}


func _log(event: String) -> void:
	events.append(event)


func _log_checked(event: String, verified: bool) -> void:
	_log(event if verified else event + ":unverified")
