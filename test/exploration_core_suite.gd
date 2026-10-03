extends SceneTree
# 探索核心隔离测试（#152 草案）：只用夹具目录与假宿主，不加载场景、不碰玩家存档。
# 对应契约 §12 第 1–16 项；宿主侧联合验收（#149/#150）不在本 suite 内。
# 第 15、16 项只证明串行事务与回院导航协议本身，平台持久化确认另行举证。

const C := preload("res://scripts/exploration/exploration_contract.gd")
const Fixtures := preload("res://test/fixtures/exploration_fixture_routes.gd")
const FakeHost := preload("res://test/fixtures/exploration_fake_host.gd")
const CLOCK := {"day": 3, "elapsed": 120.0}

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_legal_paths()
	_illegal_events()
	_repeated_operations()
	_commit_failures()
	_roundtrip_and_seeds()
	_bad_records()
	_catalog_changes()
	_fixture_gate()
	_lifecycle()
	_no_wall_clock()
	_commit_fault_matrix()
	_stage_fault_matrix()
	_acks()
	_untrusted_and_quarantine()
	_async_interleaving()
	_return_navigation()
	if failures.is_empty():
		print("EXPLORATION CORE PASS ", checks)
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	quit(1)


## 1. 合法路径：出门 → 走 → 带 → 回院 → 提交 → 关闭；空手与取消同一路径
func _legal_paths() -> void:
	var host = FakeHost.new(Fixtures.formal_catalog())
	var s: ExplorationSession = host.session
	_check(s.begin("formal.test_walk", CLOCK, 7).get("persist"), "begin asks the host to save")
	host.persist()
	_check(s.visit("pond").ok, "a reachable stop can be visited")
	_check(s.get_view()["offer"] == "formal.find.reed", "the only find appears at the pond")
	_check(s.take("formal.find.reed").ok, "the offered find can be taken")
	_check(s.request_return("player").ok and s.get_state() == C.STATE_PENDING, "returning freezes the proposal")
	host.submit()
	_check(s.get_state() == C.STATE_COMMITTED and host.grants == 1, "a successful commit grants once")
	_check(s.close().ok and s.get_state() == C.STATE_IDLE, "close returns to idle")
	_check(host.inventory == ["formal.find.reed"], "the find is in the published inventory")
	for reason: String in ["player", "cancel"]:
		s.begin("formal.test_walk", CLOCK, 9)
		s.request_return(reason)
		host.submit()
		_check(s.get_state() == C.STATE_COMMITTED and host.grants == 1, "an empty %s return commits without granting" % reason)
		s.close()
	_check(host.watermark == 3, "every trip advances the committed serial")


## 2. 非法转换：每个状态下不允许的事件被拒，记录字节不变
func _illegal_events() -> void:
	var catalog := Fixtures.catalog()
	var states := {}
	var idle := ExplorationSession.new(catalog, 0)
	states["idle"] = idle
	var active := ExplorationSession.new(catalog, 0)
	active.begin("fixture.meadow", CLOCK, 1)
	states["active"] = active
	var pending := ExplorationSession.new(catalog, 0)
	pending.begin("fixture.meadow", CLOCK, 1)
	pending.request_return("player")
	states["pending"] = pending
	var failure := ExplorationSession.new(catalog, 0)
	failure.begin("fixture.meadow", CLOCK, 1)
	failure.request_return("player")
	failure.commit_failed(failure.trip_id(), true)
	states["failure"] = failure
	var committed := ExplorationSession.new(catalog, 0)
	committed.begin("fixture.meadow", CLOCK, 1)
	committed.request_return("player")
	committed.commit_succeeded(committed.trip_id())
	states["committed"] = committed
	var allowed := {
		"idle": ["begin"],
		"active": ["visit", "take", "release", "request_return"],
		"pending": ["commit_succeeded", "commit_failed"],
		"failure": ["retry_commit", "defer_to_yard"],
		"committed": ["close"],
	}
	var events := ["begin", "visit", "take", "release", "request_return", "commit_succeeded", "commit_failed", "retry_commit", "settle_empty", "defer_to_yard", "close"]
	for name: String in states:
		var s: ExplorationSession = states[name]
		for event: String in events:
			if allowed[name].has(event):
				continue
			var before := JSON.stringify(s.to_record())
			var result := _send(s, event)
			_check(not result.ok, "%s rejects %s" % [name, event])
			_check(JSON.stringify(s.to_record()) == before, "%s %s leaves the record unchanged" % [name, event])
	_check(pending.begin("fixture.meadow", CLOCK).error == "pending_exists", "begin waits for the unsettled trip")


func _send(s: ExplorationSession, event: String) -> Dictionary:
	match event:
		"begin":
			return s.begin("fixture.meadow", CLOCK, 1)
		"visit":
			return s.visit("brook")
		"take":
			return s.take("fixture.find.pebble")
		"release":
			return s.release("fixture.find.pebble")
		"request_return":
			return s.request_return("player")
		"commit_succeeded":
			return s.commit_succeeded(s.trip_id())
		"commit_failed":
			return s.commit_failed(s.trip_id(), true)
		"retry_commit":
			return s.retry_commit()
		"settle_empty":
			return s.settle_empty()
		"defer_to_yard":
			return s.defer_to_yard()
	return s.close()


