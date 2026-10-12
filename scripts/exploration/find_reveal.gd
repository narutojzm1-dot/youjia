class_name FindReveal
extends Node2D
# 拾起成功后的短展示（docs/architecture/exploration-find-reveal.md）：物件从路边升到人物上方停一下，
# 再飞进提篮，同时一声原创短音。只是表现：核心状态在调用前已经改变，打断时立即收尾，不影响提交。
# 时长与尺寸都是等用户看过再调的候选值。

# 用户2026-10-12批准听验16；原PR359 WAV逐字节接入，不合成或替换缺件。
const SOUND_PATH := "res://assets/holiday/audio/exploration_find_get.wav"
const RISE := 0.35
const HOLD := 0.9
const FLY := 0.4
const CALM_IN := 0.3
const CALM_HOLD := 0.6
const CALM_OUT := 0.3
const SHOW_SIZE := 2.6
const HALO := 56.0
const LABEL_ROOM := 32.0
const INK := Color("5b4637")
# 展示圆片用稍深的低饱和暖灰并接近不透明：白羽毛不再贴着浅底，路面纹理也透不上来
const DISC := Color(0.76, 0.72, 0.66)
# REQ-20261007-053：名字原来画在一块直角、85% 透明的浅黄方块上，路面纹理会透上来，
# 也和看景字幕、悬停提示的圆角暖纸不是一套。改成同款暖纸小签：近不透明 PAPER、
# 1px 柔棕边、8px 圆角、淡墨投影；字按字体上下沿居中。位置、字号、何时出现与淡出不变。
const PaperTooltipStyle := preload("res://scripts/ui/paper_tooltip_style.gd")
const NAME_SIZE := 17
const NAME_PAD := Vector2(9.0, 3.0)
# 纸签下沿离物件中心 HALO+2：不压展示圆片；上沿（含投影）仍在 near_path_scroll 预留的 LABEL_ROOM 里
const NAME_GAP := 2.0
const NAME_SHADOW := Vector2(0.0, 2.0)
const NAME_SHADOW_SIZE := 3
# REQ-20261008-073：名字纸签原来在光晕过半那一帧以半透明整块冒出、飞向篮子时又在半透明处整块消失。
# 现在光晕 0.5→1 之间名字从透明淡到全显，飞走时对称淡尽；何时出现（光晕 > 0.5）、停留全显、低动效都不变。
const NAME_FADE_FROM := 0.5

signal settled(find_id: String)

var find_id := ""
var calm := false
var elapsed := 0.0
var from := Vector2.ZERO
var top := Vector2.ZERO
var basket := Vector2.ZERO
var from_size := 1.0
var basket_size := 0.9
var title := ""
var sound: AudioStream
var sound_plays := 0
# Node2D 拿不到 UI 主题；不设时 ThemeDB.fallback_font 在 Web 上没有中文字形，名字会成方框
var label_font: Font
var _player: AudioStreamPlayer
var _name_slip: StyleBoxFlat
var _application_active := true
var _audio: Node


func _ready() -> void:
	if sound == null and ResourceLoader.exists(SOUND_PATH):
		sound = load(SOUND_PATH) as AudioStream
	_player = AudioStreamPlayer.new()
	_player.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	add_child(_player)
	_audio = get_node("/root/AudioDirector")
	get_node("/root/TuningStore").value_changed.connect(_on_audio_setting_changed)
	visible = false


func is_active() -> bool:
	return not find_id.is_empty()


func total() -> float:
	return CALM_IN + CALM_HOLD + CALM_OUT if calm else RISE + HOLD + FLY


## 位置都是屏幕坐标；reduced 为低动效：原地淡入淡出，不升起、不飞、不缩放
func play(id: String, from_screen: Vector2, top_screen: Vector2, basket_screen: Vector2, scene_size: float, name_text: String, reduced: bool) -> void:
	settle()
	find_id = id
	calm = reduced
	elapsed = 0.0
	from = from_screen
	top = top_screen
	basket = basket_screen
	from_size = scene_size
	title = name_text
	modulate.a = pose().alpha
	visible = true
	if sound != null and _sound_allowed():
		sound_plays += 1
		if _player != null:
			_player.stream = sound
			_player.play()
	queue_redraw()


func is_sounding() -> bool:
	return _player != null and _player.playing


## 一次性的获得声不能排队等解锁或解除静音；只消费已有音频状态。
func _sound_allowed() -> bool:
	if not is_inside_tree() or get_tree().paused or not _application_active:
		return false
	for bus_name: StringName in [&"Master", &"SFX"]:
		var index := AudioServer.get_bus_index(bus_name)
		if index >= 0 and (AudioServer.is_bus_mute(index) or AudioServer.get_bus_volume_db(index) <= -80.0):
			return false
	if OS.has_feature("web"):
		return _audio != null and not _audio.awaiting_gesture() and _audio.backend_state() == "running"
	return true


