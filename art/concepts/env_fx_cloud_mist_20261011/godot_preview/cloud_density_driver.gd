extends Node2D

# 隔离预览驱动：只推进 phase，不碰主游戏、存档或导航。
## phase 从 0 走到 2π 用 8 秒，对应生成脚本 40 帧 @ 5fps。
## 暂停时停止累加；低动效把速度降到 0.25 倍，仍然在动。

const PERIOD_SEC := 8.0
const LOW_MOTION_SCALE := 0.25
const FRAME_COUNT := 40.0

var phase: float = 0.0
var paused: bool = false
var low_motion: bool = false

var _dump_path: String = ""
var _dump_started: bool = false
var _self_check: bool = false
var _keep_ui: bool = false
var _button_text_ready: bool = false
var _shown_paused: bool = false
var _shown_low_motion: bool = false

@onready var _preview: CanvasItem = $Preview
@onready var _ui: CanvasLayer = $UI
@onready var _pause_button: Button = $UI/Panel/VBox/Buttons/PauseButton
@onready var _low_button: Button = $UI/Panel/VBox/Buttons/LowMotionButton
@onready var _status: Label = $UI/Panel/VBox/Status


func _ready() -> void:
	_parse_user_args()
	_apply_ui_font()
	_pause_button.pressed.connect(_toggle_paused)
	_low_button.pressed.connect(_toggle_low_motion)
	if _dump_path != "":
		## 对照 PNG 时藏起按钮。--keep-ui 留给视口截图。
		if not _keep_ui:
			_ui.visible = false
		paused = true
	_push_phase()
	_refresh_status()
	print("Cloud density preview ready. phase=", phase, " paused=", paused, " low_motion=", low_motion)
	print("window ", DisplayServer.window_get_size(), " viewport ", get_viewport().get_visible_rect().size)
	if _self_check:
		_run_motion_self_check()


func _advance(delta: float) -> float:
	## 暂停返回 0。低动效只走正常速度的 0.25。同时打开时暂停优先。
	if paused:
		return 0.0
	var speed := TAU / PERIOD_SEC
	if low_motion:
		speed *= LOW_MOTION_SCALE
	var step := speed * delta
	phase = fposmod(phase + step, TAU)
	return step


func _process(delta: float) -> void:
	if _advance(delta) != 0.0:
		_push_phase()
	_refresh_status()
	if _dump_path != "" and not _dump_started:
		_dump_started = true
		_dump_and_quit()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := event as InputEventKey
	if key.keycode == KEY_P or key.keycode == KEY_SPACE:
		_toggle_paused()
	elif key.keycode == KEY_L:
		_toggle_low_motion()


func _toggle_paused() -> void:
	paused = not paused
	_refresh_status()


func _toggle_low_motion() -> void:
	low_motion = not low_motion
	_refresh_status()


func _push_phase() -> void:
	var mat := _preview.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("phase", phase)


func _refresh_status() -> void:
	if _pause_button == null:
		return
	## 按钮文字只在开关变化时改，避免每帧重设文本打断点击。
	if not _button_text_ready or paused != _shown_paused or low_motion != _shown_low_motion:
		_button_text_ready = true
		_shown_paused = paused
		_shown_low_motion = low_motion
		_pause_button.text = "继续 Resume (P)" if paused else "暂停 Pause (P)"
		_low_button.text = "低动效 开 LowOn (L)" if low_motion else "低动效 关 LowOff (L)"
	var motion := "暂停 stopped" if paused else ("低动效 ×0.25" if low_motion else "正常 8s / 2π")
	_status.text = "phase %.3f / %.3f   %s" % [phase, TAU, motion]


func _apply_ui_font() -> void:
	## 优先用系统里的中文字体；没有时拉丁按键说明仍然可读。
	var font := SystemFont.new()
	font.font_names = PackedStringArray([
		"Noto Sans CJK SC",
		"Noto Sans SC",
		"Source Han Sans SC",
		"Microsoft YaHei",
		"PingFang SC",
		"WenQuanYi Micro Hei",
		"Droid Sans Fallback",
	])
	var theme := Theme.new()
	theme.default_font = font
	theme.set_font_size("font_size", "Button", 42)
	theme.set_font_size("font_size", "Label", 36)
	$UI/Panel.theme = theme


func _parse_user_args() -> void:
	## 仅供对照截帧：--dump-frame 路径 --phase-frame 10
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		var token := str(args[i])
		if token == "--dump-frame" and i + 1 < args.size():
			_dump_path = str(args[i + 1])
			i += 2
		elif token == "--phase" and i + 1 < args.size():
			phase = float(args[i + 1])
			paused = true
			i += 2
		elif token == "--phase-frame" and i + 1 < args.size():
			phase = float(args[i + 1]) / FRAME_COUNT * TAU
			paused = true
			i += 2
		elif token == "--self-check":
			_self_check = true
			i += 1
		elif token == "--keep-ui":
			_keep_ui = true
			i += 1
		else:
			i += 1


func _run_motion_self_check() -> void:
	## 用固定 delta 检查暂停是否停住、低动效是否只走四分之一。
	var delta := 0.1
	phase = 0.0
	paused = false
	low_motion = false
	var normal := _advance(delta)
	phase = 0.0
	paused = true
	low_motion = false
	var held := _advance(delta)
	var held_phase := phase
	phase = 0.0
	paused = false
	low_motion = true
	var slow := _advance(delta)
	var ok := absf(normal - TAU / PERIOD_SEC * delta) < 0.000001
	ok = ok and held == 0.0 and held_phase == 0.0
	ok = ok and absf(slow - normal * LOW_MOTION_SCALE) < 0.000001
	print("motion self-check normal=", normal, " held=", held, " slow=", slow, " ok=", ok)
	if not ok:
		push_error("pause/low_motion self-check failed")
	get_tree().quit(0 if ok else 1)


func _dump_and_quit() -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(_dump_path)
	print("dump ", _dump_path, " err ", err, " size ", image.get_size(), " phase ", phase)
	get_tree().quit()