## 3. 重复操作不二次授予
func _repeated_operations() -> void:
	var host = FakeHost.new(Fixtures.formal_catalog())
	var s: ExplorationSession = host.session
	s.begin("formal.test_walk", CLOCK, 2)
	s.visit("pond")
	s.take("formal.find.reed")
	s.request_return("player")
	_check(s.request_return("player").error == "illegal_transition", "a second return tap is ignored")
	host.submit()
	_check(not s.commit_succeeded(s.trip_id()).ok, "a duplicate success callback is rejected")
	_check(s.commit_succeeded("trip-99").error == "illegal_transition", "a foreign trip id is rejected")
	_check(host.grants == 1, "repeats never grant twice")


## 4. 提交失败的各条出路都能到达 committed
func _commit_failures() -> void:
	var host = FakeHost.new(Fixtures.formal_catalog())
	var s: ExplorationSession = host.session
	s.begin("formal.test_walk", CLOCK, 2)
	s.visit("pond")
	s.take("formal.find.reed")
	s.request_return("player")
	host.fail_next_saves = 1
	host.submit()
	_check(s.get_state() == C.STATE_FAILURE and host.grants == 0, "a failed save keeps the proposal and grants nothing")
	_check(s.settle_empty().error == "illegal_transition", "settle_empty is refused while a retry is possible")
	_check(s.defer_to_yard().ok, "the player can go home first")
	_check(s.begin("formal.test_walk", CLOCK).error == "pending_exists", "deferring keeps ownership of the trip")
	s.retry_commit()
	host.submit()
	_check(s.get_state() == C.STATE_COMMITTED and host.grants == 1, "retrying commits exactly once")
	s.close()
	## 部分物品失效
	var two := FakeHost.new(_two_find_catalog())
	var t: ExplorationSession = two.session
	t.begin("formal.two", CLOCK, 1)
	t.visit("a")
	t.take("formal.find.one")
	t.visit("b")
	t.take("formal.find.two")
	t.request_return("player")
	var trip := t.trip_id()
	_check(t.commit_failed(trip, false, PackedStringArray(["formal.find.zzz"])).error == "invalid_rejection", "a rejection outside the proposal changes nothing")
	_check(t.commit_failed(trip, false, PackedStringArray(["formal.find.one"])).ok, "a partial rejection is accepted")
	var proposal := t.get_proposal()
	_check(proposal["revision"] == 2 and proposal["trip_id"] == trip and proposal["items"].size() == 1, "partial rejection bumps the revision and keeps the trip")
	_check(t.commit_failed(trip, false, PackedStringArray(["formal.find.two"])).ok and t.get_proposal()["items"].is_empty(), "rejecting everything leaves an empty proposal")
	two.submit()
	_check(t.get_state() == C.STATE_COMMITTED, "the empty proposal still settles")
	## 整体不可接受
	var three := ExplorationSession.new(Fixtures.formal_catalog(), 0)
	three.begin("formal.test_walk", CLOCK, 1)
	three.request_return("player")
	three.commit_failed(three.trip_id(), false)
	_check(three.retry_commit().error == "illegal_transition", "a non-retryable failure cannot be retried")
	_check(three.settle_empty().ok and three.get_state() == C.STATE_PENDING, "settle_empty always leaves a way out")


func _two_find_catalog() -> ExplorationCatalog:
	return ExplorationCatalog.new(C.SOURCE_FORMAL, {
		"formal.two": {
			"start_stop": "gate",
			"carry_limit": 2,
			"stops": {
				"gate": {"next": ["a"], "find_pool": []},
				"a": {"next": ["b"], "find_pool": [{"find_id": "formal.find.one", "weight": 1}]},
				"b": {"next": ["gate"], "find_pool": [{"find_id": "formal.find.two", "weight": 1}]},
			},
		},
	})