func _on_audio_setting_changed(id: String, _requested: Variant, _active: Variant) -> void:
	if id.begins_with("audio.") and not _sound_allowed() and _player != null:
		_player.stop()


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		_application_active = false
		settle(true)
	elif what in [NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_WM_WINDOW_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED]:
		_application_active = true
	elif what == NOTIFICATION_PAUSED:
		settle(true)


## 走动、接着走时调用：物件直接算进篮子，声音让它自然放完。
## silence 用于暂停、失焦、回院和离开画卷：短音也停掉，恢复后不补播
func settle(silence: bool = false) -> void:
	if silence and _player != null:
		_player.stop()
	if find_id.is_empty():
		return
	var id := find_id
	find_id = ""
	visible = false
	queue_redraw()
	settled.emit(id)


func _process(delta: float) -> void:
	if is_sounding() and not _sound_allowed():
		_player.stop()
	if find_id.is_empty():
		return
	elapsed += delta
	if elapsed >= total():
		settle()
	else:
		modulate.a = pose().alpha
		queue_redraw()


## 当前帧的位置、大小、透明度
func pose() -> Dictionary:
	if calm:
		var alpha := 1.0
		if elapsed < CALM_IN:
			alpha = elapsed / CALM_IN
		elif elapsed > CALM_IN + CALM_HOLD:
			alpha = 1.0 - (elapsed - CALM_IN - CALM_HOLD) / CALM_OUT
		return {"at": top, "size": SHOW_SIZE, "alpha": clampf(alpha, 0.0, 1.0), "halo": 1.0}
	if elapsed < RISE:
		var t := ease(elapsed / RISE, 0.4)
		return {"at": from.lerp(top, t), "size": lerpf(from_size, SHOW_SIZE, t), "alpha": 1.0, "halo": t}
	if elapsed < RISE + HOLD:
		return {"at": top, "size": SHOW_SIZE, "alpha": 1.0, "halo": 1.0}
	var f := ease(clampf((elapsed - RISE - HOLD) / FLY, 0.0, 1.0), 2.2)
	return {"at": top.lerp(basket, f), "size": lerpf(SHOW_SIZE, basket_size, f), "alpha": 1.0, "halo": 1.0 - f}


func _draw() -> void:
	if find_id.is_empty():
		return
	var p := pose()
	var halo: float = p.halo
	if halo > 0.01:
		draw_circle(p.at + Vector2(0, 3), HALO, Color(INK, 0.12 * halo))
		draw_circle(p.at, HALO * 0.9, Color(DISC, 0.94 * halo))
		draw_arc(p.at, HALO * 0.9, 0.0, TAU, 48, Color(INK, 0.22 * halo), 1.5, true)
	KeepsakeArt.draw(self, find_id, p.at, p.size)
	if halo > NAME_FADE_FROM and not title.is_empty():
		var fade := name_fade(halo)
		var font := name_font()
		var slip := name_slip_rect(p.at, font, title)
		draw_style_box(name_slip_style(fade), slip)
		var baseline := Vector2(slip.position.x + NAME_PAD.x, slip.position.y + NAME_PAD.y + font.get_ascent(NAME_SIZE))
		draw_string(font, baseline, title, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE, Color(INK, fade))


## 名字纸签与字的透明度：光晕 ≤ 0.5 时为 0，0.5→1 线性升到 1（升起时淡入、飞走时淡尽）
static func name_fade(halo: float) -> float:
	return clampf((halo - NAME_FADE_FROM) / (1.0 - NAME_FADE_FROM), 0.0, 1.0)


func name_font() -> Font:
	return label_font if label_font != null else ThemeDB.fallback_font


## 名字纸签（不含投影）：水平以物件为中，宽 = 字宽 + 两侧 NAME_PAD，高 = 字体上下沿 + 上下 NAME_PAD，
## 下沿在物件中心上方 HALO + NAME_GAP
static func name_slip_rect(at: Vector2, font: Font, text: String) -> Rect2:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE).x + NAME_PAD.x * 2.0
	var height := font.get_ascent(NAME_SIZE) + font.get_descent(NAME_SIZE) + NAME_PAD.y * 2.0
	return Rect2(Vector2(at.x - width * 0.5, at.y - HALO - NAME_GAP - height), Vector2(width, height))


## 与悬停提示同一张暖纸（PaperTooltipStyle），整体透明度随展示光晕一起淡出
func name_slip_style(halo: float) -> StyleBoxFlat:
	if _name_slip == null:
		_name_slip = PaperTooltipStyle.panel()
		_name_slip.shadow_size = NAME_SHADOW_SIZE
		_name_slip.shadow_offset = NAME_SHADOW
	var fade := clampf(halo, 0.0, 1.0)
	_name_slip.bg_color = Color(PaperTooltipStyle.PANEL_FILL, PaperTooltipStyle.PANEL_FILL.a * fade)
	_name_slip.border_color = Color(PaperTooltipStyle.PANEL_EDGE, PaperTooltipStyle.PANEL_EDGE.a * fade)
	_name_slip.shadow_color = Color(PaperTooltipStyle.PANEL_SHADOW, PaperTooltipStyle.PANEL_SHADOW.a * fade)
	return _name_slip
