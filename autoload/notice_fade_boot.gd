extends Node

## REQ-20261008-075: fade the bottom paper notice in/out without editing
## `scripts/main.gd` (other agents touch that file for music / save / HUD).
## Same node_added pattern as PaperSliderBoot. Tracks age locally from the
## owned remaining clock on Main; paper colour, keys, pause hide and durations
## stay with Main.

const FADE := preload("res://scripts/ui/notice_fade.gd")

var _host: Node = null
var _age := 0.0
var _prev_remaining := -1.0
var _prev_key := ""


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if _host != null:
		return
	if node is Label:
		call_deferred("_try_bind_from_label", node)


func _try_bind_from_label(label: Label) -> void:
	if _host != null or not is_instance_valid(label):
		return
	var host: Node = label
	while host != null and not _is_notice_host(host):
		host = host.get_parent()
	if host != null:
		_host = host


func _is_notice_host(node: Node) -> bool:
	return ("_notice" in node) and ("_notice_time" in node) and ("_notice_key" in node)


func _process(delta: float) -> void:
	if _host == null or not is_instance_valid(_host):
		_host = null
		return
	var notice: Label = _host.get("_notice") as Label
	if notice == null:
		return
	var remaining := float(_host.get("_notice_time"))
	var key := str(_host.get("_notice_key"))
	if remaining > 0.0 and _prev_remaining <= 0.0:
		_age = 0.0
	elif key != _prev_key and remaining > 0.0:
		_age = 0.0
	_prev_key = key
	if remaining > 0.0 and notice.visible:
		_age += delta
	_prev_remaining = remaining
	var reduced := bool(TuningStore.get_value("ui.reduced_motion", false))
	if notice.visible:
		notice.modulate.a = FADE.alpha(remaining, _age, reduced)
	else:
		notice.modulate.a = 1.0


## Test helper: age tracked for the current notice (0 when none).
func notice_age() -> float:
	return _age
