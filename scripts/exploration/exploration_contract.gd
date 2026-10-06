class_name ExplorationContract
extends RefCounted
# 探索模块契约：版本、状态名、ID 格式、预算与纯值校验。
# 不持有状态，不访问 SaveStore；见 docs/architecture/exploration-module-contract.md。

const CONTRACT_VERSION := 1

## 状态名（字符串，便于 JSON 与日志阅读）
const STATE_IDLE := "idle"
const STATE_ACTIVE := "active"
const STATE_PENDING := "pending_commit"
const STATE_FAILURE := "recoverable_failure"
const STATE_COMMITTED := "committed"
const PERSISTED_SESSION_STATES := [STATE_ACTIVE, STATE_PENDING, STATE_FAILURE, STATE_COMMITTED]

const RETURN_REASONS := ["player", "cancel", "host_interrupt", "restored"]

## 宿主动作（与契约 §8 表逐行对应）
const HOST_NONE := "none"
const HOST_CLOSE := "close"
const HOST_REQUEST_RETURN_RESTORED := "request_return_restored"
const HOST_SUBMIT_PROPOSAL := "submit_proposal"
const HOST_RETRY_COMMIT := "retry_commit"
const HOST_SETTLE_EMPTY := "settle_empty"
const HOST_QUARANTINE := "quarantine"
const HOST_QUARANTINE_AND_FREEZE := "quarantine_and_freeze"
const HOST_QUARANTINE_AND_RESET := "quarantine_and_reset_session"
const HOST_FREEZE_NEW_TRIPS := "freeze_new_trips"

const WATERMARK_UNTRUSTED := -1
const MAX_INT := 2147483647
const MAX_STOPS := 16
const MAX_CARRY := 3
const MAX_ID_LENGTH := 64
const RECORD_BUDGET_BYTES := 4096
const NEXT_SERIAL_SLACK := 1000000

const SOURCE_FORMAL := "formal"
const SOURCE_FIXTURE := "fixture"

static var _id_regex: RegEx
static var _stop_regex: RegEx
static var _int_regex: RegEx


static func _regexes() -> void:
	if _id_regex != null:
		return
	_id_regex = RegEx.create_from_string("^(formal|fixture)(\\.[a-z0-9_]+){1,4}$")
	_stop_regex = RegEx.create_from_string("^[a-z0-9_]{1,32}$")
	_int_regex = RegEx.create_from_string("^-?[0-9]{1,19}$")


## ID 与前缀

static func is_valid_id(value: Variant, source: String = "") -> bool:
	if typeof(value) != TYPE_STRING:
		return false
	var text: String = value
	_regexes()
	if text.length() > MAX_ID_LENGTH or _id_regex.search(text) == null:
		return false
	return source == "" or text.begins_with(source + ".")


static func is_valid_stop_id(value: Variant) -> bool:
	if typeof(value) != TYPE_STRING:
		return false
	_regexes()
	return _stop_regex.search(value) != null


static func id_source(id: String) -> String:
	return id.get_slice(".", 0)


## 整数：JSON 解析出的数字是 float，这里统一收成 int；不合格返回 null

static func as_int(value: Variant, min_value: int = 0, max_value: int = MAX_INT) -> Variant:
	var number: int
	if typeof(value) == TYPE_INT:
		number = value
	elif typeof(value) == TYPE_FLOAT:
		var real: float = value
		if is_nan(real) or is_inf(real) or real != floorf(real):
			return null
		if real < float(min_value) or real > float(max_value):
			return null
		number = int(real)
	else:
		return null
	if number < min_value or number > max_value:
		return null
	return number


static func is_number(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) == TYPE_FLOAT:
		return not is_nan(value) and not is_inf(value)
	return false


## 随机种子：有符号 64 位，以十进制字符串存储

static func is_valid_seed_text(value: Variant) -> bool:
	if typeof(value) != TYPE_STRING:
		return false
	_regexes()
	var text: String = value
	if _int_regex.search(text) == null:
		return false
	return str(text.to_int()) == text


