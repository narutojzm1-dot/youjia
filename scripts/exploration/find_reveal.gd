class_name FindReveal
extends Node2D
# 拾起成功后的短展示（docs/architecture/exploration-find-reveal.md）：物件从路边升到人物上方停一下，
# 再飞进提篮，同时一声原创短音。只是表现：核心状态在调用前已经改变，打断时立即收尾，不影响提交。
# 时长与尺寸都是等用户看过再调的候选值。

# 保留原静音降级路径；PR359短音仍待真实听验，不随视觉接入启用。
const SOUND_PATH := "res://assets/audio/sfx/exploration_find_get.ogg"
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
const GLOW := Color(1.0, 0.97, 0.86)
# 展示圆片用稍深的低饱和暖灰并接近不透明：白羽毛不再贴着浅底，路面纹理也透不上来
const DISC := Color(0.76, 0.72, 0.66)

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


func _ready() -> void:
	if sound == null and ResourceLoader.exists(SOUND_PATH):
		sound = load(SOUND_PATH) as AudioStream
	_player = AudioStreamPlayer.new()
	_player.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	add_child(_player)
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
	if sound != null:
		sound_plays += 1
		if _player != null:
			_player.stream = sound
			_player.play()
	queue_redraw()


func is_sounding() -> bool:
	return _player != null and _player.playing


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
	if halo > 0.5 and not title.is_empty():
		var font := label_font if label_font != null else ThemeDB.fallback_font
		var text_size := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17)
		var base: Vector2 = p.at + Vector2(-text_size.x * 0.5, -HALO - 8.0)
		var pill := Rect2(base + Vector2(-8, -text_size.y + 2), text_size + Vector2(16, 6))
		draw_rect(pill, Color(GLOW, 0.85 * halo))
		draw_string(font, base, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(INK, halo))
