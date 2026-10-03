extends Node
## REQ-20261003-024: under reduced motion, keep unreachable-tap arcs readable
## without rewriting YardWorld._draw. YardWorld fades with
## minf(1, remaining/0.35)*0.80 — holding remaining at >= 0.35 until the
## original cue lifetime ends matches BoundaryFeedback.pose(..., true).

const _YARD_SCRIPT := preload("res://scripts/game/yard_world.gd")

var _end_msec: int = -1
var _watching: Node = null

func _ready() -> void:
	# Run after YardWorld's decay so the clamp sticks for the draw pass.
	process_priority = 1000

func _process(_delta: float) -> void:
	if not bool(TuningStore.get_value("ui.reduced_motion", false)):
		_clear()
		return
	var yw := _find_yard()
	if yw == null:
		_clear()
		return
	var rem := float(yw.get("_rejected_seconds"))
	if rem <= 0.0:
		_clear()
		return
	# New or refreshed cue (YardWorld sets ~1.2); keep end time locked while held at 0.35.
	if _watching != yw or _end_msec < 0 or rem >= 1.0:
		_watching = yw
		_end_msec = Time.get_ticks_msec() + int(ceil(rem * 1000.0))
	if Time.get_ticks_msec() < _end_msec:
		if rem < 0.35:
			yw.set("_rejected_seconds", 0.35)
		if yw.has_method("queue_redraw"):
			yw.queue_redraw()
	else:
		yw.set("_rejected_seconds", 0.0)
		if yw.has_method("queue_redraw"):
			yw.queue_redraw()
		_clear()

func _clear() -> void:
	_end_msec = -1
	_watching = null

func _find_yard() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return _find_recursive(scene)

func _find_recursive(n: Node) -> Node:
	if n != null and n.get_script() == _YARD_SCRIPT:
		return n
	for c in n.get_children():
		var found := _find_recursive(c)
		if found != null:
			return found
	return null
