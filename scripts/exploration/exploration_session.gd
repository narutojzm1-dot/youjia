class_name ExplorationSession
extends RefCounted
# 形态无关的旅程状态机：接受事件、返回结果、产出只读视图与结果提案。
# 不创建/删除 Node，不加载资源，不写文件，不发全局信号，不读现实时钟。
# 非法事件返回 {ok: false, error}，会话不做任何修改。

const C := preload("res://scripts/exploration/exploration_contract.gd")

var _catalog: ExplorationCatalog
var _watermark: int = C.WATERMARK_UNTRUSTED
var _next_trip_serial: int = 1
var _state: String = C.STATE_IDLE

## 旅程字段（idle 时清空）
var _trip_serial: int = 0
var _trip_id: String = ""
var _record_revision: int = 0
var _persisted_revision: int = 0
var _route_id: String = ""
var _session_source: String = ""
var _started_clock: Dictionary = {}
var _current_stop: String = ""
var _visited: Array = []
var _offers: Dictionary = {}
var _carried: Array = []
# 每处停留点的东西被带走后记在这里（停留点 → find_id）；同名东西可以分别来自不同停留点
var _taken: Dictionary = {}
var _rng_seed: String = ""
var _companion: Variant = null # null preserves records created before this feature
var _proposal: Variant = null
var _failure: Variant = null
var _last_save_failure: String = ""

## 隔离模式：to_record() 原样返回读到的原始记录，变更方法一律拒绝
var _quarantined := false
var _quarantine_raw: Variant = null
var _quarantine_reason: String = ""
## 夹具作废是 restore 自己的改写，需要宿主保存新的空闲记录
var _reset_pending_save := false


func _init(catalog: ExplorationCatalog = null, last_committed_trip_serial: int = 0) -> void:
	_catalog = catalog if catalog != null else ExplorationCatalog.new()
	_watermark = _sanitize_watermark(last_committed_trip_serial)
	if _watermark != C.WATERMARK_UNTRUSTED:
		_next_trip_serial = _watermark + 1


## ───────────── 恢复（契约 §8，自上而下匹配） ─────────────

static func restore(record: Variant, catalog: ExplorationCatalog, last_committed_trip_serial: int) -> Dictionary:
	var session := ExplorationSession.new(catalog, last_committed_trip_serial)
	var action := session._restore_from(record)
	var result := {
		"session": session,
		"host_action": action,
		"can_begin": session.can_begin(),
		"persist": session._record_revision > session._persisted_revision or session._reset_pending_save,
	}
	if action in [C.HOST_QUARANTINE, C.HOST_QUARANTINE_AND_FREEZE, C.HOST_QUARANTINE_AND_RESET]:
		result["quarantine_record"] = _copy(record)
		result["quarantine_reason"] = session._quarantine_reason
	return result


