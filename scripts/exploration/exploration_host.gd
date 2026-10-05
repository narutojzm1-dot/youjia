class_name ExplorationHost
extends RefCounted
# 探索核心与 SaveStore 异步存档队列之间的宿主桥（契约 §7、§8）。
# 每次落盘只拿到受理编号：commit_confirmed 之后才发布授予与序号，被拒按延后处理，结果未知时原地等待。
# 这不是 #150 的 Web durable 验收；文案只在确认之后才说“收好了”。

const C := preload("res://scripts/exploration/exploration_contract.gd")

signal changed
## 回院、恢复或重试的那笔提交在受理之后才有结论时发出（committed / deferred）
signal settled(outcome: Dictionary)

var store: Object
var catalog: ExplorationCatalog
var session: ExplorationSession
var restore_action := ""
# 上一次提交事务的结果，供小院文案使用；只在确认之后才有 granted。提交还在路上时为空。
var last_outcome: Dictionary = {}
# 受理编号 → 这笔写入要回报给核心的内容；同一个存档可能挂着多个宿主，只认自己的编号
var _ops: Dictionary = {}


func _init(save_store: Object, route_catalog: ExplorationCatalog = null) -> void:
	store = save_store
	catalog = route_catalog if route_catalog != null else ExplorationRoutes.catalog()
	session = ExplorationSession.new(catalog, 0)
	store.commit_confirmed.connect(_on_confirmed)
	store.commit_rejected.connect(_on_rejected)


## 启动时在院内调用：按契约 §8 收尾上次中断的旅程。外出途中重启 → 安全回院并照常收下已带的东西。
## 提交要等确认的，这里返回空，结论随 settled 发出。
func restore() -> Dictionary:
	var result := ExplorationSession.restore(store.get_exploration_record(), catalog, store.get_exploration_committed_serial())
	session = result.session
	restore_action = result.host_action
	last_outcome = {}
	match restore_action:
		C.HOST_CLOSE:
			session.close()
			_persist_idle()
		C.HOST_REQUEST_RETURN_RESTORED:
			_persist_if(result.persist)
			_apply(session.request_return("restored"))
			_submit({"restored": true})
		C.HOST_SUBMIT_PROPOSAL:
			_persist_if(result.persist)
			_submit({"restored": true})
		C.HOST_RETRY_COMMIT:
			_apply(session.retry_commit())
			_submit({"restored": true})
		C.HOST_SETTLE_EMPTY:
			_apply(session.settle_empty())
			_submit({"restored": true})
		C.HOST_QUARANTINE_AND_RESET:
			_persist_idle()
		_:
			_persist_if(result.persist)
	changed.emit()
	return last_outcome.duplicate(true)


func can_begin() -> bool:
	return session.can_begin()


func is_unavailable() -> bool:
	return session.is_quarantined() or not session.can_begin() and session.get_state() == C.STATE_IDLE


func state() -> String:
	return session.get_state()


func view() -> Dictionary:
	return session.get_view()


## 这一趟的提交已受理、还没有结论
func is_settling() -> bool:
	for op: Dictionary in _ops.values():
		if op.kind == "trip":
			return true
	return false


func begin(clock: Dictionary, seed: Variant = null) -> Dictionary:
	var result := session.begin(ExplorationRoutes.NEAR_PATH, clock, seed)
	_apply(result)
	return result


func visit(stop_id: String) -> Dictionary:
	if session.get_state() == C.STATE_ACTIVE and session.get_view().get("current_stop", "") == stop_id:
		return {"ok": true, "state": session.get_state(), "persist": false}
	var result := session.visit(stop_id)
	_apply(result)
	return result


func take(find_id: String) -> Dictionary:
	var result := session.take(find_id)
	_apply(result)
	return result


func release(find_id: String) -> Dictionary:
	var result := session.release(find_id)
	_apply(result)
	return result


## 篮子满时“换成这个”：放下与带上合成一次落盘，中途断电不会恢复成空篮
func swap(old_id: String, new_id: String) -> Dictionary:
	var view := session.get_view()
	if session.get_state() != C.STATE_ACTIVE or not (view.get("carried", []) as Array).has(old_id) \
			or str(view.get("offer", "")) != new_id or new_id.is_empty():
		return {"ok": false, "error": "not_offered"}
	var released := session.release(old_id)
	if not released.ok:
		return released
	var taken := session.take(new_id)
	# 前置校验已保证 take 成功；万一失败也不把空篮写盘
	if taken.ok:
		_persist()
	return taken


