extends SceneTree
const Host := preload("res://scripts/game/meal_audio_host.gd")
class Room extends RefCounted:
	var stage := ""
	func busy() -> bool: return not stage.is_empty()
class World extends Node2D:
	var house := Room.new()
	var holiday_day := 2
	var fraction := 0.16
	func tod_fraction() -> float: return fraction
class Store extends Node:
	var idle := true
	var ledger := {"receipts": []}
	func is_save_idle() -> bool: return idle
	func get_meal_ledger() -> Dictionary: return ledger
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated.trim_suffix("/") + "/"):
		quit(2)
		return
	var world := World.new()
	var store := Store.new()
	var host := Host.new()
	root.add_child(world)
	root.add_child(store)
	root.add_child(host)
	await process_frame
	for stage in ["", "take", "porch", "open", "in", "close", "cook", "saving", "balcony", "wake", "out"]:
		world.house.stage = stage
		host.sync(world, store, true, false, true)
		check(host.leaf.is_cooking() == (stage == "cook"), "loop only cook: " + stage)
	world.house.stage = "cook"
	host.sync(world, store, true, false, true)
	check(host.leaf.is_cook_playing(), "live cook starts")
	host.sync(world, store, true, true, true)
	check(not host.leaf.is_cook_playing(), "menu pauses cook")
	host.sync(world, store, true, false, false)
	check(not host.leaf.is_cook_playing(), "unlock deny survives unpause")
	host.sync(world, store, true, false, true)
	check(host.leaf.is_cook_playing(), "allowed resumes active loop")
	host.suspend()
	check(not host.leaf.is_cook_playing(), "focus loss immediately stops")
	world.house.stage = ""
	# Hearing batch13 is rejected: no meal edge may dispatch this asset.
	# Keep receipt/clock cases so a future replacement retains their coverage.
	for end_hour in [10.0, 15.0, 21.0]:
		var before: float = (end_hour - 6.0) / 24.0 - 0.001
		var after: float = before + 0.002
		for scenario in ["missed", "eaten", "pending", "invalid", "paused", "denied", "reopen", "jump", "newday"]:
			host.suspend()
			# Cases jump between meal times; do not let the leaf's real-time
			# 350ms cue throttle couple otherwise independent clock fixtures.
			host.leaf._last_hunger_at = -INF
			store.idle = scenario != "pending"
			store.ledger = {"receipts": []}
			world.holiday_day = 2
			world.fraction = before
			host.sync(world, store, true, false, true)
			if scenario == "eaten": store.ledger.receipts.append({"day":2,"meal":host.last_meal,"earned":0})
			if scenario == "invalid": store.ledger = {}
			if scenario == "reopen": host.suspend()
			if scenario == "newday": world.holiday_day = 3
			world.fraction = after + (0.1 if scenario == "jump" else 0.0)
			var count: int = host.missed_count
			host.sync(world, store, true, scenario == "paused", scenario != "denied")
			check(host.missed_count == count, "meal edge " + str(end_hour) + ":" + scenario)
			store.idle = true
			host.sync(world, store, true, false, true)
			check(host.missed_count == count, "edge never repeats")
			# Real short-cue cooldown is wall-clock based; space independent cases.
			if scenario == "missed": await create_timer(0.4).timeout
	check(host.leaf.hunger_play_count == 0, "rejected batch13 never reaches audio playback")
	host.queue_free()
	world.queue_free()
	store.queue_free()
	await process_frame
	print("MEAL_AUDIO_HOST checks=%d failures=%d" % [checks, failures.size()])
	for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
