extends Node
## #239 业务夹具（CURSOR-CLOUD）：实际 Godot 场景 + SaveWriteGate + JavaScriptBridge。
## 只负责业务：serial 水位去重、Gate 在途身份、确认后请求清理。
## 存储、封套、Probe 屏障与注入、异步桥接归 CODEX-LEAD 的 window.YoujiaRecoveryHostBridge；
## 桥接缺失时只公开 blocked_reason，绝不自造回执或替代 Host。

const Gate = preload("res://gate.gd")
const ROOT_PAYLOAD := {"watermark": 0, "grants": []}
const RESOLVE_ATTEMPTS := 5
const RESOLVE_RETRY_SECONDS := 0.2

var gate
var host
var facade
var current_token := ""
## 业务在途：从受理 grant 起到收尾（含 acknowledge 完成）为止，期间新的 grant 一律拒绝，不覆盖本次上下文。
var busy := false
var resolve_failures := 0
## 每次受理的 grant 分配一个上下文序号；异步回调绑定序号，不匹配的迟到回调直接忽略。
var context_id := 0
var pending_request := ""
var pending_write_id := 0
var pending_serial := 0
var confirmed_serials: Array = []
var refused: Array = []
var blocked_reason := ""
var verdict := ""
var _callbacks: Array = []


func _ready() -> void:
	if not OS.has_feature("web"):
		push_error("recovery fixture requires Web export")
		return
	facade = JavaScriptBridge.get_interface("YoujiaRecoveryFixture")
	host = JavaScriptBridge.get_interface("YoujiaRecoveryHostBridge")
	facade._grant = _callback(_on_grant)
	if host == null:
		_block("host bridge missing (YoujiaRecoveryHostBridge 未由 R1 接线提供)")
		return
	## 先公开“已启动、尚不可写”，等锁或无锁拒绝时驱动也能区分夹具已运行。
	_block("opening store")
	var store := str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('recovery_store') || ''"))
	host.open(store, _callback(_on_opened))


func _callback(method: Callable) -> JavaScriptObject:
	## JavaScriptBridge 回调必须持有引用，否则会被回收。
	var cb := JavaScriptBridge.create_callback(method)
	_callbacks.append(cb)
	return cb


func _block(reason: String) -> void:
	blocked_reason = reason
	_publish()


func _parse(args: Array) -> Dictionary:
	var data: Variant = JSON.parse_string(str(args[0])) if args.size() > 0 else null
	return data if data is Dictionary else {"error": "malformed bridge reply"}


func _on_opened(args: Array) -> void:
	var reply := _parse(args)
	verdict = str(reply.get("verdict", ""))
	if reply.has("error"):
		_block("open failed: %s" % reply.error)
	elif verdict == "empty":
		host.initialize(JSON.stringify(ROOT_PAYLOAD), _callback(_on_opened))
	elif verdict in ["clean", "restored_candidate", "restored_parent_intent_rejected"]:
		_adopt(reply)
	else:
		## quarantined / no_web_locks 等：不写入，只公开状态。
		_block("not writable: %s" % verdict)


func _adopt(reply: Dictionary) -> void:
	## confirmed 初值只来自已验证 current 的 payload 与其 token。
	var payload: Variant = JSON.parse_string(str(reply.get("current_payload", "")))
	var token := str(reply.get("current_token", ""))
	if not payload is Dictionary or token.is_empty():
		_block("trusted current missing")
		return
	current_token = token
	gate = Gate.new(payload)
	blocked_reason = ""
	_publish()


func _business() -> Dictionary:
	return gate.confirmed() if gate != null else {}


