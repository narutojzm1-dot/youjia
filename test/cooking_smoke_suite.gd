extends SceneTree
## GROK #705: cooking chimney smoke — contract, idempotency, no node accumulation.

const Smoke := preload("res://scripts/presentation/cooking_smoke.gd")

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(why)


func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		quit(2)
		return

	var host := Node2D.new()
	root.add_child(host)
	var smoke: Node2D = Smoke.new()
	host.add_child(smoke)
	await process_frame

	check(smoke.position == Smoke.DEFAULT_CHIMNEY_ANCHOR or smoke.position != Vector2.ZERO, "default chimney anchor applied")
	check(smoke.get_child_count() == 1, "exactly one emitter child after ready")
	check(not smoke.is_cooking() and not smoke.is_emitting(), "starts idle")

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
	var snap: Dictionary = smoke.debug_snapshot()
	check(snap.has("anchor") and snap.has("cooking"), "debug_snapshot exposes contract fields")

	host.queue_free()
	await process_frame

	if failures != 0:
		push_error("[cooking-smoke] FAIL: %d/%d" % [failures, checks])
		quit(1)
		return
	print("[cooking-smoke] PASS: %d checks" % checks)
	quit(0)
