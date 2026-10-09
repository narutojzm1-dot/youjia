extends Node2D
## REQ-20261008-069（Owner GROK-CONTRIBUTOR）：小物在院里放好（存档确认后）那一下，
## 原来只是凭空出现，玩家要盯着看才知道放下了。在小物脚下泛开一圈很淡的暖墨落定圈，
## 0.5 秒内由小变大并淡掉，然后自己移除。小物本身的位置、大小、透明度一律不动，
## 所以遮挡判断、照片取景（照片只记 YardPropVisual / Sprite2D / Line2D）都不受影响。
## 低动效：圈不扩大，只在固定大小上淡出。布置编辑会暂停小院，圈照常走完。
const DURATION := 0.5
## 道具本地坐标：圈心贴近小物下沿（bounds("keepsake") 下沿为 +12）
const OFFSET := Vector2(0.0, 7.0)
const START_RADII := Vector2(9.0, 3.0)
const END_RADII := Vector2(22.0, 7.5)
const CALM_RADII := Vector2(17.0, 5.8)
const INK := Color(0.36, 0.27, 0.2)
const RING_ALPHA := 0.42
const FILL_ALPHA := 0.12
const RING_WIDTH := 1.5
const POINTS := 40

var elapsed := 0.0
var reduced := false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func progress() -> float:
	return clampf(elapsed / DURATION, 0.0, 1.0)


func radii() -> Vector2:
	if reduced:
		return CALM_RADII
	return START_RADII.lerp(END_RADII, ease(progress(), 0.4))


## 1 → 0：前段保持可见，后段淡得快
func fade() -> float:
	var p := progress()
	return (1.0 - p) * (1.0 - p * 0.5)


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= DURATION:
		visible = false
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var r := radii()
	var f := fade()
	if f <= 0.0:
		return
	draw_set_transform(OFFSET, 0.0, r)
	draw_circle(Vector2.ZERO, 1.0, Color(INK, FILL_ALPHA * f))
	draw_set_transform(Vector2.ZERO)
	var points := PackedVector2Array()
	for i: int in POINTS + 1:
		var angle := TAU * float(i) / float(POINTS)
		points.append(OFFSET + Vector2(cos(angle) * r.x, sin(angle) * r.y))
	draw_polyline(points, Color(INK, RING_ALPHA * f), RING_WIDTH, true)
