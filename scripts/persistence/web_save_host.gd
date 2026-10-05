extends Node
## Dormant production adapter. Attach explicitly; not an autoload and no legacy writes.
signal completed(request_id: String, method: String, reply: Dictionary)
const Reply = preload("res://scripts/persistence/web_save_reply.gd")
const Legacy = preload("res://scripts/persistence/web_save_legacy_reply.gd")
const METHODS := ["open","initialize","prepare","submit","resolve","acknowledge","close","inspectLegacy","exportRecovery"]
const ROUTER_SCRIPT := """
if (!window.__YoujiaGodotSaveRouter) window.__YoujiaGodotSaveRouter = {
 callbacks: Object.create(null),
 install(key,fn) { this.callbacks[key]=fn; },
 make(key,id) { return raw => { const fn=this.callbacks[key]; if(typeof fn==='function') fn(id,raw); }; },
 remove(key) { delete this.callbacks[key]; }
};
"""
var timeout_ms := 30000
var last_request_error := ""
var _host: JavaScriptObject
var _router: JavaScriptObject
var _dispatcher: JavaScriptObject
var _route := ""
var _sequence := 0
var _pending: Dictionary = {}
var _current: Dictionary = {}
var _flight: Dictionary = {}
var _submitted := false
var _confirmed := false
var _flight_done := true

func _enter_tree() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS

func _setup() -> bool:
	if _host!=null: return true
	if not OS.has_feature("web"): return false
	_host=JavaScriptBridge.get_interface("YoujiaSaveHost")
	if _host==null: return false
	if not JavaScriptBridge.eval("['open','initialize','prepare','submit','resolve','acknowledge','close','inspectLegacy','exportRecovery'].every(k=>typeof window.YoujiaSaveHost[k]==='function')",true):
		_host=null
		return false
	JavaScriptBridge.eval(ROUTER_SCRIPT,true)
	_router=JavaScriptBridge.get_interface("__YoujiaGodotSaveRouter")
	_route="gd_%s_%s" % [get_instance_id(),Time.get_ticks_usec()]
	_dispatcher=JavaScriptBridge.create_callback(_receive)
	_router.install(_route,_dispatcher)
	return true

func request(method: String, args: Dictionary, expected: Dictionary = {}) -> String:
	last_request_error=""
	if not _pending.is_empty(): last_request_error="REQUEST_PENDING"; return ""
	if not method in METHODS or not _valid_args(method,args,expected): last_request_error="INVALID_REQUEST"; return ""
	if not is_inside_tree() or not _setup(): last_request_error="HOST_UNAVAILABLE"; return ""
	_sequence+=1
	var id := "%s:%s" % [_route,_sequence]
	_pending={"id":id,"method":method,"args":args.duplicate(true),"expected":expected.duplicate(true),"deadline":Time.get_ticks_msec()+timeout_ms}
	var callback: JavaScriptObject=_router.make(_route,id)
	match method:
		"open": _host.open(callback)
		"initialize": _host.initialize(args.payload,JSON.stringify(args.paths),callback)
		"prepare": _host.prepare(args.payload,args.parent_token,args.write_id,callback)
		"submit":
			_submitted=true
			_host.submit(args.request_id,args.write_id,callback)
		"resolve": _host.resolve(args.request_id,args.write_id,callback)
		"acknowledge": _host.acknowledge(args.request_id,args.write_id,callback)
		"close": _host.close(callback)
		"inspectLegacy": _host.inspectLegacy(JSON.stringify(args.paths),callback)
		"exportRecovery": _host.exportRecovery(JSON.stringify(args.paths),callback)
	return id

func _valid_args(method: String, args: Dictionary, expected: Dictionary) -> bool:
	match method:
		"open","close": return args.is_empty() and expected.is_empty()
		"initialize":
			return Reply.exact(args,["payload","paths"]) and _payload(args.payload,Reply.IMPORT_BYTES) and args.paths is Dictionary and Reply.exact(args.paths,["primaryPath","backupPath"]) and args.paths.primaryPath is String and args.paths.backupPath is String and expected.is_empty()
		"inspectLegacy","exportRecovery":
			return Reply.exact(args,["paths"]) and args.paths is Dictionary and Reply.exact(args.paths,["primaryPath","backupPath"]) and args.paths.primaryPath is String and args.paths.backupPath is String and expected.is_empty() and not _current.is_empty() and _flight_done
		"prepare":
			return Reply.exact(args,["payload","parent_token","write_id"]) and _payload(args.payload,Reply.WRITE_BYTES) and Reply.hex(args.parent_token,32) and Reply.decimal(args.write_id) and _flight_done and not _current.is_empty() and args.parent_token==_current.token and _current.generation!="9223372036854775807" and expected.is_empty()
		"submit","resolve","acknowledge":
			return Reply.exact(args,["request_id","write_id"]) and Reply.prepared(_flight) and args.request_id==_flight.request_id and args.write_id==_flight.write_id and (expected.is_empty() or expected==_flight) and ((method=="submit" and not _submitted) or (method=="resolve" and _submitted) or (method=="acknowledge" and _confirmed))
	return false