func _restore_from(record: Variant) -> String:
	var present := record != null
	var is_dict := typeof(record) == TYPE_DICTIONARY
	var session_value: Variant = record.get("session") if is_dict else null
	## 宿主序号不可信：无法确认没有会话的记录隔离并冻结，其余只冻结新旅程
	if _watermark == C.WATERMARK_UNTRUSTED:
		if present and (not is_dict or session_value != null or _is_future_version(record)):
			return _enter_quarantine(record, "watermark_untrusted")
		_restore_meta(record if is_dict else {})
		return C.HOST_FREEZE_NEW_TRIPS
	if not present:
		return C.HOST_NONE
	if not is_dict:
		return _enter_quarantine(record, "not_dictionary")
	if _is_future_version(record):
		_quarantined = true
		_quarantine_raw = _copy(record)
		_quarantine_reason = "future_version"
		return C.HOST_QUARANTINE
	if session_value == null:
		_restore_meta(record)
		return C.HOST_NONE
	if typeof(session_value) != TYPE_DICTIONARY:
		return _enter_quarantine(record, "session_not_dictionary")
	var structure := C.validate_session_structure(session_value)
	if structure == "" and C.record_size_bytes(record) > C.RECORD_BUDGET_BYTES:
		structure = "over_budget"
	if structure != "":
		return _enter_quarantine(record, structure)
	## 纯夹具会话：结构校验已保证所有 ID 前缀一致，夹具物品永远不会授予，可作废
	if session_value["catalog"] == C.SOURCE_FIXTURE and _catalog.source != C.SOURCE_FIXTURE:
		_quarantine_reason = "fixture_in_player_save"
		_restore_meta(record)
		_next_trip_serial = maxi(_next_trip_serial, int(session_value["trip_serial"]) + 1)
		_reset_pending_save = true
		return C.HOST_QUARANTINE_AND_RESET
	_restore_meta(record)
	_load_session(session_value)
	if _trip_serial <= _watermark:
		_state = C.STATE_COMMITTED
		return C.HOST_CLOSE
	if _state == C.STATE_COMMITTED:
		_clear_session()
		return _enter_quarantine(record, "committed_ahead_of_watermark")
	if _state == C.STATE_ACTIVE:
		return _restore_active()
	if _state == C.STATE_PENDING:
		return C.HOST_SUBMIT_PROPOSAL
	return C.HOST_RETRY_COMMIT if _failure["retryable"] else C.HOST_SETTLE_EMPTY


func _restore_active() -> String:
	if not _catalog.has_route(_route_id):
		_freeze_proposal("restored")
		_bump()
		return C.HOST_SUBMIT_PROPOSAL
	var changed := false
	var kept_visited: Array = []
	for stop_id: String in _visited:
		if _catalog.has_stop(_route_id, stop_id):
			kept_visited.append(stop_id)
		else:
			changed = true
	_visited = kept_visited
	# 篮子里东西的来处即使停留点已下架也留着，taken 与 carried 才对得上
	for stop_id: String in _offers.keys():
		if not _catalog.has_stop(_route_id, stop_id) and not _taken.has(stop_id):
			_offers.erase(stop_id)
			changed = true
	if not _catalog.has_stop(_route_id, _current_stop):
		_current_stop = _catalog.get_route(_route_id)["start_stop"]
		changed = true
	if changed:
		_bump()
	return C.HOST_REQUEST_RETURN_RESTORED


func _restore_meta(record: Dictionary) -> void:
	if _watermark == C.WATERMARK_UNTRUSTED:
		return
	var hint: Variant = C.as_int(record.get("next_trip_serial"), 1)
	if hint != null and hint <= _watermark + C.NEXT_SERIAL_SLACK:
		_next_trip_serial = maxi(hint, _watermark + 1)


func _load_session(session: Dictionary) -> void:
	_trip_serial = int(session["trip_serial"])
	_trip_id = session["trip_id"]
	_record_revision = int(session["record_revision"])
	_persisted_revision = _record_revision
	_route_id = session["route_id"]
	_session_source = session["catalog"]
	_started_clock = {"day": int(session["started_clock"]["day"]), "elapsed": float(session["started_clock"]["elapsed"])}
	_current_stop = session["current_stop"]
	_visited = session["visited"].duplicate()
	_offers = session["offers"].duplicate()
	_carried = session["carried"].duplicate()
	_taken = session["taken"].duplicate() if session.has("taken") else _derive_taken(_carried, _offers)
	_rng_seed = session["rng_seed"]
	_companion = session.get("companion", {}).duplicate(true) if session.has("companion") else null
	_proposal = _normalize_proposal(session["proposal"]) if session["proposal"] != null else null
	_failure = _normalize_failure(session["failure"]) if session["failure"] != null else null
	_state = session["state"]
	_next_trip_serial = maxi(_next_trip_serial, _trip_serial + 1)


func _enter_quarantine(record: Variant, reason: String) -> String:
	_quarantined = true
	_quarantine_raw = _copy(record)
	_quarantine_reason = reason
	return C.HOST_QUARANTINE_AND_FREEZE


