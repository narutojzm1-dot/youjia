extends RefCounted
## Readonly inspection/export validation. Never merges or mutates legacy data.
const R=preload("res://scripts/persistence/web_save_reply.gd")
const ROW=["status","snapshot_status","sha256","bytes","baseline_status","baseline_sha256","baseline_bytes","reason"]
static func count(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and value>=0 and value<=R.WRITE_BYTES and value==floor(value)
static func digest(bytes: PackedByteArray) -> String:
	var h=HashingContext.new();h.start(HashingContext.HASH_SHA256)
	if not bytes.is_empty(): h.update(bytes)
	return h.finish().hex_encode()
static func inspection(w: Variant) -> bool:
	if not w is Dictionary or not R.exact(w,["schema","namespace","current_token","baseline","status","sources"]): return false
	if w.schema!="youjia.legacy-inspection/v1" or w.namespace!=R.NAMESPACE or not R.hex(w.current_token,32) or not w.baseline in ["sealed","none"]: return false
	if not w.sources is Dictionary or not R.exact(w.sources,["primary","backup"]): return false
	var unavailable=false;var absent=true;var changed=false
	for key in ["primary","backup"]:
		var row:Variant=w.sources[key]
		if not row is Dictionary or not R.exact(row,ROW) or not count(row.bytes) or not count(row.baseline_bytes) or not row.reason is String: return false
		if not row.snapshot_status in ["present","absent","unavailable"] or not row.baseline_status in ["present","absent"]: return false
		if row.snapshot_status=="present":
			if not R.hex(row.sha256,64) or row.reason!="": return false
		else:
			if row.sha256!="" or row.bytes!=0 or (row.snapshot_status=="absent" and row.reason!="") or (row.snapshot_status=="unavailable" and row.reason==""): return false
		if row.baseline_status=="present":
			if not R.hex(row.baseline_sha256,64): return false
		elif row.baseline_sha256!="" or row.baseline_bytes!=0: return false
		if w.baseline=="none" and row.baseline_status!="absent": return false
		var expected="unavailable" if row.snapshot_status=="unavailable" else "absent" if row.snapshot_status=="absent" else "same" if row.baseline_status=="present" and row.sha256==row.baseline_sha256 else "changed"
		if row.status!=expected or (expected=="same" and row.bytes!=row.baseline_bytes): return false
		unavailable=unavailable or expected=="unavailable"
		absent=absent and row.snapshot_status=="absent"
		changed=changed or expected=="changed" or (expected=="absent" and row.baseline_status=="present")
	return w.status==("unavailable" if unavailable else "absent" if absent else "changed" if changed else "same")
static func seal_sources(seal: Variant, env: Dictionary) -> Dictionary:
	if not seal is Dictionary or not R.exact(seal,["schema","store_id","import_payload","payload_sha256","seal_sha256"]): return {}
	if seal.schema!="youjia.legacy-sources/v1" or seal.store_id!=env.store_id or not seal.import_payload is String or seal.import_payload.to_utf8_buffer().size()>R.IMPORT_BYTES: return {}
	if not R.hex(seal.payload_sha256,64) or not R.hex(seal.seal_sha256,64) or seal.import_payload.sha256_text()!=seal.payload_sha256 or seal.seal_sha256!=env.get("legacy_sources_sha256"): return {}
	# JS JSON.stringify(array) and Godot compact JSON stringify share escaping here.
	if JSON.stringify([seal.schema,seal.store_id,seal.import_payload,seal.payload_sha256]).sha256_text()!=seal.seal_sha256: return {}
	var v=R.parse(seal.import_payload)
	if not R.exact(v,["schema","selected","sources"]) or v.schema!="youjia.legacy-v5-import/v1" or not v.selected in ["primary","backup"] or not v.sources is Dictionary or not R.exact(v.sources,["primary","backup"]): return {}
	for key in ["primary","backup"]:
		var src=v.sources[key]
		if not src is Dictionary: return {}
		if src.get("status")=="absent" and R.exact(src,["status"]): continue
		if not R.exact(src,["status","text"]) or src.status!="present" or not src.text is String or src.text.to_utf8_buffer().size()>R.WRITE_BYTES: return {}
		var parsed=JSON.parse_string(src.text)
		if parsed is Dictionary and parsed.get("version")!=5: return {}
	if v.sources[v.selected].get("status")!="present": return {}
	var chosen=JSON.parse_string(v.sources[v.selected].text)
	if not chosen is Dictionary or chosen.get("version")!=5: return {}
	return v.sources
static func exported(w: Variant) -> bool:
	if not w is Dictionary or not R.exact(w,["schema","namespace","inspection","current_envelope","legacy_sources","legacy_snapshot"]): return false
	if w.schema!="youjia.recovery-export/v1" or w.namespace!=R.NAMESPACE or not inspection(w.inspection) or not R.envelope(w.current_envelope) or w.current_envelope.commit_id!=w.inspection.current_token: return false
	var baseline={"primary":{"status":"absent"},"backup":{"status":"absent"}}
	if w.current_envelope.schema=="youjia.save-envelope/v2":
		baseline=seal_sources(w.legacy_sources,w.current_envelope)
		if baseline.is_empty() or w.inspection.baseline!="sealed": return false
	elif w.legacy_sources!=null or w.inspection.baseline!="none": return false
	if not w.legacy_snapshot is Dictionary or not R.exact(w.legacy_snapshot,["primary","backup"]): return false
	for key in ["primary","backup"]:
		var row=w.inspection.sources[key];var src=w.legacy_snapshot[key];var old=baseline[key]
		if row.baseline_status!=old.status: return false
		if old.status=="present" and (row.baseline_sha256!=old.text.sha256_text() or row.baseline_bytes!=old.text.to_utf8_buffer().size()): return false
		if not src is Dictionary: return false
		match src.get("status"):
			"absent":
				if not R.exact(src,["status"]) or row.snapshot_status!="absent": return false
			"read_error":
				if not R.exact(src,["status","reason"]) or not src.reason is String or src.reason=="" or row.snapshot_status!="unavailable" or row.reason!=src.reason: return false
			"present":
				if not R.exact(src,["status","base64"]) or not src.base64 is String or src.base64.length()>2097152 or src.base64.length()%4!=0: return false
				for c in src.base64:
					if not c in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=": return false
				var raw=Marshalls.base64_to_raw(src.base64)
				if Marshalls.raw_to_base64(raw)!=src.base64 or raw.size()>R.WRITE_BYTES or row.snapshot_status!="present" or row.bytes!=raw.size() or row.sha256!=digest(raw): return false
			_: return false
	return true
