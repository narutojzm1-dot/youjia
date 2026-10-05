class_name ExplorationDirector
extends Node
# 宿主侧的外出导航（契约 §4“回院导航”、§9 生命周期）：院门前出发 → 画卷 → 回院。
# Main 只负责隐藏 / 恢复小院与界面；本节点负责核心宿主、画卷的创建与释放、回院后的文案。

signal entered
signal returned(notice_key: String)
signal notice(notice_key: String)

const RETRY_SECONDS := 30.0

var host: ExplorationHost
var scroll: NearPathScroll
var world_root: Node
var _retry_timer := RETRY_SECONDS


func attach(store: Object, root: Node) -> String:
	world_root = root
	host = ExplorationHost.new(store)
	var outcome := host.restore()
	if host.session.is_quarantined():
		return "notice.exploration.unavailable"
	return outcome_notice(outcome)


func is_exploring() -> bool:
	return scroll != null


## 小院里在门前小路选“出门走走”时调用；不能出门时只给温和说明，不困住玩家
func try_begin(clock: Dictionary, weather: String, seed: Variant = null) -> bool:
	if host == null or scroll != null:
		return false
	if not host.can_begin():
		if host.state() in [ExplorationContract.STATE_PENDING, ExplorationContract.STATE_FAILURE]:
			var outcome := host.retry_deferred()
			if host.can_begin():
				notice.emit(outcome_notice(outcome))
			else:
				notice.emit("notice.exploration.still_saving")
				return false
		else:
			notice.emit("notice.exploration.unavailable")
			return false
	if not host.begin(clock, seed).ok:
		notice.emit("notice.exploration.unavailable")
		return false
	scroll = NearPathScroll.new()
	scroll.name = "NearPathScroll"
	world_root.add_child(scroll)
	scroll.setup(host, weather)
	scroll.return_requested.connect(_on_return_requested)
	entered.emit()
	return true


## 标题 / 重开等宿主切换时：按宿主中断回院，已带上的东西照常提交
func interrupt() -> void:
	if scroll != null:
		_finish("host_interrupt")


## 院内空闲时自动重试上次没收好的提交；不需要玩家操作
func idle_tick(delta: float) -> void:
	if host == null or scroll != null:
		return
	if host.state() != ExplorationContract.STATE_FAILURE:
		_retry_timer = RETRY_SECONDS
		return
	_retry_timer -= delta
	if _retry_timer <= 0.0:
		_retry_timer = RETRY_SECONDS
		var outcome := host.retry_deferred()
		if outcome.get("state", "") == "committed":
			notice.emit(outcome_notice(outcome))


func _on_return_requested(reason: String) -> void:
	_finish(reason)


func _finish(reason: String) -> void:
	var result := host.request_return(reason)
	if not result.get("navigate", false):
		if scroll != null:
			scroll.leaving = false
		return
	var old := scroll
	scroll = null
	old.release()
	old.queue_free()
	returned.emit(outcome_notice(result.get("outcome", {})))


## “已回院”与“收好了”分开：只有提交成功才说收进篮子
static func outcome_notice(outcome: Dictionary) -> String:
	if outcome.is_empty():
		return ""
	var granted: PackedStringArray = outcome.get("items", PackedStringArray())
	if outcome.get("state", "") == "committed":
		if granted.is_empty():
			return "notice.exploration.restored_empty" if outcome.get("restored", false) else "notice.exploration.back_empty"
		return "notice.exploration.kept.%s" % granted[0].get_slice(".", 2)
	if outcome.get("state", "") == "deferred":
		return "notice.exploration.deferred_items" if not granted.is_empty() else "notice.exploration.deferred_empty"
	return ""