## 5. 往返与种子
func _roundtrip_and_seeds() -> void:
	var catalog := Fixtures.catalog()
	var s := ExplorationSession.new(catalog, 0)
	s.begin("fixture.meadow", CLOCK, "-9007199254740993")
	s.visit("brook")
	s.take("fixture.find.pebble")
	for step: int in 4:
		var text := JSON.stringify(s.to_record())
		var watermark := 1 if step == 3 else 0
		var restored: ExplorationSession = ExplorationSession.restore(JSON.parse_string(text), catalog, watermark)["session"]
		_check(JSON.stringify(restored.to_record()) == text, "JSON roundtrip is stable at step %d" % step)
		match step:
			0:
				s.request_return("host_interrupt")
			1:
				s.commit_failed(s.trip_id(), true)
			2:
				s.retry_commit()
				s.commit_succeeded(s.trip_id())
	_check(s.to_record()["session"]["rng_seed"] == "-9007199254740993", "a seed beyond 2^53 survives as text")
	var first := ExplorationSession.new(_order_catalog(), 0)
	first.begin("fixture.order", CLOCK, 42)
	first.visit("a")
	first.visit("gate")
	first.visit("b")
	var second := ExplorationSession.new(_order_catalog(), 0)
	second.begin("fixture.order", CLOCK, 42)
	second.visit("b")
	second.visit("gate")
	second.visit("a")
	var offers_a: Dictionary = first.to_record()["session"]["offers"]
	var offers_b: Dictionary = second.to_record()["session"]["offers"]
	_check(offers_a["a"] == offers_b["a"] and offers_a["b"] == offers_b["b"], "finds do not depend on visit order")
	var negative := ""
	for i: int in 64:
		var stop := "s%d" % i
		var digest := ("42:" + stop).sha256_buffer()
		if digest[7] >= 0x80:
			negative = stop
			_check(C.derive_stop_seed("42", stop) < 0, "byte 7 >= 0x80 yields a negative stop seed")
			break
	_check(negative != "", "a negative stop seed exists among sample stops")


func _order_catalog() -> ExplorationCatalog:
	var pool := []
	for i: int in 8:
		pool.append({"find_id": "fixture.find.f%d" % i, "weight": 1})
	return ExplorationCatalog.new(C.SOURCE_FIXTURE, {
		"fixture.order": {
			"start_stop": "gate",
			"stops": {
				"gate": {"next": ["a", "b"], "find_pool": []},
				"a": {"next": ["gate"], "find_pool": pool, "empty_weight": 2},
				"b": {"next": ["gate"], "find_pool": pool, "empty_weight": 2},
			},
		},
	})


## 6. 坏数据：含会话的损坏记录隔离并冻结；无会话的元数据损坏照常
func _bad_records() -> void:
	var catalog := Fixtures.catalog()
	var good := ExplorationSession.new(catalog, 0)
	good.begin("fixture.meadow", CLOCK, 5)
	var base: Dictionary = good.to_record()
	var cases := {
		"not a dictionary": "garbage",
		"session not a dictionary": {"contract_version": 1, "session": 3},
		"bad serial": _with(base, "trip_serial", -2),
		"fractional serial": _with(base, "trip_serial", 1.5),
		"serial beyond range": _with(base, "trip_serial", 4294967296.0),
		"trip id mismatch": _with(base, "trip_id", "trip-9"),
		"bad route id": _with(base, "route_id", "Fixture.Meadow"),
		"prefix mismatch": _with(base, "carried", ["formal.find.pebble"]),
		"long visited": _with(base, "visited", _many(17)),
		"bad seed": _with(base, "rng_seed", "12abc"),
		"unknown state": _with(base, "state", "wandering"),
	}
	for name: String in cases:
		var result := ExplorationSession.restore(cases[name], catalog, 0)
		_check(result["host_action"] == C.HOST_QUARANTINE_AND_FREEZE and not result["can_begin"], "%s is quarantined and frozen" % name)
		_check(JSON.stringify(result["session"].to_record()) == JSON.stringify(cases[name]), "%s is kept verbatim" % name)
		_check(result.has("quarantine_record"), "%s hands the original to the host" % name)
	var oversize := base.duplicate(true)
	oversize["padding"] = "x".repeat(4096)
	_check(ExplorationSession.restore(oversize, catalog, 0)["host_action"] == C.HOST_QUARANTINE_AND_FREEZE, "an over-budget record is quarantined")
	_check(ExplorationSession.restore(null, catalog, 4)["host_action"] == C.HOST_NONE, "a missing record is idle")
	var meta := ExplorationSession.restore({"contract_version": 1, "next_trip_serial": -5, "session": null}, catalog, 4)
	_check(meta["host_action"] == C.HOST_NONE and meta["can_begin"], "corrupt metadata without a session is ignored")
	var s: ExplorationSession = meta["session"]
	s.begin("fixture.meadow", CLOCK, 1)
	_check(s.trip_id() == "trip-5", "the next serial follows the committed watermark")
	var huge: ExplorationSession = ExplorationSession.restore({"contract_version": 1, "next_trip_serial": 99999999, "session": null}, catalog, 4)["session"]
	huge.begin("fixture.meadow", CLOCK, 1)
	_check(huge.trip_id() == "trip-5", "an implausible serial hint is ignored")
	var future := ExplorationSession.restore({"contract_version": 2, "session": null, "new_field": true}, catalog, 0)
	_check(future["host_action"] == C.HOST_QUARANTINE and not future["can_begin"], "a future version is kept and blocks trips")
	_check(future["session"].to_record().has("new_field"), "future fields are not dropped")
	_check(future["session"].begin("fixture.meadow", CLOCK).error == "exploration_unavailable", "a future version explains trips are unavailable")
	_check(not future["persist"] and future["session"].get_proposal().is_empty(), "quarantine neither saves nor exposes a proposal")


