extends SceneTree
const Host = preload("res://scripts/persistence/native_save_host.gd")
const Files = preload("res://scripts/persistence/save_files.gd")
var count := 0
var dir := "user://native-host-suite-" + str(Time.get_ticks_usec())
class Broken extends RefCounted:
	var real = Files.new()
	var writes := 0
	func read_record(p): return real.read_record(p)
	func recover(p,b): return real.recover(p,b)
	func commit(_d,_p,_t,_b):
		writes += 1
		return false
func _initialize(): call_deferred("run")
func check(value, label):
	assert(value,label)
	count += 1
func put(path,text):
	var f=FileAccess.open(path,FileAccess.WRITE)
	f.store_string(text)
	f.close()
func ask(h,method,args={},expected={}):
	var id=h.request(method,args,expected)
	var reply=await h.completed
	check(reply[0]==id and reply[1]==method,"deferred identity")
	return reply[2]
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var p=dir+"/p";var t=dir+"/t";var b=dir+"/b"
	var h=Host.new(p,t,b)
	check(h.get_state()=="ready" and not FileAccess.file_exists(p),"absent no write")
	var payload='{"version":5,"album":["kept"]}'
	var r=await ask(h,"prepare",{"payload":payload,"parent_token":h.get_initial_token(),"write_id":"1"})
	check(r.status=="prepared" and r.wire.size()==9,"nine fields")
	var w=r.wire;var args={"request_id":w.request_id,"write_id":"1"}
	r=await ask(h,"submit",args,w)
	check(r.status=="confirmed" and r.wire.size()==14,"14 receipt actual file")
	check(FileAccess.get_file_as_string(p).sha256_text()==w.candidate_token,"token binds pretty actual bytes")
	r=await ask(h,"submit",args,w)
	check(r.status=="unknown","duplicate submit refused")
	r=await ask(h,"acknowledge",args,w)
	check(r.status=="acknowledged" and r.wire.size()==5,"ack five")
	var raw=' {"version":5,"album":[]}  '
	put(p,raw)
	h=Host.new(p,t,b)
	check(h.get_initial_token()==raw.sha256_text(),"raw initial token")
	var broken=Broken.new();h=Host.new(p,t,b,broken)
	r=await ask(h,"prepare",{"payload":payload,"parent_token":h.get_initial_token(),"write_id":"2"})
	w=r.wire;args={"request_id":w.request_id,"write_id":"2"}
	r=await ask(h,"submit",args,w)
	check(r.status=="unknown","failed write unknown")
	r=await ask(h,"submit",args,w)
	check(broken.writes==1,"never retry submit")
	r=await ask(h,"resolve",args,w)
	check(r.status=="rejected" and r.wire.observed_token==raw.sha256_text(),"resolve trusted parent")
	h=Host.new(p,t,b)
	r=await ask(h,"prepare",{"payload":payload,"parent_token":h.get_initial_token(),"write_id":"3"})
	w=r.wire;args={"request_id":w.request_id,"write_id":"3"}
	put(p,'{"version":5,"external":true}')
	r=await ask(h,"submit",args,w)
	check(r.status=="unknown","external write after prepare")
	r=await ask(h,"resolve",args,w)
	check(r.status=="unknown","unrelated remains unknown")
	put(p,raw);h=Host.new(p,t,b)
	r=await ask(h,"open")
	check(r.status=="ready" and r.wire.size()==6 and r.wire.current_payload==raw,"open six real raw")
	r=await ask(h,"prepare",{"payload":payload,"parent_token":h.get_initial_token(),"write_id":"4"})
	w=r.wire;args={"request_id":w.request_id,"write_id":"4"}
	r=await ask(h,"submit",args,w)
	check(r.status=="confirmed","commit before ack failure")
	put(p,'{"version":5,"external":2}')
	r=await ask(h,"acknowledge",args,w)
	check(r.status=="unknown" and h.get_initial_token()==w.candidate_token and h.get_state()=="blocked","ack failure cannot undo confirmation")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(p+".legacy-sources.json"))
	put(p,raw);h=Host.new(p,dir+"/missing-folder/tmp",b)
	r=await ask(h,"prepare",{"payload":payload,"parent_token":h.get_initial_token(),"write_id":"5"})
	w=r.wire;args={"request_id":w.request_id,"write_id":"5"}
	r=await ask(h,"submit",args,w)
	check(r.status=="unknown" and FileAccess.get_file_as_string(p)==raw,"real temporary path failure preserves primary")
	r=await ask(h,"resolve",args,w)
	check(r.status=="rejected","real failure resolves parent")
	put(p,"broken");put(b,raw);h=Host.new(p,t,b)
	check(h.get_state()=="blocked" and h.get_initial_token()==raw.sha256_text(),"backup shown but corrupted evidence blocked")
	put(p,'{"version":6}');h=Host.new(p,t,b)
	check(h.get_state()=="blocked","future blocked")
	for version: int in range(1,6):
		var lp=dir+"/legacy-"+str(version)
		var lb=lp+".bak"
		var original=' {"version":%d,"unknown":{"number":9007199254740993},"album":[]}\n' % version
		var backup_original='{"version":1,"backup_unknown":true}'
		put(lp,original);put(lb,backup_original)
		var legacy=Host.new(lp,lp+".tmp",lb)
		check(legacy.get_state()=="ready" and legacy.get_initial_snapshot().version==5 and legacy.get_initial_snapshot().has("unknown"),"legacy accepted projected without dropping unknown")
		check(legacy.get_initial_token()==original.sha256_text(),"legacy raw token")
		var seal_path=lp+".legacy-sources.json"
		var seal_text=FileAccess.get_file_as_string(seal_path)
		var seal=JSON.parse_string(seal_text)
		check(Marshalls.base64_to_raw(seal.sources.primary.base64)==original.to_utf8_buffer() and Marshalls.base64_to_raw(seal.sources.backup.base64)==backup_original.to_utf8_buffer(),"both original bytes permanent")
		for turn: int in [1,2]:
			var candidate=legacy.get_initial_snapshot();candidate["turn"]=turn
			r=await ask(legacy,"prepare",{"payload":JSON.stringify(candidate),"parent_token":legacy.get_initial_token(),"write_id":str(turn)})
			w=r.wire;args={"request_id":w.request_id,"write_id":str(turn)}
			r=await ask(legacy,"submit",args,w)
			check(r.status=="confirmed","legacy real commit")
			r=await ask(legacy,"acknowledge",args,w)
			check(r.status=="acknowledged" and FileAccess.get_file_as_string(seal_path)==seal_text,"ack keeps original evidence")
			legacy=Host.new(lp,lp+".tmp",lb)
			check(legacy.get_state()=="ready" and legacy.get_initial_snapshot().turn==turn,"reopen migrated sources")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(seal_path))
		legacy=Host.new(lp,lp+".tmp",lb)
		check(legacy.get_state()=="blocked" and not FileAccess.file_exists(seal_path),"deleted evidence blocks no replacement")
		for path in [lp,lb,lp+".tmp"]:
			if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var cp=dir+"/compat";var cb=cp+".bak"
	var craw=' {"version":3,"custom":"keep","album":[]} '
	put(cp,craw)
	var compat=Host.new(cp,cp+".tmp",cb)
	var evidence=FileAccess.get_file_as_string(cp+".legacy-sources.json")
	var working=compat.get_initial_snapshot();working["turn"]=1
	r=await ask(compat,"prepare",{"payload":JSON.stringify(working),"parent_token":compat.get_initial_token(),"write_id":"1"})
	w=r.wire;args={"request_id":w.request_id,"write_id":"1"}
	check(compat.commit_compat(working).status=="unknown","sync cannot interleave prepared async")
	r=await ask(compat,"submit",args,w)
	r=await ask(compat,"acknowledge",args,w)
	working=compat.get_initial_snapshot();working["turn"]=2
	var sync_result=compat.commit_compat(working)
	check(sync_result.status=="confirmed" and sync_result.ready and sync_result.snapshot.has(Host.SOURCE_KEY) and sync_result.snapshot.custom=="keep","sync returns full linked confirmed snapshot")
	check(sync_result.token==FileAccess.get_file_as_string(cp).sha256_text(),"sync token actual bytes")
	working=sync_result.snapshot;working["turn"]=3
	r=await ask(compat,"prepare",{"payload":JSON.stringify(working),"parent_token":sync_result.token,"write_id":"3"})
	w=r.wire;args={"request_id":w.request_id,"write_id":"3"}
	r=await ask(compat,"submit",args,w)
	r=await ask(compat,"acknowledge",args,w)
	compat=Host.new(cp,cp+".tmp",cb)
	check(compat.get_state()=="ready" and compat.get_initial_snapshot().turn==3 and FileAccess.get_file_as_string(cp+".legacy-sources.json")==evidence,"legacy async sync async reopen preserves evidence")
	var committed_text=FileAccess.get_file_as_string(cp)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(cp+".legacy-sources.json"))
	sync_result=compat.commit_compat(working)
	check(sync_result.status=="unknown" and not sync_result.ready and FileAccess.get_file_as_string(cp)==committed_text,"compat cannot bypass deleted source evidence")
	compat=Host.new(cp,cp+".tmp",cb)
	check(compat.commit_compat(working).status=="unknown","restarted unlinked compat blocked")
	for path in [cp,cb,cp+".tmp"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	put(cp,craw)
	compat=Host.new(cp,dir+"/missing-compat/tmp",cb)
	sync_result=compat.commit_compat(compat.get_initial_snapshot())
	check(sync_result.status=="rejected" and sync_result.ready and FileAccess.get_file_as_string(cp)==craw,"real sync failure resolves proven parent not guessed failure")
	put(cp,"corrupt")
	var corrupt_text=FileAccess.get_file_as_string(cp)
	sync_result=compat.commit_compat(working)
	check(sync_result.status=="unknown" and FileAccess.get_file_as_string(cp)==corrupt_text,"corrupt source cannot bypass via compat")
	for path in [cp,cb,cp+".tmp",cp+".legacy-sources.json",cp+".legacy-sources.json.tmp"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for residue: String in ["valid1", "valid2", "valid3", "valid4", "valid5", "corrupt", "directory", "temporary"]:
		var rp=dir+"/residue-"+residue
		var residue_version := residue.right(1).to_int() if residue.begins_with("valid") else 2
		put(rp,'{"version":%d,"retained":true}' % residue_version)
		var rh=Host.new(rp,rp+".tmp",rp+".bak")
		check(rh.get_state()=="ready","residue fixture sealed")
		var source_path=rp+".legacy-sources.json"
		if residue=="corrupt": put(source_path,"broken")
		if residue in ["directory", "temporary"]:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(source_path))
			if residue=="directory": DirAccess.make_dir_absolute(ProjectSettings.globalize_path(source_path))
			else: put(source_path+".tmp","retained incomplete evidence")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(rp))
		rh=Host.new(rp,rp+".tmp",rp+".bak")
		check(rh.get_state()=="blocked" and rh.get_initial_snapshot().is_empty() and rh.get_initial_token().is_empty(),"orphan source evidence never fresh defaults "+residue)
		check(rh.commit_compat({"version":5}).status=="unknown" and not FileAccess.file_exists(rp),"orphan evidence cannot be overwritten "+residue)
		for path in [source_path,source_path+".tmp"]:
			if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var bp=dir+"/backup-binding"
	put(bp,'{"version":1,"unknown":"retained"}')
	var bh=Host.new(bp,bp+".tmp",bp+".bak")
	check(bh.commit_compat(bh.get_initial_snapshot()).status=="confirmed","bound current created")
	var bound_bytes=FileAccess.get_file_as_bytes(bp)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(bp+".bak"))
	DirAccess.rename_absolute(ProjectSettings.globalize_path(bp),ProjectSettings.globalize_path(bp+".bak"))
	bh=Host.new(bp,bp+".tmp",bp+".bak")
	check(bh.get_state()=="ready" and bh.get_initial_snapshot().has(Host.SOURCE_KEY),"bound backup alone remains trusted")
	check(bh.get_initial_token()==bound_bytes.get_string_from_utf8().sha256_text(),"backup binding raw identity")
	check(bh.commit_compat(bh.get_initial_snapshot()).status=="confirmed","bound backup permits guarded recovery commit")
	for path in [bp,bp+".bak",bp+".tmp",bp+".legacy-sources.json"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for damage: String in ["json-primary", "utf8-primary", "json-backup", "utf8-backup"]:
		var dp=dir+"/damage-"+damage; var db=dp+".bak"
		var good=' {"version":5,"holiday_day":9,"first_fish_caught":true,"album":["llama_fed_gentle"]} '
		var bad_bytes=PackedByteArray([255, 0, 128]) if damage.begins_with("utf8") else "bad json".to_utf8_buffer()
		put(dp,good);put(db,good)
		var bad_path=dp if damage.ends_with("primary") else db
		var bad_file=FileAccess.open(bad_path,FileAccess.WRITE);bad_file.store_buffer(bad_bytes);bad_file.close()
		var recovery=Host.new(dp,dp+".tmp",db)
		check(recovery.get_state()=="ready" and recovery.get_initial_snapshot().holiday_day==9,"good copy recoverable after full damaged source seal "+damage)
		var sealed=JSON.parse_string(FileAccess.get_file_as_string(dp+".legacy-sources.json"))
		var bad_label="primary" if damage.ends_with("primary") else "backup"
		check(Marshalls.base64_to_raw(sealed.sources[bad_label].base64)==bad_bytes,"exact corrupt bytes sealed "+damage)
		var repaired=recovery.commit_compat(recovery.get_initial_snapshot())
		check(repaired.status=="confirmed","can save after preserved recovery "+damage)
		recovery=Host.new(dp,dp+".tmp",db)
		check(recovery.get_state()=="ready" and recovery.get_initial_snapshot().first_fish_caught,"repaired progress reopens "+damage)
		check(JSON.parse_string(FileAccess.get_file_as_string(dp+".legacy-sources.json"))==sealed,"repair never rewrites evidence "+damage)
		for path in [dp,db,dp+".tmp",dp+".legacy-sources.json"]:
			if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var cannot_seal=dir+"/cannot-seal"
	put(cannot_seal,'{"version":3,"unknown":true}')
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(cannot_seal+".legacy-sources.json"))
	var blocked_seal=Host.new(cannot_seal,cannot_seal+".tmp",cannot_seal+".bak")
	check(blocked_seal.get_state()=="blocked" and FileAccess.get_file_as_string(cannot_seal)=='{"version":3,"unknown":true}',"real sidecar failure blocks and preserves legacy")
	for path in [cannot_seal,cannot_seal+".legacy-sources.json.tmp",cannot_seal+".legacy-sources.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var fraction=dir+"/fraction"
	put(fraction,'{"version":4.5}')
	var invalid=Host.new(fraction,fraction+".tmp",fraction+".bak")
	check(invalid.get_state()=="blocked" and not FileAccess.file_exists(fraction+".legacy-sources.json"),"fraction version blocked no writes")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fraction))
	for path in [p,t,b,p+".legacy-sources.json",p+".legacy-sources.json.tmp"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir))
	print("NATIVE SAVE HOST PASS ",count)
	quit()