## 每个停留点的专用种子只由 (rng_seed, stop_id) 决定，与访问顺序无关
static func derive_stop_seed(rng_seed: String, stop_id: String) -> int:
	return (rng_seed + ":" + stop_id).sha256_buffer().decode_s64(0)


static func record_size_bytes(record: Variant) -> int:
	return JSON.stringify(record).to_utf8_buffer().size()


## 路线目录校验：返回错误列表，空表示合法

static func validate_catalog(source: String, routes: Variant) -> PackedStringArray:
	var errors := PackedStringArray()
	if source != SOURCE_FORMAL and source != SOURCE_FIXTURE:
		errors.append("unknown_source")
		return errors
	if typeof(routes) != TYPE_DICTIONARY:
		errors.append("routes_not_dictionary")
		return errors
	for route_id: Variant in routes:
		var route: Variant = routes[route_id]
		var where := str(route_id)
		if not is_valid_id(route_id, source):
			errors.append("bad_route_id:" + where)
			continue
		if typeof(route) != TYPE_DICTIONARY:
			errors.append("route_not_dictionary:" + where)
			continue
		var stops: Variant = route.get("stops")
		if typeof(stops) != TYPE_DICTIONARY or stops.is_empty() or stops.size() > MAX_STOPS:
			errors.append("bad_stops:" + where)
			continue
		if not stops.has(route.get("start_stop", "")):
			errors.append("bad_start_stop:" + where)
		var limit: Variant = as_int(route.get("carry_limit", 1), 1, MAX_CARRY)
		if limit == null:
			errors.append("bad_carry_limit:" + where)
		var returns: Variant = route.get("return_stops", "any")
		if typeof(returns) == TYPE_STRING:
			if returns != "any":
				errors.append("bad_return_stops:" + where)
		elif typeof(returns) == TYPE_ARRAY:
			for stop_id: Variant in returns:
				if not stops.has(stop_id):
					errors.append("bad_return_stops:" + where)
		else:
			errors.append("bad_return_stops:" + where)
		for stop_id: Variant in stops:
			var stop: Variant = stops[stop_id]
			var stop_where := where + "/" + str(stop_id)
			if not is_valid_stop_id(stop_id) or typeof(stop) != TYPE_DICTIONARY:
				errors.append("bad_stop:" + stop_where)
				continue
			var next: Variant = stop.get("next", [])
			if typeof(next) != TYPE_ARRAY:
				errors.append("bad_next:" + stop_where)
			else:
				for target: Variant in next:
					if not stops.has(target):
						errors.append("bad_next:" + stop_where)
			var pool: Variant = stop.get("find_pool", [])
			if typeof(pool) != TYPE_ARRAY:
				errors.append("bad_find_pool:" + stop_where)
				continue
			for entry: Variant in pool:
				if typeof(entry) != TYPE_DICTIONARY or not is_valid_id(entry.get("find_id"), source) \
						or as_int(entry.get("weight"), 0) == null:
					errors.append("bad_find_entry:" + stop_where)
			if as_int(stop.get("empty_weight", 0), 0) == null:
				errors.append("bad_empty_weight:" + stop_where)
	return errors


## 会话记录的结构校验（不查目录成员；目录变更由恢复流程单独处理）
## 返回空字符串表示结构合法，否则返回损坏原因