func _with(record: Dictionary, key: String, value: Variant) -> Dictionary:
	var copy := record.duplicate(true)
	copy["session"][key] = value
	return copy


func _many(count: int) -> Array:
	var stops := []
	for i: int in count:
		stops.append("s%d" % i)
	return stops


## 7. 目录变更
func _catalog_changes() -> void:
	var s := ExplorationSession.new(Fixtures.catalog(), 0)
	s.begin("fixture.meadow", CLOCK, 5)
	s.visit("brook")
	s.visit("ridge")
	s.take("fixture.find.flower")
	var record: Dictionary = JSON.parse_string(JSON.stringify(s.to_record()))
	var gone := ExplorationSession.restore(record, ExplorationCatalog.new(C.SOURCE_FIXTURE, {}), 0)
	_check(gone["host_action"] == C.HOST_SUBMIT_PROPOSAL and gone["persist"], "a removed route returns home with the carried find")
	_check(gone["session"].get_proposal()["items"] == [{"find_id": "fixture.find.flower"}], "the carried find is proposed")
	var trimmed_routes := Fixtures.routes()
	trimmed_routes["fixture.meadow"]["stops"].erase("ridge")
	trimmed_routes["fixture.meadow"]["stops"]["brook"]["next"] = ["gate"]
	var trimmed := ExplorationSession.restore(record, ExplorationCatalog.new(C.SOURCE_FIXTURE, trimmed_routes), 0)
	var view: Dictionary = trimmed["session"].get_view()
	_check(trimmed["host_action"] == C.HOST_REQUEST_RETURN_RESTORED and view["current_stop"] == "gate", "a removed current stop falls back to the start")
	_check(trimmed["persist"] and trimmed["session"].has_unsaved_changes(), "restore rewrites ask to be saved")
	_check(not trimmed["session"].to_record()["session"]["offers"].has("ridge"), "offers for removed stops are dropped")
	var intact := ExplorationSession.restore(record, Fixtures.catalog(), 0)
	_check(intact["host_action"] == C.HOST_REQUEST_RETURN_RESTORED and not intact["persist"], "an intact active trip goes home safely")


## 8. 夹具闸门
func _fixture_gate() -> void:
	var formal := Fixtures.formal_catalog()
	_check(not ExplorationSession.new(formal, 0).begin("fixture.meadow", CLOCK).ok, "the formal entry cannot begin a fixture route")
	_check(not formal.has_route("fixture.meadow") and formal.route_ids() == PackedStringArray(["formal.test_walk"]), "the formal catalog holds no fixture ids")
	_check(not ExplorationCatalog.new(C.SOURCE_FIXTURE, {"formal.bad": {}}).is_valid(), "a fixture catalog refuses formal ids")
	var s := ExplorationSession.new(Fixtures.catalog(), 0)
	s.begin("fixture.meadow", CLOCK, 5)
	s.visit("brook")
	s.take("fixture.find.pebble")
	var record: Dictionary = JSON.parse_string(JSON.stringify(s.to_record()))
	var reset := ExplorationSession.restore(record, formal, 0)
	_check(reset["host_action"] == C.HOST_QUARANTINE_AND_RESET and reset["can_begin"], "a pure fixture session is voided and trips continue")
	_check(reset["persist"] and reset["session"].to_record()["session"] == null, "voiding asks the host to save the idle record")
	var next: ExplorationSession = reset["session"]
	next.begin("formal.test_walk", CLOCK, 1)
	_check(next.trip_id() == "trip-2", "the voided fixture serial is not reused")
	var mixed := record.duplicate(true)
	mixed["session"]["carried"] = ["formal.find.reed"]
	_check(ExplorationSession.restore(mixed, formal, 0)["host_action"] == C.HOST_QUARANTINE_AND_FREEZE, "a fixture label with formal finds is frozen, not voided")
	var host = FakeHost.new(Fixtures.catalog())
	host.session.begin("fixture.meadow", CLOCK, 5)
	host.session.visit("brook")
	host.session.take("fixture.find.pebble")
	host.session.request_return("player")
	host.submit()
	_check(host.session.get_proposal()["items"].is_empty(), "a submitted fixture find is rejected by the host")
	host.submit()
	_check(host.session.get_state() == C.STATE_COMMITTED and host.grants == 0, "the fixture trip still settles with nothing granted")


## 9. 生命周期：反复创建释放
func _lifecycle() -> void:
	var catalog := Fixtures.catalog()
	var before := Performance.get_monitor(Performance.OBJECT_COUNT)
	for i: int in 1000:
		var s := ExplorationSession.new(catalog, i)
		s.begin("fixture.meadow", CLOCK, i)
		s.request_return("cancel")
		s.commit_succeeded(s.trip_id())
		s.close()
	_check(Performance.get_monitor(Performance.OBJECT_COUNT) - before < 16, "1000 sessions leave no object growth")


