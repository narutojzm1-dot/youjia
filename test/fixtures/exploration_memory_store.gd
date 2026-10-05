extends "res://autoload/save_store.gd"
# 生产 SaveStore 的探索 API，只把异步存档队列换成内存：受理后要调 pump() 才求值、确认或拒绝。
# 用来注入被拒 / 结果未知，不碰真实存档。

var fail_commits := false
# >= 0 时：再确认这么多笔后开始拒绝（模拟“提交成功、随后的空闲记录没写上就断电”）
var fail_after := -1
# 非空时 pump() 把下一笔这种 kind 的写入挂成结果未知，直到 resolve_unknown()
var unknown_kind := ""
var commits := 0
var queue: Array[Dictionary] = []
var _unknown: Dictionary = {}
var _sequence := 0


func _init() -> void:
	_data = _default_data()
	_boot_state = "ready"


func request_intent(kind: String, intent: Callable) -> String:
	_sequence += 1
	var op_id := "mem-%d" % _sequence
	_pending_kinds[op_id] = kind
	queue.append({"op_id": op_id, "kind": kind, "intent": intent})
	return op_id


func is_save_idle() -> bool:
	return queue.is_empty() and _unknown.is_empty()


## 按先进先出求值并回报，直到队列空或挂起一笔未知
func pump() -> void:
	while _unknown.is_empty() and not queue.is_empty():
		var op: Dictionary = queue.pop_front()
		var candidate: Variant = op.intent.call(_data.duplicate(true))
		if op.kind == unknown_kind:
			unknown_kind = ""
			_unknown = {"op_id": op.op_id, "candidate": candidate}
			_on_commit_unknown(op.op_id, "MEMORY_UNKNOWN")
			return
		_settle(op.op_id, candidate)


func resolve_unknown(landed: bool) -> void:
	var op := _unknown
	_unknown = {}
	if landed:
		_settle(op.op_id, op.candidate)
	else:
		_on_commit_rejected(op.op_id, "RESOLVED_PARENT")
	pump()


func _settle(op_id: String, candidate: Variant) -> void:
	if fail_commits or fail_after == 0 or not candidate is Dictionary:
		_on_commit_rejected(op_id, "MEMORY_FAIL")
		return
	if fail_after > 0:
		fail_after -= 1
	commits += 1
	_on_commit_confirmed(op_id, candidate, "")