func _on_grant(args: Array) -> void:
	var serial := int(args[0]) if args.size() > 0 else 0
	if gate == null or serial <= 0 or busy or gate.blocked():
		refused.append(serial)
		_publish()
		return
	var confirmed := _business()
	if serial <= int(confirmed.get("watermark", 0)):
		## 已在可信水位内：直接确认，不再授予、不写入。
		confirmed_serials.append(serial)
		_publish()
		return
	busy = true
	context_id += 1
	resolve_failures = 0
	pending_serial = serial
	var grants: Array = confirmed.get("grants", []).duplicate()
	grants.append(serial)
	gate.replace_working({"watermark": serial, "grants": grants})
	host.prepare(JSON.stringify(gate.working()), current_token, _callback(_on_prepared.bind(context_id)))
	_publish()


func _on_prepared(args: Array, ctx: int) -> void:
	if ctx != context_id or not busy:
		return
	var reply := _parse(args)
	var flight: Dictionary = {}
	if not reply.has("error"):
		flight = gate.begin_write(str(reply.get("candidate_token", "")), current_token)
	if flight.is_empty():
		## 未开始写入：只撤销本次上下文，working 回到已确认值，不留虚假在途。
		gate.replace_working(_business())
		refused.append(pending_serial)
		_settle()
		return
	gate.mark_unknown(flight.write_id)
	pending_write_id = int(flight.write_id)
	pending_request = str(reply.get("request_id", ""))
	host.submit(pending_request, str(pending_write_id), _callback(_on_receipt.bind(ctx)))
	_publish()


func _on_receipt(args: Array, ctx: int) -> void:
	if ctx != context_id or not busy:
		return
	var raw := str(args[0]) if args.size() > 0 else ""
	var receipt: Variant = JSON.parse_string(raw)
	if receipt is Dictionary and receipt.has("error"):
		## 提交失败或结果未知：不当作失败立即重试，先由 Host 按可信 current 出回执。
		if not gate.blocked():
			return
		resolve_failures += 1
		if resolve_failures > RESOLVE_ATTEMPTS:
			## Host 持续无法给出可信回执：保持在途、停止重试，公开不可写原因。
			_block("resolve failed: %s" % receipt.error)
			return
		if resolve_failures > 1:
			await get_tree().create_timer(RESOLVE_RETRY_SECONDS).timeout
			if ctx != context_id or not busy:
				return
		host.resolve(pending_request, str(pending_write_id), _callback(_on_receipt.bind(ctx)))
		return
	var before := _business()
	if not gate.resolve_verified_json(raw):
		## 错身份、重复或迟到的旧回执：Gate 拒绝，保持在途。
		_publish()
		return
	var request := pending_request
	if receipt.get("observed_token") == receipt.get("candidate_token"):
		current_token = str(receipt.candidate_token)
		confirmed_serials.append(pending_serial)
		pending_request = ""
		pending_write_id = 0
		pending_serial = 0
		host.acknowledge(request, _callback(_on_acknowledged.bind(ctx)))
		_publish()
	else:
		## 可信 parent 且旧写已终止：未授予，working 回到已确认值。
		gate.replace_working(before)
		_settle()


func _settle() -> void:
	busy = false
	pending_request = ""
	pending_write_id = 0
	pending_serial = 0
	_publish()


func _on_acknowledged(args: Array, ctx: int) -> void:
	if ctx != context_id or not busy:
		return
	var reply := _parse(args)
	if reply.has("error"):
		## 清理失败不回滚已确认的提交，但意图仍在，Host 会拒绝下次写入；公开为不可写，不假装可继续。
		blocked_reason = "acknowledge failed: %s" % reply.error
	_settle()


func _publish() -> void:
	if facade == null:
		return
	var confirmed := _business()
	facade._publish(JSON.stringify({
		"ready": gate != null and blocked_reason.is_empty(),
		"blocked_reason": blocked_reason,
		"verdict": verdict,
		"watermark": int(confirmed.get("watermark", 0)),
		"grants": confirmed.get("grants", []),
		"pending": busy or (gate != null and gate.blocked()),
		"pending_request": pending_request,
		"confirmed_serials": confirmed_serials,
		"refused": refused,
	}))