## 10. 不读现实时钟
func _no_wall_clock() -> void:
	for file: String in ["exploration_contract.gd", "exploration_catalog.gd", "exploration_session.gd"]:
		var text := FileAccess.get_file_as_string("res://scripts/exploration/" + file)
		_check(text != "", "%s is readable" % file)
		for banned: String in ["Time.", "OS.get_unix_time", "OS.get_ticks"]:
			_check(not text.contains(banned), "%s does not read %s" % [file, banned])


## 11. 提交阶段故障矩阵
func _commit_fault_matrix() -> void:
	var host = FakeHost.new(Fixtures.formal_catalog())
	host.disk["watermark"] = 4
	host.reboot()
	var s: ExplorationSession = host.session
	s.begin("formal.test_walk", CLOCK, 3)
	s.visit("pond")
	s.take("formal.find.reed")
	s.request_return("player")
	host.persist()
	host.yard["photo"] = "new"
	host.fail_next_saves = 1
	host.submit()
	_check(host.disk["watermark"] == 4 and host.watermark == 4, "a failed commit publishes no serial")
	host.session.retry_commit()
	host.submit()
	_check(host.disk["yard"].get("photo") == "new", "the commit keeps unsaved yard progress")
	host.session.close()
	host.persist()
	host.reboot()
	_check(host.grants == 1 and host.disk["watermark"] == 5 and host.inventory.size() == 1, "fail, retry, close, reboot grants exactly once")
	## 首次失败后不重试直接重启
	var other = FakeHost.new(Fixtures.formal_catalog())
	other.session.begin("formal.test_walk", CLOCK, 3)
	other.session.visit("pond")
	other.session.take("formal.find.reed")
	other.session.request_return("player")
	other.persist()
	other.fail_next_saves = 1
	other.submit()
	var result: Dictionary = other.reboot()
	_check(other.grants == 0 and result["host_action"] == C.HOST_RETRY_COMMIT, "a reboot after a failed commit resumes the retry")
	other.session.retry_commit()
	other.submit()
	_check(other.grants == 1 and other.session.get_state() == C.STATE_COMMITTED, "the resumed retry grants once")
	## 提交已落盘但确认丢失：重启后直接收尾
	var lost = FakeHost.new(Fixtures.formal_catalog())
	lost.session.begin("formal.test_walk", CLOCK, 3)
	lost.session.visit("pond")
	lost.session.take("formal.find.reed")
	lost.session.request_return("player")
	lost.submit()
	var reboot: Dictionary = lost.reboot()
	_check(reboot["host_action"] == C.HOST_SUBMIT_PROPOSAL or reboot["host_action"] == C.HOST_CLOSE, "a committed trip restores to a settling action")


## 12. 出门阶段逐阶段保存失败后重启
func _stage_fault_matrix() -> void:
	for stage: String in ["visit", "take", "release", "request_return"]:
		var host = FakeHost.new(Fixtures.formal_catalog())
		var s: ExplorationSession = host.session
		s.begin("formal.test_walk", CLOCK, 3)
		host.persist()
		var saved := JSON.stringify(host.disk["exploration"])
		if stage == "release":
			s.visit("pond")
			s.take("formal.find.reed")
			host.persist()
			saved = JSON.stringify(host.disk["exploration"])
		host.fail_next_saves = 99
		match stage:
			"visit":
				s.visit("pond")
			"take":
				s.visit("pond")
				s.take("formal.find.reed")
			"release":
				s.release("formal.find.reed")
			"request_return":
				s.request_return("player")
		host.persist()
		_check(s.has_unsaved_changes() and s.get_view()["last_save_failure"] == "save_failed", "%s failure is visible as unsaved" % stage)
		host.fail_next_saves = 0
		var result: Dictionary = host.reboot()
		_check(JSON.stringify(host.disk["exploration"]) == saved, "%s reboot reads the last good save" % stage)
		_check(result["host_action"] == C.HOST_REQUEST_RETURN_RESTORED, "%s reboot goes home safely from the last active save" % stage)
		_check(host.grants == 0, "%s failure grants nothing on its own" % stage)


## 13. 保存确认：绑定会话，忽略旧、乱序、超前通知，确认不触发保存
func _acks() -> void:
	var s := ExplorationSession.new(Fixtures.catalog(), 0)
	s.begin("fixture.meadow", CLOCK, 1)
	var first_trip := s.trip_id()
	s.visit("brook")
	var revision := s.record_revision()
	_check(s.host_persisted(first_trip, revision + 1).error == "future_ack", "a future revision is ignored")
	_check(s.host_persisted("trip-77", revision).error == "stale_ack", "another trip's ack is ignored")
	_check(s.host_persisted(first_trip, revision).ok and not s.has_unsaved_changes(), "a matching ack marks the record saved")
	s.take("fixture.find.pebble")
	_check(s.host_persisted(first_trip, revision).ok and s.has_unsaved_changes(), "an out-of-order old success keeps unsaved changes")
	_check(s.host_persist_failed(first_trip, revision).ok and s.get_view()["last_save_failure"] == "", "an old failure after a newer success is ignored")
	var ack: Dictionary = s.host_persist_failed(first_trip, s.record_revision())
	_check(not ack.has("persist") and s.get_view()["last_save_failure"] == "save_failed", "failure acks never request another save")
	s.request_return("player")
	s.commit_succeeded(first_trip)
	s.close()
	s.begin("fixture.meadow", CLOCK, 2)
	_check(s.host_persisted(first_trip, 1).error == "stale_ack" and s.has_unsaved_changes(), "a late ack from the old trip cannot clear the new trip")
	var record: Dictionary = JSON.parse_string(JSON.stringify(s.to_record()))
	var restored: ExplorationSession = ExplorationSession.restore(record, Fixtures.catalog(), 1)["session"]
	_check(not restored.has_unsaved_changes(), "restore starts from the revision read from disk")


