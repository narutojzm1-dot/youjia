extends RefCounted
# 假宿主：按契约 §7 的建议流程模拟 SaveStore 桥，用来驱动核心的故障矩阵。
# 只在测试中使用；真实宿主由 CODEX-LEAD 在 #149/#150 实现。

const C := preload("res://scripts/exploration/exploration_contract.gd")

## “磁盘”：最后一次成功保存的完整提交（同代）
var disk := {"inventory": [], "watermark": 0, "exploration": null, "yard": {}}
## 宿主内存：已发布状态 + 院内未保存改动
var inventory: Array = []
var watermark: int = 0
var yard: Dictionary = {}
var grants := 0
var fail_next_saves := 0
var reject_ids := PackedStringArray()
var session: ExplorationSession
var catalog: ExplorationCatalog

## 契约 §7.1 统一串行事务队列：只记提案身份 {trip_id, revision}，不复制 items
var queue: Array[Dictionary] = []
## 在途事务：已构造候选快照、正在等待持久化确认；为空表示队列可放行下一笔
var in_flight := {}
## 关掉合并只用于测试：证明即使重复请求进了队列，队首重查也能挡住二次授予
var merge_duplicates := true
## 写入进行中又请求的保存：不并入在途快照，等本笔结束后重排
var persist_pending := false
## 院内改动版本：用来证明成功回调不会抹掉等待期间的新改动与未保存标记
var yard_revision := 0
var yard_saved_revision := 0
## 表现层是否已回院（契约 §4 回院导航：不等持久化）
var at_home := true
## 平台结果未知：在途身份与候选保留，不发确认、不放行下一笔
var unknown := false
## 导航调用 request_return 的次数，用来证明重复回院只做幂等导航
var return_calls := 0


func _init(route_catalog: ExplorationCatalog) -> void:
	catalog = route_catalog
	session = ExplorationSession.new(catalog, 0)


## 院内产生一项合法但尚未保存的进展（新照片、关系变化等）
func change_yard(key: String, value: Variant) -> void:
	yard[key] = value
	yard_revision += 1


func has_unsaved_yard() -> bool:
	return yard_saved_revision != yard_revision


## 模拟重启：从磁盘读取同一代提交并调用 restore；trusted=false 模拟“上次结果未知且无法核验”
func reboot(trusted := true) -> Dictionary:
	inventory = disk["inventory"].duplicate()
	watermark = disk["watermark"]
	yard = disk["yard"].duplicate(true)
	queue.clear()
	in_flight = {}
	unknown = false
	persist_pending = false
	yard_saved_revision = yard_revision
	at_home = true
	var record: Variant = JSON.parse_string(JSON.stringify(disk["exploration"])) if disk["exploration"] != null else null
	var result := ExplorationSession.restore(record, catalog, watermark if trusted else C.WATERMARK_UNTRUSTED)
	session = result["session"]
	return result


func set_out(route_id: String, clock: Dictionary, seed: Variant = null) -> Dictionary:
	var result := session.begin(route_id, clock, seed)
	if result.ok:
		at_home = false
	return result


## 玩家按“回院”：首次冻结提案并入队，随即切回院子；已在待提交时只做幂等导航
func go_home(reason := "player") -> void:
	if session.get_state() == C.STATE_ACTIVE:
		return_calls += 1
		if session.request_return(reason).ok:
			persist()
			enqueue_submit()
	at_home = true


## 出门阶段保存：以当前内存为底写入，并把结果按 (trip_id, revision) 通知核心
func persist() -> bool:
	## 同一时刻只有一次写入；在途时只记下“还要再存一次”
	if not in_flight.is_empty():
		persist_pending = true
		return false
	persist_pending = false
	var trip := session.trip_id()
	var revision := session.record_revision()
	var saving_yard := yard_revision
	var ok := _write({"inventory": inventory.duplicate(), "watermark": watermark, "exploration": session.to_record(), "yard": yard.duplicate(true)})
	if ok:
		yard_saved_revision = saving_yard
		session.host_persisted(trip, revision)
	else:
		session.host_persist_failed(trip, revision)
	return ok


## 回院提交的同步写法：入队 → 队首事务 → 立即确认 → 收尾保存
func submit() -> Dictionary:
	var proposal := session.get_proposal()
	if proposal.is_empty() or proposal["trip_id"] != session.trip_id():
		return {"ok": false, "error": "stale_proposal"}
	enqueue_submit()
	var result := start_next()
	if result.get("waiting", false):
		result = finish()
	persist()
	return result


## 提交请求入队：只记 (trip_id, revision)；同一身份已在队列或在途时合并为一笔
func enqueue_submit() -> bool:
	var proposal := session.get_proposal()
	if proposal.is_empty():
		return false
	var identity := {"trip_id": proposal["trip_id"], "revision": int(proposal["revision"])}
	if merge_duplicates:
		if _same_identity(in_flight, identity):
			return false
		for queued: Dictionary in queue:
			if _same_identity(queued, identity):
				return false
	queue.append(identity)
	return true


## 放行队首一笔事务：§7 第 0–3 步；需要写入时停在“等待持久化确认”，由 finish() 收尾
func start_next() -> Dictionary:
	if not in_flight.is_empty():
		return {"ok": false, "error": "busy"}
	if queue.is_empty():
		return {"ok": false, "error": "empty"}
	var result := _run_head()
	if not result.get("waiting", false):
		_end_transaction()
	return result


