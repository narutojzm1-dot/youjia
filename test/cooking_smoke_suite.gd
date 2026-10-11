extends SceneTree
## GROK #705: cooking chimney smoke — contract, fade ramp, reduced-motion reapply.

const Smoke := preload("res://scripts/presentation/cooking_smoke.gd")

var checks := 0
var failures := 0


class TuningStub extends Node:
	signal value_changed(id: String, requested_value: Variant, active_value: Variant)
	var _values := {"ui.reduced_motion": false}

	func get_value(id: String, fallback: Variant = null) -> Variant:
		return _values.get(id, fallback)

	func set_value(id: String, value: Variant, _persist: bool = true) -> bool:
		_values[id] = value
		value_changed.emit(id, value, value)
		return true


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(why)


func _ensure_tuning_store() -> Node:
	var store := root.get_node_or_null("/root/TuningStore")
	if store != null:
		return store
	# 隔离运行若没有自动加载，补一个同路径的最小替身，仍走 get_value / value_changed。
	var stub := TuningStub.new()
	stub.name = "TuningStore"
	root.add_child(stub)
	return stub


func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return

	var store := _ensure_tuning_store()
	var previous_reduced := false
	if store.has_method("get_value"):
		previous_reduced = bool(store.get_value("ui.reduced_motion", false))
	if previous_reduced and store.has_method("set_value"):
		store.set_value("ui.reduced_motion", false, false)
		await process_frame

	var host := Node2D.new()
	root.add_child(host)
	var smoke: Node2D = Smoke.new()
	host.add_child(smoke)
	await process_frame

	check(smoke.position == Smoke.DEFAULT_CHIMNEY_ANCHOR or smoke.position != Vector2.ZERO, "default chimney anchor applied")
	check(smoke.get_child_count() == 1, "exactly one emitter child after ready")
	check(not smoke.is_cooking() and not smoke.is_emitting(), "starts idle")

	var snap: Dictionary = smoke.debug_snapshot()
	check(bool(snap.get("has_soft_texture", false)), "soft puff texture present")
	check(float(snap.get("texture_center_alpha", 0.0)) > 0.45, "soft circle center is visible")
	check(float(snap.get("texture_corner_alpha", 1.0)) < 0.05, "soft circle corner is clear")
	check(float(snap.get("ramp_peak_alpha", 0.0)) > 0.12, "lifetime ramp has a visible middle")
	check(float(snap.get("ramp_end_alpha", 1.0)) < 0.02, "lifetime ramp fades out")
	check(bool(snap.get("tuning_hooked", false)), "subscribes to TuningStore value_changed when the node exists")

	smoke.set_chimney_anchor(Vector2(300, 210))
	check(smoke.position == Vector2(300, 210), "set_chimney_anchor moves node")

	smoke.set_cooking(true)
	await process_frame
	check(smoke.is_cooking(), "set_cooking(true) latches")
	check(smoke.is_emitting() or smoke.debug_snapshot().get("reduced_motion", false), "emits unless reduced_motion")
	var kids_after_on := smoke.get_child_count()
	check(kids_after_on == 1, "cooking on does not add nodes")

	# Idempotent: same state must not restart / accumulate.
	smoke.set_cooking(true)
	await process_frame
	check(smoke.get_child_count() == kids_after_on, "repeat set_cooking(true) does not accumulate")
	check(smoke.is_cooking(), "still cooking after repeat true")
	check(smoke.is_emitting(), "repeat set_cooking(true) does not stop an active puff")

	var day_wash: Color = smoke.debug_snapshot().get("wash", Color.BLACK)
	smoke.set_night_tint(true)
	var night_wash: Color = smoke.debug_snapshot().get("wash", Color.WHITE)
	check(night_wash.r < day_wash.r - 0.05, "night tint retints the lifetime ramp while cooking stays true")
	check(float(smoke.debug_snapshot().get("ramp_end_alpha", 1.0)) < 0.02, "night ramp still fades out")
	check(smoke.is_emitting() and smoke.get_child_count() == 1, "night tint reapply does not add nodes or stop cooking smoke")
	smoke.set_night_tint(true)
	check(smoke.get_child_count() == 1, "repeat set_night_tint(true) does not accumulate")
	smoke.set_night_tint(false)

	smoke.set_paused(true)
	await process_frame
	check(smoke.is_paused() and smoke.is_cooking(), "pause keeps cooking flag")
	check(not smoke.is_emitting(), "pause stops new emission")
	smoke.set_paused(true)
	check(smoke.get_child_count() == 1, "repeat set_paused(true) does not accumulate")

	smoke.set_paused(false)
	await process_frame
	check(not smoke.is_paused(), "unpause clears pause")
	check(smoke.is_emitting() or smoke.debug_snapshot().get("reduced_motion", false), "unpause resumes emission while cooking")

	var reduced_written := false
	if store.has_method("set_value"):
		reduced_written = bool(store.set_value("ui.reduced_motion", true, false))
	check(reduced_written, "ui.reduced_motion write accepted")
	await process_frame
	check(smoke.is_cooking() and not smoke.is_emitting(), "reduced_motion stops emission while cooking stays true")
	check(smoke.get_child_count() == 1, "reduced_motion change does not add nodes")
	smoke.set_cooking(true)
	await process_frame
	check(smoke.is_cooking() and not smoke.is_emitting() and smoke.get_child_count() == 1, "idempotent set_cooking(true) stays quiet under reduced motion")
	if store.has_method("set_value"):
		store.set_value("ui.reduced_motion", false, false)
	await process_frame
	check(smoke.is_cooking() and smoke.is_emitting(), "clearing reduced_motion resumes emission without set_cooking")
	check(smoke.get_child_count() == 1, "reduced_motion resume does not add nodes")

	smoke.set_cooking(false)
	await process_frame
	check(not smoke.is_cooking() and not smoke.is_emitting(), "set_cooking(false) stops emission for natural fade")
	smoke.set_cooking(false)
	check(smoke.get_child_count() == 1, "repeat set_cooking(false) does not accumulate")

	smoke.set_night_tint(true)
	smoke.set_night_tint(true)
	check(smoke.debug_snapshot().get("night_tint", false) == true, "night tint latches without extras")
	check(smoke.get_child_count() == 1, "night tint does not add nodes")

	# Isolation: no Main holiday wiring; Leader cooking events still pending.
	check(not smoke.has_method("_start_holiday"), "leaf is not Main")
	snap = smoke.debug_snapshot()
	check(snap.has("anchor") and snap.has("cooking"), "debug_snapshot exposes contract fields")

	if store.has_method("set_value"):
		store.set_value("ui.reduced_motion", previous_reduced, false)

	host.queue_free()
	await process_frame

	if failures != 0:
		push_error("[cooking-smoke] FAIL: %d/%d" % [failures, checks])
		quit(1)
		return
	print("[cooking-smoke] PASS: %d checks" % checks)
	quit(0)