## 14. 序号不可信与隔离
func _untrusted_and_quarantine() -> void:
	var catalog := Fixtures.catalog()
	var s := ExplorationSession.new(catalog, 0)
	s.begin("fixture.meadow", CLOCK, 1)
	var active_record: Dictionary = JSON.parse_string(JSON.stringify(s.to_record()))
	var frozen := ExplorationSession.restore(active_record, catalog, C.WATERMARK_UNTRUSTED)
	_check(frozen["host_action"] == C.HOST_QUARANTINE_AND_FREEZE and not frozen["can_begin"], "an open session with an untrusted serial is frozen")
	_check(frozen["session"].visit("brook").error == "quarantine_frozen", "a frozen session refuses changes")
	var frozen_ack: Dictionary = frozen["session"].host_persisted("trip-1", 1)
	_check(frozen_ack.error == "quarantine_frozen" and not frozen_ack.unsaved_changes, "acks during quarantine change nothing")
	var trusted_frozen: ExplorationSession = ExplorationSession.restore("garbage", catalog, 0)["session"]
	_check(trusted_frozen.begin("fixture.meadow", CLOCK).error == "quarantine_frozen", "a trusted serial with a frozen record says quarantine_frozen")
	_check(frozen["session"].begin("fixture.meadow", CLOCK).error == "watermark_untrusted", "an untrusted serial takes priority over the freeze")
	for record: Variant in [null, {"contract_version": 1, "next_trip_serial": 3, "session": null}]:
		var idle := ExplorationSession.restore(record, catalog, C.WATERMARK_UNTRUSTED)
		_check(idle["host_action"] == C.HOST_FREEZE_NEW_TRIPS and not idle["can_begin"], "no session with an untrusted serial freezes new trips")
		_check(idle["session"].begin("fixture.meadow", CLOCK).error == "watermark_untrusted", "begin explains the untrusted serial")
	for record: Variant in ["garbage", {"contract_version": 2, "session": null}, {"contract_version": 1, "session": {"bad": true}}]:
		var result := ExplorationSession.restore(record, catalog, C.WATERMARK_UNTRUSTED)
		_check(result["host_action"] == C.HOST_QUARANTINE_AND_FREEZE and not result["can_begin"], "untrusted serial never unlocks a doubtful record")
	## committed 但序号超前
	s.request_return("player")
	s.commit_succeeded(s.trip_id())
	var ahead: Dictionary = JSON.parse_string(JSON.stringify(s.to_record()))
	var result := ExplorationSession.restore(ahead, catalog, 0)
	_check(result["host_action"] == C.HOST_QUARANTINE_AND_FREEZE and not result["can_begin"], "committed ahead of the watermark is quarantined")
	_check(ExplorationSession.restore(ahead, catalog, 1)["host_action"] == C.HOST_CLOSE, "committed within the watermark simply closes")
	## 冻结跨普通保存与重启保持
	var host = FakeHost.new(catalog)
	host.disk["exploration"] = "garbage"
	host.reboot()
	_check(not host.session.can_begin(), "a frozen record blocks trips after boot")
	host.persist()
	host.reboot()
	_check(not host.session.can_begin() and host.disk["exploration"] == "garbage", "a normal save and reboot keep the freeze and the original")
	var dict_host = FakeHost.new(catalog)
	dict_host.disk["exploration"] = {"contract_version": 1, "session": {"bad": true}}
	dict_host.reboot()
	dict_host.persist()
	dict_host.reboot()
	_check(not dict_host.session.can_begin(), "a frozen dictionary record also survives a save and reboot")
	var bad_serial := ExplorationSession.new(catalog, 2147483647)
	_check(bad_serial.begin("fixture.meadow", CLOCK).error == "serial_exhausted", "the serial range is enforced")


