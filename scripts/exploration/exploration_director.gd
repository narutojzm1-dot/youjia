class_name ExplorationDirector
extends Node
# 宿主侧的外出导航（契约 §4“回院导航”、§9 生命周期）：院门前出发 → 画卷 → 回院。
# Main 只负责隐藏 / 恢复小院与界面；本节点负责核心宿主、画卷的创建与释放、回院后的文案。
# 回院时提交通常还没确认：returned 带空文案（Main 显示“回到院里了”），确认后再经 notice 说收好了。

signal entered
signal returned(notice_key: String)
signal notice(notice_key: String)
## 宿主重交了被拒的收尾清理（见 ExplorationHost.cleanup_resubmitted），Main 据此把旧失败绑到新编号
signal cleanup_resubmitted(failed_ops: Array, op_id: String)

const RETRY_SECONDS := 30.0

var host: ExplorationHost
var scroll: NearPathScroll
var world_root: Node
var _retry_timer := RETRY_SECONDS
# 最近一条外出提示要填的物品名，Main 显示提示时一起用
var last_params := {}


func attach(store: Object, root: Node) -> String:
	world_root = root
	host = ExplorationHost.new(store)
	host.cleanup_resubmitted.connect(func(failed_ops: Array, op_id: String) -> void: cleanup_resubmitted.emit(failed_ops, op_id))
	var outcome := host.restore()
	host.settled.connect(_on_settled)
	if host.session.is_quarantined():
		return "notice.exploration.unavailable"
	return _notice_for(outcome)


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
				var kept := _notice_for(outcome)
				notice.emit(kept)
				# 上一趟的东西刚收好：先留在院里让玩家看到，再点一次出门
				if kept.begins_with("notice.exploration.kept."):
					return false
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
			notice.emit(_notice_for(outcome))


## 提交受理后才有结论：确认了就说收好了；重试又没写上就不再打扰（院内会再试）
func _on_settled(outcome: Dictionary) -> void:
	if outcome.get("state", "") == "deferred" and outcome.get("retry", false):
		return
	notice.emit(_notice_for(outcome))


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
	returned.emit(_notice_for(result.get("outcome", {})))


func _notice_for(outcome: Dictionary) -> String:
	last_params = notice_params(outcome)
	return outcome_notice(outcome)


## 提示里要填的物品名（多件时用）；Main 显示提示时一并传给 I18n
static func notice_params(outcome: Dictionary) -> Dictionary:
	return {"items": items_text(outcome.get("items", PackedStringArray()))}


## 同名合并计数：圆石×2、松果
static func items_text(find_ids: PackedStringArray) -> String:
	var counts := {}
	var order: Array[String] = []
	for find_id: String in find_ids:
		if not counts.has(find_id):
			order.append(find_id)
		counts[find_id] = int(counts.get(find_id, 0)) + 1
	var parts: PackedStringArray = []
	for find_id: String in order:
		var name := I18n.t(ExplorationRoutes.find_name_key(find_id))
		parts.append(name if counts[find_id] == 1 else I18n.t("exploration.find.count", {"item": name, "count": counts[find_id]}))
	return I18n.t("exploration.find.separator").join(parts)


## “已回院”与“收好了”分开：只有提交成功才说收进篮子
static func outcome_notice(outcome: Dictionary) -> String:
	if outcome.is_empty():
		return ""
	var granted: PackedStringArray = outcome.get("items", PackedStringArray())
	if outcome.get("state", "") == "committed":
		if granted.is_empty():
			return "notice.exploration.restored_empty" if outcome.get("restored", false) else "notice.exploration.back_empty"
		if granted.size() == 1:
			return "notice.exploration.kept.%s" % granted[0].get_slice(".", 2)
		return "notice.exploration.kept_many"
	if outcome.get("state", "") == "deferred":
		return "notice.exploration.deferred_items" if not granted.is_empty() else "notice.exploration.deferred_empty"
	return ""