func _payload(value: Variant, limit: int) -> bool:
	return value is String and value.length()<=limit and value.to_utf8_buffer().size()<=limit

func _process(_delta: float) -> void:
	if not _pending.is_empty() and Time.get_ticks_msec()>=_pending.deadline:
		_finish(_uncertain_status(_pending.method),"TIMEOUT",{})

func _uncertain_status(method: String) -> String:
	if method in ["submit","resolve"]: return "unknown"
	if method=="acknowledge": return "ack_failed"
	return "blocked"

func _receive(args: Array) -> void:
	if args.size()!=2 or not args[0] is String or _pending.is_empty() or args[0]!=_pending.id: return
	var method: String=_pending.method
	var wire: Dictionary=Reply.parse(args[1],method in ["inspectLegacy","exportRecovery"])
	if Reply.exact(wire,["schema","code","cause"]) and wire.schema=="youjia.save-error/v1" and wire.code is String and wire.cause is String:
		_finish(_uncertain_status(method),wire.code,wire)
		return
	var valid := false
	var status := "blocked"
	match method:
		"open","initialize":
			valid=Reply.opened(wire)
			if valid:
				status=wire.status
				if status=="ready": _current={"token":wire.current_token,"store_id":wire.current_envelope.store_id,"generation":wire.current_envelope.generation}
		"prepare":
			var sent: Dictionary=_pending.args
			valid=Reply.prepared(wire) and wire.write_id==sent.write_id and wire.parent_token==sent.parent_token and wire.store_id==_current.store_id and wire.generation==str(int(_current.generation)+1) and wire.payload_sha256==sent.payload.sha256_text()
			if valid:
				_flight=wire.duplicate(true)
				_submitted=false
				_flight_done=false
				_confirmed=false
				status="prepared"
		"submit","resolve":
			valid=Reply.receipt(wire,_flight) and not (_confirmed and wire.get("outcome")=="rejected")
			if valid:
				status=wire.outcome
				if status=="rejected": _flight_done=true
				if status=="confirmed":
					_confirmed=true
					_current={"token":wire.candidate_token,"store_id":wire.store_id,"generation":wire.generation}
		"acknowledge":
			valid=Reply.exact(wire,["schema","namespace","request_id","write_id","status"]) and wire.schema=="youjia.save-ack/v1" and wire.namespace==Reply.NAMESPACE and wire.request_id==_flight.request_id and wire.write_id==_flight.write_id and wire.status in ["cleared","already_clear"]
			if valid:
				status="acknowledged"
				_flight_done=true
		"inspectLegacy":
			valid=Legacy.inspection(wire) and wire.current_token==_current.token
			if valid: status=wire.status
		"exportRecovery":
			valid=Legacy.exported(wire) and wire.inspection.current_token==_current.token and wire.current_envelope.store_id==_current.store_id
			if valid: status=wire.inspection.status
		"close":
			valid=Reply.exact(wire,["schema","status"]) and wire.schema=="youjia.save-close/v1" and wire.status=="closed"
			if valid: status="closed"
	if not valid:
		_finish(_uncertain_status(method),"INVALID_RECEIPT",{})
		return
	_finish(status,"",wire)

func _finish(status: String, code: String, wire: Dictionary) -> void:
	var id: String=_pending.id
	var method: String=_pending.method
	_pending={}
	call_deferred("_emit_completed",id,method,{"status":status,"code":code,"wire":wire.duplicate(true)})

func _emit_completed(id: String, method: String, reply: Dictionary) -> void:
	completed.emit(id,method,reply)

func _exit_tree() -> void:
	if _router!=null and not _route.is_empty(): _router.remove(_route)
	_pending={}
	_dispatcher=null
	_host=null