## 回院导航不等待持久化：冻结提案、把提交排进队列后立即可以切回小院。
## 已在待提交时再次回院只做幂等导航，不再调用核心、不多交一笔。
func request_return(reason: String = "player") -> Dictionary:
	if session.get_state() == C.STATE_ACTIVE:
		var result := session.request_return(reason)
		_apply(result)
		if not result.ok:
			return {"navigate": false, "error": result.error}
		last_outcome = {}
		_submit({})
	return {"navigate": true, "outcome": last_outcome.duplicate(true)}


## 院内空闲时调用：上次提交失败（已标记延后）就再排一次，不需要玩家操作。结论随 settled 发出。
func retry_deferred() -> Dictionary:
	if session.get_state() == C.STATE_FAILURE and not is_settling():
		var failure: Dictionary = session.get_view().get("failure", {})
		if failure.get("retryable", false):
			last_outcome = {}
			_apply(session.retry_commit())
			_submit({"retry": true})
			changed.emit()
			return last_outcome.duplicate(true)
	return {}


func pending_items() -> PackedStringArray:
	var items := PackedStringArray()
	var proposal := session.get_proposal()
	for item: Dictionary in proposal.get("items", []):
		items.append(item.find_id)
	return items


## 契约 §7 第 0–4 步。存档队列先进先出，这一趟同一时间只排一笔；确认前宿主内存不变。
func _submit(tags: Dictionary) -> void:
	if is_settling():
		return
	for _attempt in C.MAX_CARRY + 2:
		if session.get_state() != C.STATE_PENDING:
			return
		var proposal := session.get_proposal()
		var trip_id: String = proposal.trip_id
		var serial := int(trip_id.trim_prefix("trip-"))
		var items := pending_items()
		if serial <= store.get_exploration_committed_serial():
			_finish(trip_id, PackedStringArray(), tags)
			return
		var rejected := PackedStringArray()
		for find_id: String in items:
			if not ExplorationRoutes.is_formal_find(find_id):
				rejected.append(find_id)
		if not rejected.is_empty():
			_apply(session.commit_failed(trip_id, false, rejected))
			continue
		var receipt := {}
		var op_id: String = store.request_exploration_trip(session.to_record(), serial, items, receipt)
		if op_id.is_empty():
			_defer(trip_id, items, tags)
			return
		_ops[op_id] = {"kind": "trip", "trip_id": trip_id, "revision": session.record_revision(), "items": items, "receipt": receipt, "tags": tags}
		return


func _on_confirmed(op_id: String, _kind: String) -> void:
	if not _ops.has(op_id):
		return
	var op: Dictionary = _ops[op_id]
	_ops.erase(op_id)
	if op.kind == "record":
		session.host_persisted(op.trip_id, op.revision)
	elif op.kind == "trip" and session.get_state() == C.STATE_PENDING and session.trip_id() == op.trip_id:
		session.host_persisted(op.trip_id, op.revision)
		_finish(op.trip_id, op.items if op.receipt.get("granted", false) else PackedStringArray(), op.tags)
		settled.emit(last_outcome.duplicate(true))
	changed.emit()


func _on_rejected(op_id: String, _kind: String, code: String) -> void:
	if not _ops.has(op_id):
		return
	var op: Dictionary = _ops[op_id]
	_ops.erase(op_id)
	if op.kind == "record":
		session.host_persist_failed(op.trip_id, op.revision, code)
	elif op.kind == "trip" and session.get_state() == C.STATE_PENDING and session.trip_id() == op.trip_id:
		_defer(op.trip_id, op.items, op.tags)
		settled.emit(last_outcome.duplicate(true))
	changed.emit()


func _finish(trip_id: String, granted: PackedStringArray, tags: Dictionary) -> void:
	session.commit_succeeded(trip_id)
	session.close()
	_persist_idle()
	last_outcome = {"state": "committed", "items": granted}
	last_outcome.merge(tags)


func _defer(trip_id: String, items: PackedStringArray, tags: Dictionary) -> void:
	session.commit_failed(trip_id, true)
	session.defer_to_yard()
	last_outcome = {"state": "deferred", "items": items}
	last_outcome.merge(tags)
	_persist()


func _apply(result: Dictionary) -> void:
	if result.get("persist", false):
		_persist()


func _persist_if(needed: bool) -> void:
	if needed:
		_persist()


func _persist() -> void:
	var revision := session.record_revision()
	var trip_id := session.trip_id()
	var op_id: String = store.request_exploration_record(session.to_record())
	if op_id.is_empty():
		session.host_persist_failed(trip_id, revision)
	else:
		_ops[op_id] = {"kind": "record", "trip_id": trip_id, "revision": revision}


func _persist_idle() -> void:
	store.request_exploration_record(session.to_record())