## 15. 异步提交交错：分别控制“写入开始”和“持久化确认”的时机
func _async_interleaving() -> void:
	## A 确认前重复提交同一 trip：同一身份合并为一笔
	var host = _pending_reed_host()
	_check(host.enqueue_submit(), "the first request is queued")
	_check(host.start_next().get("waiting", false), "the first request waits for persistence")
	_check(not host.enqueue_submit() and host.queue.is_empty(), "a duplicate of the in-flight identity is merged")
	_check(host.start_next().error == "busy", "the queue holds the next transaction until this one is published")
	host.finish()
	host.persist()
	host.reboot()
	_check(host.grants == 1 and host.inventory.size() == 1 and host.disk["watermark"] == 1, "a duplicate submission before confirmation grants once")
	## 即使重复请求进了队列：A 成功但回调丢失，B 在队首按新水位收尾
	var dup = _pending_reed_host()
	dup.merge_duplicates = false
	dup.enqueue_submit()
	dup.enqueue_submit()
	dup.start_next()
	_check(dup.finish(true, false).get("delivered") == false and dup.session.get_state() == C.STATE_PENDING, "A is on disk but its callback is lost")
	var b: Dictionary = dup.start_next()
	_check(b.ok and not b.has("waiting") and dup.session.get_state() == C.STATE_COMMITTED, "B re-checks the confirmed serial and settles without writing")
	dup.persist()
	dup.reboot()
	_check(dup.grants == 1 and dup.inventory.size() == 1 and dup.disk["watermark"] == 1, "A then B grants exactly once")
	## 正常合并时回调丢失：入队义务的兜底重新入队，按已确认水位收尾
	var lost = _pending_reed_host()
	lost.enqueue_submit()
	lost.start_next()
	lost.enqueue_submit()
	lost.finish(true, false)
	_check(lost.queue.size() == 1 and lost.session.get_state() == C.STATE_PENDING, "a lost callback leaves exactly one request for the current identity")
	_check(lost.start_next().ok and lost.session.get_state() == C.STATE_COMMITTED and lost.grants == 1, "the fallback request settles without granting again")
	## A 成功并回调后，排队的 B 在第 0 步被丢弃
	var late = _pending_reed_host()
	late.merge_duplicates = false
	late.enqueue_submit()
	late.enqueue_submit()
	late.start_next()
	late.finish()
	var before := JSON.stringify(late.session.to_record())
	_check(late.start_next().get("dropped", false) and JSON.stringify(late.session.to_record()) == before, "a stale request after commit is dropped without touching the session")
	_check(late.grants == 1, "the dropped request grants nothing")
	## A 失败后重试：只授予一次
	var retry = _pending_reed_host()
	retry.enqueue_submit()
	retry.start_next()
	retry.finish(false)
	_check(retry.grants == 0 and retry.watermark == 0 and retry.session.get_state() == C.STATE_FAILURE, "a failed write publishes nothing")
	retry.persist()
	retry.session.retry_commit()
	retry.enqueue_submit()
	retry.start_next()
	retry.finish()
	retry.persist()
	retry.reboot()
	_check(retry.grants == 1 and retry.inventory.size() == 1 and retry.disk["watermark"] == 1, "fail then retry grants once")
	## 等待确认期间院内有新进展：成功回调不覆盖，未保存标记保留
	var yard = _pending_reed_host()
	yard.enqueue_submit()
	yard.start_next()
	yard.change_yard("photo", "sunset")
	yard.finish()
	_check(yard.yard.get("photo") == "sunset" and yard.has_unsaved_yard(), "the success callback keeps the newer yard change unsaved")
	_check(yard.disk["yard"].get("photo") == null and yard.grants == 1, "the in-flight snapshot did not include the later change")
	yard.fail_next_saves = 1
	yard.persist()
	_check(yard.yard.get("photo") == "sunset" and yard.has_unsaved_yard(), "a failed follow-up save still keeps the change in memory")
	yard.persist()
	_check(yard.disk["yard"].get("photo") == "sunset" and not yard.has_unsaved_yard(), "the next save writes the newer change")
	yard.reboot()
	_check(yard.grants == 1 and yard.yard.get("photo") == "sunset" and yard.disk["watermark"] == 1, "reboot keeps the find once and the new yard progress")
	## 写入期间请求的保存：不并入在途快照，本笔结束后自动重排
	var deferred = _pending_reed_host()
	deferred.enqueue_submit()
	deferred.start_next()
	deferred.change_yard("photo", "rain")
	_check(not deferred.persist() and deferred.persist_pending, "a save during the write is deferred, not merged")
	_check(deferred.in_flight["candidate"]["yard"].get("photo") == null, "the in-flight candidate stays as it was built")
	deferred.finish()
	_check(not deferred.persist_pending and deferred.disk["yard"].get("photo") == "rain" and not deferred.has_unsaved_yard(), "the deferred save runs after the write with the latest memory")
	_check(deferred.disk["exploration"]["session"]["state"] == C.STATE_COMMITTED, "the rescheduled save also records the committed session")
	## 旧提案排队期间被拒绝项升版：旧身份丢弃，只按新版本提交
	var two = FakeHost.new(_two_find_catalog())
	var t: ExplorationSession = two.session
	t.begin("formal.two", CLOCK, 1)
	t.visit("a")
	t.take("formal.find.one")
	t.visit("b")
	t.take("formal.find.two")
	t.request_return("player")
	two.persist()
	two.merge_duplicates = false
	two.reject_ids = PackedStringArray(["formal.find.one"])
	two.enqueue_submit()
	two.enqueue_submit()
	two.start_next()
	_check(t.get_proposal()["revision"] == 2 and two.grants == 0, "the rejection bumps the proposal revision")
	var stale_before := JSON.stringify(t.to_record())
	_check(two.start_next().get("dropped", false) and JSON.stringify(t.to_record()) == stale_before, "the old revision's request is dropped")
	_check(two.queue.size() == 1 and int(two.queue[0]["revision"]) == 2, "the new revision was enqueued by the host")
	two.persist()
	two.start_next()
	two.finish()
	two.persist()
	two.reboot()
	_check(two.grants == 1 and two.inventory == ["formal.find.two"] and two.disk["watermark"] == 1, "only the new revision is committed")


