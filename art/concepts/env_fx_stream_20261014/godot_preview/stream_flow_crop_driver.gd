extends Node2D

# #749 溪流裁切版隔离 demo 驱动。仍只是候选：不碰主游戏、存档、导航或生产宿主文件。
## 画面结构仿近郊宿主：Painting 是整幅原画，StreamCrop 是挂在它下面的 183×302 溪床子层。
## phase 是弧度 0→TAU，一圈 8 秒：phase = fposmod(phase + max(delta, 0) * TAU / 8, TAU)。
## 不复用现有近郊动效的 0.42 rad/s，也不用内置 TIME。
## 暂停：phase 冻结。减少动态：撤掉子层（隐藏），只剩原画静帧，phase 冻结。
## strength 0 时子层整层透明，同样只剩原画。
## 线性过滤 / 缩放：--scale 把整幅 Painting（含子层）按比例缩放，用于观察不同分辨率下的采样；
## 控制图与底图采样方式见 shader 头注释（detail/ripple 已 linear，其余 nearest）。

const PERIOD_SEC := 8.0
const CROP_RECT := Rect2i(191, 543, 183, 302)

var phase: float = 0.0
var paused: bool = false
var reduced_motion: bool = false
var scale_factor: float = 1.0

var _dump_path: String = ""
var _dump_started: bool = false
var _self_check: bool = false

@onready var _painting: Sprite2D = $Painting
@onready var _crop: Sprite2D = $Painting/StreamCrop


func _ready() -> void:
	_parse_user_args()
	_crop.position = Vector2(CROP_RECT.position)
	_painting.scale = Vector2(scale_factor, scale_factor)
	_apply_motion()
	_push_phase()
	print("Stream crop demo ready. phase=", phase, " paused=", paused, " reduced=", reduced_motion,
		" strength=", _material().get_shader_parameter("strength"), " crop=", CROP_RECT,
		" scale=", scale_factor)
	if _self_check:
		_run_self_check()


func _material() -> ShaderMaterial:
	return _crop.material as ShaderMaterial


func step_phase(delta: float) -> float:
	if paused or reduced_motion:
		return 0.0
	var before := phase
	phase = fposmod(phase + maxf(delta, 0.0) * TAU / PERIOD_SEC, TAU)
	return phase - before


func _process(delta: float) -> void:
	if step_phase(delta) != 0.0:
		_push_phase()
	if _dump_path != "" and not _dump_started:
		_dump_started = true
		_dump_and_quit()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := event as InputEventKey
	if key.keycode == KEY_P or key.keycode == KEY_SPACE:
		paused = not paused
	elif key.keycode == KEY_R:
		reduced_motion = not reduced_motion
		_apply_motion()
	elif key.keycode == KEY_BRACKETLEFT:
		scale_factor = maxf(0.25, scale_factor - 0.25)
		_painting.scale = Vector2(scale_factor, scale_factor)
	elif key.keycode == KEY_BRACKETRIGHT:
		scale_factor = minf(3.0, scale_factor + 0.25)
		_painting.scale = Vector2(scale_factor, scale_factor)


func _apply_motion() -> void:
	# 与生产既有减少动态一致：撤掉动效层，回到原画静态，不把 strength 0.20 当默认。
	_crop.visible = not reduced_motion


func _push_phase() -> void:
	_material().set_shader_parameter("phase", phase)


func _parse_user_args() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		var token := str(args[i])
		if token == "--dump-frame" and i + 1 < args.size():
			_dump_path = str(args[i + 1])
			paused = true
			i += 2
		elif token == "--phase" and i + 1 < args.size():
			phase = float(args[i + 1])
			paused = true
			i += 2
		elif token == "--strength" and i + 1 < args.size():
			_material().set_shader_parameter("strength", float(args[i + 1]))
			i += 2
		elif token == "--scale" and i + 1 < args.size():
			scale_factor = float(args[i + 1])
			i += 2
		elif token == "--reduced":
			reduced_motion = true
			i += 1
		elif token == "--self-check":
			_self_check = true
			i += 1
		else:
			i += 1


func _run_self_check() -> void:
	var ok := true
	var eps := 0.000001
	phase = 0.0; paused = false; reduced_motion = false
	var normal := step_phase(0.1)
	ok = ok and absf(normal - TAU / PERIOD_SEC * 0.1) < eps
	phase = 1.0
	var back := step_phase(-0.5)
	ok = ok and back == 0.0 and phase == 1.0
	phase = TAU - 0.01
	step_phase(0.1)
	ok = ok and phase >= 0.0 and phase < TAU
	phase = 0.5; paused = true
	ok = ok and step_phase(0.1) == 0.0 and phase == 0.5
	paused = false; reduced_motion = true; _apply_motion()
	ok = ok and step_phase(0.1) == 0.0 and not _crop.visible
	reduced_motion = false; _apply_motion()
	ok = ok and _crop.visible
	var tex_size := _crop.texture.get_size()
	ok = ok and Vector2i(tex_size) == CROP_RECT.size
	ok = ok and Vector2i(_crop.position) == CROP_RECT.position
	print("crop self-check normal=", normal, " back=", back, " tex=", tex_size, " ok=", ok)
	if not ok:
		push_error("crop demo self-check failed")
	get_tree().quit(0 if ok else 1)


func _dump_and_quit() -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(_dump_path)
	print("dump ", _dump_path, " err ", err, " size ", image.get_size(), " phase ", phase)
	get_tree().quit()
