extends Node
## Live presentation only. Completion truth remains in the shared meal ledger.
## Hearing batch 2026-10-11: #13 rejected by user on 2026-10-12.
## Keep observing meal edges, but do not dispatch the unapproved recording.
const HUNGER_AUDIO_APPROVED := false
const Schedule := preload("res://scripts/game/meal_schedule.gd")
var leaf: Node
var last_day := -1
var last_fraction := -1.0
var last_meal := ""
var missed_count := 0

func _ready() -> void:
	if leaf == null:
		leaf = preload("res://scripts/presentation/meal_audio.gd").new()
		add_child(leaf)

func suspend() -> void:
	if leaf != null:
		leaf.set_playback_allowed(false)
	last_day = -1
	last_meal = ""

func sync(world: Node2D, store: Node, active: bool, blocked: bool, allowed: bool) -> void:
	leaf.set_paused(blocked or not active)
	leaf.set_playback_allowed(active and allowed)
	var cooking: bool = active and world != null and world.house.stage == "cook"
	leaf.set_cooking(cooking)
	if not active or blocked or not allowed or world == null:
		last_day = -1
		last_meal = ""
		return
	var day: int = world.holiday_day
	var fraction: float = world.tod_fraction()
	var meal := Schedule.meal_at(fraction)
	# Observe an actual continuous live crossing; load/sleep/time jumps do not
	# retroactively create hunger, nor do pause/scene resume replay old cues.
	var crossed := day == last_day and not last_meal.is_empty() and meal != last_meal and fraction >= last_fraction and fraction - last_fraction < 0.02
	var prior_meal := last_meal
	last_day = day
	last_fraction = fraction
	last_meal = meal
	if not crossed or world.house.busy() or not store.is_save_idle(): return
	var ledger: Dictionary = store.get_meal_ledger()
	if ledger.is_empty(): return # unknown/invalid truth is not a missed meal
	for receipt: Dictionary in ledger.receipts:
		if int(receipt.day) == day and str(receipt.meal) == prior_meal: return
	# A fatigued breakfast earns zero but still has a receipt: never use AP here.
	if HUNGER_AUDIO_APPROVED and leaf.play_hunger(): missed_count += 1