## 16. 回院导航：回院不等持久化；结果未知期间保持待提交、不发确认、不放行
func _return_navigation() -> void:
	var host = FakeHost.new(Fixtures.formal_catalog())
	var s: ExplorationSession = host.session
	host.set_out("formal.test_walk", CLOCK, 3)
	_check(not host.at_home, "setting out leaves the yard")
	s.visit("pond")
	s.take("formal.find.reed")
	host.persist()
	host.go_home()
	var proposal := s.get_proposal()
	_check(host.at_home and s.get_state() == C.STATE_PENDING and host.grants == 0, "the player is home at once while the commit waits")
	host.go_home()
	host.go_home()
	_check(host.return_calls == 1 and host.queue.size() == 1, "repeated return taps only navigate")
	_check(s.get_proposal() == proposal, "repeated return taps keep the trip and proposal revision")
	host.start_next()
	host.finish_unknown(false)
	_check(s.get_state() == C.STATE_PENDING and s.begin("formal.test_walk", CLOCK).error == "pending_exists", "an unknown result keeps the trip open and blocks new trips")
	_check(s.get_proposal() == proposal and host.grants == 0, "an unknown result keeps the proposal and grants nothing")
	host.change_yard("photo", "dusk")
	_check(not host.persist() and host.start_next().error == "busy", "an unknown result holds every later write")
	_check(host.finish().error == "unknown", "an unknown write cannot be finished as a plain success")
	var record_before := s.record_revision()
	_check(s.visit("pond").error == "illegal_transition" and s.record_revision() == record_before, "the old view cannot change the pending session")	## 核验后确定未落盘：按明确失败回到可重试，再提交只授予一次
	host.resolve_unknown()
	_check(s.get_state() == C.STATE_FAILURE and host.grants == 0, "a verified non-landing becomes a retryable failure")
	s.retry_commit()
	host.enqueue_submit()
	host.start_next()
	host.finish()
	_check(host.grants == 1 and host.disk["yard"].get("photo") == "dusk", "the retry grants once and the deferred yard save follows")
	## 迟到成功：其实已落盘，核验后只发布一次
	var late = _pending_reed_host()
	late.go_home()
	late.enqueue_submit()
	late.start_next()
	late.finish_unknown(true)
	_check(late.grants == 0 and late.session.get_state() == C.STATE_PENDING, "a landed but unknown write publishes nothing yet")
	late.resolve_unknown()
	late.persist()
	late.reboot()
	_check(late.grants == 1 and late.inventory.size() == 1 and late.disk["watermark"] == 1, "a late success publishes the find once")
	## 未知后重启：无法核验 → 隔离冻结；核验可信后再 restore 正常收尾
	var boot = _pending_reed_host()
	boot.enqueue_submit()
	boot.start_next()
	boot.finish_unknown(true)
	var frozen: Dictionary = boot.reboot(false)
	_check(frozen["host_action"] == C.HOST_QUARANTINE_AND_FREEZE and not frozen["can_begin"] and boot.at_home, "an unverifiable restart quarantines in the yard")
	boot.persist()
	var thawed: Dictionary = boot.reboot(true)
	_check(thawed["host_action"] == C.HOST_CLOSE and boot.inventory.size() == 1, "a later trusted restore settles without granting again")
	var lost = _pending_reed_host()
	lost.enqueue_submit()
	lost.start_next()
	lost.finish_unknown(false)
	lost.reboot(false)
	lost.persist()
	var retried: Dictionary = lost.reboot(true)
	_check(retried["host_action"] == C.HOST_SUBMIT_PROPOSAL, "a trusted restore after a non-landing resubmits the same proposal")
	lost.submit()
	_check(lost.inventory.size() == 1 and lost.disk["watermark"] == 1, "the resubmission grants once")


func _pending_reed_host():
	var host = FakeHost.new(Fixtures.formal_catalog())
	host.session.begin("formal.test_walk", CLOCK, 3)
	host.session.visit("pond")
	host.session.take("formal.find.reed")
	host.session.request_return("player")
	host.persist()
	return host


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
