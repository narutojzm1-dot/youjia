class_name ExplorationHost
extends RefCounted
# 探索核心与现有 SaveStore 之间的宿主桥（契约 §7、§8）。
# 写入是同步的文件提交：一次 commit 就是一次串行事务，返回 true 才发布授予与序号。
# 这不是 #150 的 Web durable ack；文案只在提交成功后才说“收好了”。

const C := preload("res://scripts/exploration/exploration_contract.gd")

signal changed

var store: Object
var catalog: ExplorationCatalog
var session: ExplorationSession
var restore_action := ""
# 上一次提交事务的结果，供小院文案使用；只在 commit_succeeded 之后才有 granted。
var last_outcome: Dictionary = {}


func _init(save_store: Object, route_catalog: ExplorationCatalog = null) -> void:
	store = save_store
	catalog = route_catalog if route_catalog != null else ExplorationRoutes.catalog()
	session = ExplorationSession.new(catalog, 0)


## 启动时在院内调用：按契约 §8 收尾上次中断的旅程。外出途中重启 → 安全回院并照常收下已带的东西。
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
			_submit()
		C.HOST_SUBMIT_PROPOSAL:
			_persist_if(result.persist)
			_submit()
		C.HOST_RETRY_COMMIT:
			_apply(session.retry_commit())
			_submit()
		C.HOST_SETTLE_EMPTY:
			_apply(session.settle_empty())
			_submit()
		C.HOST_QUARANTINE_AND_RESET:
			_persist_idle()
		_:
			_persist_if(result.persist)
	if not last_outcome.is_empty():
		last_outcome["restored"] = true
	changed.emit()
	return last_outcome


func can_begin() -> bool:
	return session.can_begin()


func is_unavailable() -> bool:
	return session.is_quarantined() or not session.can_begin() and session.get_state() == C.STATE_IDLE


func state() -> String:
	return session.get_state()


func view() -> Dictionary:
	return session.get_view()


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


## 回院导航不等待持久化：冻结提案后立即可以切回小院，提交随后同步进行。
## 已在待提交时再次回院只做幂等导航，不再调用核心、不多交一笔。
func request_return(reason: String = "player") -> Dictionary:
	if session.get_state() == C.STATE_ACTIVE:
		var result := session.request_return(reason)
		_apply(result)
		if not result.ok:
			return {"navigate": false, "error": result.error}
		_submit()
	return {"navigate": true, "outcome": last_outcome.duplicate(true)}


## 院内空闲时调用：上次提交失败（已标记延后）就再试一次，不需要玩家操作。
func retry_deferred() -> Dictionary:
	if session.get_state() == C.STATE_FAILURE:
		var failure: Dictionary = session.get_view().get("failure", {})
		if failure.get("retryable", false):
			_apply(session.retry_commit())
			_submit()
			changed.emit()
			return last_outcome.duplicate(true)
	return {}


func pending_items() -> PackedStringArray:
	var items := PackedStringArray()
	var proposal := session.get_proposal()
	for item: Dictionary in proposal.get("items", []):
		items.append(item.find_id)
	return items


## 契约 §7 第 0–4 步。同步提交下整段天然串行；失败时宿主内存保持写入前原样。
func _submit() -> void:
	for _attempt in C.MAX_CARRY + 2:
		if session.get_state() != C.STATE_PENDING:
			return
		var proposal := session.get_proposal()
		var trip_id: String = proposal.trip_id
		var serial := int(trip_id.trim_prefix("trip-"))
		var items := pending_items()
		if serial <= store.get_exploration_committed_serial():
			_finish(trip_id, PackedStringArray())
			return
		var rejected := PackedStringArray()
		for find_id: String in items:
			if not ExplorationRoutes.is_formal_find(find_id):
				rejected.append(find_id)
		if not rejected.is_empty():
			_apply(session.commit_failed(trip_id, false, rejected))
			continue
		if store.commit_exploration_trip(session.to_record(), serial, items):
			session.host_persisted(trip_id, session.record_revision())
			_finish(trip_id, items)
			return
		session.commit_failed(trip_id, true)
		session.defer_to_yard()
		last_outcome = {"state": "deferred", "items": items}
		store.save_exploration_record(session.to_record())
		return


func _finish(trip_id: String, granted: PackedStringArray) -> void:
	session.commit_succeeded(trip_id)
	session.close()
	_persist_idle()
	last_outcome = {"state": "committed", "items": granted}


func _apply(result: Dictionary) -> void:
	if result.get("persist", false):
		_persist()


func _persist_if(needed: bool) -> void:
	if needed:
		_persist()


func _persist() -> void:
	var revision := session.record_revision()
	var trip_id := session.trip_id()
	if store.save_exploration_record(session.to_record()):
		session.host_persisted(trip_id, revision)
	else:
		session.host_persist_failed(trip_id, revision)


func _persist_idle() -> void:
	store.save_exploration_record(session.to_record())
