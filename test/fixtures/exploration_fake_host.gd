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


func _init(route_catalog: ExplorationCatalog) -> void:
	catalog = route_catalog
	session = ExplorationSession.new(catalog, 0)


## 模拟重启：从磁盘读取同一代提交并调用 restore
func reboot() -> Dictionary:
	inventory = disk["inventory"].duplicate()
	watermark = disk["watermark"]
	yard = disk["yard"].duplicate(true)
	var record: Variant = JSON.parse_string(JSON.stringify(disk["exploration"])) if disk["exploration"] != null else null
	var result := ExplorationSession.restore(record, catalog, watermark)
	session = result["session"]
	return result


## 出门阶段保存：以当前内存为底写入，并把结果按 (trip_id, revision) 通知核心
func persist() -> bool:
	var trip := session.trip_id()
	var revision := session.record_revision()
	var ok := _write({"inventory": inventory.duplicate(), "watermark": watermark, "exploration": session.to_record(), "yard": yard.duplicate(true)})
	if ok:
		session.host_persisted(trip, revision)
	else:
		session.host_persist_failed(trip, revision)
	return ok


## 回院提交：§7 第 0–4 步
func submit() -> Dictionary:
	var proposal := session.get_proposal()
	if proposal.is_empty() or proposal["trip_id"] != session.trip_id():
		return {"ok": false, "error": "stale_proposal"}
	var serial := int(String(proposal["trip_id"]).trim_prefix("trip-"))
	if serial <= disk["watermark"]:
		var done := session.commit_succeeded(proposal["trip_id"])
		persist()
		return done
	var rejected := PackedStringArray()
	for item: Dictionary in proposal["items"]:
		if not C.is_valid_id(item["find_id"], C.SOURCE_FORMAL) or reject_ids.has(item["find_id"]):
			rejected.append(item["find_id"])
	if not rejected.is_empty():
		var result := session.commit_failed(proposal["trip_id"], false, rejected)
		persist()
		return result
	var candidate_inventory := inventory.duplicate()
	for item: Dictionary in proposal["items"]:
		candidate_inventory.append(item["find_id"])
	var candidate := {"inventory": candidate_inventory, "watermark": serial, "exploration": session.to_record(), "yard": yard.duplicate(true)}
	if _write(candidate):
		inventory = candidate_inventory
		watermark = serial
		grants += (proposal["items"] as Array).size()
		var success := session.commit_succeeded(proposal["trip_id"])
		persist()
		return success
	var failed := session.commit_failed(proposal["trip_id"], true)
	persist()
	return failed


func _write(snapshot: Dictionary) -> bool:
	if fail_next_saves > 0:
		fail_next_saves -= 1
		return false
	disk = JSON.parse_string(JSON.stringify(snapshot))
	disk["watermark"] = int(disk["watermark"])
	return true