static func _is_future_version(record: Dictionary) -> bool:
	var version: Variant = record.get("contract_version")
	return C.is_number(version) and float(version) > float(C.CONTRACT_VERSION)


## ───────────── 出门阶段事件 ─────────────

func begin(route_id: String, clock: Dictionary, seed: Variant = null, companion_context: Dictionary = {}) -> Dictionary:
	## 拒绝码优先级：watermark_untrusted > quarantine_frozen > exploration_unavailable > pending_exists
	if _watermark == C.WATERMARK_UNTRUSTED:
		return _reject("watermark_untrusted")
	if _quarantined:
		return _reject("exploration_unavailable" if _quarantine_reason == "future_version" else "quarantine_frozen")
	if _state == C.STATE_PENDING or _state == C.STATE_FAILURE:
		return _reject("pending_exists")
	if _state != C.STATE_IDLE:
		return _reject("illegal_transition")
	if not _catalog.has_route(route_id):
		return _reject("unknown_route")
	if not AnimalCompanions.valid_context(companion_context):
		return _reject("bad_companion_context")
	if C.as_int(clock.get("day"), 0) == null or not C.is_number(clock.get("elapsed")):
		return _reject("bad_clock")
	var seed_value: int
	if seed == null:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		seed_value = (int(rng.randi()) << 32) | int(rng.randi())
	elif typeof(seed) == TYPE_INT:
		seed_value = seed
	elif C.is_valid_seed_text(seed):
		seed_value = str(seed).to_int()
	else:
		return _reject("bad_seed")
	var route := _catalog.get_route(route_id)
	_trip_serial = maxi(_next_trip_serial, _watermark + 1)
	if _trip_serial > C.MAX_INT:
		return _reject("serial_exhausted")
	_trip_id = "trip-%d" % _trip_serial
	_next_trip_serial = _trip_serial + 1
	_route_id = route_id
	_session_source = _catalog.source
	_started_clock = {"day": int(clock["day"]), "elapsed": float(clock["elapsed"])}
	_rng_seed = str(seed_value)
	_companion = AnimalCompanions.choose(companion_context, _rng_seed) if not companion_context.is_empty() else null
	_current_stop = route["start_stop"]
	_visited = [_current_stop]
	_offers = {}
	_roll_offer(_current_stop)
	_carried = []
	_taken = {}
	_proposal = null
	_failure = null
	_last_save_failure = ""
	_record_revision = 0
	_persisted_revision = 0
	_state = C.STATE_ACTIVE
	_bump()
	return _ok(true)


func visit(stop_id: String) -> Dictionary:
	if _quarantined:
		return _reject("quarantine_frozen")
	if _state != C.STATE_ACTIVE:
		return _reject("illegal_transition")
	var route := _catalog.get_route(_route_id)
	if route.is_empty():
		return _reject("unknown_route")
	var next: Array = route["stops"][_current_stop].get("next", [])
	if not next.has(stop_id):
		return _reject("unreachable_stop")
	_current_stop = stop_id
	if not _visited.has(stop_id):
		_visited.append(stop_id)
		_roll_offer(stop_id)
	_bump()
	return _ok(true)


func take(find_id: String) -> Dictionary:
	if _quarantined:
		return _reject("quarantine_frozen")
	if _state != C.STATE_ACTIVE:
		return _reject("illegal_transition")
	if _offers.get(_current_stop, "") != find_id or find_id == "" or _taken.has(_current_stop):
		return _reject("not_offered")
	if _carried.size() >= _catalog.carry_limit(_route_id):
		return _reject("carry_limit")
	_carried.append(find_id)
	_taken[_current_stop] = find_id
	_bump()
	return _ok(true)


