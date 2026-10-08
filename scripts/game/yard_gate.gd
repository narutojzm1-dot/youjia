extends Node2D
## Persist first; geometry and art change together only on a confirmed receipt.
const Ground := preload("res://scripts/game/yard_gate_ground.gd")
var opened := false
var pending := ""
var world: Node2D
var store: Node

func _init(owner_world: Node2D, save_store: Node, initial: bool) -> void:
	world = owner_world
	store = save_store
	opened = initial
	store.commit_confirmed.connect(_confirmed)
	store.commit_rejected.connect(_rejected)

func toggle() -> void:
	if not pending.is_empty(): return
	if opened and threshold_occupied():
		world.notice_requested.emit("notice.gate_occupied")
		return
	pending = store.request_yard_gate(not opened)
	if pending.is_empty(): world.notice_requested.emit("notice.gate_save_wait")

func threshold_occupied() -> bool:
	for body: Dictionary in world.physical_obstacles(""):
		var radius: Vector2 = body.radius
		if Ground.THRESHOLD.grow_individual(radius.x, radius.y, radius.x, radius.y).has_point(body.position): return true
	return false

func _confirmed(op_id: String, _kind: String) -> void:
	if op_id != pending: return
	pending = ""
	opened = store.get_yard_gate_open()
	world.get_player().walk_ground = world.player_ground()
	world._walk_path.clear()
	world._has_walk_goal = false
	world.notice_requested.emit("notice.gate_open" if opened else "notice.gate_closed")
	world._apply_weather_art()

func _rejected(op_id: String, _kind: String, _code: String) -> void:
	if op_id == pending: pending = ""
