extends RefCounted
## Strict production Host wire decoder. Does not project business state.
const NAMESPACE := "youjia-save-host-v1"
const MAX_WIRE_BYTES := 44 * 1024 * 1024
const IMPORT_BYTES := 3670016
const WRITE_BYTES := 1572864
const ENVELOPE_FIELDS := ["schema","store_id","commit_id","request_id","parent_commit_id","generation","payload_bytes","payload_sha256","envelope_sha256"]
const PREPARED_FIELDS := ["schema","namespace","store_id","write_id","request_id","candidate_token","parent_token","payload_sha256","generation"]
const RECEIPT_FIELDS := ["schema","namespace","store_id","write_id","request_id","candidate_token","parent_token","payload_sha256","generation","observed_token","outcome","transaction_state","readback_verified","old_write_terminated"]

static func exact(value: Dictionary, fields: Array) -> bool:
	return value.size()==fields.size() and fields.all(func(key): return value.has(key))

static func hex(value: Variant, length: int) -> bool:
	if not value is String or value.length()!=length: return false
	for character: String in value:
		if not character in "0123456789abcdef": return false
	return true

static func decimal(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length()>19 or value[0]=="0": return false
	for character: String in value:
		if not character in "0123456789": return false
	return value.length()<19 or value<="9223372036854775807"

static func parse(raw: Variant, allow_numbers: bool = false) -> Dictionary:
	if not raw is String or raw.length()>MAX_WIRE_BYTES or raw.to_utf8_buffer().size()>MAX_WIRE_BYTES: return {}
	# Reply objects contain strings/bools/null and one optional envelope, no arrays
	# or numeric tokens. Reject duplicate keys before JSON's last-key-wins parse.
	var stack: Array = []
	var index := 0
	while index<raw.length():
		var character: String = raw[index]
		if character=='"':
			var start := index
			index+=1
			while index<raw.length():
				if raw[index]=='\\': index+=2; continue
				if raw.unicode_at(index)<32: return {}
				if raw[index]=='"': break
				index+=1
			if index>=raw.length(): return {}
			var token: Variant=JSON.parse_string(raw.substr(start,index-start+1))
			if not token is String: return {}
			var next := index+1
			while next<raw.length() and raw[next] in " \n\r\t": next+=1
			if next<raw.length() and raw[next]==":":
				if stack.is_empty() or stack[-1].has(token): return {}
				stack[-1][token]=true
		elif character=="{": stack.append({})
		elif character=="}":
			if stack.is_empty(): return {}
			stack.pop_back()
		elif character==",":
			var next := index+1
			while next<raw.length() and raw[next] in " \n\r\t": next+=1
			if next>=raw.length() or raw[next]=="}": return {}
		elif character in "[]" or (not allow_numbers and character in "0123456789+-"): return {}
		index+=1
	if not stack.is_empty(): return {}
	var parser := JSON.new()
	if parser.parse(raw)!=OK or not parser.data is Dictionary: return {}
	return parser.data

static func envelope(value: Variant) -> bool:
	if not value is Dictionary: return false
	var fields := ENVELOPE_FIELDS.duplicate()
	if value.get("schema")=="youjia.save-envelope/v2": fields.insert(fields.size()-1,"legacy_sources_sha256")
	elif value.get("schema")!="youjia.save-envelope/v1": return false
	if not exact(value,fields): return false
	for key: String in fields:
		if not value[key] is String: return false
	if not hex(value.store_id,32) or not hex(value.commit_id,32) or not hex(value.request_id,32) or not decimal(value.generation): return false
	if not (value.parent_commit_id=="" or hex(value.parent_commit_id,32)): return false
	if (value.generation=="1")!=(value.parent_commit_id==""): return false
	if value.has("legacy_sources_sha256") and not hex(value.legacy_sources_sha256,64): return false
	if not hex(value.payload_sha256,64) or not hex(value.envelope_sha256,64): return false
	var bytes: PackedByteArray=value.payload_bytes.to_utf8_buffer()
	if bytes.size()>(IMPORT_BYTES if value.generation=="1" else WRITE_BYTES): return false
	if value.payload_bytes.sha256_text()!=value.payload_sha256: return false
	var payload: Variant=JSON.parse_string(value.payload_bytes)
	if not payload is Dictionary: return false
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	for key: String in fields.slice(0,fields.size()-1):
		var part: PackedByteArray=value[key].to_utf8_buffer()
		var prefix := PackedByteArray()
		for shift: int in range(7,-1,-1): prefix.append((part.size()>>(shift*8))&255)
		digest.update(prefix)
		if not part.is_empty(): digest.update(part)
	return digest.finish().hex_encode()==value.envelope_sha256

static func opened(wire: Dictionary) -> bool:
	if not exact(wire,["schema","status","code","current_payload","current_token","current_envelope"]) or wire.schema!="youjia.host-open/v1": return false
	if not wire.code is String or not wire.status is String or not wire.current_payload is String or not wire.current_token is String: return false
	if wire.status in ["empty","blocked"]: return wire.current_envelope==null and wire.current_token=="" and wire.current_payload==""
	return wire.status=="ready" and envelope(wire.current_envelope) and wire.current_token==wire.current_envelope.commit_id and wire.current_payload==wire.current_envelope.payload_bytes

static func prepared(wire: Dictionary) -> bool:
	if not exact(wire,PREPARED_FIELDS) or wire.schema!="youjia.save-prepared/v1" or wire.namespace!=NAMESPACE: return false
	return hex(wire.store_id,32) and decimal(wire.write_id) and hex(wire.request_id,32) and hex(wire.candidate_token,32) and hex(wire.parent_token,32) and hex(wire.payload_sha256,64) and decimal(wire.generation) and wire.candidate_token!=wire.parent_token

static func receipt(wire: Dictionary, frozen: Dictionary) -> bool:
	if not prepared(frozen) or not exact(wire,RECEIPT_FIELDS) or wire.schema!="youjia.save-receipt/v2": return false
	for key: String in PREPARED_FIELDS:
		if key!="schema" and (typeof(wire[key])!=typeof(frozen[key]) or wire[key]!=frozen[key]): return false
	if not wire.readback_verified is bool or not wire.old_write_terminated is bool or not wire.readback_verified or not wire.old_write_terminated: return false
	if wire.outcome=="confirmed": return wire.transaction_state=="complete" and wire.observed_token==frozen.candidate_token
	if wire.outcome=="rejected": return wire.transaction_state=="terminated" and wire.observed_token==frozen.parent_token
	return false