func release(find_id: String) -> Dictionary:
	if _quarantined:
		return _reject("quarantine_frozen")
	if _state != C.STATE_ACTIVE:
		return _reject("illegal_transition")
	if not _carried.has(find_id):
		return _reject("not_carried")
	_carried.erase(find_id)
	# 优先放回眼前这一处；在别处放下时，原停留点的东西重新出现
	if _taken.get(_current_stop, "") == find_id:
		_taken.erase(_current_stop)
	else:
		for stop_id: String in _taken.keys():
			if _taken[stop_id] == find_id:
				_taken.erase(stop_id)
				break
	_bump()
	return _ok(true)


func request_return(reason: String) -> Dictionary:
	if _quarantined:
		return _reject("quarantine_frozen")
	if _state != C.STATE_ACTIVE:
		return _reject("illegal_transition")
	if not C.RETURN_REASONS.has(reason):
		return _reject("invalid_reason")
	if (reason == "player" or reason == "cancel") and not _can_return_here():
		return _reject("not_return_stop")
	_freeze_proposal(reason)
	_bump()
	return _ok(true)


## ───────────── 提交阶段事件 ─────────────

func commit_succeeded(trip_id: String) -> Dictionary:
	if _quarantined:
		return _reject("quarantine_frozen")
	if _state != C.STATE_PENDING:
		return _reject("illegal_transition")
	if trip_id != _trip_id:
		return _reject("trip_mismatch")
	_state = C.STATE_COMMITTED
	_failure = null
	_bump()
	return _ok(true)


func commit_failed(trip_id: String, retryable: bool, rejected: PackedStringArray = PackedStringArray()) -> Dictionary:
	if _quarantined:
		return _reject("quarantine_frozen")
	if _state != C.STATE_PENDING:
		return _reject("illegal_transition")
	if trip_id != _trip_id:
		return _reject("trip_mismatch")
	var attempts: int = (_failure["attempts"] if _failure != null else 0) + 1
	if retryable:
		_failure = {"code": "save_failed", "retryable": true, "attempts": attempts, "deferred": false}
		_state = C.STATE_FAILURE
		_bump()
		return _ok(true)
	if rejected.is_empty():
		_failure = {"code": "content_rejected", "retryable": false, "attempts": attempts, "deferred": false}
		_state = C.STATE_FAILURE
		_bump()
		return _ok(true)
	var kept: Array = []
	var removed := false
	for item: Dictionary in _proposal["items"]:
		if rejected.has(item["find_id"]):
			removed = true
		else:
			kept.append(item)
	if not removed:
		return _reject("invalid_rejection")
	_proposal["items"] = kept
	_proposal["revision"] = int(_proposal["revision"]) + 1
	for find_id: String in rejected:
		while _carried.has(find_id):
			_carried.erase(find_id)
		for stop_id: String in _taken.keys():
			if _taken[stop_id] == find_id:
				_taken.erase(stop_id)
	_bump()
	return _ok(true)


func retry_commit() -> Dictionary:
	if _quarantined:
		return _reject("quarantine_frozen")
	if _state != C.STATE_FAILURE or not _failure["retryable"]:
		return _reject("illegal_transition")
	_failure["deferred"] = false
	_state = C.STATE_PENDING
	_bump()
	return _ok(true)


func settle_empty() -> Dictionary:
	if _quarantined:
		return _reject("quarantine_frozen")
	if _state != C.STATE_FAILURE or _failure["retryable"]:
		return _reject("illegal_transition")
	_proposal["items"] = []
	_proposal["revision"] = int(_proposal["revision"]) + 1
	_carried = []
	_taken = {}
	_failure = null
	_state = C.STATE_PENDING
	_bump()
	return _ok(true)


func defer_to_yard() -> Dictionary:
	if _quarantined:
		return _reject("quarantine_frozen")
	if _state != C.STATE_FAILURE:
		return _reject("illegal_transition")
	if _failure["deferred"]:
		return _ok(false)
	_failure["deferred"] = true
	_bump()
	return _ok(true)


func close() -> Dictionary:
	if _quarantined:
		return _reject("quarantine_frozen")
	if _state != C.STATE_COMMITTED:
		return _reject("illegal_transition")
	_clear_session()
	return _ok(false)