func _run_head() -> Dictionary:
	var identity: Dictionary = queue.pop_front()
	## 第 0 步：重读核心当前状态，身份不一致就丢弃，不回成功也不回失败
	var proposal := session.get_proposal()
	if session.get_state() != C.STATE_PENDING or proposal.is_empty() or not _same_identity(identity, {"trip_id": proposal["trip_id"], "revision": int(proposal["revision"])}):
		return {"ok": false, "dropped": true}
	var trip: String = proposal["trip_id"]
	var serial := int(trip.trim_prefix("trip-"))
	## 第 1 步：只和此刻已确认持久化的水位比较
	if serial <= disk["watermark"]:
		return session.commit_succeeded(trip)
	## 第 2 步：内容校验，items 取自第 0 步刚读到的当前提案
	var rejected := PackedStringArray()
	for item: Dictionary in proposal["items"]:
		if not C.is_valid_id(item["find_id"], C.SOURCE_FORMAL) or reject_ids.has(item["find_id"]):
			rejected.append(item["find_id"])
	if not rejected.is_empty():
		return session.commit_failed(trip, false, rejected)
	## 第 3 步：以当前内存为底构造候选快照
	var finds: Array = []
	for item: Dictionary in proposal["items"]:
		finds.append(item["find_id"])
	var candidate_inventory := inventory.duplicate()
	candidate_inventory.append_array(finds)
	in_flight = {
		"trip_id": trip,
		"revision": identity["revision"],
		"serial": serial,
		"finds": finds,
		"yard_revision": yard_revision,
		"candidate": {"inventory": candidate_inventory, "watermark": serial, "exploration": session.to_record(), "yard": yard.duplicate(true)},
	}
	return {"ok": true, "waiting": true}


## 第 4 步：写入在途候选并处理持久化确认
## write_ok=false 模拟写入失败；deliver=false 模拟“已落盘但回调丢失”
func finish(write_ok := true, deliver := true) -> Dictionary:
	if in_flight.is_empty():
		return {"ok": false, "error": "idle"}
	if unknown:
		return {"ok": false, "error": "unknown"}
	var flight := in_flight
	in_flight = {}
	var result := _publish(flight, write_ok, deliver)
	_end_transaction()
	return result


## 平台结果未知（契约 §7.2）：landed 表示候选其实已经落盘，但宿主此刻不知道
## 不发任何确认、不发布授予；在途身份保留，队列不放行
func finish_unknown(landed: bool) -> void:
	if in_flight.is_empty():
		return
	unknown = true
	if landed:
		disk = JSON.parse_string(JSON.stringify(in_flight["candidate"]))
		disk["watermark"] = int(disk["watermark"])


## 静止核验（#150 H2 的模型）：读可信持久化存储判断候选是否落盘，再按结果收尾
func resolve_unknown() -> Dictionary:
	if not unknown:
		return {"ok": false, "error": "not_unknown"}
	unknown = false
	var flight := in_flight
	in_flight = {}
	var landed: bool = int(disk["watermark"]) >= int(flight["serial"])
	var result: Dictionary
	if landed:
		inventory.append_array(flight["finds"])
		watermark = flight["serial"]
		grants += (flight["finds"] as Array).size()
		if yard_saved_revision < flight["yard_revision"]:
			yard_saved_revision = flight["yard_revision"]
		result = session.commit_succeeded(flight["trip_id"])
	else:
		result = session.commit_failed(flight["trip_id"], true)
	_end_transaction()
	return result


func _publish(flight: Dictionary, write_ok: bool, deliver: bool) -> Dictionary:
	if not write_ok or not _write(flight["candidate"]):
		## 失败：持有物、水位、院内未保存改动都保持写入前原样
		return session.commit_failed(flight["trip_id"], true)
	## 成功：只发布本次确认的授予与水位，不用候选快照覆盖较新的工作内存
	inventory.append_array(flight["finds"])
	watermark = flight["serial"]
	grants += (flight["finds"] as Array).size()
	if yard_saved_revision < flight["yard_revision"]:
		yard_saved_revision = flight["yard_revision"]
	if not deliver:
		return {"ok": true, "delivered": false}
	return session.commit_succeeded(flight["trip_id"])


## 一笔事务结束：§7.1 入队义务的兜底，以及写入期间被推迟的保存重排
func _end_transaction() -> void:
	if session.get_state() == C.STATE_PENDING:
		var proposal := session.get_proposal()
		var identity := {"trip_id": proposal["trip_id"], "revision": int(proposal["revision"])}
		var held := false
		for queued: Dictionary in queue:
			held = held or _same_identity(queued, identity)
		if not held:
			queue.append(identity)
	if persist_pending:
		persist()


func _same_identity(a: Dictionary, b: Dictionary) -> bool:
	return not a.is_empty() and a.get("trip_id") == b.get("trip_id") and int(a.get("revision", -1)) == int(b.get("revision", -2))


func _write(snapshot: Dictionary) -> bool:
	if fail_next_saves > 0:
		fail_next_saves -= 1
		return false
	disk = JSON.parse_string(JSON.stringify(snapshot))
	disk["watermark"] = int(disk["watermark"])
	return true