static func validate_session_structure(session: Dictionary) -> String:
	var serial: Variant = as_int(session.get("trip_serial"), 1)
	if serial == null:
		return "bad_trip_serial"
	if session.get("trip_id") != "trip-%d" % serial:
		return "trip_id_mismatch"
	if as_int(session.get("record_revision"), 0) == null:
		return "bad_record_revision"
	var source: Variant = session.get("catalog")
	if source != SOURCE_FORMAL and source != SOURCE_FIXTURE:
		return "bad_catalog"
	if not is_valid_id(session.get("route_id"), source):
		return "bad_route_id"
	var state: Variant = session.get("state")
	if not PERSISTED_SESSION_STATES.has(state):
		return "bad_state"
	var clock: Variant = session.get("started_clock")
	if typeof(clock) != TYPE_DICTIONARY or as_int(clock.get("day"), 0) == null or not is_number(clock.get("elapsed")):
		return "bad_clock"
	if not is_valid_stop_id(session.get("current_stop")):
		return "bad_current_stop"
	var visited: Variant = session.get("visited")
	if typeof(visited) != TYPE_ARRAY or visited.size() > MAX_STOPS:
		return "bad_visited"
	for stop_id: Variant in visited:
		if not is_valid_stop_id(stop_id):
			return "bad_visited"
	var offers: Variant = session.get("offers")
	if typeof(offers) != TYPE_DICTIONARY or offers.size() > MAX_STOPS:
		return "bad_offers"
	for stop_id: Variant in offers:
		var offer: Variant = offers[stop_id]
		if not is_valid_stop_id(stop_id) or typeof(offer) != TYPE_STRING:
			return "bad_offers"
		if offer != "" and not is_valid_id(offer, source):
			return "bad_offers"
	var carried: Variant = session.get("carried")
	if typeof(carried) != TYPE_ARRAY or carried.size() > MAX_CARRY:
		return "bad_carried"
	for find_id: Variant in carried:
		if not is_valid_id(find_id, source):
			return "bad_carried"
	if session.has("taken"):
		var taken_reason := _validate_taken(session.get("taken"), offers, carried, source)
		if taken_reason != "":
			return taken_reason
	if not is_valid_seed_text(session.get("rng_seed")):
		return "bad_rng_seed"
	if session.has("companion") and not AnimalCompanions.valid_choice(session.companion):
		return "bad_companion"
	var proposal: Variant = session.get("proposal")
	if state == STATE_ACTIVE:
		if proposal != null:
			return "unexpected_proposal"
	else:
		if typeof(proposal) != TYPE_DICTIONARY:
			return "missing_proposal"
		var reason := _validate_proposal(proposal, session, source)
		if reason != "":
			return reason
	var failure: Variant = session.get("failure")
	if failure != null:
		if typeof(failure) != TYPE_DICTIONARY or typeof(failure.get("code")) != TYPE_STRING \
				or typeof(failure.get("retryable")) != TYPE_BOOL or typeof(failure.get("deferred")) != TYPE_BOOL \
				or as_int(failure.get("attempts"), 0) == null:
			return "bad_failure"
	if state == STATE_FAILURE and failure == null:
		return "missing_failure"
	return ""


## taken 记的是“哪处停留点的东西在篮子里”：每处只能占一次、与该处给出的东西一致，合起来正好是 carried
static func _validate_taken(taken: Variant, offers: Dictionary, carried: Array, source: String) -> String:
	if typeof(taken) != TYPE_DICTIONARY or taken.size() > MAX_CARRY:
		return "bad_taken"
	var remaining: Array = carried.duplicate()
	for stop_id: Variant in taken:
		var find_id: Variant = taken[stop_id]
		if not is_valid_stop_id(stop_id) or not is_valid_id(find_id, source) or offers.get(stop_id) != find_id:
			return "bad_taken"
		if not remaining.has(find_id):
			return "bad_taken"
		remaining.erase(find_id)
	return "bad_taken" if not remaining.is_empty() else ""


static func _validate_proposal(proposal: Dictionary, session: Dictionary, source: String) -> String:
	if proposal.get("trip_id") != session.get("trip_id") or proposal.get("route_id") != session.get("route_id"):
		return "proposal_mismatch"
	if not RETURN_REASONS.has(proposal.get("reason")):
		return "bad_proposal_reason"
	if as_int(proposal.get("revision"), 1) == null:
		return "bad_proposal_revision"
	var items: Variant = proposal.get("items")
	if typeof(items) != TYPE_ARRAY or items.size() > MAX_CARRY:
		return "bad_proposal_items"
	for item: Variant in items:
		if typeof(item) != TYPE_DICTIONARY or not is_valid_id(item.get("find_id"), source):
			return "bad_proposal_items"
	return ""