## ───────────── 宿主保存确认（契约 §7.2） ─────────────

func host_persisted(trip_id: String, record_revision: int) -> Dictionary:
	var check := _check_ack(trip_id, record_revision)
	if not check.is_empty():
		return check
	if record_revision > _persisted_revision:
		_persisted_revision = record_revision
		if _record_revision == _persisted_revision:
			_last_save_failure = ""
	return {"ok": true, "unsaved_changes": has_unsaved_changes()}


func host_persist_failed(trip_id: String, record_revision: int, code: String = "save_failed") -> Dictionary:
	var check := _check_ack(trip_id, record_revision)
	if not check.is_empty():
		return check
	if record_revision > _persisted_revision:
		_last_save_failure = code
	return {"ok": true, "unsaved_changes": has_unsaved_changes()}


func _check_ack(trip_id: String, record_revision: int) -> Dictionary:
	if _quarantined:
		return {"ok": false, "error": "quarantine_frozen", "unsaved_changes": false}
	if _state == C.STATE_IDLE or trip_id != _trip_id:
		return {"ok": false, "error": "stale_ack", "unsaved_changes": has_unsaved_changes()}
	if record_revision > _record_revision:
		return {"ok": false, "error": "future_ack", "unsaved_changes": has_unsaved_changes()}
	return {}


## ───────────── 只读查询 ─────────────

func get_state() -> String:
	return _state


func is_quarantined() -> bool:
	return _quarantined


func can_begin() -> bool:
	return not _quarantined and _watermark != C.WATERMARK_UNTRUSTED and _state == C.STATE_IDLE


func has_unsaved_changes() -> bool:
	return _state != C.STATE_IDLE and _record_revision > _persisted_revision


func record_revision() -> int:
	return _record_revision


func trip_id() -> String:
	return _trip_id


func get_proposal() -> Dictionary:
	return _copy(_proposal) if _proposal != null and not _quarantined else {}


func get_view() -> Dictionary:
	var view := {
		"state": _state,
		"quarantined": _quarantined,
		"can_begin": can_begin(),
		"unsaved_changes": has_unsaved_changes(),
		"last_save_failure": _last_save_failure,
	}
	if _state == C.STATE_IDLE or _quarantined:
		return view
	view["trip_id"] = _trip_id
	view["route_id"] = _route_id
	view["current_stop"] = _current_stop
	view["carried"] = _carried.duplicate()
	view["companion"] = _companion.duplicate(true) if _companion != null else {}
	if _state == C.STATE_ACTIVE:
		var route := _catalog.get_route(_route_id)
		view["reachable"] = route["stops"][_current_stop].get("next", []).duplicate() if not route.is_empty() else []
		var offer: String = _offers.get(_current_stop, "")
		view["offer"] = offer if offer != "" and not _taken.has(_current_stop) else ""
		view["can_return"] = _can_return_here()
		view["carry_limit"] = _catalog.carry_limit(_route_id) if not route.is_empty() else 0
		view["taken"] = _taken.duplicate()
	else:
		view["proposal_items"] = (_proposal["items"] as Array).size()
		view["failure"] = _copy(_failure) if _failure != null else {}
	return view


func scene_identity() -> Dictionary:
	if _state == C.STATE_IDLE or _quarantined:
		return {}
	return {"trip_id": _trip_id, "route_id": _route_id, "stop_id": _current_stop, "clock": _started_clock.duplicate()}


## 纯值，可直接 JSON；隔离模式下原样返回读到的原始记录
func to_record() -> Variant:
	if _quarantined:
		return _copy(_quarantine_raw)
	var record := {"contract_version": C.CONTRACT_VERSION, "next_trip_serial": _next_trip_serial, "session": null}
	if _state == C.STATE_IDLE:
		return record
	record["session"] = {
		"trip_id": _trip_id,
		"trip_serial": _trip_serial,
		"record_revision": _record_revision,
		"route_id": _route_id,
		"catalog": _session_source,
		"state": _state,
		"started_clock": _started_clock.duplicate(),
		"current_stop": _current_stop,
		"visited": _visited.duplicate(),
		"offers": _offers.duplicate(),
		"carried": _carried.duplicate(),
		"taken": _taken.duplicate(),
		"rng_seed": _rng_seed,
		"proposal": _copy(_proposal),
		"failure": _copy(_failure),
	}
	if _companion != null: record.session.companion = _companion.duplicate(true)
	return record


