extends "res://autoload/save_store.gd"
# 生产 SaveStore 的探索 API，只把异步存档队列换成内存：受理后要调 pump() 才求值、确认或拒绝。
# 用来注入被拒 / 结果未知，不碰真实存档。

var fail_commits := false
# >= 0 时：再确认这么多笔后开始拒绝（模拟“提交成功、随后的空闲记录没写上就断电”）
var fail_after := -1
# 非空时 pump() 把下一笔这种 kind 的写入挂成结果未知，直到 resolve_unknown()
var unknown_kind := ""
# 非空时下一笔这种 kind 的写入被拒一次（存储写失败），之后恢复正常
var fail_kind_once := ""
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
		# 真实协调器在 prepare 之前就按 typed 码拒绝，这样的请求不会挂成未知
		if op.kind == unknown_kind and candidate is Dictionary:
			unknown_kind = ""
			_unknown = {"op_id": op.op_id, "candidate": candidate}
			_on_commit_unknown(op.op_id, "MEMORY_UNKNOWN")
			return
		if op.kind == fail_kind_once and candidate is Dictionary:
			fail_kind_once = ""
			_on_commit_rejected(op.op_id, "MEMORY_FAIL")
			continue
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
	# 和真实协调器一样：清理接口的写前拒绝带它自己的码，在注入失败之前判定
	if candidate is CoordinatorType.IntentRejection:
		_on_commit_rejected(op_id, candidate.code)
		return
	if fail_commits or fail_after == 0 or not candidate is Dictionary:
		_on_commit_rejected(op_id, "MEMORY_FAIL")
		return
	if fail_after > 0:
		fail_after -= 1
	commits += 1
	_on_commit_confirmed(op_id, candidate, "")
