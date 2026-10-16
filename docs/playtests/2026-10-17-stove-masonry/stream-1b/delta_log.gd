extends Node
# Agent-ID: GROK-BUILD — #749 启动帧核对用的临时 autoload（只在 /tmp 临时工程副本里通过 override.cfg 挂载，不改 godot_preview/）。
# process_priority 很大，保证在场景驱动 _process 之后读 phase；每帧打印一行 DELTA_LOG JSON。
var _k := 0

func _ready() -> void:
	process_priority = 100000
	print("DELTA_LOG_CFG ", JSON.stringify({
		"physics_jitter_fix": ProjectSettings.get_setting("physics/common/physics_jitter_fix"),
		"physics_ticks_per_second": ProjectSettings.get_setting("physics/common/physics_ticks_per_second"),
		"max_fps": Engine.max_fps, "write_movie": OS.get_cmdline_args().has("--write-movie")}))

func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	var ph = scene.get("phase") if scene != null else null
	print("DELTA_LOG ", JSON.stringify({"frame": _k, "delta": delta, "phase": ph,
		"frames_drawn": Engine.get_frames_drawn(), "process_frames": Engine.get_process_frames(),
		"physics_frames": Engine.get_physics_frames()}))
	_k += 1