## ───────────── 内部 ─────────────

func _roll_offer(stop_id: String) -> void:
	var stop: Dictionary = _catalog.get_route(_route_id)["stops"][stop_id]
	var pool: Array = stop.get("find_pool", [])
	var empty_weight: int = int(stop.get("empty_weight", 0))
	var total := empty_weight
	for entry: Dictionary in pool:
		total += int(entry["weight"])
	if total <= 0:
		_offers[stop_id] = ""
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = C.derive_stop_seed(_rng_seed, stop_id)
	var roll := rng.randi_range(0, total - 1)
	for entry: Dictionary in pool:
		roll -= int(entry["weight"])
		if roll < 0:
			_offers[stop_id] = entry["find_id"]
			return
	_offers[stop_id] = ""


func _can_return_here() -> bool:
	var route := _catalog.get_route(_route_id)
	if route.is_empty():
		return true
	var returns: Variant = route.get("return_stops", "any")
	return typeof(returns) == TYPE_STRING or (returns as Array).has(_current_stop)


func _freeze_proposal(reason: String) -> void:
	var items: Array = []
	for find_id: String in _carried:
		items.append({"find_id": find_id})
	_proposal = {"trip_id": _trip_id, "route_id": _route_id, "items": items, "reason": reason, "revision": 1}
	_state = C.STATE_PENDING


func _bump() -> void:
	_record_revision += 1


func _clear_session() -> void:
	_state = C.STATE_IDLE
	_trip_serial = 0
	_trip_id = ""
	_record_revision = 0
	_persisted_revision = 0
	_route_id = ""
	_session_source = ""
	_started_clock = {}
	_current_stop = ""
	_visited = []
	_offers = {}
	_carried = []
	_taken = {}
	_rng_seed = ""
	_companion = null
	_proposal = null
	_failure = null
	_last_save_failure = ""


func _ok(persist: bool) -> Dictionary:
	return {"ok": true, "state": _state, "persist": persist}


func _reject(code: String) -> Dictionary:
	return {"ok": false, "error": code, "state": _state, "persist": false}


static func _normalize_proposal(proposal: Dictionary) -> Dictionary:
	var items: Array = []
	for item: Dictionary in proposal["items"]:
		items.append({"find_id": item["find_id"]})
	return {
		"trip_id": proposal["trip_id"],
		"route_id": proposal["route_id"],
		"items": items,
		"reason": proposal["reason"],
		"revision": int(proposal["revision"]),
	}


## 旧记录没有 taken：每件带着的东西对应一处给出同名东西、还没被占用的停留点
static func _derive_taken(carried: Array, offers: Dictionary) -> Dictionary:
	var taken := {}
	for find_id: String in carried:
		for stop_id: String in offers:
			if offers[stop_id] == find_id and not taken.has(stop_id):
				taken[stop_id] = find_id
				break
	return taken


static func _normalize_failure(failure: Dictionary) -> Dictionary:
	return {
		"code": failure["code"],
		"retryable": failure["retryable"],
		"attempts": int(failure["attempts"]),
		"deferred": failure["deferred"],
	}


static func _sanitize_watermark(value: int) -> int:
	if value == C.WATERMARK_UNTRUSTED or value < 0 or value > C.MAX_INT:
		return C.WATERMARK_UNTRUSTED
	return value


static func _copy(value: Variant) -> Variant:
	if typeof(value) == TYPE_DICTIONARY or typeof(value) == TYPE_ARRAY:
		return value.duplicate(true)
	return value
