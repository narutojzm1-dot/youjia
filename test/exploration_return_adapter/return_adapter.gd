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

## 借用 #176 夹具里的测试路线：gate ↔ pond，pond 必出 formal.find.reed，任意停留点可回院
const ROUTE := "formal.test_walk"
## 画卷占位停留点 → 核心路线停留点；未映射的停留点只能看，不调用核心
const STOP_MAP := {"placeholder_a": "gate", "placeholder_b": "pond"}

## 院内保存状态文字；只有核心进入 committed 后才会出现「已收好」
const TEXT_IDLE := "小院 · 可以出门"
const TEXT_SAVING := "正在收好带回的东西…可以先在院子里走走"
const TEXT_UNKNOWN := "还在确认带回的东西有没有收好，可以先在院子里走走"
const TEXT_FAILED := "这次没能收好，带回的东西还记着，稍后会再试"
const TEXT_REJECTED := "有带回的东西收不下"
const TEXT_SAVED := "带回的东西已收好"
const TEXT_BLOCKED := "上一趟带回的东西还没收好，先不出门"

## 核心契约与假宿主按路径加载，因此保持无类型
var C
var host
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
	host = load(FAKE_HOST_PATH).new(fixtures.formal_catalog())
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
	_close_committed()
	var result: Dictionary = host.set_out(ROUTE, {"day": 1, "elapsed": 0.0}, trips_started + 1)
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
	scroll = AdaptedScroll.new()
	scroll.name = "Scroll"
	add_child(scroll)
	scroll.return_requested.connect(_on_return_requested.bind(scroll_generation))
	scroll.observe_requested.connect(_on_observe_requested.bind(scroll_generation))
	mode = "scroll"
	_log("scroll_on")
	return result


## 回院：核心没进入待提交就留在画卷；进入后按固定顺序拆掉画卷再开放小院
func _on_return_requested(generation: int) -> void:
	if generation != scroll_generation or mode != "scroll":
		_log("stale_return_ignored")
		return
	_log("return_requested")
	host.go_home("player")
	if core_state() == C.STATE_ACTIVE:
		_log("return_rejected")
		return
	_log("core:%s" % core_state())
	_leave_scroll()
	_enter_yard()
	if host.in_flight.is_empty() and not host.queue.is_empty():
		host.start_next()
		_log("flight_started")
	refresh()


func _on_observe_requested(stop_id: String, generation: int) -> void:
	if generation != scroll_generation or mode != "scroll":
		_log("stale_observe_ignored")
		return
	if not STOP_MAP.has(stop_id):
		scroll.show_note("这里只是看看（未接入路线的占位停留点）")
		_log("observe_only:%s" % stop_id)
		return
	var target: String = STOP_MAP[stop_id]
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
	var old := scroll
	old.deactivate()
	_log("scroll_input_off")
	_log("scroll_camera_off")
	## 连接时绑定了代号，is_connected 认不出原方法，所以按连接表逐个断开
	for sig: Signal in [old.return_requested, old.observe_requested]:
		for link: Dictionary in sig.get_connections():
			if (link["callable"] as Callable).get_object() == self:
				sig.disconnect(link["callable"])
	_log("scroll_disconnected")
	remove_child(old)
	old.queue_free()
	scroll = null
	_log("scroll_freed")


func _enter_yard() -> void:
	mode = "yard"
	yard.activate()
	_log("yard_camera_current")
	_log("yard_input_on")


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
		_:
			result = {"ok": false, "error": "unknown_action"}
	_log("host:%s" % action)
	## 「先不出门」只解释刚才那次被拒；保存结果一变就回到普通状态文字
	_blocked = false
	refresh()
	return result


## 按核心与假宿主当前状态刷新院内文字；committed 后关闭旅程并记住「已收好」
func refresh() -> void:
	if core_state() == C.STATE_COMMITTED:
		_saved_trip = host.session.trip_id()
		host.session.close()
		_blocked = false
		_log("closed:%s" % _saved_trip)
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


## 已提交未关闭时才关闭；其他状态交给核心自己拒绝
func _close_committed() -> void:
	if core_state() == C.STATE_COMMITTED:
		refresh()


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
